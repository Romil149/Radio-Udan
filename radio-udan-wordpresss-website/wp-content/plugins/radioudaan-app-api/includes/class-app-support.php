<?php
/**
 * In-app support / contact form.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Stores support messages and emails site admin.
 */
class RadioUdaan_App_Support {

	const DB_VERSION_OPTION = 'radioudaan_support_db_version';
	const DB_VERSION        = '1.0';

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'init', array( __CLASS__, 'maybe_create_table' ), 5 );
	}

	/**
	 * @return string
	 */
	public static function table_name() {
		global $wpdb;
		return $wpdb->prefix . 'ru_support_contacts';
	}

	/**
	 * Create support messages table.
	 */
	public static function maybe_create_table() {
		if ( self::DB_VERSION === get_option( self::DB_VERSION_OPTION, '' ) ) {
			return;
		}

		global $wpdb;

		$table   = self::table_name();
		$charset = $wpdb->get_charset_collate();

		$sql = "CREATE TABLE {$table} (
			id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
			user_id bigint(20) unsigned NULL,
			name varchar(120) NOT NULL DEFAULT '',
			email varchar(190) NOT NULL DEFAULT '',
			subject varchar(200) NOT NULL DEFAULT '',
			message text NOT NULL,
			ip_hash varchar(64) NOT NULL DEFAULT '',
			created_at datetime NOT NULL,
			PRIMARY KEY  (id),
			KEY user_id (user_id),
			KEY created_at (created_at)
		) {$charset};";

		require_once ABSPATH . 'wp-admin/includes/upgrade.php';
		dbDelta( $sql );

		update_option( self::DB_VERSION_OPTION, self::DB_VERSION );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function handle_contact( WP_REST_Request $request ) {
		$body = $request->get_json_params();
		if ( ! is_array( $body ) ) {
			$body = array();
		}

		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		$user    = $user_id ? RadioUdaan_App_Users::get_by_id( $user_id ) : null;

		$name    = isset( $body['name'] ) ? sanitize_text_field( (string) $body['name'] ) : '';
		$email   = isset( $body['email'] ) ? strtolower( sanitize_email( (string) $body['email'] ) ) : '';
		$subject = isset( $body['subject'] ) ? sanitize_text_field( (string) $body['subject'] ) : '';
		$message = isset( $body['message'] ) ? sanitize_textarea_field( (string) $body['message'] ) : '';

		if ( $user ) {
			if ( '' === $name ) {
				$name = $user->display_name;
			}
			if ( '' === $email && is_email( $user->email ) ) {
				$email = $user->email;
			}
		}

		if ( strlen( $name ) < 2 ) {
			return new WP_Error( 'name_invalid', __( 'Name is required.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}
		if ( ! is_email( $email ) ) {
			return new WP_Error( 'email_invalid', __( 'Valid email is required.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}
		if ( strlen( $subject ) < 3 ) {
			return new WP_Error( 'subject_invalid', __( 'Subject is required.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}
		if ( strlen( $message ) < 10 ) {
			return new WP_Error( 'message_invalid', __( 'Message must be at least 10 characters.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		$ip = RadioUdaan_Rate_Limiter::get_client_ip();
		if ( RadioUdaan_Rate_Limiter::is_limited( 'support_ip_' . $ip, 5, HOUR_IN_SECONDS ) ) {
			return new WP_Error(
				'support_rate_limited',
				__( 'Too many messages. Try again later.', 'radioudaan-app-api' ),
				array( 'status' => 429 )
			);
		}
		RadioUdaan_Rate_Limiter::bump( 'support_ip_' . $ip, HOUR_IN_SECONDS );

		self::maybe_create_table();

		global $wpdb;

		$now = current_time( 'mysql', true );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery
		$ok = $wpdb->insert(
			self::table_name(),
			array(
				'user_id'    => $user_id ? (int) $user_id : null,
				'name'       => $name,
				'email'      => $email,
				'subject'    => $subject,
				'message'    => $message,
				'ip_hash'    => hash( 'sha256', $ip ),
				'created_at' => $now,
			),
			array( '%d', '%s', '%s', '%s', '%s', '%s', '%s' )
		);

		if ( ! $ok ) {
			return new WP_Error( 'support_failed', __( 'Could not send message.', 'radioudaan-app-api' ), array( 'status' => 500 ) );
		}

		$message_id = (int) $wpdb->insert_id;
		$mailed     = self::email_admin( $name, $email, $subject, $message, $user_id );

		RadioUdaan_App_Logger::log(
			'support_contact',
			array(
				'message_id' => $message_id,
				'user_id'    => $user_id ? (int) $user_id : 0,
				'mailed'     => $mailed,
			)
		);

		return new WP_REST_Response(
			array(
				'status'     => 'sent',
				'message_id' => $message_id,
			),
			201
		);
	}

	/**
	 * @param string   $name    Sender name.
	 * @param string   $email   Sender email.
	 * @param string   $subject Subject.
	 * @param string   $message Body.
	 * @param int|null $user_id App user id.
	 * @return bool
	 */
	private static function email_admin( $name, $email, $subject, $message, $user_id ) {
		$to = RadioUdaan_App_Settings::get_support_email();
		if ( ! is_email( $to ) ) {
			$to = get_option( 'admin_email' );
		}

		$app_name = RadioUdaan_App_Branding::get_app_name();
		$line     = sprintf(
			"From: %s <%s>\nApp: %s\nUser ID: %s\n\n%s",
			$name,
			$email,
			$app_name,
			$user_id ? (string) $user_id : 'guest',
			$message
		);

		$headers = array(
			'Content-Type: text/plain; charset=UTF-8',
			'Reply-To: ' . $name . ' <' . $email . '>',
		);

		$sent = wp_mail(
			$to,
			sprintf( '[%s] %s', $app_name, $subject ),
			$line,
			$headers
		);

		if ( ! $sent ) {
			RadioUdaan_App_Logger::log( 'mail_failed', array( 'type' => 'support_contact' ) );
		}

		return (bool) $sent;
	}
}

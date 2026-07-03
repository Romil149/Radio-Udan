<?php
/**
 * Push notification devices and in-app notification inbox.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * FCM device registration and user notification storage.
 */
class RadioUdaan_App_Notifications {

	const DB_VERSION_OPTION = 'radioudaan_notifications_db_version';
	const DB_VERSION        = '1.0';

	const PLATFORM_ANDROID = 'android';
	const PLATFORM_IOS     = 'ios';

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'init', array( __CLASS__, 'maybe_create_tables' ), 5 );
	}

	/**
	 * @return string
	 */
	public static function devices_table() {
		global $wpdb;
		return $wpdb->prefix . 'ru_app_devices';
	}

	/**
	 * @return string
	 */
	public static function notifications_table() {
		global $wpdb;
		return $wpdb->prefix . 'ru_app_notifications';
	}

	/**
	 * Create device + notification tables.
	 */
	public static function maybe_create_tables() {
		if ( self::DB_VERSION === get_option( self::DB_VERSION_OPTION, '' ) ) {
			return;
		}

		global $wpdb;

		$charset = $wpdb->get_charset_collate();

		$devices = self::devices_table();
		$sql1    = "CREATE TABLE {$devices} (
			id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
			user_id bigint(20) unsigned NOT NULL,
			fcm_token varchar(255) NOT NULL DEFAULT '',
			platform varchar(16) NOT NULL DEFAULT '',
			created_at datetime NOT NULL,
			updated_at datetime NOT NULL,
			last_seen_at datetime NOT NULL,
			PRIMARY KEY  (id),
			UNIQUE KEY fcm_token (fcm_token),
			KEY user_id (user_id),
			KEY platform (platform)
		) {$charset};";

		$notifications = self::notifications_table();
		$sql2          = "CREATE TABLE {$notifications} (
			id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
			user_id bigint(20) unsigned NOT NULL,
			type varchar(32) NOT NULL DEFAULT 'general',
			title varchar(200) NOT NULL DEFAULT '',
			body text NOT NULL,
			data_json longtext NULL,
			read_at datetime NULL,
			created_at datetime NOT NULL,
			PRIMARY KEY  (id),
			KEY user_id (user_id),
			KEY read_at (read_at),
			KEY created_at (created_at)
		) {$charset};";

		require_once ABSPATH . 'wp-admin/includes/upgrade.php';
		dbDelta( $sql1 );
		dbDelta( $sql2 );

		update_option( self::DB_VERSION_OPTION, self::DB_VERSION );
	}

	/**
	 * @param int               $user_id User id.
	 * @param array<string,mixed> $body  Request JSON.
	 * @return array|WP_Error
	 */
	public static function register_device( $user_id, array $body ) {
		self::maybe_create_tables();

		$token    = isset( $body['fcm_token'] ) ? sanitize_text_field( (string) $body['fcm_token'] ) : '';
		$platform = isset( $body['platform'] ) ? sanitize_key( (string) $body['platform'] ) : '';

		if ( strlen( $token ) < 20 ) {
			return new WP_Error( 'token_invalid', __( 'FCM token is required.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		if ( ! in_array( $platform, array( self::PLATFORM_ANDROID, self::PLATFORM_IOS ), true ) ) {
			return new WP_Error(
				'platform_invalid',
				__( 'Platform must be android or ios.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		global $wpdb;

		$table = self::devices_table();
		$now   = current_time( 'mysql', true );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$existing = $wpdb->get_row(
			$wpdb->prepare(
				"SELECT id, user_id FROM {$table} WHERE fcm_token = %s",
				$token
			)
		);

		if ( $existing ) {
			// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
			$wpdb->update(
				$table,
				array(
					'user_id'      => (int) $user_id,
					'platform'     => $platform,
					'updated_at'   => $now,
					'last_seen_at' => $now,
				),
				array( 'id' => (int) $existing->id ),
				array( '%d', '%s', '%s', '%s' ),
				array( '%d' )
			);
			$device_id = (int) $existing->id;
		} else {
			// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery
			$ok = $wpdb->insert(
				$table,
				array(
					'user_id'      => (int) $user_id,
					'fcm_token'    => $token,
					'platform'     => $platform,
					'created_at'   => $now,
					'updated_at'   => $now,
					'last_seen_at' => $now,
				),
				array( '%d', '%s', '%s', '%s', '%s', '%s' )
			);
			if ( ! $ok ) {
				return new WP_Error( 'device_register_failed', __( 'Could not register device.', 'radioudaan-app-api' ), array( 'status' => 500 ) );
			}
			$device_id = (int) $wpdb->insert_id;
		}

		self::maybe_seed_welcome_notification( $user_id );

		RadioUdaan_App_Logger::log(
			'device_registered',
			array(
				'user_id'   => (int) $user_id,
				'device_id' => $device_id,
				'platform'  => $platform,
			)
		);

		return array(
			'status'    => 'registered',
			'device_id' => $device_id,
			'platform'  => $platform,
		);
	}

	/**
	 * @param int $user_id  User id.
	 * @param int $page     Page.
	 * @param int $per_page Per page.
	 * @return array
	 */
	public static function list_for_user( $user_id, $page = 1, $per_page = 20 ) {
		self::maybe_create_tables();

		global $wpdb;

		$page     = max( 1, (int) $page );
		$per_page = max( 1, min( 50, (int) $per_page ) );
		$offset   = ( $page - 1 ) * $per_page;
		$table    = self::notifications_table();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$total = (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE user_id = %d",
				(int) $user_id
			)
		);

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$table} WHERE user_id = %d ORDER BY created_at DESC, id DESC LIMIT %d OFFSET %d",
				(int) $user_id,
				$per_page,
				$offset
			)
		);

		$items = array();
		foreach ( is_array( $rows ) ? $rows : array() as $row ) {
			$items[] = self::format_notification( $row );
		}

		return array(
			'items'        => $items,
			'page'         => $page,
			'per_page'     => $per_page,
			'total'        => $total,
			'unread_count' => self::count_unread_for_user( $user_id ),
			'total_pages'  => $per_page > 0 ? (int) ceil( $total / $per_page ) : 0,
		);
	}

	/**
	 * @param int $user_id User id.
	 * @return int
	 */
	public static function count_unread_for_user( $user_id ) {
		self::maybe_create_tables();

		global $wpdb;

		$table = self::notifications_table();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		return (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE user_id = %d AND read_at IS NULL",
				(int) $user_id
			)
		);
	}

	/**
	 * @param int $user_id User id.
	 * @param int $id      Notification id.
	 * @return array|WP_Error
	 */
	public static function mark_read( $user_id, $id ) {
		self::maybe_create_tables();

		global $wpdb;

		$table = self::notifications_table();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$row = $wpdb->get_row(
			$wpdb->prepare(
				"SELECT * FROM {$table} WHERE id = %d AND user_id = %d",
				(int) $id,
				(int) $user_id
			)
		);

		if ( ! $row ) {
			return new WP_Error( 'not_found', __( 'Notification not found.', 'radioudaan-app-api' ), array( 'status' => 404 ) );
		}

		if ( $row->read_at ) {
			return array(
				'status'       => 'already_read',
				'notification' => self::format_notification( $row ),
			);
		}

		$now = current_time( 'mysql', true );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$wpdb->update(
			$table,
			array( 'read_at' => $now ),
			array( 'id' => (int) $id ),
			array( '%s' ),
			array( '%d' )
		);

		$row->read_at = $now;

		return array(
			'status'       => 'read',
			'notification' => self::format_notification( $row ),
		);
	}

	/**
	 * Mark every unread notification for a user as read.
	 *
	 * @param int $user_id User id.
	 * @return array<string,int|string>
	 */
	public static function mark_all_read( $user_id ) {
		self::maybe_create_tables();

		global $wpdb;

		$table = self::notifications_table();
		$now   = current_time( 'mysql', true );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$marked = $wpdb->query(
			$wpdb->prepare(
				"UPDATE {$table} SET read_at = %s WHERE user_id = %d AND read_at IS NULL",
				$now,
				(int) $user_id
			)
		);

		return array(
			'status' => 'read_all',
			'marked' => false === $marked ? 0 : (int) $marked,
		);
	}

	/**
	 * Users who have at least one registered push device.
	 *
	 * @return array<int,array<string,mixed>>
	 */
	public static function list_users_with_devices() {
		self::maybe_create_tables();

		global $wpdb;

		$devices = self::devices_table();
		$users   = RadioUdaan_App_Users::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT u.id, u.display_name, u.email, u.phone_e164,
					COUNT(d.id) AS device_count,
					MAX(d.last_seen_at) AS last_device_seen
				FROM {$users} u
				INNER JOIN {$devices} d ON d.user_id = u.id
				WHERE u.status != %s
				GROUP BY u.id, u.display_name, u.email, u.phone_e164
				ORDER BY last_device_seen DESC, u.id DESC",
				RadioUdaan_App_Users::STATUS_DELETED
			),
			ARRAY_A
		);

		return is_array( $rows ) ? $rows : array();
	}

	/**
	 * @return int
	 */
	public static function count_registered_devices() {
		self::maybe_create_tables();

		global $wpdb;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		return (int) $wpdb->get_var( 'SELECT COUNT(*) FROM ' . self::devices_table() );
	}

	/**
	 * Distinct user IDs that have push devices.
	 *
	 * @return int[]
	 */
	public static function user_ids_with_devices() {
		self::maybe_create_tables();

		global $wpdb;

		$table = self::devices_table();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$rows = $wpdb->get_col( "SELECT DISTINCT user_id FROM {$table} ORDER BY user_id ASC" );

		$out = array();
		foreach ( is_array( $rows ) ? $rows : array() as $id ) {
			$out[] = (int) $id;
		}

		return $out;
	}

	/**
	 * Create notifications for multiple users (admin broadcast).
	 *
	 * @param int[]                $user_ids User ids.
	 * @param string               $title    Title.
	 * @param string               $body     Body.
	 * @param string               $type     Type slug.
	 * @param array<string,mixed>  $data     Payload.
	 * @return array{created:int,push_sent:int,push_failed:int}
	 */
	public static function create_for_users( array $user_ids, $title, $body, $type = 'general', array $data = array() ) {
		$result = array(
			'created'     => 0,
			'push_sent'   => 0,
			'push_failed' => 0,
			'push_pruned' => 0,
			'fcm_skipped' => ! RadioUdaan_App_Fcm_Sender::is_configured(),
		);

		foreach ( array_unique( array_map( 'intval', $user_ids ) ) as $user_id ) {
			if ( $user_id < 1 ) {
				continue;
			}

			$created = self::create( $user_id, $title, $body, $type, $data );
			if ( empty( $created['id'] ) ) {
				continue;
			}

			++$result['created'];

			$push = isset( $created['push'] ) && is_array( $created['push'] ) ? $created['push'] : array();
			$result['push_sent']   += isset( $push['sent'] ) ? (int) $push['sent'] : 0;
			$result['push_failed'] += isset( $push['failed'] ) ? (int) $push['failed'] : 0;
			$result['push_pruned'] += isset( $push['pruned'] ) ? (int) $push['pruned'] : 0;
			if ( ! empty( $push['skipped'] ) ) {
				$result['fcm_skipped'] = true;
			}
		}

		return $result;
	}

	/**
	 * Create a notification (admin / internal use).
	 *
	 * @param int                  $user_id User id.
	 * @param string               $title   Title.
	 * @param string               $body    Body.
	 * @param string               $type    Type slug.
	 * @param array<string,mixed>  $data    Optional payload.
	 * @return array{id:int|false,push:array{sent:int,failed:int,pruned:int,skipped:bool}}
	 */
	public static function create( $user_id, $title, $body, $type = 'general', array $data = array() ) {
		self::maybe_create_tables();

		global $wpdb;

		$now = current_time( 'mysql', true );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery
		$ok = $wpdb->insert(
			self::notifications_table(),
			array(
				'user_id'    => (int) $user_id,
				'type'       => sanitize_key( $type ),
				'title'      => sanitize_text_field( $title ),
				'body'       => sanitize_textarea_field( $body ),
				'data_json'  => $data ? wp_json_encode( $data ) : null,
				'created_at' => $now,
			),
			array( '%d', '%s', '%s', '%s', '%s', '%s' )
		);

		$notification_id = $ok ? (int) $wpdb->insert_id : false;

		$push_result = array(
			'sent'    => 0,
			'failed'  => 0,
			'pruned'  => 0,
			'skipped' => false,
		);

		if ( $notification_id && self::should_deliver_push_for_type( $type, (int) $user_id ) ) {
			$push_result = self::deliver_push(
				(int) $user_id,
				$notification_id,
				$title,
				$body,
				$type,
				$data
			);
		} elseif ( $notification_id && ! RadioUdaan_App_Fcm_Sender::is_configured() ) {
			$push_result['skipped'] = true;
		}

		return array(
			'id'   => $notification_id,
			'push' => $push_result,
		);
	}

	/**
	 * @param int $user_id User id.
	 * @return array<int,array<string,mixed>>
	 */
	public static function get_device_tokens_for_user( $user_id ) {
		self::maybe_create_tables();

		global $wpdb;

		$table = self::devices_table();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT id, fcm_token, platform FROM {$table} WHERE user_id = %d ORDER BY last_seen_at DESC",
				(int) $user_id
			),
			ARRAY_A
		);

		return is_array( $rows ) ? $rows : array();
	}

	/**
	 * @param int $device_id Device row id.
	 * @return bool
	 */
	public static function delete_device( $device_id ) {
		self::maybe_create_tables();

		global $wpdb;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$deleted = $wpdb->delete(
			self::devices_table(),
			array( 'id' => (int) $device_id ),
			array( '%d' )
		);

		return (bool) $deleted;
	}

	/**
	 * @param string $type    Notification type.
	 * @param int    $user_id User id.
	 * @return bool
	 */
	private static function should_deliver_push_for_type( $type, $user_id ) {
		$type = sanitize_key( (string) $type );
		$prefs = RadioUdaan_App_User_Notification_Prefs::get_for_user( $user_id );

		if ( in_array( $type, array( 'welcome', 'general', 'account', 'security' ), true ) ) {
			return true;
		}

		if ( in_array( $type, array( 'event', 'events' ), true ) ) {
			return ! empty( $prefs['events_enabled'] );
		}

		if ( in_array( $type, array( 'library', 'live', 'live_broadcast', 'live_broadcasts' ), true ) ) {
			return ! empty( $prefs['live_broadcasts_enabled'] );
		}

		if ( in_array( $type, array( 'promotion', 'promotions' ), true ) ) {
			return ! empty( $prefs['promotions_enabled'] );
		}

		return true;
	}

	/**
	 * @param int                  $user_id         User id.
	 * @param int                  $notification_id Notification id.
	 * @param string               $title           Title.
	 * @param string               $body            Body.
	 * @param string               $type            Type slug.
	 * @param array<string,mixed>  $data            Payload.
	 * @return array{sent:int,failed:int,pruned:int,skipped:bool}
	 */
	private static function deliver_push( $user_id, $notification_id, $title, $body, $type, array $data = array() ) {
		$payload = array_merge(
			$data,
			array(
				'notification_id' => (string) $notification_id,
			)
		);

		$result = RadioUdaan_App_Fcm_Sender::send_to_user_devices(
			$user_id,
			$title,
			$body,
			$type,
			$payload
		);

		if ( $result['sent'] > 0 || $result['failed'] > 0 || $result['pruned'] > 0 ) {
			RadioUdaan_App_Logger::log(
				'fcm_push_delivery',
				array(
					'user_id'         => (int) $user_id,
					'notification_id' => (int) $notification_id,
					'type'            => sanitize_key( (string) $type ),
					'sent'            => (int) $result['sent'],
					'failed'          => (int) $result['failed'],
					'pruned'          => (int) $result['pruned'],
				)
			);
		}

		return $result;
	}

	/**
	 * Seed a welcome notification once per user (dev / demo inbox).
	 *
	 * @param int $user_id User id.
	 */
	private static function maybe_seed_welcome_notification( $user_id ) {
		if ( ! apply_filters( 'radioudaan_app_seed_welcome_notification', true ) ) {
			return;
		}

		global $wpdb;

		$table = self::notifications_table();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$count = (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE user_id = %d",
				(int) $user_id
			)
		);

		if ( $count > 0 ) {
			return;
		}

		$app_name = RadioUdaan_App_Branding::get_app_name();

		self::create(
			$user_id,
			sprintf(
				/* translators: %s: app name */
				__( 'Welcome to %s', 'radioudaan-app-api' ),
				$app_name
			),
			__( 'You will see event updates and library highlights here.', 'radioudaan-app-api' ),
			'welcome',
			array( 'seeded' => true )
		);
	}

	/**
	 * @param object $row DB row.
	 * @return array<string,mixed>
	 */
	private static function format_notification( $row ) {
		$data = array();
		if ( ! empty( $row->data_json ) ) {
			$decoded = json_decode( $row->data_json, true );
			if ( is_array( $decoded ) ) {
				$data = $decoded;
			}
		}

		return array(
			'id'         => (int) $row->id,
			'type'       => (string) $row->type,
			'title'      => (string) $row->title,
			'body'       => (string) $row->body,
			'data'       => $data,
			'is_read'    => ! empty( $row->read_at ),
			'read_at'    => $row->read_at ? gmdate( 'c', strtotime( $row->read_at ) ) : null,
			'created_at' => gmdate( 'c', strtotime( $row->created_at ) ),
		);
	}
}

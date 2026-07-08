<?php
/**
 * MSG91 OTP SMS provider (India domestic sendhttp.php + DLT).
 *
 * Accepts E.164 input but delivery is reliable for +91 only unless
 * international routing is configured separately. See .cursor/memory/msg91-international.md.
 *
 * Configure in WP admin or wp-config.php:
 * - radioudaan_msg91_auth_key (option) or RADIOUDAAN_MSG91_AUTH_KEY constant
 * - radioudaan_msg91_sender_id (option) or RADIOUDAAN_MSG91_SENDER_ID constant
 * - radioudaan_msg91_template_id (option) — DLT template id when required
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Sends OTP via MSG91 when credentials are present.
 */
class RadioUdaan_Otp_Msg91 {

	/**
	 * Register hook on `radioudaan_app_api_send_otp`.
	 */
	public static function init() {
		add_action( 'radioudaan_app_api_send_otp', array( __CLASS__, 'send_otp' ), 10, 2 );
	}

	/**
	 * @return bool
	 */
	public static function is_configured() {
		return '' !== self::get_auth_key();
	}

	/**
	 * @param string $phone E.164 phone.
	 * @param string $otp   OTP digits.
	 */
	public static function send_otp( $phone, $otp ) {
		if ( ! self::is_configured() ) {
			return;
		}

		if ( RadioUdaan_Otp_Service::expose_dev_otp_public() ) {
			return;
		}

		$auth_key = self::get_auth_key();
		$mobile   = preg_replace( '/\D/', '', $phone );
		// Must match VILPOWER/MSG91 DLT template `1107178349700604138` exactly (only OTP digits vary).
		$message = sprintf(
			'Your Radio Udaan verification code is %s. Valid for 5 minutes. -Udaan Empowerment Trust',
			$otp
		);

		$body = array(
			'mobiles' => $mobile,
			'message' => $message,
			'authkey' => $auth_key,
		);

		$sender = self::get_sender_id();
		if ( $sender ) {
			$body['sender'] = $sender;
		}

		$template = self::get_template_id();
		if ( $template ) {
			$body['DLT_TE_ID'] = $template;
		}

		$response = wp_remote_post(
			'https://api.msg91.com/api/sendhttp.php',
			array(
				'timeout' => 15,
				'body'    => $body,
			)
		);

		if ( is_wp_error( $response ) ) {
			if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
				// phpcs:ignore WordPress.PHP.DevelopmentFunctions.error_log_error_log
				error_log( 'RadioUdaan MSG91: ' . $response->get_error_message() );
			}
			return;
		}

		$code = wp_remote_retrieve_response_code( $response );
		if ( $code < 200 || $code >= 300 ) {
			if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
				// phpcs:ignore WordPress.PHP.DevelopmentFunctions.error_log_error_log
				error_log( 'RadioUdaan MSG91 HTTP ' . $code . ': ' . wp_remote_retrieve_body( $response ) );
			}
		}
	}

	/**
	 * @return string
	 */
	private static function get_auth_key() {
		if ( defined( 'RADIOUDAAN_MSG91_AUTH_KEY' ) && RADIOUDAAN_MSG91_AUTH_KEY ) {
			return (string) RADIOUDAAN_MSG91_AUTH_KEY;
		}

		return (string) get_option( 'radioudaan_msg91_auth_key', '' );
	}

	/**
	 * @return string
	 */
	private static function get_sender_id() {
		if ( defined( 'RADIOUDAAN_MSG91_SENDER_ID' ) && RADIOUDAAN_MSG91_SENDER_ID ) {
			return (string) RADIOUDAAN_MSG91_SENDER_ID;
		}

		return (string) get_option( 'radioudaan_msg91_sender_id', 'RADIO' );
	}

	/**
	 * @return string
	 */
	private static function get_template_id() {
		if ( defined( 'RADIOUDAAN_MSG91_TEMPLATE_ID' ) && RADIOUDAAN_MSG91_TEMPLATE_ID ) {
			return (string) RADIOUDAAN_MSG91_TEMPLATE_ID;
		}

		return (string) get_option( 'radioudaan_msg91_template_id', '' );
	}
}

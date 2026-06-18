<?php
/**
 * Plugin settings (WP options + wp-config overrides).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Central settings accessors for the App API.
 */
class RadioUdaan_App_Settings {

	const OPTION_MAX_UPLOAD_MB              = 'radioudaan_app_api_max_upload_mb';
	const OPTION_DEV_OTP                    = 'radioudaan_app_api_dev_otp';
	const OPTION_DEV_AUTH                   = 'radioudaan_app_api_dev_auth';
	const OPTION_OTP_LIMIT_HOUR             = 'radioudaan_otp_limit_hour';
	const OPTION_OTP_VERIFY_MAX             = 'radioudaan_otp_verify_max';
	const OPTION_OTP_RESEND_DELAY           = 'radioudaan_otp_resend_delay';
	const OPTION_REG_LIMIT_PHONE_HOUR       = 'radioudaan_reg_limit_phone_hour';
	const OPTION_REG_LIMIT_IP_HOUR          = 'radioudaan_reg_limit_ip_hour';
	const OPTION_ALLOWED_MIME               = 'radioudaan_allowed_mime';
	const OPTION_MAX_FILES_PER_FIELD        = 'radioudaan_max_files_per_field';
	const OPTION_PREVENT_DUPLICATE_REG      = 'radioudaan_prevent_duplicate_reg';
	const OPTION_UPLOAD_RETENTION_DAYS      = 'radioudaan_upload_retention_days';
	const OPTION_STREAM_URL                 = 'radioudaan_stream_url';
	const OPTION_API_BASE_URL               = 'radioudaan_app_api_base_url';
	const OPTION_PRIVATE_UPLOADS            = 'radioudaan_private_uploads';
	const OPTION_PRIVACY_POLICY_URL         = 'radioudaan_privacy_policy_url';
	const OPTION_TERMS_URL                  = 'radioudaan_terms_url';
	const OPTION_ABOUT_URL                  = 'radioudaan_about_url';
	const OPTION_CONTACT_URL                = 'radioudaan_contact_url';
	const OPTION_REQUIRE_UNIQUE_EMAIL       = 'radioudaan_require_unique_email';
	const OPTION_REQUIRE_EMAIL_VERIFICATION = 'radioudaan_require_email_verification';
	const OPTION_PASSWORD_MIN_LENGTH        = 'radioudaan_password_min_length';
	const OPTION_EMAIL_VERIFY_SUBJECT       = 'radioudaan_email_verify_subject';
	const OPTION_EMAIL_VERIFY_BODY          = 'radioudaan_email_verify_body';
	const OPTION_EMAIL_RESET_SUBJECT        = 'radioudaan_email_reset_subject';
	const OPTION_EMAIL_RESET_BODY           = 'radioudaan_email_reset_body';
	const OPTION_SUPPORT_HELPLINE_PHONE     = 'radioudaan_support_helpline_phone';
	const OPTION_SUPPORT_EMAIL              = 'radioudaan_support_email';
	const OPTION_FCM_SERVICE_ACCOUNT        = 'radioudaan_fcm_service_account';
	const OPTION_FCM_PROJECT_ID             = 'radioudaan_fcm_project_id';
	const OPTION_NOTIF_EVENTS_DEFAULT       = 'radioudaan_notif_events_default';
	const OPTION_NOTIF_LIBRARY_DEFAULT      = 'radioudaan_notif_library_default';
	const OPTION_NOTIF_PROMOTIONS_DEFAULT   = 'radioudaan_notif_promotions_default';

	const DEFAULT_STREAM_URL = 'https://stream.radioudaan.com/listen/radio_udaan/radio.mp3';

	/**
	 * @return int Megabytes.
	 */
	public static function get_max_upload_mb() {
		$mb = (int) get_option( self::OPTION_MAX_UPLOAD_MB, 25 );
		if ( $mb < 1 ) {
			$mb = 25;
		}

		return (int) apply_filters( 'radioudaan_app_api_max_upload_mb', $mb );
	}

	/**
	 * @return bool
	 */
	public static function is_dev_otp_enabled() {
		if ( self::is_production_environment() ) {
			return false;
		}
		if ( defined( 'RADIOUDAAN_APP_API_DEV_OTP' ) ) {
			return (bool) RADIOUDAAN_APP_API_DEV_OTP;
		}

		return (bool) get_option( self::OPTION_DEV_OTP, false );
	}

	/**
	 * @return bool
	 */
	public static function is_dev_auth_enabled() {
		if ( self::is_production_environment() ) {
			return false;
		}
		if ( defined( 'RADIOUDAAN_APP_API_DEV_AUTH' ) && RADIOUDAAN_APP_API_DEV_AUTH ) {
			return true;
		}

		return (bool) get_option( self::OPTION_DEV_AUTH, false );
	}

	/**
	 * Dev bypass flags must never apply on production hosts.
	 *
	 * @return bool
	 */
	private static function is_production_environment() {
		if ( function_exists( 'wp_get_environment_type' ) && 'production' === wp_get_environment_type() ) {
			return true;
		}

		return defined( 'WP_ENVIRONMENT_TYPE' ) && 'production' === WP_ENVIRONMENT_TYPE;
	}

	/**
	 * @return int
	 */
	public static function get_otp_limit_per_hour() {
		return max( 1, (int) get_option( self::OPTION_OTP_LIMIT_HOUR, 8 ) );
	}

	/**
	 * @return int
	 */
	public static function get_otp_verify_max_attempts() {
		return max( 1, (int) get_option( self::OPTION_OTP_VERIFY_MAX, 5 ) );
	}

	/**
	 * @return int
	 */
	public static function get_otp_resend_delay_sec() {
		return max( 30, (int) get_option( self::OPTION_OTP_RESEND_DELAY, 60 ) );
	}

	/**
	 * @return int
	 */
	public static function get_registration_limit_per_phone_hour() {
		return max( 1, (int) get_option( self::OPTION_REG_LIMIT_PHONE_HOUR, 10 ) );
	}

	/**
	 * @return int
	 */
	public static function get_registration_limit_per_ip_hour() {
		return max( 1, (int) get_option( self::OPTION_REG_LIMIT_IP_HOUR, 20 ) );
	}

	/**
	 * @return int
	 */
	public static function get_max_files_per_field() {
		return max( 1, (int) get_option( self::OPTION_MAX_FILES_PER_FIELD, 1 ) );
	}

	/**
	 * @return bool
	 */
	public static function prevent_duplicate_registration() {
		return (bool) get_option( self::OPTION_PREVENT_DUPLICATE_REG, true );
	}

	/**
	 * @return int
	 */
	public static function get_upload_retention_days() {
		return max( 1, (int) get_option( self::OPTION_UPLOAD_RETENTION_DAYS, 7 ) );
	}

	/**
	 * @return bool
	 */
	public static function use_private_uploads() {
		return (bool) get_option( self::OPTION_PRIVATE_UPLOADS, true );
	}

	/**
	 * @return string
	 */
	public static function get_stream_url() {
		$url = (string) get_option( self::OPTION_STREAM_URL, self::DEFAULT_STREAM_URL );
		return $url ? esc_url_raw( $url ) : self::DEFAULT_STREAM_URL;
	}

	/**
	 * REST API base for this WordPress site (no trailing slash).
	 * Override in Settings when the app must use a public URL (CDN, reverse proxy).
	 * Empty option = auto from site URL.
	 *
	 * @return string
	 */
	public static function get_api_base_url() {
		$override = trim( (string) get_option( self::OPTION_API_BASE_URL, '' ) );
		if ( $override ) {
			return untrailingslashit( esc_url_raw( $override ) );
		}

		return untrailingslashit( rest_url( 'radioudaan/v1' ) );
	}

	/**
	 * @param string $option   WP option key for override.
	 * @param string $default  Path or URL when option and WP defaults are empty.
	 * @return string
	 */
	private static function get_legal_url( $option, $default ) {
		$override = trim( (string) get_option( $option, '' ) );
		if ( $override ) {
			return esc_url_raw( $override );
		}

		return esc_url_raw( $default );
	}

	/**
	 * @return string
	 */
	public static function get_privacy_policy_url() {
		$override = trim( (string) get_option( self::OPTION_PRIVACY_POLICY_URL, '' ) );
		if ( $override ) {
			return esc_url_raw( $override );
		}

		if ( function_exists( 'get_privacy_policy_url' ) ) {
			$wp_url = get_privacy_policy_url();
			if ( $wp_url ) {
				return esc_url_raw( $wp_url );
			}
		}

		return esc_url_raw( home_url( '/privacy-policy/' ) );
	}

	/**
	 * @return string
	 */
	public static function get_terms_url() {
		return self::get_legal_url( self::OPTION_TERMS_URL, home_url( '/terms/' ) );
	}

	/**
	 * @return string
	 */
	public static function get_about_url() {
		return self::get_legal_url( self::OPTION_ABOUT_URL, home_url( '/about/' ) );
	}

	/**
	 * @return string
	 */
	public static function get_contact_url() {
		return self::get_legal_url( self::OPTION_CONTACT_URL, home_url( '/contact/' ) );
	}

	/**
	 * @return string E.164 or empty.
	 */
	public static function get_support_helpline_phone() {
		$phone = preg_replace( '/\s+/', '', (string) get_option( self::OPTION_SUPPORT_HELPLINE_PHONE, '' ) );
		if ( $phone && preg_match( '/^\+[1-9]\d{7,14}$/', $phone ) ) {
			return $phone;
		}

		return '';
	}

	/**
	 * @return string
	 */
	public static function get_support_email() {
		$email = strtolower( sanitize_email( (string) get_option( self::OPTION_SUPPORT_EMAIL, '' ) ) );
		if ( is_email( $email ) ) {
			return $email;
		}

		return '';
	}

	/**
	 * Firebase service account JSON (admin only — never exposed in public config).
	 *
	 * @return string
	 */
	public static function get_fcm_service_account_json() {
		if ( defined( 'RADIOUDAAN_FCM_SERVICE_ACCOUNT_JSON' ) ) {
			return (string) RADIOUDAAN_FCM_SERVICE_ACCOUNT_JSON;
		}

		if ( defined( 'RADIOUDAAN_FCM_SERVICE_ACCOUNT_PATH' ) ) {
			$path = (string) RADIOUDAAN_FCM_SERVICE_ACCOUNT_PATH;
			if ( is_readable( $path ) ) {
				return (string) file_get_contents( $path ); // phpcs:ignore WordPress.WP.AlternativeFunctions.file_get_contents_file_get_contents
			}
		}

		return (string) get_option( self::OPTION_FCM_SERVICE_ACCOUNT, '' );
	}

	/**
	 * @return bool
	 */
	public static function is_fcm_service_account_set() {
		$raw = trim( self::get_fcm_service_account_json() );
		if ( '' === $raw ) {
			return false;
		}

		$decoded = json_decode( $raw, true );
		if ( ! is_array( $decoded ) ) {
			return false;
		}

		return ! empty( $decoded['client_email'] ) && ! empty( $decoded['private_key'] );
	}

	/**
	 * @return string
	 */
	public static function get_fcm_project_id() {
		if ( defined( 'RADIOUDAAN_FCM_PROJECT_ID' ) ) {
			return (string) RADIOUDAAN_FCM_PROJECT_ID;
		}

		return sanitize_text_field( (string) get_option( self::OPTION_FCM_PROJECT_ID, '' ) );
	}

	/**
	 * Default notification opt-in flags for new installs (app may override per user later).
	 *
	 * @return array<string,bool>
	 */
	public static function get_notification_preferences_defaults() {
		return array(
			'events_enabled'     => (bool) get_option( self::OPTION_NOTIF_EVENTS_DEFAULT, 1 ),
			'library_enabled'    => (bool) get_option( self::OPTION_NOTIF_LIBRARY_DEFAULT, 1 ),
			'promotions_enabled' => (bool) get_option( self::OPTION_NOTIF_PROMOTIONS_DEFAULT, 0 ),
		);
	}

	/**
	 * @return string[]
	 */
	public static function get_allowed_mime_list() {
		$raw = (string) get_option( self::OPTION_ALLOWED_MIME, '' );
		if ( '' === trim( $raw ) ) {
			return self::default_mime_list();
		}

		$parts = array_map( 'trim', explode( ',', $raw ) );
		$out   = array();
		foreach ( $parts as $mime ) {
			if ( $mime && preg_match( '#^[a-z0-9.+-]+/[a-z0-9.+-]+$#i', $mime ) ) {
				$out[] = strtolower( $mime );
			}
		}

		return $out ? $out : self::default_mime_list();
	}

	/**
	 * @return array<string,string> wp_handle_upload mimes map.
	 */
	public static function get_allowed_mimes_map() {
		$mime_to_ext = array(
			'application/pdf' => 'pdf',
			'image/jpeg'      => 'jpg|jpeg|jpe',
			'image/png'       => 'png',
			'audio/mpeg'      => 'mp3',
			'audio/mp4'       => 'm4a',
			'audio/wav'       => 'wav',
			'video/mp4'       => 'mp4',
		);

		$list = self::get_allowed_mime_list();
		$map  = array();
		foreach ( $list as $mime ) {
			if ( isset( $mime_to_ext[ $mime ] ) ) {
				$map[ $mime_to_ext[ $mime ] ] = $mime;
			} else {
				$ext = explode( '/', $mime );
				$map[ end( $ext ) ] = $mime;
			}
		}

		return $map;
	}

	/**
	 * @return string Comma-separated for admin textarea.
	 */
	public static function get_allowed_mime_csv() {
		return implode( ', ', self::get_allowed_mime_list() );
	}

	/**
	 * @return string[]
	 */
	public static function default_mime_list() {
		return array(
			'image/jpeg',
			'image/png',
			'application/pdf',
			'audio/mpeg',
			'audio/wav',
			'audio/mp4',
			'video/mp4',
		);
	}

	/**
	 * @return bool
	 */
	public static function require_unique_email() {
		return (bool) get_option( self::OPTION_REQUIRE_UNIQUE_EMAIL, true );
	}

	/**
	 * @return bool
	 */
	public static function require_email_verification() {
		return (bool) get_option( self::OPTION_REQUIRE_EMAIL_VERIFICATION, false );
	}

	/**
	 * @return int
	 */
	public static function get_password_min_length() {
		return max( 8, (int) get_option( self::OPTION_PASSWORD_MIN_LENGTH, 8 ) );
	}

	/**
	 * @return string
	 */
	public static function get_email_verify_subject() {
		$subject = (string) get_option( self::OPTION_EMAIL_VERIFY_SUBJECT, '' );
		if ( $subject ) {
			return $subject;
		}

		return __( 'Verify your email — {{app_name}}', 'radioudaan-app-api' );
	}

	/**
	 * @return string
	 */
	public static function get_email_verify_body() {
		$body = (string) get_option( self::OPTION_EMAIL_VERIFY_BODY, '' );
		if ( $body ) {
			return $body;
		}

		return __(
			"Hi {{name}},\n\nYour verification code is: {{code}}\n\nEnter this code in the {{app_name}} app.\n",
			'radioudaan-app-api'
		);
	}

	/**
	 * @return string
	 */
	public static function get_email_reset_subject() {
		$subject = (string) get_option( self::OPTION_EMAIL_RESET_SUBJECT, '' );
		if ( $subject ) {
			return $subject;
		}

		return __( 'Reset your password — {{app_name}}', 'radioudaan-app-api' );
	}

	/**
	 * @return string
	 */
	public static function get_email_reset_body() {
		$body = (string) get_option( self::OPTION_EMAIL_RESET_BODY, '' );
		if ( $body ) {
			return $body;
		}

		return __(
			"Hi {{name}},\n\nYour reset code is: {{code}}\n\nOr open: {{link}}\n",
			'radioudaan-app-api'
		);
	}

	/**
	 * @return array<string,mixed>
	 */
	public static function get_auth_policy_public() {
		$msg91_configured = class_exists( 'RadioUdaan_Otp_Msg91' ) && RadioUdaan_Otp_Msg91::is_configured();

		return array(
			'require_unique_email'       => self::require_unique_email(),
			'require_email_verification' => self::require_email_verification(),
			'password_min_length'        => self::get_password_min_length(),
			'sms_otp_country_code'       => '91',
			'sms_otp_supported'          => $msg91_configured,
			'otp_purposes'               => array(
				RadioUdaan_Otp_Service::PURPOSE_LOGIN,
				RadioUdaan_Otp_Service::PURPOSE_VERIFY_PHONE,
				RadioUdaan_Otp_Service::PURPOSE_RESET_PASSWORD,
			),
		);
	}

	/**
	 * Production safety warnings for admin dashboard.
	 *
	 * @return string[]
	 */
	public static function get_production_warnings() {
		$warnings = array();
		if ( self::is_dev_otp_enabled() ) {
			$warnings[] = __( 'Development OTP is ON — disable before production.', 'radioudaan-app-api' );
		}
		if ( self::is_dev_auth_enabled() ) {
			$warnings[] = __( 'Skip bearer token check is ON — disable before production.', 'radioudaan-app-api' );
		}
		if ( ! self::is_dev_otp_enabled() && class_exists( 'RadioUdaan_Otp_Msg91' ) && ! RadioUdaan_Otp_Msg91::is_configured() ) {
			$warnings[] = __( 'MSG91 is not configured — OTP SMS will not send.', 'radioudaan-app-api' );
		}
		return $warnings;
	}
}

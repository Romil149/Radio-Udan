<?php
/**
 * Public app configuration for mobile clients.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * GET /config response builder (cached for fast mobile cold start).
 */
class RadioUdaan_App_Config {

	const CACHE_KEY            = 'radioudaan_app_public_config';
	const CACHE_TTL            = 300;
	const LIVE_RADIO_CACHE_KEY = 'radioudaan_app_live_radio_config';
	const LIVE_RADIO_CACHE_TTL = 60;

	/**
	 * Cached public config (rebuilt when settings change or TTL expires).
	 *
	 * @return array<string,mixed>
	 */
	public static function get_public_config() {
		$cached = get_transient( self::CACHE_KEY );
		if ( is_array( $cached ) && ! empty( $cached ) ) {
			$config = $cached;
		} else {
			$config = self::build_public_config();
			set_transient( self::CACHE_KEY, $config, self::CACHE_TTL );
		}

		$config['api_version'] = RADIOUDAAN_APP_API_VERSION;
		$config['live_radio']  = self::get_cached_live_radio();

		return $config;
	}

	/**
	 * Clear config cache after admin saves branding/settings.
	 */
	public static function invalidate_cache() {
		delete_transient( self::CACHE_KEY );
		delete_transient( self::LIVE_RADIO_CACHE_KEY );
	}

	/**
	 * On-air show title / RJ / hero from radio-shows schedule (short TTL).
	 *
	 * @return array<string,mixed>
	 */
	private static function get_cached_live_radio() {
		$cached = get_transient( self::LIVE_RADIO_CACHE_KEY );
		if ( is_array( $cached ) && ! empty( $cached ) ) {
			return $cached;
		}

		$config = RadioUdaan_App_Live_Radio::get_public_config();
		set_transient( self::LIVE_RADIO_CACHE_KEY, $config, self::LIVE_RADIO_CACHE_TTL );

		return $config;
	}

	/**
	 * @return array<string,mixed>
	 */
	private static function build_public_config() {
		return array(
			'api_version'        => RADIOUDAAN_APP_API_VERSION,
			'api_base_url'       => RadioUdaan_App_Settings::get_api_base_url(),
			'site_url'           => home_url( '/' ),
			'stream_url'         => RadioUdaan_App_Settings::get_stream_url(),
			'upload_constraints' => array(
				'max_file_mb'         => RadioUdaan_App_Settings::get_max_upload_mb(),
				'max_files_per_field' => RadioUdaan_App_Settings::get_max_files_per_field(),
				'allowed_mime'        => RadioUdaan_App_Settings::get_allowed_mime_list(),
			),
			'otp_policy'         => array(
				'resend_delay_sec' => RadioUdaan_App_Settings::get_otp_resend_delay_sec(),
			),
			'auth_policy'        => RadioUdaan_App_Settings::get_auth_policy_public(),
			'features'           => array(
				'prevent_duplicate_registration' => RadioUdaan_App_Settings::prevent_duplicate_registration(),
				'in_app_library_playback'        => true,
			),
			'privacy_policy_url' => RadioUdaan_App_Settings::get_privacy_policy_url(),
			'terms_url'          => RadioUdaan_App_Settings::get_terms_url(),
			'about_url'          => RadioUdaan_App_Settings::get_about_url(),
			'contact_url'        => RadioUdaan_App_Settings::get_contact_url(),
			'legal_pages'        => RadioUdaan_App_Legal_Pages::get_config_payload(),
			'support'            => array(
				'helpline_phone' => RadioUdaan_App_Settings::get_support_helpline_phone(),
				'email'          => RadioUdaan_App_Settings::get_support_email(),
			),
			'notification_preferences' => RadioUdaan_App_Settings::get_notification_preferences_defaults(),
			'branding'           => RadioUdaan_App_Branding::get_public_branding(),
			'copy'               => RadioUdaan_App_Branding::get_public_copy(),
		);
	}
}

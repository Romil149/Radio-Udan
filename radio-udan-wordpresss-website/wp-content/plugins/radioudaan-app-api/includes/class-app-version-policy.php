<?php
/**
 * Minimum app build enforcement policy.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Public policy slice for `GET /config`.
 */
class RadioUdaan_App_Version_Policy {

	// When false, app never hard-blocks.
	const OPTION_FORCE_UPDATE_ENABLED = 'radioudaan_force_update_enabled';

	// Android build number (versionCode). 0 disables.
	const OPTION_MIN_ANDROID_BUILD = 'radioudaan_min_android_build';

	// iOS build number (CFBundleVersion). 0 disables.
	const OPTION_MIN_IOS_BUILD = 'radioudaan_min_ios_build';

	/**
	 * @return bool
	 */
	public static function is_force_update_enabled() {
		return ! empty( get_option( self::OPTION_FORCE_UPDATE_ENABLED, 0 ) );
	}

	/**
	 * @return int
	 */
	public static function get_min_android_build() {
		$min = (int) get_option( self::OPTION_MIN_ANDROID_BUILD, 0 );
		return max( 0, $min );
	}

	/**
	 * @return int
	 */
	public static function get_min_ios_build() {
		$min = (int) get_option( self::OPTION_MIN_IOS_BUILD, 0 );
		return max( 0, $min );
	}

	/**
	 * Public slice for `GET /config`.
	 *
	 * @return array<string,mixed>
	 */
	public static function get_public_config() {
		return array(
			'enabled'          => self::is_force_update_enabled(),
			'android_min_build'=> self::get_min_android_build(),
			'ios_min_build'    => self::get_min_ios_build(),
		);
	}
}


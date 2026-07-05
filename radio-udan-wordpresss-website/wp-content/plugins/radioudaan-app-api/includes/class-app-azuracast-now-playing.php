<?php
/**
 * AzuraCast now-playing API URL for the mobile app (fetched client-side).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Stores the public AzuraCast now-playing JSON endpoint URL in GET /config only.
 */
class RadioUdaan_App_Azuracast_Now_Playing {

	const OPTION_API_URL = 'radioudaan_azuracast_now_playing_url';

	const DEFAULT_API_URL = 'https://stream.radioudaan.com/api/nowplaying';

	/**
	 * @return string
	 */
	public static function get_api_url() {
		$url = trim( (string) get_option( self::OPTION_API_URL, '' ) );
		if ( $url === '' ) {
			return self::DEFAULT_API_URL;
		}
		return esc_url_raw( $url );
	}
}

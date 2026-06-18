<?php
/**
 * Simple transient-based rate limiting.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Rate limit helper for OTP and registrations.
 */
class RadioUdaan_Rate_Limiter {

	/**
	 * @param string $key            Unique key (include action + identifier).
	 * @param int    $max            Max hits allowed in window.
	 * @param int    $window_seconds Window length.
	 * @return bool True if limit exceeded.
	 */
	public static function is_limited( $key, $max, $window_seconds ) {
		$count = (int) get_transient( 'ru_rl_' . md5( $key ) );
		return $count >= $max;
	}

	/**
	 * @param string $key            Unique key.
	 * @param int    $window_seconds Window length.
	 */
	public static function bump( $key, $window_seconds ) {
		$hash = 'ru_rl_' . md5( $key );
		$count = (int) get_transient( $hash );
		set_transient( $hash, $count + 1, $window_seconds );
	}

	/**
	 * @return string
	 */
	public static function get_client_ip() {
		$ip = '';
		if ( ! empty( $_SERVER['REMOTE_ADDR'] ) ) {
			$ip = (string) $_SERVER['REMOTE_ADDR'];
		}

		// Only trust X-Forwarded-For when the immediate peer is a known reverse proxy.
		if ( defined( 'RADIOUDAAN_APP_API_TRUST_PROXY' ) && RADIOUDAAN_APP_API_TRUST_PROXY
			&& ! empty( $_SERVER['HTTP_X_FORWARDED_FOR'] ) ) {
			$parts = explode( ',', (string) $_SERVER['HTTP_X_FORWARDED_FOR'] );
			$ip    = trim( $parts[0] );
		}

		return sanitize_text_field( $ip ? $ip : '0.0.0.0' );
	}
}

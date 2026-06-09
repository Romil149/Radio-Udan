<?php
/**
 * PII-safe API logging.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Writes to error_log when WP_DEBUG_LOG is enabled.
 */
class RadioUdaan_App_Logger {

	/**
	 * @param string               $code    Event code.
	 * @param array<string,mixed>  $context Context (phones redacted).
	 */
	public static function log( $code, $context = array() ) {
		if ( ! ( defined( 'WP_DEBUG' ) && WP_DEBUG ) ) {
			return;
		}

		$safe = self::redact_context( $context );
		$line = sprintf(
			'[RadioUdaan App API] %s %s',
			sanitize_key( $code ),
			wp_json_encode( $safe )
		);

		if ( defined( 'WP_DEBUG_LOG' ) && WP_DEBUG_LOG ) {
			// phpcs:ignore WordPress.PHP.DevelopmentFunctions.error_log_error_log
			error_log( $line );
		}
	}

	/**
	 * @param array<string,mixed> $context Context.
	 * @return array<string,mixed>
	 */
	private static function redact_context( $context ) {
		$out = array();
		foreach ( $context as $key => $value ) {
			if (
				is_string( $value )
				&& (
					false !== stripos( $key, 'phone' )
					|| false !== stripos( $key, 'otp' )
					|| false !== stripos( $key, 'fcm_token' )
					|| false !== stripos( $key, 'token' )
				)
			) {
				$out[ $key ] = self::mask_phone( $value );
			} elseif ( is_array( $value ) ) {
				$out[ $key ] = self::redact_context( $value );
			} else {
				$out[ $key ] = $value;
			}
		}
		return $out;
	}

	/**
	 * @param string $phone Phone.
	 * @return string
	 */
	private static function mask_phone( $phone ) {
		$phone = preg_replace( '/\s+/', '', (string) $phone );
		if ( strlen( $phone ) < 4 ) {
			return '****';
		}
		return '****' . substr( $phone, -4 );
	}
}

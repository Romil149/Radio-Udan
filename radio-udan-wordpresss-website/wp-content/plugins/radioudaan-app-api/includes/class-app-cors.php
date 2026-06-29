<?php
/**
 * CORS for Flutter web and local dev tools hitting the App API.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Allows browser-based clients (Flutter web, admin tools) to call the REST API.
 */
class RadioUdaan_App_Cors {

	/**
	 * Register filters.
	 */
	public static function init() {
		add_filter( 'rest_pre_serve_request', array( __CLASS__, 'send_cors_headers' ), 15, 4 );
		add_filter( 'rest_allowed_cors_headers', array( __CLASS__, 'allowed_headers' ) );
	}

	/**
	 * @param bool              $served  Whether request was served.
	 * @param WP_HTTP_Response  $result  Result.
	 * @param WP_REST_Request   $request Request.
	 * @param WP_REST_Server    $server  Server.
	 * @return bool
	 */
	public static function send_cors_headers( $served, $result, $request, $server ) {
		if ( ! $request instanceof WP_REST_Request ) {
			return $served;
		}

		if ( 0 !== strpos( $request->get_route(), '/radioudaan/' ) ) {
			return $served;
		}

		$origin = isset( $_SERVER['HTTP_ORIGIN'] ) ? sanitize_text_field( wp_unslash( $_SERVER['HTTP_ORIGIN'] ) ) : '';

		if ( self::is_allowed_origin( $origin ) ) {
			header( 'Access-Control-Allow-Origin: ' . $origin );
			header( 'Access-Control-Allow-Credentials: true' );
		} elseif ( defined( 'RADIOUDAAN_APP_API_DEV_CORS' ) && RADIOUDAAN_APP_API_DEV_CORS ) {
			header( 'Access-Control-Allow-Origin: *' );
		}

		header( 'Access-Control-Allow-Methods: GET, POST, OPTIONS' );
		header( 'Access-Control-Allow-Headers: Authorization, Content-Type, X-WP-Nonce' );

		if ( 'OPTIONS' === $request->get_method() ) {
			status_header( 200 );
			exit;
		}

		return $served;
	}

	/**
	 * @param string[] $headers Existing headers.
	 * @return string[]
	 */
	public static function allowed_headers( $headers ) {
		$headers[] = 'Authorization';
		return $headers;
	}

	/**
	 * @param string $origin Origin header.
	 * @return bool
	 */
	private static function is_allowed_origin( $origin ) {
		if ( ! $origin ) {
			return false;
		}

		$allowed = array(
			'http://localhost:8765',
			'http://127.0.0.1:8765',
			home_url(),
		);

		$allowed = apply_filters( 'radioudaan_app_api_cors_origins', $allowed );

		if ( in_array( $origin, $allowed, true ) ) {
			return true;
		}

		// Flutter web dev servers use random ports — allow localhost over HTTP only.
		if ( preg_match( '#^http://(localhost|127\.0\.0\.1)(:\d+)?$#', $origin ) ) {
			return true;
		}

		return false;
	}
}

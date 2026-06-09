<?php
/**
 * Fetch Firebase Android/iOS client config via Management API (local dev).
 *
 * @package RadioUdaanAppApi
 */

$remote = isset( $_SERVER['REMOTE_ADDR'] ) ? (string) $_SERVER['REMOTE_ADDR'] : '';
if ( ! in_array( $remote, array( '127.0.0.1', '::1' ), true ) ) {
	http_response_code( 403 );
	exit;
}

define( 'WP_USE_THEMES', false );
require dirname( __DIR__, 4 ) . '/wp-load.php';

header( 'Content-Type: application/json' );

$project_id = RadioUdaan_App_Settings::get_fcm_project_id();
$raw        = RadioUdaan_App_Settings::get_fcm_service_account_json();
$account    = RadioUdaan_App_Fcm_Sender::parse_service_account_json( $raw );

if ( ! $account || '' === $project_id ) {
	echo wp_json_encode( array( 'error' => 'fcm_not_configured' ) );
	exit;
}

/**
 * @param array<string,string> $account Service account.
 * @return string|WP_Error
 */
function radioudaan_firebase_mgmt_token( array $account ) {
	$ref    = new ReflectionClass( 'RadioUdaan_App_Fcm_Sender' );
	$build  = $ref->getMethod( 'build_jwt' );
	$build->setAccessible( true );

	$client_email = $account['client_email'];
	$private_key  = $account['private_key'];
	$now          = time();

	$encode = function ( $value ) {
		return rtrim( strtr( base64_encode( (string) $value ), '+/', '-_' ), '=' );
	};

	$header  = $encode( wp_json_encode( array( 'alg' => 'RS256', 'typ' => 'JWT' ) ) );
	$claims  = $encode(
		wp_json_encode(
			array(
				'iss'   => $client_email,
				'sub'   => $client_email,
				'aud'   => 'https://oauth2.googleapis.com/token',
				'iat'   => $now,
				'exp'   => $now + 3600,
				'scope' => 'https://www.googleapis.com/auth/firebase.readonly https://www.googleapis.com/auth/cloud-platform',
			)
		)
	);
	$unsigned = $header . '.' . $claims;
	$key      = openssl_pkey_get_private( $private_key );
	if ( false === $key ) {
		return new WP_Error( 'key_invalid', 'invalid private key' );
	}
	$signature = '';
	openssl_sign( $unsigned, $signature, $key, OPENSSL_ALGO_SHA256 );
	openssl_free_key( $key );
	$jwt = $unsigned . '.' . $encode( $signature );

	$response = wp_remote_post(
		'https://oauth2.googleapis.com/token',
		array(
			'timeout' => 15,
			'body'    => array(
				'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
				'assertion'  => $jwt,
			),
		)
	);

	if ( is_wp_error( $response ) ) {
		return $response;
	}

	$json = json_decode( (string) wp_remote_retrieve_body( $response ), true );
	if ( empty( $json['access_token'] ) ) {
		return new WP_Error( 'oauth_failed', 'mgmt oauth failed' );
	}

	return (string) $json['access_token'];
}

/**
 * @param string $token Access token.
 * @param string $url   URL.
 * @return array|WP_Error
 */
function radioudaan_firebase_get_json( $token, $url ) {
	$response = wp_remote_get(
		$url,
		array(
			'timeout' => 20,
			'headers' => array( 'Authorization' => 'Bearer ' . $token ),
		)
	);
	if ( is_wp_error( $response ) ) {
		return $response;
	}
	$code = (int) wp_remote_retrieve_response_code( $response );
	$body = json_decode( (string) wp_remote_retrieve_body( $response ), true );
	if ( $code < 200 || $code >= 300 ) {
		return new WP_Error( 'api_failed', 'HTTP ' . $code, $body );
	}
	return is_array( $body ) ? $body : array();
}

$token = radioudaan_firebase_mgmt_token( $account );
if ( is_wp_error( $token ) ) {
	echo wp_json_encode( array( 'error' => $token->get_error_message() ) );
	exit;
}

$base     = 'https://firebase.googleapis.com/v1beta1/projects/' . rawurlencode( $project_id );
$android  = radioudaan_firebase_get_json( $token, $base . '/androidApps' );
$ios      = radioudaan_firebase_get_json( $token, $base . '/iosApps' );
$web      = radioudaan_firebase_get_json( $token, $base . '/webApps' );

$out = array(
	'project_id' => $project_id,
	'android'    => is_wp_error( $android ) ? array( 'error' => $android->get_error_message(), 'data' => $android->get_error_data() ) : $android,
	'ios'        => is_wp_error( $ios ) ? array( 'error' => $ios->get_error_message(), 'data' => $ios->get_error_data() ) : $ios,
	'web'        => is_wp_error( $web ) ? array( 'error' => $web->get_error_message(), 'data' => $web->get_error_data() ) : $web,
);

// Pull full config for first android/ios app.
if ( ! is_wp_error( $android ) && ! empty( $android['apps'][0]['name'] ) ) {
	$app_name = (string) $android['apps'][0]['name'];
	$config   = radioudaan_firebase_get_json( $token, $app_name . '/config' );
	$out['android_config'] = $config;
}
if ( ! is_wp_error( $ios ) && ! empty( $ios['apps'][0]['name'] ) ) {
	$app_name = (string) $ios['apps'][0]['name'];
	$config   = radioudaan_firebase_get_json( $token, $app_name . '/config' );
	$out['ios_config'] = $config;
}

echo wp_json_encode( $out, JSON_PRETTY_PRINT );

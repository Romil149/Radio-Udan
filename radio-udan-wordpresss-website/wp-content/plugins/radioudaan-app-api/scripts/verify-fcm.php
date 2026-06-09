<?php
/**
 * One-off FCM HTTP v1 configuration check (local dev).
 * Access only from localhost; delete after verification.
 *
 * @package RadioUdaanAppApi
 */

$remote = isset( $_SERVER['REMOTE_ADDR'] ) ? (string) $_SERVER['REMOTE_ADDR'] : '';
if ( ! in_array( $remote, array( '127.0.0.1', '::1' ), true ) ) {
	http_response_code( 403 );
	header( 'Content-Type: application/json' );
	echo wp_json_encode( array( 'error' => 'forbidden' ) );
	exit;
}

define( 'WP_USE_THEMES', false );
require dirname( __DIR__, 4 ) . '/wp-load.php';

header( 'Content-Type: application/json' );

$project_id  = RadioUdaan_App_Settings::get_fcm_project_id();
$account_set = RadioUdaan_App_Settings::is_fcm_service_account_set();
$configured  = RadioUdaan_App_Fcm_Sender::is_configured();

global $wpdb;
$device_count = (int) $wpdb->get_var( 'SELECT COUNT(*) FROM ' . $wpdb->prefix . 'ru_app_devices' );
$devices      = $wpdb->get_results(
	'SELECT id, user_id, platform, LENGTH(fcm_token) AS token_length, LEFT(fcm_token, 12) AS token_prefix, (fcm_token LIKE "test_fcm%") AS is_test_token, last_seen_at FROM ' . $wpdb->prefix . 'ru_app_devices ORDER BY id DESC LIMIT 5',
	ARRAY_A
);

$oauth_ok    = false;
$oauth_error = '';
if ( $configured ) {
	$oauth = RadioUdaan_App_Fcm_Sender::verify_oauth_connection();
	if ( is_wp_error( $oauth ) ) {
		$oauth_error = $oauth->get_error_message();
	} else {
		$oauth_ok = true;
	}
}

echo wp_json_encode(
	array(
		'fcm_project_id'     => $project_id,
		'service_account_set' => $account_set,
		'fcm_configured'     => $configured,
		'oauth_token_ok'     => $oauth_ok,
		'oauth_error'        => $oauth_error ? $oauth_error : null,
		'registered_devices' => $device_count,
		'devices'            => is_array( $devices ) ? $devices : array(),
	),
	JSON_PRETTY_PRINT
);

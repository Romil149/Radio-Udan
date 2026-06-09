<?php
/**
 * Send a test notification to one app user (localhost only).
 *
 * Usage: https://radio/.../send-test-notification.php?user_id=6
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

$user_id = isset( $_GET['user_id'] ) ? (int) $_GET['user_id'] : 0;
if ( $user_id < 1 ) {
	echo wp_json_encode( array( 'error' => 'user_id query param required' ) );
	exit;
}

$id = RadioUdaan_App_Notifications::create(
	$user_id,
	'Radio Udaan test',
	'This is a test push from the WordPress server.',
	'general',
	array(
		'source' => 'dev_script',
	)
);

echo wp_json_encode(
	array(
		'notification_id' => $id,
		'user_id'         => $user_id,
		'fcm_configured'  => RadioUdaan_App_Fcm_Sender::is_configured(),
	),
	JSON_PRETTY_PRINT
);

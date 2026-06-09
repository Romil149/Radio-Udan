<?php
/**
 * Export service account JSON to a local temp file (localhost only).
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

$raw = RadioUdaan_App_Settings::get_fcm_service_account_json();
if ( '' === trim( $raw ) ) {
	http_response_code( 404 );
	exit;
}

$path = sys_get_temp_dir() . '/radioudaan-fcm-sa.json';
file_put_contents( $path, $raw );
header( 'Content-Type: text/plain' );
echo $path;

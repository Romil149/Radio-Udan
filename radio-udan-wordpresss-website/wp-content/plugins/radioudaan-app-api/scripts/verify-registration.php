<?php
/**
 * Registration DB probe for staging/local troubleshooting.
 * Delete after use on production.
 *
 * @package RadioUdaanAppApi
 */

$remote = isset( $_SERVER['REMOTE_ADDR'] ) ? (string) $_SERVER['REMOTE_ADDR'] : '';
$allowed = in_array( $remote, array( '127.0.0.1', '::1' ), true );
if ( ! $allowed && defined( 'RADIOUDAAN_VERIFY_REGISTRATION_KEY' ) ) {
	$key = isset( $_GET['key'] ) ? (string) $_GET['key'] : '';
	$allowed = hash_equals( (string) RADIOUDAAN_VERIFY_REGISTRATION_KEY, $key );
}
if ( ! $allowed ) {
	http_response_code( 403 );
	header( 'Content-Type: application/json' );
	echo wp_json_encode( array( 'error' => 'forbidden' ) );
	exit;
}

define( 'WP_USE_THEMES', false );
require dirname( __DIR__, 4 ) . '/wp-load.php';

header( 'Content-Type: application/json' );

RadioUdaan_App_Users::ensure_schema();

global $wpdb;
$table = RadioUdaan_App_Users::table_name();
$stamp = (string) time();
$probe = RadioUdaan_App_Users::create_pending(
	array(
		'display_name'  => 'Probe User',
		'email'         => 'probe-' . $stamp . '@example.com',
		'phone_e164'    => '+91999' . substr( $stamp, -6 ),
		'password_hash' => wp_hash_password( 'ProbePass123' ),
	)
);

$columns = $wpdb->get_results( "SHOW COLUMNS FROM {$table}", ARRAY_A );

echo wp_json_encode(
	array(
		'table'               => $table,
		'schema_ready'        => RadioUdaan_App_Users::schema_ready(),
		'primary_auto_inc'    => RadioUdaan_App_Users::primary_key_auto_increments(),
		'row_count'           => RadioUdaan_App_Users::row_count(),
		'probe_user_id'       => $probe ? (int) $probe : 0,
		'wpdb_last_error'     => (string) $wpdb->last_error,
		'columns'             => is_array( $columns ) ? $columns : array(),
	),
	JSON_PRETTY_PRINT
);

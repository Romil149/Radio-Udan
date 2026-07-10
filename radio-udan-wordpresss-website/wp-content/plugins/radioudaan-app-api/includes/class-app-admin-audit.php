<?php
/**
 * Admin audit log for app user management actions.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Persists WP-admin actions on app accounts (pause, resume, delete, notify).
 */
class RadioUdaan_App_Admin_Audit {

	const DB_VERSION_OPTION = 'radioudaan_app_admin_audit_db_version';
	const DB_VERSION        = '1.0';

	const ACTION_USER_PAUSED   = 'user_paused';
	const ACTION_USER_RESUMED  = 'user_resumed';
	const ACTION_USER_DELETED  = 'user_deleted';
	const ACTION_USER_NOTIFIED = 'user_notified';
	const ACTION_BULK_PAUSED   = 'bulk_paused';
	const ACTION_BULK_RESUMED  = 'bulk_resumed';
	const ACTION_BULK_DELETED  = 'bulk_deleted';
	const ACTION_BULK_NOTIFIED = 'bulk_notified';

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'init', array( __CLASS__, 'maybe_create_table' ), 5 );
	}

	/**
	 * @return string
	 */
	public static function table_name() {
		global $wpdb;
		return $wpdb->prefix . 'ru_app_admin_audit';
	}

	/**
	 * Create audit table.
	 */
	public static function maybe_create_table() {
		if ( self::DB_VERSION === get_option( self::DB_VERSION_OPTION, '' ) ) {
			return;
		}

		global $wpdb;

		$table   = self::table_name();
		$charset = $wpdb->get_charset_collate();

		$sql = "CREATE TABLE {$table} (
			id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
			admin_user_id bigint(20) unsigned NOT NULL DEFAULT 0,
			action varchar(40) NOT NULL DEFAULT '',
			target_user_id bigint(20) unsigned NULL,
			details longtext NULL,
			created_at datetime NOT NULL,
			PRIMARY KEY  (id),
			KEY action (action),
			KEY target_user_id (target_user_id),
			KEY admin_user_id (admin_user_id),
			KEY created_at (created_at)
		) {$charset};";

		require_once ABSPATH . 'wp-admin/includes/upgrade.php';
		dbDelta( $sql );

		update_option( self::DB_VERSION_OPTION, self::DB_VERSION );
	}

	/**
	 * @return array<string>
	 */
	public static function allowed_actions() {
		return array(
			self::ACTION_USER_PAUSED,
			self::ACTION_USER_RESUMED,
			self::ACTION_USER_DELETED,
			self::ACTION_USER_NOTIFIED,
			self::ACTION_BULK_PAUSED,
			self::ACTION_BULK_RESUMED,
			self::ACTION_BULK_DELETED,
			self::ACTION_BULK_NOTIFIED,
		);
	}

	/**
	 * @param string               $action         Audit action.
	 * @param int                  $admin_user_id  WP user id (0 = system).
	 * @param int|null             $target_user_id App user id.
	 * @param array<string,mixed>  $details        Optional metadata.
	 * @return int Audit row id or 0.
	 */
	public static function log( $action, $admin_user_id = 0, $target_user_id = null, array $details = array() ) {
		self::maybe_create_table();

		$action = sanitize_key( (string) $action );
		if ( ! in_array( $action, self::allowed_actions(), true ) ) {
			return 0;
		}

		global $wpdb;

		$details_json = '';
		if ( ! empty( $details ) ) {
			$encoded = wp_json_encode( $details );
			if ( is_string( $encoded ) ) {
				$details_json = $encoded;
			}
		}

		$row = array(
			'admin_user_id'  => max( 0, (int) $admin_user_id ),
			'action'         => $action,
			'target_user_id' => null !== $target_user_id ? (int) $target_user_id : null,
			'details'        => $details_json,
			'created_at'     => current_time( 'mysql', true ),
		);

		$format = array( '%d', '%s', '%d', '%s', '%s' );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery
		$ok = $wpdb->insert( self::table_name(), $row, $format );

		return ( $ok && (int) $wpdb->insert_id > 0 ) ? (int) $wpdb->insert_id : 0;
	}

	/**
	 * @param int $limit Max rows.
	 * @return array<int,object>
	 */
	public static function list_recent( $limit = 50 ) {
		self::maybe_create_table();

		global $wpdb;

		$limit = max( 1, min( 500, (int) $limit ) );
		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$table} ORDER BY created_at DESC, id DESC LIMIT %d",
				$limit
			)
		);

		return is_array( $rows ) ? $rows : array();
	}
}

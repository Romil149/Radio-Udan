<?php
/**
 * App users — mobile app accounts (password + OTP v2).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Stores app account records separate from WordPress users and event form entries.
 */
class RadioUdaan_App_Users {

	const DB_VERSION_OPTION    = 'radioudaan_app_users_db_version';
	const DB_VERSION           = '2.0';
	const COLUMN_VERSION_OPTION = 'radioudaan_app_users_column_version';
	const COLUMN_VERSION        = '2.2';

	const STATUS_PENDING = 'pending';
	const STATUS_ACTIVE  = 'active';
	const STATUS_PAUSED  = 'paused';
	const STATUS_DELETED = 'deleted';

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'init', array( __CLASS__, 'maybe_create_table' ), 5 );
		add_action( 'init', array( __CLASS__, 'maybe_migrate_columns' ), 6 );
	}

	/**
	 * @return string
	 */
	public static function table_name() {
		global $wpdb;
		return $wpdb->prefix . 'ru_app_users';
	}

	/**
	 * @return bool True when the app users table exists with required columns.
	 */
	public static function schema_ready() {
		if ( ! self::table_exists() ) {
			return false;
		}

		global $wpdb;

		$table = self::table_name();
		$required = array(
			'id',
			'display_name',
			'email',
			'phone_e164',
			'password_hash',
			'phone_verified',
			'email_verified',
			'status',
			'login_count',
			'created_at',
			'updated_at',
		);

		foreach ( $required as $column ) {
			// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
			$found = $wpdb->get_results( $wpdb->prepare( "SHOW COLUMNS FROM {$table} LIKE %s", $column ) );
			if ( empty( $found ) ) {
				return false;
			}
		}

		return self::primary_key_auto_increments();
	}

	/**
	 * @return bool
	 */
	public static function primary_key_auto_increments() {
		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$id_col = $wpdb->get_row( "SHOW COLUMNS FROM {$table} LIKE 'id'", ARRAY_A );
		if ( empty( $id_col ) ) {
			return false;
		}

		$extra = isset( $id_col['Extra'] ) ? (string) $id_col['Extra'] : '';

		return false !== stripos( $extra, 'auto_increment' );
	}

	/**
	 * @return int
	 */
	public static function row_count() {
		if ( ! self::table_exists() ) {
			return 0;
		}

		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		return (int) $wpdb->get_var( "SELECT COUNT(*) FROM {$table}" );
	}

	/**
	 * Drop and recreate the table when it is empty but structurally invalid.
	 *
	 * @return bool
	 */
	public static function repair_schema_if_empty() {
		if ( self::schema_ready() ) {
			return true;
		}

		if ( self::row_count() > 0 ) {
			RadioUdaan_App_Logger::log( 'app_users_schema_broken_nonempty', array() );
			return false;
		}

		self::drop_table();
		delete_option( self::DB_VERSION_OPTION );
		delete_option( self::COLUMN_VERSION_OPTION );
		self::maybe_create_table();
		self::maybe_migrate_columns();

		return self::schema_ready();
	}

	/**
	 * Remove the app users table.
	 */
	public static function drop_table() {
		if ( ! self::table_exists() ) {
			return;
		}

		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.SchemaChange, WordPress.DB.DirectDatabaseQuery.DirectQuery
		$wpdb->query( "DROP TABLE IF EXISTS {$table}" );
	}

	/**
	 * @return bool True when the physical table exists.
	 */
	public static function table_exists() {
		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$found = $wpdb->get_var( $wpdb->prepare( 'SHOW TABLES LIKE %s', $table ) );

		return $found === $table;
	}

	/**
	 * Create or repair schema when options say "installed" but the table is missing.
	 *
	 * @return bool
	 */
	public static function ensure_schema() {
		if ( ! self::table_exists() || ! self::schema_ready() ) {
			delete_option( self::DB_VERSION_OPTION );
			delete_option( self::COLUMN_VERSION_OPTION );
		}

		self::maybe_create_table();
		self::maybe_migrate_columns();
		self::repair_schema_if_empty();

		return self::schema_ready();
	}

	/**
	 * Create or migrate table.
	 */
	public static function maybe_create_table() {
		$installed = get_option( self::DB_VERSION_OPTION, '' );
		if ( self::DB_VERSION === $installed ) {
			return;
		}

		global $wpdb;

		$table = self::table_name();

		if ( $installed && version_compare( $installed, self::DB_VERSION, '<' ) ) {
			// phpcs:ignore WordPress.DB.DirectDatabaseQuery.SchemaChange, WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
			$wpdb->query( "DROP TABLE IF EXISTS {$table}" );
			self::purge_legacy_on_migrate();
		}

		$charset = $wpdb->get_charset_collate();

		$sql = "CREATE TABLE {$table} (
			id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
			display_name varchar(120) NOT NULL DEFAULT '',
			email varchar(190) NOT NULL DEFAULT '',
			phone_e164 varchar(20) NOT NULL DEFAULT '',
			password_hash varchar(255) NOT NULL DEFAULT '',
			phone_verified tinyint(1) NOT NULL DEFAULT 0,
			email_verified tinyint(1) NOT NULL DEFAULT 0,
			status varchar(20) NOT NULL DEFAULT 'pending',
			first_login_at datetime NULL,
			last_login_at datetime NULL,
			login_count int(11) unsigned NOT NULL DEFAULT 0,
			created_at datetime NOT NULL,
			updated_at datetime NOT NULL,
			PRIMARY KEY  (id),
			KEY phone_e164 (phone_e164),
			KEY email (email),
			KEY status (status),
			KEY last_login_at (last_login_at)
		) {$charset};";

		require_once ABSPATH . 'wp-admin/includes/upgrade.php';
		dbDelta( $sql );

		update_option( self::DB_VERSION_OPTION, self::DB_VERSION );
	}

	/**
	 * Additive column migrations (no table drop).
	 */
	public static function maybe_migrate_columns() {
		self::maybe_create_table();

		if ( self::COLUMN_VERSION === get_option( self::COLUMN_VERSION_OPTION, '' ) ) {
			return;
		}

		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$column = $wpdb->get_results( "SHOW COLUMNS FROM {$table} LIKE 'avatar_attachment_id'" );
		if ( empty( $column ) ) {
			// phpcs:ignore WordPress.DB.DirectDatabaseQuery.SchemaChange, WordPress.DB.DirectDatabaseQuery.DirectQuery
			$wpdb->query( "ALTER TABLE {$table} ADD COLUMN avatar_attachment_id bigint(20) unsigned NOT NULL DEFAULT 0 AFTER password_hash" );
		}

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$prefs_col = $wpdb->get_results( "SHOW COLUMNS FROM {$table} LIKE 'notification_prefs'" );
		if ( empty( $prefs_col ) ) {
			// phpcs:ignore WordPress.DB.DirectDatabaseQuery.SchemaChange, WordPress.DB.DirectDatabaseQuery.DirectQuery
			$wpdb->query( "ALTER TABLE {$table} ADD COLUMN notification_prefs longtext NULL AFTER avatar_attachment_id" );
		}

		update_option( self::COLUMN_VERSION_OPTION, self::COLUMN_VERSION );
	}

	/**
	 * Drop v1 OTP-only rows on upgrade (table already recreated).
	 */
	private static function purge_legacy_on_migrate() {
		RadioUdaan_App_Logger::log( 'app_users_migrated_v2', array() );
	}

	/**
	 * @param array{display_name:string,email:string,phone_e164:string,password_hash:string} $data User fields.
	 * @return int|false User id.
	 */
	public static function create_pending( array $data ) {
		if ( ! self::ensure_schema() ) {
			RadioUdaan_App_Logger::log( 'app_users_schema_unavailable', array() );
			return false;
		}

		$user_id = self::insert_pending_row( $data );
		if ( $user_id > 0 ) {
			return $user_id;
		}

		if ( self::repair_schema_if_empty() ) {
			$user_id = self::insert_pending_row( $data );
			if ( $user_id > 0 ) {
				return $user_id;
			}
		}

		return false;
	}

	/**
	 * @param array{display_name:string,email:string,phone_e164:string,password_hash:string} $data User fields.
	 * @return int Inserted user id, or 0 on failure.
	 */
	private static function insert_pending_row( array $data ) {
		self::maybe_migrate_columns();

		global $wpdb;

		$now = current_time( 'mysql', true );

		$row = array(
			'display_name'   => $data['display_name'],
			'email'          => strtolower( sanitize_email( $data['email'] ) ),
			'phone_e164'     => $data['phone_e164'],
			'password_hash'  => $data['password_hash'],
			'phone_verified' => 0,
			'email_verified' => 0,
			'status'         => self::STATUS_PENDING,
			'login_count'    => 0,
			'created_at'     => $now,
			'updated_at'     => $now,
		);

		$format = array( '%s', '%s', '%s', '%s', '%d', '%d', '%s', '%d', '%s', '%s' );

		if ( self::column_exists( 'avatar_attachment_id' ) ) {
			$row['avatar_attachment_id'] = 0;
			$format[]                    = '%d';
		}

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery
		$ok = $wpdb->insert( self::table_name(), $row, $format );

		if ( ! $ok || (int) $wpdb->insert_id <= 0 ) {
			RadioUdaan_App_Logger::log(
				'app_users_insert_failed',
				array(
					'db_error'   => sanitize_text_field( (string) $wpdb->last_error ),
					'insert_ok'  => (bool) $ok,
					'insert_id'  => (int) $wpdb->insert_id,
					'auto_inc'   => self::primary_key_auto_increments(),
					'row_count'  => self::row_count(),
				)
			);
			return 0;
		}

		return (int) $wpdb->insert_id;
	}

	/**
	 * @param string $column Column name.
	 * @return bool
	 */
	private static function column_exists( $column ) {
		if ( ! self::table_exists() ) {
			return false;
		}

		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$found = $wpdb->get_results( $wpdb->prepare( "SHOW COLUMNS FROM {$table} LIKE %s", $column ) );

		return ! empty( $found );
	}

	/**
	 * @param int $user_id User id.
	 * @return bool
	 */
	public static function activate_phone( $user_id ) {
		self::maybe_create_table();

		global $wpdb;

		$now = current_time( 'mysql', true );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$updated = $wpdb->update(
			self::table_name(),
			array(
				'status'         => self::STATUS_ACTIVE,
				'phone_verified' => 1,
				'updated_at'     => $now,
			),
			array(
				'id'     => (int) $user_id,
				'status' => self::STATUS_PENDING,
			),
			array( '%s', '%d', '%s' ),
			array( '%d', '%s' )
		);

		return (bool) $updated;
	}

	/**
	 * @param int $user_id User id.
	 * @return bool
	 */
	public static function mark_email_verified( $user_id ) {
		self::maybe_create_table();

		global $wpdb;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$updated = $wpdb->update(
			self::table_name(),
			array(
				'email_verified' => 1,
				'updated_at'     => current_time( 'mysql', true ),
			),
			array( 'id' => (int) $user_id ),
			array( '%d', '%s' ),
			array( '%d' )
		);

		return (bool) $updated;
	}

	/**
	 * @param int    $user_id User id.
	 * @param string $hash    Password hash.
	 * @return bool
	 */
	/**
	 * @param int                  $user_id User id.
	 * @param array<string,mixed>  $fields  Column => value.
	 * @return bool
	 */
	public static function update_fields( $user_id, array $fields ) {
		self::maybe_create_table();
		self::maybe_migrate_columns();

		$allowed = array(
			'display_name'         => '%s',
			'email'                => '%s',
			'phone_e164'           => '%s',
			'phone_verified'       => '%d',
			'email_verified'       => '%d',
			'avatar_attachment_id' => '%d',
			'notification_prefs'   => '%s',
		);

		$data   = array();
		$format = array();

		foreach ( $fields as $key => $value ) {
			if ( ! isset( $allowed[ $key ] ) ) {
				continue;
			}
			$data[ $key ] = $value;
			$format[]     = $allowed[ $key ];
		}

		if ( empty( $data ) ) {
			return false;
		}

		$data['updated_at'] = current_time( 'mysql', true );
		$format[]           = '%s';

		global $wpdb;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$updated = $wpdb->update(
			self::table_name(),
			$data,
			array( 'id' => (int) $user_id ),
			$format,
			array( '%d' )
		);

		return false !== $updated;
	}

	/**
	 * @param int    $user_id User id.
	 * @param string $hash    Password hash.
	 * @return bool
	 */
	public static function update_password( $user_id, $hash ) {
		self::maybe_create_table();

		global $wpdb;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$updated = $wpdb->update(
			self::table_name(),
			array(
				'password_hash' => $hash,
				'updated_at'      => current_time( 'mysql', true ),
			),
			array( 'id' => (int) $user_id ),
			array( '%s', '%s' ),
			array( '%d' )
		);

		return (bool) $updated;
	}

	/**
	 * @param int $user_id User id.
	 * @return object|null
	 */
	public static function get_by_id( $user_id ) {
		self::maybe_create_table();

		global $wpdb;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$row = $wpdb->get_row(
			$wpdb->prepare(
				'SELECT * FROM ' . self::table_name() . ' WHERE id = %d',
				(int) $user_id
			)
		);

		return $row ? $row : null;
	}

	/**
	 * @param string $phone_e164 E.164 phone.
	 * @return object|null
	 */
	public static function find_by_phone( $phone_e164 ) {
		$phone = self::sanitize_phone( $phone_e164 );
		if ( ! $phone ) {
			return null;
		}

		return self::find_active_row( 'phone_e164', $phone );
	}

	/**
	 * @param string $email Email address.
	 * @return object|null
	 */
	public static function find_by_email( $email ) {
		$email = strtolower( sanitize_email( $email ) );
		if ( ! is_email( $email ) ) {
			return null;
		}

		return self::find_active_row( 'email', $email );
	}

	/**
	 * @param string $identifier Email or E.164 phone.
	 * @return object|null
	 */
	public static function find_by_identifier( $identifier ) {
		$identifier = trim( (string) $identifier );
		if ( '' === $identifier ) {
			return null;
		}

		if ( false !== strpos( $identifier, '@' ) ) {
			return self::find_by_email( $identifier );
		}

		return self::find_by_phone( $identifier );
	}

	/**
	 * Lookup for login/OTP — includes paused accounts (not deleted).
	 *
	 * @param string $identifier Email or E.164 phone.
	 * @return object|null
	 */
	public static function find_by_identifier_for_auth( $identifier ) {
		$identifier = trim( (string) $identifier );
		if ( '' === $identifier ) {
			return null;
		}

		$statuses = array(
			self::STATUS_PENDING,
			self::STATUS_ACTIVE,
			self::STATUS_PAUSED,
		);

		if ( false !== strpos( $identifier, '@' ) ) {
			$email = strtolower( sanitize_email( $identifier ) );
			if ( ! is_email( $email ) ) {
				return null;
			}
			return self::find_row_by_statuses( 'email', $email, $statuses );
		}

		$phone = self::sanitize_phone( $identifier );
		if ( ! $phone ) {
			return null;
		}

		return self::find_row_by_statuses( 'phone_e164', $phone, $statuses );
	}

	/**
	 * @param string $phone_e164 E.164 phone.
	 * @return object|null
	 */
	public static function find_by_phone_for_auth( $phone_e164 ) {
		$phone = self::sanitize_phone( $phone_e164 );
		if ( ! $phone ) {
			return null;
		}

		return self::find_row_by_statuses(
			'phone_e164',
			$phone,
			array(
				self::STATUS_PENDING,
				self::STATUS_ACTIVE,
				self::STATUS_PAUSED,
			)
		);
	}

	/**
	 * @return bool
	 */
	public static function is_paused( $user ) {
		return (bool) ( $user && self::STATUS_PAUSED === $user->status );
	}

	/**
	 * Standard WP_Error for paused accounts (login / OTP).
	 *
	 * @return WP_Error
	 */
	public static function account_paused_error() {
		return new WP_Error(
			'account_paused',
			__( 'Your account has been paused. Please contact Radio Udaan support.', 'radioudaan-app-api' ),
			array( 'status' => 403 )
		);
	}

	/**
	 * Remove abandoned pending signups so phone numbers are not squatted without OTP proof.
	 *
	 * @param string $phone_e164   E.164 phone.
	 * @param int    $max_age_secs Max age before purge (default 24h).
	 */
	public static function purge_stale_pending_phone( $phone_e164, $max_age_secs = DAY_IN_SECONDS ) {
		$user = self::find_by_phone( $phone_e164 );
		if ( ! $user || self::STATUS_PENDING !== $user->status ) {
			return;
		}
		if ( (int) $user->phone_verified ) {
			return;
		}

		$created = isset( $user->created_at ) ? strtotime( (string) $user->created_at ) : 0;
		if ( $created > 0 && ( time() - $created ) >= (int) $max_age_secs ) {
			self::soft_delete( (int) $user->id );
		}
	}

	/**
	 * @param string $phone_e164 Phone.
	 * @return bool
	 */
	public static function phone_taken( $phone_e164 ) {
		return (bool) self::find_by_phone( $phone_e164 );
	}

	/**
	 * @param string $email Email.
	 * @return bool
	 */
	public static function email_taken( $email ) {
		if ( ! RadioUdaan_App_Settings::require_unique_email() ) {
			return false;
		}

		return (bool) self::find_by_email( $email );
	}

	/**
	 * Soft-delete: free phone/email for reuse and revoke sessions externally.
	 *
	 * @param int $user_id User id.
	 * @return bool
	 */
	public static function soft_delete( $user_id ) {
		self::maybe_create_table();

		global $wpdb;

		$now = current_time( 'mysql', true );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$updated = $wpdb->update(
			self::table_name(),
			array(
				'status'         => self::STATUS_DELETED,
				'phone_e164'     => '',
				'email'          => '',
				'password_hash'  => '',
				'phone_verified' => 0,
				'email_verified' => 0,
				'updated_at'     => $now,
			),
			array( 'id' => (int) $user_id ),
			array( '%s', '%s', '%s', '%s', '%d', '%d', '%s' ),
			array( '%d' )
		);

		return (bool) $updated;
	}

	/**
	 * @param int $user_id User id.
	 */
	public static function record_login( $user_id ) {
		self::maybe_create_table();

		global $wpdb;

		$user = self::get_by_id( $user_id );
		if ( ! $user || self::STATUS_ACTIVE !== $user->status ) {
			return;
		}

		$now   = current_time( 'mysql', true );
		$table = self::table_name();

		$first = $user->first_login_at ? $user->first_login_at : $now;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$wpdb->update(
			$table,
			array(
				'first_login_at' => $first,
				'last_login_at'  => $now,
				'login_count'    => (int) $user->login_count + 1,
				'updated_at'     => $now,
			),
			array( 'id' => (int) $user_id ),
			array( '%s', '%s', '%d', '%s' ),
			array( '%d' )
		);
	}

	/**
	 * @param string $status Status value.
	 * @return int
	 */
	public static function count_by_status( $status ) {
		self::maybe_create_table();

		$status = sanitize_key( (string) $status );
		if ( '' === $status ) {
			return 0;
		}

		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		return (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE status = %s",
				$status
			)
		);
	}

	/**
	 * @return int
	 */
	public static function count_active_users() {
		return self::count_by_status( self::STATUS_ACTIVE );
	}

	/**
	 * @param int $days Lookback window in days.
	 * @return int
	 */
	public static function count_logged_in_last_days( $days ) {
		self::maybe_create_table();

		$days = max( 1, (int) $days );
		$since = gmdate( 'Y-m-d H:i:s', time() - ( $days * DAY_IN_SECONDS ) );

		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		return (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE status = %s AND last_login_at IS NOT NULL AND last_login_at >= %s",
				self::STATUS_ACTIVE,
				$since
			)
		);
	}

	/**
	 * @param array<string,mixed> $args Query args: page, per_page, status, search, orderby, order.
	 * @return array{items:array<int,object>,page:int,per_page:int,total:int,total_pages:int}
	 */
	public static function list_users_paginated( array $args = array() ) {
		self::maybe_create_table();

		global $wpdb;

		$page     = max( 1, (int) ( $args['page'] ?? 1 ) );
		$per_page = max( 1, min( 500, (int) ( $args['per_page'] ?? 50 ) ) );
		$offset   = ( $page - 1 ) * $per_page;
		$status   = isset( $args['status'] ) ? sanitize_key( (string) $args['status'] ) : '';
		$search   = isset( $args['search'] ) ? trim( (string) $args['search'] ) : '';
		$orderby  = isset( $args['orderby'] ) ? sanitize_key( (string) $args['orderby'] ) : 'last_login_at';
		$order    = isset( $args['order'] ) ? strtoupper( (string) $args['order'] ) : 'DESC';

		$allowed_orderby = array(
			'last_login_at' => 'last_login_at',
			'created_at'    => 'created_at',
			'display_name'  => 'display_name',
			'email'         => 'email',
			'status'        => 'status',
		);
		if ( ! isset( $allowed_orderby[ $orderby ] ) ) {
			$orderby = 'last_login_at';
		}
		$order_sql = 'ASC' === $order ? 'ASC' : 'DESC';

		$table  = self::table_name();
		$where  = array( 'status != %s' );
		$params = array( self::STATUS_DELETED );

		if ( '' !== $status && self::STATUS_DELETED !== $status ) {
			$where[]  = 'status = %s';
			$params[] = $status;
		}

		if ( '' !== $search ) {
			$like     = '%' . $wpdb->esc_like( $search ) . '%';
			$where[]  = '(display_name LIKE %s OR email LIKE %s OR phone_e164 LIKE %s)';
			$params[] = $like;
			$params[] = $like;
			$params[] = $like;
		}

		$where_sql = implode( ' AND ', $where );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching, WordPress.DB.PreparedSQL.InterpolatedNotPrepared
		$total = (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE {$where_sql}",
				$params
			)
		);

		$params[] = $per_page;
		$params[] = $offset;

		$order_col = $allowed_orderby[ $orderby ];

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching, WordPress.DB.PreparedSQL.InterpolatedNotPrepared
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$table} WHERE {$where_sql} ORDER BY {$order_col} {$order_sql}, created_at DESC LIMIT %d OFFSET %d",
				$params
			)
		);

		return array(
			'items'       => is_array( $rows ) ? $rows : array(),
			'page'        => $page,
			'per_page'    => $per_page,
			'total'       => $total,
			'total_pages' => $per_page > 0 ? (int) ceil( $total / $per_page ) : 0,
		);
	}

	/**
	 * @param int $user_id User id.
	 * @return bool
	 */
	public static function pause( $user_id ) {
		return self::set_status( (int) $user_id, self::STATUS_PAUSED );
	}

	/**
	 * @param int $user_id User id.
	 * @return bool
	 */
	public static function resume( $user_id ) {
		$user = self::get_by_id( $user_id );
		if ( ! $user || self::STATUS_PAUSED !== $user->status ) {
			return false;
		}

		return self::set_status( (int) $user_id, self::STATUS_ACTIVE );
	}

	/**
	 * @param int    $user_id User id.
	 * @param string $status  Target status.
	 * @return bool
	 */
	public static function set_status( $user_id, $status ) {
		self::maybe_create_table();

		$user_id = (int) $user_id;
		$status  = sanitize_key( (string) $status );

		$allowed = array(
			self::STATUS_PENDING,
			self::STATUS_ACTIVE,
			self::STATUS_PAUSED,
			self::STATUS_DELETED,
		);
		if ( ! in_array( $status, $allowed, true ) ) {
			return false;
		}

		$user = self::get_by_id( $user_id );
		if ( ! $user || $status === $user->status ) {
			return false;
		}

		if ( self::STATUS_PAUSED === $status && self::STATUS_ACTIVE !== $user->status ) {
			return false;
		}

		if ( self::STATUS_ACTIVE === $status && ! in_array( $user->status, array( self::STATUS_PAUSED, self::STATUS_PENDING ), true ) ) {
			return false;
		}

		global $wpdb;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$updated = $wpdb->update(
			self::table_name(),
			array(
				'status'     => $status,
				'updated_at' => current_time( 'mysql', true ),
			),
			array( 'id' => $user_id ),
			array( '%s', '%s' ),
			array( '%d' )
		);

		if ( false === $updated ) {
			return false;
		}

		if ( self::STATUS_PAUSED === $status ) {
			RadioUdaan_App_Auth::revoke_all_tokens_for_user_id( $user_id );
		}

		return true;
	}

	/**
	 * @param int $limit Max rows.
	 * @return array<int,object>
	 */
	public static function list_users( $limit = 100 ) {
		self::maybe_create_table();

		global $wpdb;

		$limit = max( 1, min( 500, (int) $limit ) );
		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$table} WHERE status != %s ORDER BY last_login_at DESC, created_at DESC LIMIT %d",
				self::STATUS_DELETED,
				$limit
			)
		);

		return is_array( $rows ) ? $rows : array();
	}

	/**
	 * @return int
	 */
	public static function count_users() {
		self::maybe_create_table();

		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		return (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE status != %s",
				self::STATUS_DELETED
			)
		);
	}

	/**
	 * @deprecated Use soft_delete() by user id.
	 * @param string $phone_e164 E.164 phone.
	 * @return bool
	 */
	public static function delete_by_phone( $phone_e164 ) {
		$user = self::find_by_phone( $phone_e164 );
		if ( ! $user ) {
			return false;
		}

		return self::soft_delete( (int) $user->id );
	}

	/**
	 * Phone/email uniqueness — pending and active only (paused may re-register same identifiers).
	 *
	 * @param string $column Column name.
	 * @param string $value  Value.
	 * @return object|null
	 */
	private static function find_active_row( $column, $value ) {
		return self::find_row_by_statuses(
			$column,
			$value,
			array(
				self::STATUS_PENDING,
				self::STATUS_ACTIVE,
			)
		);
	}

	/**
	 * @param string        $column   Column name.
	 * @param string        $value    Value.
	 * @param array<string> $statuses Allowed statuses.
	 * @return object|null
	 */
	private static function find_row_by_statuses( $column, $value, array $statuses ) {
		self::maybe_create_table();

		if ( ! in_array( $column, array( 'phone_e164', 'email' ), true ) ) {
			return null;
		}

		$statuses = array_values( array_filter( array_map( 'sanitize_key', $statuses ) ) );
		if ( empty( $statuses ) ) {
			return null;
		}

		global $wpdb;

		$table        = self::table_name();
		$placeholders = implode( ', ', array_fill( 0, count( $statuses ), '%s' ) );
		$params       = array_merge( array( $value ), $statuses );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching, WordPress.DB.PreparedSQL.InterpolatedNotPrepared
		$row = $wpdb->get_row(
			$wpdb->prepare(
				"SELECT * FROM {$table} WHERE {$column} = %s AND status IN ({$placeholders})",
				$params
			)
		);

		return $row ? $row : null;
	}

	/**
	 * @param string $phone Phone input.
	 * @return string
	 */
	private static function sanitize_phone( $phone ) {
		$phone = preg_replace( '/\s+/', '', (string) $phone );
		if ( ! preg_match( '/^\+[1-9]\d{7,14}$/', $phone ) ) {
			return '';
		}

		return $phone;
	}
}

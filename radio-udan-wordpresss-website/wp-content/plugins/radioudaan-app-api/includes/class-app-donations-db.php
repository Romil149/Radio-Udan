<?php
/**
 * Donation records for Razorpay online payments.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Persists donation orders and capture status.
 */
class RadioUdaan_App_Donations_Db {

	const DB_VERSION_OPTION = 'radioudaan_donations_db_version';
	const DB_VERSION        = '1.0';

	const STATUS_CREATED  = 'created';
	const STATUS_CAPTURED = 'captured';
	const STATUS_FAILED   = 'failed';

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'init', array( __CLASS__, 'maybe_create_tables' ), 5 );
	}

	/**
	 * @return string
	 */
	public static function table() {
		global $wpdb;
		return $wpdb->prefix . 'ru_app_donations';
	}

	/**
	 * Create donations table.
	 */
	public static function maybe_create_tables() {
		if ( self::DB_VERSION === get_option( self::DB_VERSION_OPTION, '' ) ) {
			return;
		}

		global $wpdb;
		$table   = self::table();
		$charset = $wpdb->get_charset_collate();

		$sql = "CREATE TABLE {$table} (
			id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
			user_id bigint(20) unsigned DEFAULT NULL,
			razorpay_order_id varchar(64) NOT NULL,
			razorpay_payment_id varchar(64) DEFAULT NULL,
			payment_link_id varchar(64) DEFAULT NULL,
			amount_paise int(11) unsigned NOT NULL,
			currency varchar(8) NOT NULL DEFAULT 'INR',
			status varchar(20) NOT NULL DEFAULT 'created',
			donor_name varchar(191) DEFAULT NULL,
			email varchar(191) DEFAULT NULL,
			phone varchar(32) DEFAULT NULL,
			want_80g tinyint(1) NOT NULL DEFAULT 0,
			pan_encrypted text DEFAULT NULL,
			receipt_sent_at datetime DEFAULT NULL,
			created_at datetime NOT NULL,
			updated_at datetime NOT NULL,
			PRIMARY KEY  (id),
			UNIQUE KEY razorpay_order_id (razorpay_order_id),
			KEY status (status),
			KEY user_id (user_id),
			KEY created_at (created_at)
		) {$charset};";

		require_once ABSPATH . 'wp-admin/includes/upgrade.php';
		dbDelta( $sql );
		update_option( self::DB_VERSION_OPTION, self::DB_VERSION );
	}

	/**
	 * @param array<string,mixed> $data Row data.
	 * @return int Donation id or 0.
	 */
	public static function insert( array $data ) {
		global $wpdb;
		$now = current_time( 'mysql', true );
		$row = array(
			'user_id'            => isset( $data['user_id'] ) ? (int) $data['user_id'] : null,
			'razorpay_order_id'  => sanitize_text_field( (string) ( $data['razorpay_order_id'] ?? '' ) ),
			'razorpay_payment_id'=> isset( $data['razorpay_payment_id'] ) ? sanitize_text_field( (string) $data['razorpay_payment_id'] ) : null,
			'payment_link_id'    => isset( $data['payment_link_id'] ) ? sanitize_text_field( (string) $data['payment_link_id'] ) : null,
			'amount_paise'       => (int) ( $data['amount_paise'] ?? 0 ),
			'currency'           => sanitize_text_field( (string) ( $data['currency'] ?? 'INR' ) ),
			'status'             => sanitize_text_field( (string) ( $data['status'] ?? self::STATUS_CREATED ) ),
			'donor_name'         => isset( $data['donor_name'] ) ? sanitize_text_field( (string) $data['donor_name'] ) : null,
			'email'              => isset( $data['email'] ) ? sanitize_email( (string) $data['email'] ) : null,
			'phone'              => isset( $data['phone'] ) ? sanitize_text_field( (string) $data['phone'] ) : null,
			'want_80g'           => ! empty( $data['want_80g'] ) ? 1 : 0,
			'pan_encrypted'      => isset( $data['pan_encrypted'] ) ? (string) $data['pan_encrypted'] : null,
			'created_at'         => $now,
			'updated_at'         => $now,
		);

		if ( '' === $row['razorpay_order_id'] || $row['amount_paise'] < 1 ) {
			return 0;
		}

		$wpdb->insert( self::table(), $row );
		return (int) $wpdb->insert_id;
	}

	/**
	 * @param string $order_id Razorpay order id.
	 * @return object|null
	 */
	public static function get_by_order_id( $order_id ) {
		global $wpdb;
		$order_id = sanitize_text_field( (string) $order_id );
		if ( '' === $order_id ) {
			return null;
		}
		return $wpdb->get_row(
			$wpdb->prepare(
				'SELECT * FROM ' . self::table() . ' WHERE razorpay_order_id = %s LIMIT 1',
				$order_id
			)
		);
	}

	/**
	 * @param string $payment_link_id Razorpay payment link id.
	 * @return object|null
	 */
	public static function get_by_payment_link_id( $payment_link_id ) {
		global $wpdb;
		$payment_link_id = sanitize_text_field( (string) $payment_link_id );
		if ( '' === $payment_link_id ) {
			return null;
		}
		return $wpdb->get_row(
			$wpdb->prepare(
				'SELECT * FROM ' . self::table() . ' WHERE payment_link_id = %s LIMIT 1',
				$payment_link_id
			)
		);
	}

	/**
	 * @param int    $id              Donation id.
	 * @param string $payment_link_id Payment link id.
	 * @return bool
	 */
	public static function update_payment_link_id( $id, $payment_link_id ) {
		global $wpdb;
		return (bool) $wpdb->update(
			self::table(),
			array(
				'payment_link_id' => sanitize_text_field( (string) $payment_link_id ),
				'updated_at'      => current_time( 'mysql', true ),
			),
			array( 'id' => (int) $id ),
			array( '%s', '%s' ),
			array( '%d' )
		);
	}

	/**
	 * @param int $id Donation id.
	 * @return object|null
	 */
	public static function get_by_id( $id ) {
		global $wpdb;
		$id = (int) $id;
		if ( $id < 1 ) {
			return null;
		}
		return $wpdb->get_row(
			$wpdb->prepare(
				'SELECT * FROM ' . self::table() . ' WHERE id = %d LIMIT 1',
				$id
			)
		);
	}

	/**
	 * @param int    $id     Donation id.
	 * @param string $status Status.
	 * @param string $payment_id Payment id.
	 * @return bool
	 */
	public static function mark_captured( $id, $payment_id ) {
		global $wpdb;
		return (bool) $wpdb->update(
			self::table(),
			array(
				'status'              => self::STATUS_CAPTURED,
				'razorpay_payment_id' => sanitize_text_field( (string) $payment_id ),
				'updated_at'          => current_time( 'mysql', true ),
			),
			array( 'id' => (int) $id ),
			array( '%s', '%s', '%s' ),
			array( '%d' )
		);
	}

	/**
	 * @param int    $id         Donation id.
	 * @param string $payment_id Optional payment id.
	 * @return bool
	 */
	public static function mark_failed( $id, $payment_id = '' ) {
		global $wpdb;
		$data = array(
			'status'     => self::STATUS_FAILED,
			'updated_at' => current_time( 'mysql', true ),
		);
		$format = array( '%s', '%s' );
		if ( '' !== $payment_id ) {
			$data['razorpay_payment_id'] = sanitize_text_field( (string) $payment_id );
			$format[]                    = '%s';
		}
		return (bool) $wpdb->update(
			self::table(),
			$data,
			array( 'id' => (int) $id ),
			$format,
			array( '%d' )
		);
	}

	/**
	 * @param int $id Donation id.
	 * @return bool
	 */
	public static function mark_receipt_sent( $id ) {
		global $wpdb;
		return (bool) $wpdb->update(
			self::table(),
			array(
				'receipt_sent_at' => current_time( 'mysql', true ),
				'updated_at'      => current_time( 'mysql', true ),
			),
			array( 'id' => (int) $id ),
			array( '%s', '%s' ),
			array( '%d' )
		);
	}

	/**
	 * @param int $limit Limit.
	 * @return array<int,object>
	 */
	public static function list_recent( $limit = 50 ) {
		$result = self::list_paginated(
			array(
				'per_page' => max( 1, min( 200, (int) $limit ) ),
				'page'     => 1,
			)
		);
		return $result['items'];
	}

	/**
	 * @param array<string,mixed> $args page, per_page, status, search.
	 * @return array{items:array<int,object>,page:int,per_page:int,total:int,total_pages:int}
	 */
	public static function list_paginated( array $args = array() ) {
		global $wpdb;

		$page     = max( 1, (int) ( $args['page'] ?? 1 ) );
		$per_page = max( 1, min( 100, (int) ( $args['per_page'] ?? 25 ) ) );
		$offset   = ( $page - 1 ) * $per_page;
		$status   = isset( $args['status'] ) ? sanitize_key( (string) $args['status'] ) : '';
		$search   = isset( $args['search'] ) ? trim( (string) $args['search'] ) : '';

		$table  = self::table();
		$where  = array( '1=1' );
		$params = array();

		$allowed_statuses = array(
			self::STATUS_CREATED,
			self::STATUS_CAPTURED,
			self::STATUS_FAILED,
		);
		if ( '' !== $status && in_array( $status, $allowed_statuses, true ) ) {
			$where[]  = 'status = %s';
			$params[] = $status;
		}

		if ( '' !== $search ) {
			$like     = '%' . $wpdb->esc_like( $search ) . '%';
			$where[]  = '(donor_name LIKE %s OR email LIKE %s OR phone LIKE %s OR razorpay_payment_id LIKE %s OR razorpay_order_id LIKE %s)';
			$params[] = $like;
			$params[] = $like;
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

		$query_params   = $params;
		$query_params[] = $per_page;
		$query_params[] = $offset;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching, WordPress.DB.PreparedSQL.InterpolatedNotPrepared
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$table} WHERE {$where_sql} ORDER BY id DESC LIMIT %d OFFSET %d",
				$query_params
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
	 * Aggregates for the donations admin screen.
	 *
	 * @return array<string,int|float>
	 */
	public static function get_admin_stats() {
		global $wpdb;

		$table = self::table();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$total = (int) $wpdb->get_var( "SELECT COUNT(*) FROM {$table}" );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$captured = (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE status = %s",
				self::STATUS_CAPTURED
			)
		);

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$failed = (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE status = %s",
				self::STATUS_FAILED
			)
		);

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$pending = (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE status = %s",
				self::STATUS_CREATED
			)
		);

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$captured_paise = (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COALESCE(SUM(amount_paise), 0) FROM {$table} WHERE status = %s",
				self::STATUS_CAPTURED
			)
		);

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$with_80g = (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$table} WHERE want_80g = 1 AND status = %s",
				self::STATUS_CAPTURED
			)
		);

		return array(
			'total'               => $total,
			'captured'            => $captured,
			'failed'              => $failed,
			'pending'             => $pending,
			'captured_amount_inr' => $captured_paise / 100,
			'with_80g'            => $with_80g,
		);
	}
}

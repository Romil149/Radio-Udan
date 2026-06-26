<?php
/**
 * Per-user saved radio shows and library videos.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Stores favorites in wp_ru_app_favorites with item snapshots for offline list UI.
 */
class RadioUdaan_App_Favorites {

	const DB_VERSION_OPTION = 'radioudaan_favorites_db_version';
	const DB_VERSION        = '1.0';

	const TYPE_RADIO_SHOW    = 'radio_show';
	const TYPE_LIBRARY_VIDEO = 'library_video';

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
		return $wpdb->prefix . 'ru_app_favorites';
	}

	/**
	 * Create favorites table when needed.
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
			user_id bigint(20) unsigned NOT NULL,
			item_type varchar(32) NOT NULL DEFAULT '',
			item_id varchar(128) NOT NULL DEFAULT '',
			title varchar(500) NOT NULL DEFAULT '',
			meta_json longtext NULL,
			created_at datetime NOT NULL,
			updated_at datetime NOT NULL,
			PRIMARY KEY  (id),
			UNIQUE KEY user_item (user_id, item_type, item_id),
			KEY user_id (user_id),
			KEY item_type (item_type)
		) {$charset};";

		require_once ABSPATH . 'wp-admin/includes/upgrade.php';
		dbDelta( $sql );

		update_option( self::DB_VERSION_OPTION, self::DB_VERSION );
	}

	/**
	 * @param int $user_id User id.
	 * @return array<int,array<string,mixed>>
	 */
	public static function list_for_user( $user_id ) {
		self::maybe_create_table();

		$user_id = (int) $user_id;
		if ( $user_id <= 0 ) {
			return array();
		}

		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$table} WHERE user_id = %d ORDER BY updated_at DESC, id DESC",
				$user_id
			)
		);

		if ( ! is_array( $rows ) ) {
			return array();
		}

		$items = array();
		foreach ( $rows as $row ) {
			$formatted = self::format_row( $row );
			if ( null !== $formatted ) {
				$items[] = $formatted;
			}
		}

		return $items;
	}

	/**
	 * @param int                 $user_id User id.
	 * @param array<string,mixed> $body    Request JSON.
	 * @return array<string,mixed>|WP_Error
	 */
	public static function toggle( $user_id, array $body ) {
		self::maybe_create_table();

		$user_id = (int) $user_id;
		if ( $user_id <= 0 ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$type    = isset( $body['type'] ) ? sanitize_key( (string) $body['type'] ) : '';
		$item_id = isset( $body['item_id'] ) ? sanitize_text_field( (string) $body['item_id'] ) : '';

		if ( ! self::is_valid_type( $type ) ) {
			return new WP_Error( 'type_invalid', __( 'Invalid favorite type.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}
		if ( '' === $item_id ) {
			return new WP_Error( 'item_id_required', __( 'Item id is required.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		global $wpdb;

		$table = self::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$existing_id = $wpdb->get_var(
			$wpdb->prepare(
				"SELECT id FROM {$table} WHERE user_id = %d AND item_type = %s AND item_id = %s",
				$user_id,
				$type,
				$item_id
			)
		);

		if ( $existing_id ) {
			// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
			$wpdb->delete(
				$table,
				array( 'id' => (int) $existing_id ),
				array( '%d' )
			);

			return array(
				'saved' => false,
				'items' => self::list_for_user( $user_id ),
			);
		}

		$title = isset( $body['title'] ) ? sanitize_text_field( (string) $body['title'] ) : '';
		$meta  = self::sanitize_meta( isset( $body['meta'] ) && is_array( $body['meta'] ) ? $body['meta'] : array() );
		$now   = current_time( 'mysql', true );

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery
		$inserted = $wpdb->insert(
			$table,
			array(
				'user_id'    => $user_id,
				'item_type'  => $type,
				'item_id'    => $item_id,
				'title'      => $title,
				'meta_json'  => wp_json_encode( $meta ),
				'created_at' => $now,
				'updated_at' => $now,
			),
			array( '%d', '%s', '%s', '%s', '%s', '%s', '%s' )
		);

		if ( ! $inserted ) {
			return new WP_Error( 'favorite_save_failed', __( 'Could not save favorite.', 'radioudaan-app-api' ), array( 'status' => 500 ) );
		}

		return array(
			'saved' => true,
			'items' => self::list_for_user( $user_id ),
		);
	}

	/**
	 * Union-merge client favorites into the account (e.g. after guest → login).
	 *
	 * @param int                 $user_id User id.
	 * @param array<string,mixed> $body    Request JSON.
	 * @return array<string,mixed>|WP_Error
	 */
	public static function sync( $user_id, array $body ) {
		self::maybe_create_table();

		$user_id = (int) $user_id;
		if ( $user_id <= 0 ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$raw_items = isset( $body['items'] ) && is_array( $body['items'] ) ? $body['items'] : array();
		if ( count( $raw_items ) > 200 ) {
			return new WP_Error( 'too_many_items', __( 'Too many favorites in one sync.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		global $wpdb;

		$table = self::table_name();
		$now   = current_time( 'mysql', true );

		foreach ( $raw_items as $item ) {
			if ( ! is_array( $item ) ) {
				continue;
			}

			$type    = isset( $item['type'] ) ? sanitize_key( (string) $item['type'] ) : '';
			$item_id = isset( $item['item_id'] ) ? sanitize_text_field( (string) $item['item_id'] ) : '';
			if ( ! self::is_valid_type( $type ) || '' === $item_id ) {
				continue;
			}

			$title = isset( $item['title'] ) ? sanitize_text_field( (string) $item['title'] ) : '';
			$meta  = self::sanitize_meta( isset( $item['meta'] ) && is_array( $item['meta'] ) ? $item['meta'] : array() );

			// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
			$existing_id = $wpdb->get_var(
				$wpdb->prepare(
					"SELECT id FROM {$table} WHERE user_id = %d AND item_type = %s AND item_id = %s",
					$user_id,
					$type,
					$item_id
				)
			);

			if ( $existing_id ) {
				// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
				$wpdb->update(
					$table,
					array(
						'title'      => $title,
						'meta_json'  => wp_json_encode( $meta ),
						'updated_at' => $now,
					),
					array( 'id' => (int) $existing_id ),
					array( '%s', '%s', '%s' ),
					array( '%d' )
				);
				continue;
			}

			// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery
			$wpdb->insert(
				$table,
				array(
					'user_id'    => $user_id,
					'item_type'  => $type,
					'item_id'    => $item_id,
					'title'      => $title,
					'meta_json'  => wp_json_encode( $meta ),
					'created_at' => $now,
					'updated_at' => $now,
				),
				array( '%d', '%s', '%s', '%s', '%s', '%s', '%s' )
			);
		}

		return array( 'items' => self::list_for_user( $user_id ) );
	}

	/**
	 * @param int $user_id User id.
	 */
	public static function delete_for_user( $user_id ) {
		self::maybe_create_table();

		$user_id = (int) $user_id;
		if ( $user_id <= 0 ) {
			return;
		}

		global $wpdb;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$wpdb->delete(
			self::table_name(),
			array( 'user_id' => $user_id ),
			array( '%d' )
		);
	}

	/**
	 * @param string $type Item type.
	 * @return bool
	 */
	private static function is_valid_type( $type ) {
		return in_array( $type, array( self::TYPE_RADIO_SHOW, self::TYPE_LIBRARY_VIDEO ), true );
	}

	/**
	 * @param array<string,mixed> $meta Raw meta.
	 * @return array<string,string>
	 */
	private static function sanitize_meta( array $meta ) {
		$allowed = array(
			'thumbnail_url',
			'hosts',
			'category',
			'channel_title',
			'duration',
			'description',
		);

		$clean = array();
		foreach ( $allowed as $key ) {
			if ( ! isset( $meta[ $key ] ) ) {
				continue;
			}
			$value = is_scalar( $meta[ $key ] ) ? (string) $meta[ $key ] : '';
			$value = sanitize_text_field( $value );
			if ( '' !== $value ) {
				$clean[ $key ] = $value;
			}
		}

		return $clean;
	}

	/**
	 * @param object $row DB row.
	 * @return array<string,mixed>|null
	 */
	private static function format_row( $row ) {
		if ( ! is_object( $row ) ) {
			return null;
		}

		$type = isset( $row->item_type ) ? (string) $row->item_type : '';
		if ( ! self::is_valid_type( $type ) ) {
			return null;
		}

		$meta = array();
		if ( ! empty( $row->meta_json ) ) {
			$decoded = json_decode( (string) $row->meta_json, true );
			if ( is_array( $decoded ) ) {
				$meta = self::sanitize_meta( $decoded );
			}
		}

		return array(
			'type'     => $type,
			'item_id'  => (string) $row->item_id,
			'title'    => (string) $row->title,
			'meta'     => $meta,
			'saved_at' => (string) $row->updated_at,
		);
	}
}

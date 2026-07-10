<?php
/**
 * Admin data helpers (stats, entries, events).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Queries and aggregates for the app admin dashboard.
 */
class RadioUdaan_Admin_Data {

	/**
	 * @return array<string,mixed>
	 */
	public static function get_dashboard_stats() {
		$events           = self::get_managed_events();
		$open_count       = 0;
		$open_in_app      = 0;
		$form_ids         = array();

		foreach ( $events as $event ) {
			$has_code = ! empty( $event['event_code'] );
			$has_form = ! empty( $event['form_id'] );
			if ( 'open' === $event['status'] ) {
				++$open_count;
				if ( $has_code && $has_form ) {
					++$open_in_app;
				}
			}
			if ( $has_form ) {
				$form_ids[] = (int) $event['form_id'];
			}
		}

		$app_users_active  = RadioUdaan_App_Users::count_by_status( RadioUdaan_App_Users::STATUS_ACTIVE );
		$app_users_pending = RadioUdaan_App_Users::count_by_status( RadioUdaan_App_Users::STATUS_PENDING );
		$app_users_total   = RadioUdaan_App_Users::count_users();
		$app_entries   = self::count_app_entries();
		$web_entries   = self::count_web_entries();
		$health        = self::fetch_health();
		$dev_otp       = RadioUdaan_App_Settings::is_dev_otp_enabled();
		$dev_auth      = RadioUdaan_App_Settings::is_dev_auth_enabled();
		$msg91         = class_exists( 'RadioUdaan_Otp_Msg91' ) && RadioUdaan_Otp_Msg91::is_configured();

		return array(
			'events_total'      => count( $events ),
			'events_open'       => $open_count,
			'events_open_in_app' => $open_in_app,
			'app_users'         => $app_users_total,
			'app_users_active'  => $app_users_active,
			'app_users_pending' => $app_users_pending,
			'app_users_total'   => $app_users_total,
			'app_entries'   => $app_entries,
			'web_entries'   => $web_entries,
			'api_ok'        => $health['ok'],
			'api_version'   => $health['version'],
			'dev_otp'       => $dev_otp,
			'dev_auth'      => $dev_auth,
			'msg91'         => $msg91,
			'forminator_ok' => class_exists( 'Forminator_API' ),
		);
	}

	/**
	 * All ru_event posts for admin (includes draft status).
	 *
	 * @return array<int,array<string,mixed>>
	 */
	public static function get_managed_events() {
		$posts = get_posts(
			array(
				'post_type'      => RadioUdaan_Cpt_Ru_Event::POST_TYPE,
				'post_status'    => array( 'publish', 'draft', 'pending' ),
				'posts_per_page' => 100,
				'orderby'        => array( 'menu_order' => 'ASC', 'title' => 'ASC' ),
				'order'          => 'ASC',
			)
		);

		$events = array();
		foreach ( $posts as $post ) {
			$event = self::build_admin_event( $post );
			if ( $event ) {
				$events[] = $event;
			}
		}

		if ( ! empty( $events ) ) {
			return $events;
		}

		return self::legacy_events_as_admin();
	}

	/**
	 * @param WP_Post $post ru_event.
	 * @return array<string,mixed>|null
	 */
	public static function build_admin_event( $post ) {
		$event_code = get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_EVENT_CODE, true );
		$form_id    = (int) get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_FORMINATOR_FORM_ID, true );
		$status     = get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_EVENT_STATUS, true );
		$page_id    = (int) get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_REGISTRATION_PAGE_ID, true );

		if ( ! $status ) {
			$status = 'open';
		}

		$thumb = get_the_post_thumbnail_url( $post->ID, 'thumbnail' );
		if ( ! $thumb && $page_id ) {
			$thumb = get_the_post_thumbnail_url( $page_id, 'thumbnail' );
		}

		$page = $page_id ? get_post( $page_id ) : null;
		$counts = self::get_form_entry_counts( $form_id );

		return array(
			'event_id'     => (int) $post->ID,
			'event_code'  => $event_code,
			'title'       => $post->post_title,
			'status'      => $status,
			'form_id'     => $form_id,
			'page_url'    => $page ? get_permalink( $page ) : '',
			'thumb'       => $thumb,
			'edit_url'    => RadioUdaan_Admin_Event_Editor::edit_url( (int) $post->ID ),
			'entries_app' => $counts['app'],
			'entries_web' => $counts['web'],
			'entries_all' => $counts['all'],
		);
	}

	/**
	 * @return array<int,array<string,mixed>>
	 */
	private static function legacy_events_as_admin() {
		$items = array();
		foreach ( RadioUdaan_Event_Registry::list_events( 'all' ) as $event ) {
			$counts = self::get_form_entry_counts( (int) $event['form_id'] );
			$items[] = array_merge(
				$event,
				array(
					'thumb'       => ! empty( $event['banner_image']['url'] ) ? $event['banner_image']['url'] : '',
					'edit_url'    => RadioUdaan_Admin_Event_Editor::edit_url( (int) $event['event_id'] ),
					'entries_app' => $counts['app'],
					'entries_web' => $counts['web'],
					'entries_all' => $counts['all'],
				)
			);
		}
		return $items;
	}

	/**
	 * Forminator form IDs linked to app events.
	 *
	 * @return int[]
	 */
	public static function get_event_form_ids() {
		$ids = array();
		foreach ( self::get_managed_events() as $event ) {
			if ( ! empty( $event['form_id'] ) ) {
				$ids[] = (int) $event['form_id'];
			}
		}
		return array_values( array_unique( array_filter( $ids ) ) );
	}

	/**
	 * @param int $form_id Forminator form ID.
	 * @return array{app:int,web:int,all:int}
	 */
	public static function get_form_entry_counts( $form_id ) {
		$form_id = (int) $form_id;
		if ( $form_id <= 0 ) {
			return array( 'app' => 0, 'web' => 0, 'all' => 0 );
		}

		$all = 0;
		if ( class_exists( 'Forminator_Form_Entry_Model' ) ) {
			$all = (int) Forminator_Form_Entry_Model::count_entries( $form_id );
		}

		return array(
			'app' => self::count_entries_by_source_for_form( $form_id, RadioUdaan_Entry_Source::SOURCE_APP ),
			'web' => self::count_entries_by_source_for_form( $form_id, RadioUdaan_Entry_Source::SOURCE_WEB ),
			'all' => $all,
		);
	}

	/**
	 * @param int    $form_id Form ID.
	 * @param string $source  app|web.
	 * @return int
	 */
	public static function count_entries_by_source_for_form( $form_id, $source ) {
		global $wpdb;

		$form_id = (int) $form_id;
		if ( $form_id <= 0 ) {
			return 0;
		}

		$entry_table = $wpdb->prefix . 'frmt_form_entry';
		$meta_table  = $wpdb->prefix . 'frmt_form_entry_meta';

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$count = $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(DISTINCT e.entry_id)
				FROM {$entry_table} e
				INNER JOIN {$meta_table} m ON e.entry_id = m.entry_id
				WHERE e.form_id = %d
				AND m.meta_key = %s
				AND m.meta_value = %s",
				$form_id,
				RadioUdaan_Entry_Source::META_KEY,
				$source
			)
		);

		return (int) $count;
	}

	/**
	 * @return int
	 */
	public static function count_app_entries() {
		return self::count_entries_by_source( RadioUdaan_Entry_Source::SOURCE_APP );
	}

	/**
	 * @return int
	 */
	public static function count_web_entries() {
		return self::count_entries_by_source( RadioUdaan_Entry_Source::SOURCE_WEB );
	}

	/**
	 * @param string $source app|web.
	 * @return int
	 */
	public static function count_entries_by_source( $source ) {
		global $wpdb;

		$meta_table = $wpdb->prefix . 'frmt_form_entry_meta';

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$count = $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(DISTINCT entry_id) FROM {$meta_table} WHERE meta_key = %s AND meta_value = %s",
				RadioUdaan_Entry_Source::META_KEY,
				$source
			)
		);

		return (int) $count;
	}

	/**
	 * App users with the most recent login timestamps (for dashboard widget).
	 *
	 * @param int $limit Max rows.
	 * @return array<int,object>
	 */
	public static function get_recent_app_logins( $limit = 5 ) {
		RadioUdaan_App_Users::maybe_create_table();

		global $wpdb;

		$limit = max( 1, min( 20, (int) $limit ) );
		$table = RadioUdaan_App_Users::table_name();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$table} WHERE status != %s AND last_login_at IS NOT NULL ORDER BY last_login_at DESC LIMIT %d",
				RadioUdaan_App_Users::STATUS_DELETED,
				$limit
			)
		);

		return is_array( $rows ) ? $rows : array();
	}

	/**
	 * Recent registrations for admin (mobile + website).
	 *
	 * @param int    $limit   Max rows.
	 * @param string $filter  all|app|web.
	 * @param int    $form_id Optional Forminator form ID filter.
	 * @return array<int,array<string,mixed>>
	 */
	public static function get_recent_registrations( $limit = 25, $filter = 'all', $form_id = 0 ) {
		global $wpdb;

		$limit    = max( 1, min( 5000, (int) $limit ) );
		$filter   = in_array( $filter, array( 'all', 'app', 'web' ), true ) ? $filter : 'all';
		$form_id  = (int) $form_id;
		$form_ids = self::get_event_form_ids();

		if ( empty( $form_ids ) ) {
			return array();
		}

		if ( $form_id > 0 ) {
			if ( ! in_array( $form_id, $form_ids, true ) ) {
				return array();
			}
			$form_ids = array( $form_id );
		}

		$entry_table = $wpdb->prefix . 'frmt_form_entry';
		$meta_table  = $wpdb->prefix . 'frmt_form_entry_meta';
		$placeholders = implode( ',', array_fill( 0, count( $form_ids ), '%d' ) );

		$source_sql = '';
		$extra_args = array();
		if ( 'app' === $filter || 'web' === $filter ) {
			$source_sql  = "INNER JOIN {$meta_table} src_filter ON e.entry_id = src_filter.entry_id
				AND src_filter.meta_key = %s AND src_filter.meta_value = %s";
			$extra_args[] = RadioUdaan_Entry_Source::META_KEY;
			$extra_args[] = $filter;
		}

		$sql = "SELECT e.entry_id, e.form_id, e.date_created,
				MAX(CASE WHEN m.meta_key = %s THEN m.meta_value END) AS source,
				MAX(CASE WHEN m.meta_key = '_radioudaan_phone_e164' THEN m.meta_value END) AS phone,
				MAX(CASE WHEN m.meta_key = '_radioudaan_event_code' THEN m.meta_value END) AS event_code
			FROM {$entry_table} e
			{$source_sql}
			LEFT JOIN {$meta_table} m ON e.entry_id = m.entry_id
			WHERE e.form_id IN ({$placeholders})
			GROUP BY e.entry_id, e.form_id, e.date_created
			ORDER BY e.date_created DESC
			LIMIT %d";

		$prepare_args = array_merge(
			array( RadioUdaan_Entry_Source::META_KEY ),
			$extra_args,
			$form_ids,
			array( $limit )
		);

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching, WordPress.DB.PreparedSQL.NotPrepared
		$rows = $wpdb->get_results( $wpdb->prepare( $sql, $prepare_args ), ARRAY_A );

		if ( ! is_array( $rows ) ) {
			return array();
		}

		$events_by_code = array();
		foreach ( self::get_managed_events() as $ev ) {
			if ( ! empty( $ev['event_code'] ) ) {
				$events_by_code[ $ev['event_code'] ] = $ev['title'];
			}
		}

		$items = array();
		foreach ( $rows as $row ) {
			$form_id  = (int) $row['form_id'];
			$entry_id = (int) $row['entry_id'];
			$code     = isset( $row['event_code'] ) ? (string) $row['event_code'] : '';
			$title    = isset( $events_by_code[ $code ] ) ? $events_by_code[ $code ] : __( 'Event', 'radioudaan-app-api' );
			$source   = isset( $row['source'] ) ? (string) $row['source'] : '';

			$items[] = array(
				'entry_id'    => $entry_id,
				'form_id'     => $form_id,
				'event_code'  => $code,
				'event_title' => $title,
				'phone'       => isset( $row['phone'] ) && $row['phone'] ? (string) $row['phone'] : '—',
				'date'        => $row['date_created'],
				'source'      => $source,
				'source_label'=> RadioUdaan_Entry_Source::label_for( $source ),
				'view_url'    => RadioUdaan_Admin_Entry_Viewer::view_url( $entry_id, $form_id ),
			);
		}

		return $items;
	}

	/**
	 * Event form entries matching an app user's phone (E.164).
	 *
	 * @param string $phone_e164 Phone number.
	 * @param int    $limit      Max rows.
	 * @return array<int,array<string,mixed>>
	 */
	public static function get_entries_for_phone( $phone_e164, $limit = 25 ) {
		$phone = preg_replace( '/\s+/', '', (string) $phone_e164 );
		if ( '' === $phone ) {
			return array();
		}

		global $wpdb;

		$limit    = max( 1, min( 100, (int) $limit ) );
		$form_ids = self::get_event_form_ids();
		if ( empty( $form_ids ) ) {
			return array();
		}

		$entry_table  = $wpdb->prefix . 'frmt_form_entry';
		$meta_table   = $wpdb->prefix . 'frmt_form_entry_meta';
		$placeholders = implode( ',', array_fill( 0, count( $form_ids ), '%d' ) );

		$sql = "SELECT e.entry_id, e.form_id, e.date_created,
				MAX(CASE WHEN m.meta_key = %s THEN m.meta_value END) AS source,
				MAX(CASE WHEN m.meta_key = '_radioudaan_event_code' THEN m.meta_value END) AS event_code
			FROM {$entry_table} e
			INNER JOIN {$meta_table} phone_meta ON e.entry_id = phone_meta.entry_id
				AND phone_meta.meta_key = %s AND phone_meta.meta_value = %s
			LEFT JOIN {$meta_table} m ON e.entry_id = m.entry_id
			WHERE e.form_id IN ({$placeholders})
			GROUP BY e.entry_id, e.form_id, e.date_created
			ORDER BY e.date_created DESC
			LIMIT %d";

		$prepare_args = array_merge(
			array( RadioUdaan_Entry_Source::META_KEY, '_radioudaan_phone_e164', $phone ),
			$form_ids,
			array( $limit )
		);

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching, WordPress.DB.PreparedSQL.NotPrepared
		$rows = $wpdb->get_results( $wpdb->prepare( $sql, $prepare_args ), ARRAY_A );
		if ( ! is_array( $rows ) ) {
			return array();
		}

		$events_by_code = array();
		foreach ( self::get_managed_events() as $ev ) {
			if ( ! empty( $ev['event_code'] ) ) {
				$events_by_code[ $ev['event_code'] ] = $ev['title'];
			}
		}

		$items = array();
		foreach ( $rows as $row ) {
			$form_id  = (int) $row['form_id'];
			$entry_id = (int) $row['entry_id'];
			$code     = isset( $row['event_code'] ) ? (string) $row['event_code'] : '';
			$title    = isset( $events_by_code[ $code ] ) ? $events_by_code[ $code ] : __( 'Event', 'radioudaan-app-api' );
			$source   = isset( $row['source'] ) ? (string) $row['source'] : '';

			$items[] = array(
				'entry_id'     => $entry_id,
				'form_id'      => $form_id,
				'event_code'   => $code,
				'event_title'  => $title,
				'date'         => $row['date_created'],
				'source'       => $source,
				'source_label' => RadioUdaan_Entry_Source::label_for( $source ),
				'view_url'     => RadioUdaan_Admin_Entry_Viewer::view_url( $entry_id, $form_id ),
			);
		}

		return $items;
	}

	/**
	 * @deprecated Use get_recent_registrations().
	 * @param int $limit Max rows.
	 * @return array<int,array<string,mixed>>
	 */
	public static function get_recent_app_registrations( $limit = 25 ) {
		return self::get_recent_registrations( $limit, 'app' );
	}

	/**
	 * @return array{ok:bool,version:string,error:string}
	 */
	public static function fetch_health() {
		$url = RadioUdaan_App_Settings::get_api_base_url() . '/health';

		$response = wp_remote_get(
			$url,
			array(
				'timeout'   => 8,
				'sslverify' => false,
			)
		);

		if ( is_wp_error( $response ) ) {
			return array(
				'ok'      => false,
				'version' => '',
				'error'   => $response->get_error_message(),
			);
		}

		$code = wp_remote_retrieve_response_code( $response );
		$body = json_decode( wp_remote_retrieve_body( $response ), true );

		if ( 200 !== (int) $code || empty( $body['status'] ) ) {
			return array(
				'ok'      => false,
				'version' => '',
				'error'   => 'HTTP ' . $code,
			);
		}

		return array(
			'ok'      => true,
			'version' => isset( $body['version'] ) ? (string) $body['version'] : '',
			'error'   => '',
		);
	}

	/**
	 * @param int $form_id Form ID.
	 * @return string
	 */
	public static function forminator_form_url( $form_id ) {
		if ( ! $form_id ) {
			return '';
		}
		return admin_url( 'admin.php?page=forminator-cform-wizard&id=' . (int) $form_id );
	}

	/**
	 * @param int $form_id Form ID.
	 * @return string
	 */
	public static function forminator_entries_url( $form_id ) {
		if ( ! $form_id ) {
			return '';
		}
		return admin_url( 'admin.php?page=forminator-entries&form_id=' . (int) $form_id );
	}

	/**
	 * Next menu_order slot for a new ru_event post.
	 *
	 * @return int
	 */
	public static function get_next_event_menu_order() {
		global $wpdb;

		$max = (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT MAX(menu_order) FROM {$wpdb->posts} WHERE post_type = %s",
				RadioUdaan_Cpt_Ru_Event::POST_TYPE
			)
		);

		return $max + 1;
	}

	/**
	 * AJAX: persist drag-and-drop order for the Events admin list.
	 */
	public static function ajax_save_event_order() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_send_json_error(
				array( 'message' => __( 'Insufficient permissions.', 'radioudaan-app-api' ) ),
				403
			);
		}

		check_ajax_referer( 'radioudaan_events_order', 'nonce' );

		$order = isset( $_POST['order'] ) ? wp_unslash( $_POST['order'] ) : array();
		if ( ! is_array( $order ) ) {
			wp_send_json_error(
				array( 'message' => __( 'Invalid order payload.', 'radioudaan-app-api' ) ),
				400
			);
		}

		$position = 0;
		foreach ( $order as $raw_id ) {
			$event_id = (int) $raw_id;
			if ( $event_id <= 0 ) {
				continue;
			}

			$post = get_post( $event_id );
			if ( ! $post || RadioUdaan_Cpt_Ru_Event::POST_TYPE !== $post->post_type ) {
				continue;
			}

			wp_update_post(
				array(
					'ID'         => $event_id,
					'menu_order' => $position,
				)
			);
			++$position;
		}

		wp_send_json_success(
			array(
				'message' => __( 'Event order saved.', 'radioudaan-app-api' ),
				'count'   => $position,
			)
		);
	}

	/**
	 * Deep-link to a Settings tab.
	 *
	 * @param string $tab Tab slug (matches data-tab on settings page).
	 * @return string
	 */
	public static function settings_tab_url( $tab ) {
		return add_query_arg(
			array(
				'page' => RadioUdaan_Admin_App_Hub::SETTINGS_SLUG,
				'tab'  => sanitize_key( (string) $tab ),
			),
			admin_url( 'admin.php' )
		);
	}

	/**
	 * Pre-launch checklist for the dashboard widget.
	 *
	 * @return array<int,array{id:string,label:string,ok:bool,detail:string,url:string}>
	 */
	public static function get_setup_checklist() {
		$health      = self::fetch_health();
		$copy_count  = count( RadioUdaan_App_Branding::get_public_copy() );
		$stats       = self::get_dashboard_stats();
		$fcm_raw     = RadioUdaan_App_Settings::get_fcm_service_account_json();
		$fcm_parsed  = class_exists( 'RadioUdaan_App_Fcm_Sender' )
			? RadioUdaan_App_Fcm_Sender::parse_service_account_json( $fcm_raw )
			: null;
		$msg91_ok    = class_exists( 'RadioUdaan_Otp_Msg91' ) && RadioUdaan_Otp_Msg91::is_configured();
		$privacy_url = RadioUdaan_App_Settings::get_privacy_policy_url();
		$privacy_ok  = '' !== $privacy_url && 0 === strpos( strtolower( $privacy_url ), 'https://' );
		$on_prod     = RadioUdaan_App_Settings::dev_bypass_is_locked();
		$dev_active  = RadioUdaan_App_Settings::is_dev_otp_enabled() || RadioUdaan_App_Settings::is_dev_auth_enabled();
		$dev_ok      = ! ( $on_prod && $dev_active );
		$events_ok   = (int) ( $stats['events_open_in_app'] ?? 0 ) > 0;

		return array(
			array(
				'id'     => 'fcm',
				'label'  => __( 'FCM service account JSON', 'radioudaan-app-api' ),
				'ok'     => null !== $fcm_parsed,
				'detail' => null !== $fcm_parsed
					? __( 'JSON parses as a Firebase service account.', 'radioudaan-app-api' )
					: __( 'Paste valid Firebase service account JSON.', 'radioudaan-app-api' ),
				'url'    => self::settings_tab_url( 'notifications' ),
			),
			array(
				'id'     => 'msg91',
				'label'  => __( 'MSG91 SMS', 'radioudaan-app-api' ),
				'ok'     => $msg91_ok,
				'detail' => $msg91_ok
					? __( 'Auth key, sender ID, and template are set.', 'radioudaan-app-api' )
					: __( 'Configure MSG91 for production OTP SMS.', 'radioudaan-app-api' ),
				'url'    => self::settings_tab_url( 'sms' ),
			),
			array(
				'id'     => 'api_health',
				'label'  => __( 'API health', 'radioudaan-app-api' ),
				'ok'     => ! empty( $health['ok'] ),
				'detail' => ! empty( $health['ok'] )
					? sprintf(
						/* translators: %s: API version */
						__( 'GET /health OK (v%s).', 'radioudaan-app-api' ),
						$health['version'] ? $health['version'] : '—'
					)
					: ( ! empty( $health['error'] )
						? (string) $health['error']
						: __( 'Could not reach GET /health.', 'radioudaan-app-api' ) ),
				'url'    => self::settings_tab_url( 'connection' ),
			),
			array(
				'id'     => 'copy_catalog',
				'label'  => __( 'Copy catalog', 'radioudaan-app-api' ),
				'ok'     => $copy_count >= 300,
				'detail' => sprintf(
					/* translators: %d: number of copy keys */
					__( '%d keys in GET /config → copy (need ≥300).', 'radioudaan-app-api' ),
					$copy_count
				),
				'url'    => self::settings_tab_url( 'copy' ),
			),
			array(
				'id'     => 'dev_flags',
				'label'  => __( 'Dev flags on production', 'radioudaan-app-api' ),
				'ok'     => $dev_ok,
				'detail' => $dev_ok
					? ( $on_prod
						? __( 'No dev OTP or skip-auth on this production host.', 'radioudaan-app-api' )
						: __( 'Dev bypass flags are off or host is non-production.', 'radioudaan-app-api' ) )
					: __( 'Disable fixed OTP and skip-auth before release.', 'radioudaan-app-api' ),
				'url'    => self::settings_tab_url( 'security' ),
			),
			array(
				'id'     => 'privacy_url',
				'label'  => __( 'Privacy policy URL', 'radioudaan-app-api' ),
				'ok'     => $privacy_ok,
				'detail' => $privacy_ok
					? __( 'HTTPS privacy URL is set for stores and the app.', 'radioudaan-app-api' )
					: __( 'Set an HTTPS privacy policy URL before release.', 'radioudaan-app-api' ),
				'url'    => self::settings_tab_url( 'legal' ),
			),
			array(
				'id'     => 'events_ready',
				'label'  => __( 'Events ready in app', 'radioudaan-app-api' ),
				'ok'     => $events_ok,
				'detail' => $events_ok
					? sprintf(
						/* translators: %d: open events visible in app */
						__( '%d open event(s) with form + code in the app.', 'radioudaan-app-api' ),
						(int) ( $stats['events_open_in_app'] ?? 0 )
					)
					: __( 'Add an open event with event code and Forminator form.', 'radioudaan-app-api' ),
				'url'    => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENTS_SLUG ),
			),
		);
	}
}

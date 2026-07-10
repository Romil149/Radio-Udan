<?php
/**
 * CSV export for event entries.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Admin CSV export handler.
 */
class RadioUdaan_Admin_Export {

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'admin_post_radioudaan_export_entries', array( __CLASS__, 'handle_export' ) );
		add_action( 'admin_post_radioudaan_export_app_users', array( __CLASS__, 'handle_export_app_users' ) );
	}

	/**
	 * Stream CSV download.
	 */
	public static function handle_export() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( 'radioudaan_export_entries' );

		$filter = isset( $_GET['source'] ) ? sanitize_key( wp_unslash( $_GET['source'] ) ) : 'all';
		if ( ! in_array( $filter, array( 'all', 'app', 'web' ), true ) ) {
			$filter = 'all';
		}

		$event_form = isset( $_GET['event_form'] ) ? (int) $_GET['event_form'] : 0;

		$rows = RadioUdaan_Admin_Data::get_recent_registrations( 5000, $filter, $event_form );

		$filename = 'radio-udaan-entries-' . gmdate( 'Y-m-d' ) . '.csv';

		header( 'Content-Type: text/csv; charset=utf-8' );
		header( 'Content-Disposition: attachment; filename=' . $filename );
		header( 'Pragma: no-cache' );

		$out = fopen( 'php://output', 'w' );
		if ( false === $out ) {
			wp_die( esc_html__( 'Could not create export.', 'radioudaan-app-api' ) );
		}

		fputcsv(
			$out,
			array(
				'entry_id',
				'date',
				'event',
				'source',
				'phone',
				'view_url',
			)
		);

		foreach ( $rows as $row ) {
			$view_url = '';
			if ( ! empty( $row['entry_id'] ) && ! empty( $row['form_id'] ) ) {
				$view_url = RadioUdaan_Admin_Entry_Viewer::view_url( (int) $row['entry_id'], (int) $row['form_id'] );
			}

			fputcsv(
				$out,
				array(
					$row['entry_id'] ?? '',
					$row['date'] ?? '',
					$row['event_title'] ?? '',
					$row['source_label'] ?? '',
					$row['phone'] ?? '',
					$view_url,
				)
			);
		}

		fclose( $out );
		exit;
	}

	/**
	 * @param string $filter     all|app|web.
	 * @param int    $event_form Form id filter.
	 * @return string
	 */
	public static function export_url( $filter = 'all', $event_form = 0 ) {
		$args = array(
			'action'   => 'radioudaan_export_entries',
			'_wpnonce' => wp_create_nonce( 'radioudaan_export_entries' ),
			'source'   => $filter,
		);
		if ( $event_form > 0 ) {
			$args['event_form'] = $event_form;
		}
		return add_query_arg( $args, admin_url( 'admin-post.php' ) );
	}

	/**
	 * Stream app users CSV download.
	 */
	public static function handle_export_app_users() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( 'radioudaan_export_app_users' );

		$status = isset( $_GET['status'] ) ? sanitize_key( wp_unslash( $_GET['status'] ) ) : '';
		$search = isset( $_GET['s'] ) ? trim( sanitize_text_field( wp_unslash( $_GET['s'] ) ) ) : '';

		self::export_app_users_csv( $status, $search );
	}

	/**
	 * @param string $status Status filter.
	 * @param string $search Search term.
	 */
	public static function export_app_users_csv( $status = '', $search = '' ) {
		$result = RadioUdaan_App_Users::list_users_paginated(
			array(
				'page'     => 1,
				'per_page' => 5000,
				'status'   => $status,
				'search'   => $search,
			)
		);

		$filename = 'radio-udaan-app-users-' . gmdate( 'Y-m-d' ) . '.csv';

		header( 'Content-Type: text/csv; charset=utf-8' );
		header( 'Content-Disposition: attachment; filename=' . $filename );
		header( 'Pragma: no-cache' );

		$out = fopen( 'php://output', 'w' );
		if ( false === $out ) {
			wp_die( esc_html__( 'Could not create export.', 'radioudaan-app-api' ) );
		}

		fputcsv(
			$out,
			array(
				'user_id',
				'display_name',
				'email',
				'phone_masked',
				'status',
				'phone_verified',
				'email_verified',
				'login_count',
				'first_login_at',
				'last_login_at',
				'created_at',
				'view_url',
			)
		);

		foreach ( $result['items'] as $user ) {
			fputcsv(
				$out,
				array(
					(int) $user->id,
					$user->display_name,
					$user->email,
					RadioUdaan_Admin_App_Users::mask_phone( $user->phone_e164 ),
					$user->status,
					! empty( $user->phone_verified ) ? 'yes' : 'no',
					! empty( $user->email_verified ) ? 'yes' : 'no',
					(int) $user->login_count,
					$user->first_login_at,
					$user->last_login_at,
					$user->created_at,
					RadioUdaan_Admin_App_User_Detail::view_url( (int) $user->id ),
				)
			);
		}

		fclose( $out );
		exit;
	}

	/**
	 * @param string $status Status filter.
	 * @param string $search Search term.
	 * @return string
	 */
	public static function export_app_users_url( $status = '', $search = '' ) {
		$args = array(
			'action'   => 'radioudaan_export_app_users',
			'_wpnonce' => wp_create_nonce( 'radioudaan_export_app_users' ),
		);
		if ( '' !== $status ) {
			$args['status'] = sanitize_key( $status );
		}
		if ( '' !== $search ) {
			$args['s'] = $search;
		}
		return add_query_arg( $args, admin_url( 'admin-post.php' ) );
	}
}

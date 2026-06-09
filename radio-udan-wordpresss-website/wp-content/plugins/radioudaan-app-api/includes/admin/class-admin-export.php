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

		$rows = RadioUdaan_Admin_Data::get_recent_registrations( 5000, $filter );

		if ( $event_form > 0 ) {
			$rows = array_values(
				array_filter(
					$rows,
					static function ( $row ) use ( $event_form ) {
						return isset( $row['form_id'] ) && (int) $row['form_id'] === $event_form;
					}
				)
			);
		}

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
}

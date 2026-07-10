<?php
/**
 * Global header search redirect for app admin.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Redirects layout search to App users or Events list.
 */
class RadioUdaan_Admin_Global_Search {

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'admin_init', array( __CLASS__, 'maybe_redirect' ) );
	}

	/**
	 * Handle ?ru_global_search= query on any plugin admin screen.
	 */
	public static function maybe_redirect() {
		if ( ! is_admin() || ! current_user_can( 'manage_options' ) ) {
			return;
		}

		$query = isset( $_GET['ru_global_search'] ) ? trim( sanitize_text_field( wp_unslash( $_GET['ru_global_search'] ) ) ) : '';
		if ( '' === $query ) {
			return;
		}

		$page = isset( $_GET['page'] ) ? sanitize_key( wp_unslash( $_GET['page'] ) ) : '';
		if ( '' === $page || false === strpos( $page, 'radioudaan' ) ) {
			return;
		}

		$users = RadioUdaan_App_Users::list_users_paginated(
			array(
				'search'   => $query,
				'per_page' => 5,
				'page'     => 1,
			)
		);

		if ( 1 === (int) $users['total'] && ! empty( $users['items'][0] ) ) {
			wp_safe_redirect( RadioUdaan_Admin_App_User_Detail::view_url( (int) $users['items'][0]->id ) );
			exit;
		}

		if ( (int) $users['total'] > 0 ) {
			wp_safe_redirect(
				add_query_arg(
					array(
						'page' => RadioUdaan_Admin_App_Hub::APP_USERS_SLUG,
						's'    => rawurlencode( $query ),
					),
					admin_url( 'admin.php' )
				)
			);
			exit;
		}

		$event_match = self::find_event_by_title( $query );
		if ( $event_match ) {
			wp_safe_redirect( RadioUdaan_Admin_Event_Editor::edit_url( (int) $event_match['event_id'] ) );
			exit;
		}

		wp_safe_redirect(
			add_query_arg(
				array(
					'page'   => RadioUdaan_Admin_App_Hub::EVENTS_SLUG,
					'search' => rawurlencode( $query ),
				),
				admin_url( 'admin.php' )
			)
		);
		exit;
	}

	/**
	 * @param string $query Search term.
	 * @return array<string,mixed>|null
	 */
	private static function find_event_by_title( $query ) {
		$query_lower = strtolower( $query );
		foreach ( RadioUdaan_Admin_Data::get_managed_events() as $event ) {
			$title = isset( $event['title'] ) ? strtolower( (string) $event['title'] ) : '';
			if ( '' !== $title && false !== strpos( $title, $query_lower ) ) {
				return $event;
			}
		}
		return null;
	}
}

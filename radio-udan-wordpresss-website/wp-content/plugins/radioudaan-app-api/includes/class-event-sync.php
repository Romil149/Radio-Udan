<?php
/**
 * Sync code registry → ru_event CPT posts (live DB).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Creates/updates ru_event posts from built-in definitions.
 */
class RadioUdaan_Event_Sync {

	/**
	 * Register admin hook.
	 */
	public static function init() {
		add_action( 'admin_post_radioudaan_sync_ru_events', array( __CLASS__, 'handle_admin_sync' ) );
	}

	/**
	 * Sync all definitions; return map event_code => ru_event post ID.
	 *
	 * @return array<string,int>
	 */
	public static function sync_all() {
		$map = array();

		foreach ( RadioUdaan_Event_Registry::get_definitions() as $event_code => $def ) {
			$post_id = self::sync_one( $event_code, $def );
			if ( $post_id ) {
				$map[ $event_code ] = $post_id;
			}
		}

		return $map;
	}

	/**
	 * @param string $event_code Event code.
	 * @param array  $def        Definition.
	 * @return int Post ID or 0.
	 */
	public static function sync_one( $event_code, $def ) {
		$existing = self::find_by_event_code( $event_code );
		$page_id  = (int) $def['page_id'];
		$page     = get_post( $page_id );
		$form_id  = RadioUdaan_Event_Registry::get_forminator_id( $event_code );

		if ( $form_id <= 0 ) {
			return 0;
		}

		$title = $page ? get_the_title( $page ) : $def['label'];
		if ( ! $title || ( $page && $title === $page->post_name ) ) {
			$title = $def['label'];
		}

		$postarr = array(
			'post_type'    => RadioUdaan_Cpt_Ru_Event::POST_TYPE,
			'post_title'   => $title,
			'post_content' => $page ? $page->post_content : '',
			'post_status'  => 'publish',
		);

		if ( $existing ) {
			$postarr['ID'] = $existing;
			$post_id       = wp_update_post( $postarr, true );
		} else {
			$post_id = wp_insert_post( $postarr, true );
		}

		if ( is_wp_error( $post_id ) || ! $post_id ) {
			return 0;
		}

		update_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_CODE, $event_code );
		update_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_REGISTRATION_PAGE_ID, $page_id );
		update_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_FORMINATOR_FORM_ID, $form_id );
		update_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_STATUS, 'open' );

		$success = __( 'Thank you. Your registration was received.', 'radioudaan-app-api' );
		update_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_SUCCESS_MESSAGE, $success );

		if ( $page && has_post_thumbnail( $page_id ) ) {
			$thumb_id = get_post_thumbnail_id( $page_id );
			if ( $thumb_id ) {
				set_post_thumbnail( $post_id, $thumb_id );
			}
		}

		return (int) $post_id;
	}

	/**
	 * @param string $event_code Event code.
	 * @return int
	 */
	public static function find_by_event_code( $event_code ) {
		$posts = get_posts(
			array(
				'post_type'      => RadioUdaan_Cpt_Ru_Event::POST_TYPE,
				'post_status'    => 'any',
				'posts_per_page' => 1,
				'meta_key'       => RadioUdaan_Cpt_Ru_Event::META_EVENT_CODE,
				'meta_value'     => $event_code,
				'fields'         => 'ids',
			)
		);

		return ! empty( $posts[0] ) ? (int) $posts[0] : 0;
	}

	/**
	 * Admin sync handler.
	 */
	public static function handle_admin_sync() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( 'radioudaan_sync_ru_events' );

		$map = self::sync_all();

		$args = array(
			'page'              => RadioUdaan_Admin_App_Hub::EVENTS_SLUG,
			'radioudaan_notice' => 'success',
			'radioudaan_detail' => rawurlencode(
				sprintf(
					/* translators: %d: number of events */
					__( 'Synced %d app events to ru_event CPT.', 'radioudaan-app-api' ),
					count( $map )
				)
			),
		);

		wp_safe_redirect( add_query_arg( $args, admin_url( 'admin.php' ) ) );
		exit;
	}
}

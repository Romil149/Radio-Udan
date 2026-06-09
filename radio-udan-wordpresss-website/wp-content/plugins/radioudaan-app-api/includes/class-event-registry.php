<?php
/**
 * App-visible events (ru_event CPT + legacy registry fallback).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Event registry for REST API.
 */
class RadioUdaan_Event_Registry {

	const WHATSAPP_COMMUNITY_URL = 'https://chat.whatsapp.com/BYOPTP8rLR3H53vlrnHSmF?mode=gi_t';

	/**
	 * Legacy built-in definitions (used for migration sync and fallback).
	 *
	 * @return array<string,array{label:string,cf7_id:int,page_id:int,whatsapp_url?:string}>
	 */
	public static function get_definitions() {
		return array(
			'registration-udaan-idol' => array(
				'label'        => 'Udaan Idol Season 5',
				'cf7_id'       => 855,
				'page_id'      => 825,
				'whatsapp_url' => self::WHATSAPP_COMMUNITY_URL,
			),
			'one-minute-matters-2026' => array(
				'label'        => 'One Minute Matters 2026',
				'cf7_id'       => 1125,
				'page_id'      => 1116,
				'whatsapp_url' => self::WHATSAPP_COMMUNITY_URL,
			),
			'become-rj' => array(
				'label'   => 'Become an RJ',
				'cf7_id'  => 1177,
				'page_id' => 1178,
			),
		);
	}

	/**
	 * Resolve Forminator form ID for an event (option override, else 0).
	 *
	 * @param string $event_code Event code.
	 * @return int
	 */
	public static function get_forminator_id( $event_code ) {
		return (int) get_option( 'radioudaan_forminator_' . $event_code, 0 );
	}

	/**
	 * @param string $status_filter open|all.
	 * @return array<int,array<string,mixed>>
	 */
	public static function list_events( $status_filter = 'open' ) {
		$cpt_items = self::list_from_cpt( $status_filter );
		if ( ! empty( $cpt_items ) ) {
			return $cpt_items;
		}

		return self::list_from_definitions( $status_filter );
	}

	/**
	 * @param int $event_id ru_event post ID, or legacy registration page ID.
	 * @return array<string,mixed>|null
	 */
	public static function get_event( $event_id ) {
		$from_cpt = self::get_event_from_cpt( (int) $event_id, true );
		if ( $from_cpt ) {
			return $from_cpt;
		}

		return self::get_event_by_page_id( (int) $event_id, true );
	}

	/**
	 * @param int $page_id Registration page ID.
	 * @return array<string,mixed>|null
	 */
	public static function get_event_by_page_id( $page_id, $detailed = false ) {
		$cpt = self::find_cpt_by_page_id( $page_id );
		if ( $cpt ) {
			return self::build_event_from_cpt( $cpt, $detailed );
		}

		foreach ( self::get_definitions() as $event_code => $def ) {
			if ( (int) $def['page_id'] === (int) $page_id ) {
				return self::build_event_legacy( $event_code, $def, $detailed );
			}
		}

		return null;
	}

	/**
	 * @param string $status_filter open|all.
	 * @return array<int,array<string,mixed>>
	 */
	private static function list_from_cpt( $status_filter ) {
		$posts = get_posts(
			array(
				'post_type'      => RadioUdaan_Cpt_Ru_Event::POST_TYPE,
				'post_status'    => 'publish',
				'posts_per_page' => 50,
				'orderby'        => 'menu_order title',
				'order'          => 'ASC',
			)
		);

		$items = array();
		foreach ( $posts as $post ) {
			$event = self::build_event_from_cpt( $post, false );
			if ( ! $event ) {
				continue;
			}
			if ( 'open' === $status_filter && 'open' !== $event['status'] ) {
				continue;
			}
			if ( 'open' === $status_filter && 'draft' === get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_EVENT_STATUS, true ) ) {
				continue;
			}
			$items[] = $event;
		}

		return $items;
	}

	/**
	 * @param string $status_filter open|all.
	 * @return array<int,array<string,mixed>>
	 */
	private static function list_from_definitions( $status_filter ) {
		unset( $status_filter );

		$items = array();
		foreach ( self::get_definitions() as $event_code => $def ) {
			$event = self::build_event_legacy( $event_code, $def );
			if ( $event ) {
				$items[] = $event;
			}
		}

		return $items;
	}

	/**
	 * @param int  $post_id  ru_event ID.
	 * @param bool $detailed Include description.
	 * @return array<string,mixed>|null
	 */
	private static function get_event_from_cpt( $post_id, $detailed = false ) {
		$post = get_post( $post_id );
		if ( ! $post || RadioUdaan_Cpt_Ru_Event::POST_TYPE !== $post->post_type ) {
			return null;
		}

		return self::build_event_from_cpt( $post, $detailed );
	}

	/**
	 * @param int $page_id Page ID.
	 * @return WP_Post|null
	 */
	private static function find_cpt_by_page_id( $page_id ) {
		$posts = get_posts(
			array(
				'post_type'      => RadioUdaan_Cpt_Ru_Event::POST_TYPE,
				'post_status'    => 'publish',
				'posts_per_page' => 1,
				'meta_key'       => RadioUdaan_Cpt_Ru_Event::META_REGISTRATION_PAGE_ID,
				'meta_value'     => (int) $page_id,
			)
		);

		return ! empty( $posts[0] ) ? $posts[0] : null;
	}

	/**
	 * @param WP_Post $post     ru_event post.
	 * @param bool    $detailed Include description.
	 * @return array<string,mixed>|null
	 */
	private static function build_event_from_cpt( $post, $detailed = false ) {
		$event_code = get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_EVENT_CODE, true );
		$page_id    = (int) get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_REGISTRATION_PAGE_ID, true );
		$form_id    = (int) get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_FORMINATOR_FORM_ID, true );
		$status     = get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_EVENT_STATUS, true );

		if ( ! $event_code || $form_id <= 0 ) {
			return null;
		}

		if ( ! $status ) {
			$status = 'open';
		}

		if ( 'draft' === $status ) {
			return null;
		}

		$page = $page_id ? get_post( $page_id ) : null;
		$thumb = get_the_post_thumbnail_url( $post->ID, 'large' );
		if ( ! $thumb && $page_id ) {
			$thumb = get_the_post_thumbnail_url( $page_id, 'large' );
		}

		$title      = $post->post_title;
		$event_type = self::normalize_event_type(
			get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_EVENT_TYPE, true )
		);
		$start_at   = self::normalize_datetime(
			get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_EVENT_START_AT, true )
		);

		$event = array(
			'event_id'              => (int) $post->ID,
			'event_code'            => $event_code,
			'title'                 => $title,
			'status'                => $status,
			'summary'               => self::build_event_summary( $post, $page ),
			'event_type'            => $event_type,
			'event_type_label'      => self::event_type_label( $event_type ),
			'start_at'              => $start_at,
			'end_at'                => null,
			'banner_image'          => $thumb
				? array(
					'url' => $thumb,
					'alt' => $title,
				)
				: null,
			'form_id'               => $form_id,
			'registration_page_id'  => $page_id ? $page_id : null,
			'page_url'              => $page ? get_permalink( $page ) : null,
			'updated_at'            => gmdate( 'c', strtotime( $post->post_modified_gmt ? $post->post_modified_gmt : $post->post_modified ) ),
		);

		if ( $detailed ) {
			$content = $post->post_content;
			if ( ! trim( wp_strip_all_tags( $content ) ) && $page ) {
				$content = $page->post_content;
			}
			$event['description_html'] = apply_filters( 'the_content', $content );
			$success                   = get_post_meta( $post->ID, RadioUdaan_Cpt_Ru_Event::META_SUCCESS_MESSAGE, true );
			$event['success_message']  = $success
				? $success
				: __( 'Thank you. Your registration was received.', 'radioudaan-app-api' );
		}

		return $event;
	}

	/**
	 * Legacy: event_id = registration page ID.
	 *
	 * @param string $event_code Event code.
	 * @param array  $def        Definition.
	 * @param bool   $detailed   Include description.
	 * @return array<string,mixed>|null
	 */
	private static function build_event_legacy( $event_code, $def, $detailed = false ) {
		$page_id = (int) $def['page_id'];
		$page    = get_post( $page_id );

		if ( ! $page || 'publish' !== $page->post_status ) {
			return null;
		}

		$form_id = self::get_forminator_id( $event_code );
		if ( $form_id <= 0 ) {
			return null;
		}

		$title = get_the_title( $page );
		if ( ! $title || $title === $page->post_name ) {
			$title = $def['label'];
		}
		$thumb = get_the_post_thumbnail_url( $page_id, 'large' );

		$event = array(
			'event_id'             => $page_id,
			'event_code'           => $event_code,
			'title'                => $title ? $title : $def['label'],
			'status'               => 'open',
			'summary'              => self::build_event_summary( $page, null ),
			'event_type'           => 'other',
			'event_type_label'     => '',
			'start_at'             => null,
			'end_at'               => null,
			'banner_image'         => $thumb
				? array(
					'url' => $thumb,
					'alt' => $title,
				)
				: null,
			'form_id'              => $form_id,
			'registration_page_id' => $page_id,
			'page_url'             => get_permalink( $page_id ),
			'updated_at'           => gmdate( 'c', strtotime( $page->post_modified_gmt ? $page->post_modified_gmt : $page->post_modified ) ),
		);

		if ( $detailed ) {
			$event['description_html'] = apply_filters( 'the_content', $page->post_content );
			$event['success_message']  = __( 'Thank you. Your registration was received.', 'radioudaan-app-api' );
		}

		return $event;
	}

	/**
	 * @param string $raw Raw type slug.
	 * @return string live_stream|workshop|other
	 */
	public static function normalize_event_type( $raw ) {
		$type = sanitize_key( (string) $raw );
		if ( in_array( $type, array( 'live_stream', 'workshop' ), true ) ) {
			return $type;
		}
		return 'other';
	}

	/**
	 * @param string $type Event type slug.
	 * @return string
	 */
	public static function event_type_label( $type ) {
		switch ( self::normalize_event_type( $type ) ) {
			case 'live_stream':
				return __( 'LIVE STREAM', 'radioudaan-app-api' );
			case 'workshop':
				return __( 'WORKSHOP', 'radioudaan-app-api' );
			default:
				return '';
		}
	}

	/**
	 * @param string $raw Datetime string.
	 * @return string|null ISO 8601 or null.
	 */
	public static function normalize_datetime( $raw ) {
		$raw = trim( (string) $raw );
		if ( $raw === '' ) {
			return null;
		}

		$timestamp = strtotime( $raw );
		if ( ! $timestamp ) {
			return null;
		}

		return gmdate( 'c', $timestamp );
	}

	/**
	 * Short plain-text blurb for event cards.
	 *
	 * @param WP_Post      $post Primary post.
	 * @param WP_Post|null $page Optional linked page.
	 * @return string
	 */
	public static function build_event_summary( $post, $page = null ) {
		if ( ! $post ) {
			return '';
		}

		$excerpt = trim( (string) $post->post_excerpt );
		if ( $excerpt !== '' ) {
			return wp_strip_all_tags( $excerpt );
		}

		$content = trim( (string) $post->post_content );
		if ( $content === '' && $page ) {
			$content = trim( (string) $page->post_content );
		}

		$plain = trim( wp_strip_all_tags( $content ) );
		if ( $plain === '' ) {
			return '';
		}

		if ( mb_strlen( $plain ) > 280 ) {
			return mb_substr( $plain, 0, 277 ) . '...';
		}

		return $plain;
	}
}

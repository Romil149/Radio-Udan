<?php
/**
 * Library content for mobile app (radio-shows, whats-new CPTs).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * REST handlers for YouTube/library listings.
 */
class RadioUdaan_App_Library {

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response
	 */
	public static function list_shows( WP_REST_Request $request ) {
		$per_page = min( 50, max( 1, (int) $request->get_param( 'per_page' ) ) );
		$page     = max( 1, (int) $request->get_param( 'page' ) );

		$query = new WP_Query(
			array(
				'post_type'      => 'radio-shows',
				'post_status'    => 'publish',
				'posts_per_page' => $per_page,
				'paged'          => $page,
				'orderby'        => 'title',
				'order'          => 'ASC',
			)
		);

		$items = array();
		foreach ( $query->posts as $post ) {
			$items[] = self::map_show_post( $post );
		}

		return new WP_REST_Response(
			array(
				'items'       => $items,
				'total'       => (int) $query->found_posts,
				'page'        => $page,
				'per_page'    => $per_page,
				'total_pages' => (int) $query->max_num_pages,
			),
			200
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response
	 */
	public static function list_whats_new( WP_REST_Request $request ) {
		$per_page = min( 50, max( 1, (int) $request->get_param( 'per_page' ) ) );
		$page     = max( 1, (int) $request->get_param( 'page' ) );

		$query = new WP_Query(
			array(
				'post_type'      => 'whats-new',
				'post_status'    => 'publish',
				'posts_per_page' => $per_page,
				'paged'          => $page,
				'orderby'        => 'date',
				'order'          => 'DESC',
			)
		);

		$items = array();
		foreach ( $query->posts as $post ) {
			$items[] = self::map_whats_new_post( $post );
		}

		return new WP_REST_Response(
			array(
				'items'       => $items,
				'total'       => (int) $query->found_posts,
				'page'        => $page,
				'per_page'    => $per_page,
				'total_pages' => (int) $query->max_num_pages,
			),
			200
		);
	}

	/**
	 * @param WP_Post $post Post.
	 * @return array<string,mixed>
	 */
	private static function map_show_post( WP_Post $post ) {
		$acf_title = self::acf_string( 'title', $post->ID );
		$title     = $acf_title ? $acf_title : get_the_title( $post );

		return array(
			'id'             => (int) $post->ID,
			'title'          => $title,
			'summary'        => self::summary_text( $post, 'description' ),
			'youtube_url'    => self::acf_youtube_url( $post->ID, array( 'youtube_link', 'program_video', 'video_url' ) ),
			'thumbnail_url'  => self::thumbnail_url( $post->ID ),
			'permalink'      => get_permalink( $post ),
			'published_at'   => get_post_time( 'c', true, $post ),
			'program_category' => self::acf_string( 'program_category', $post->ID ),
			'program_host'     => self::acf_host_names( $post->ID ),
			'broadcast_time'   => self::acf_string( 'broadcast_time', $post->ID ),
			'broadcasting_day' => self::acf_string( 'broadcasting_day', $post->ID ),
		);
	}

	/**
	 * @param WP_Post $post Post.
	 * @return array<string,mixed>
	 */
	private static function map_whats_new_post( WP_Post $post ) {
		$acf_title = self::acf_string( 'title', $post->ID );
		$title     = $acf_title ? $acf_title : get_the_title( $post );

		return array(
			'id'            => (int) $post->ID,
			'title'         => $title,
			'summary'       => self::summary_text( $post, 'body' ),
			'youtube_url'   => self::acf_youtube_url( $post->ID, array( 'youtube_link' ) ),
			'thumbnail_url' => self::thumbnail_url( $post->ID, 'image' ),
			'permalink'     => get_permalink( $post ),
			'published_at'  => get_post_time( 'c', true, $post ),
			'category'      => self::acf_string( 'category', $post->ID ),
		);
	}

	/**
	 * @param int      $post_id Post ID.
	 * @param string[] $keys    ACF field keys to try.
	 * @return string
	 */
	private static function acf_youtube_url( $post_id, $keys ) {
		foreach ( $keys as $key ) {
			if ( ! function_exists( 'get_field' ) ) {
				break;
			}
			$val = get_field( $key, $post_id );
			$url = self::extract_url( $val );
			if ( $url ) {
				return $url;
			}
		}
		return '';
	}

	/**
	 * @param mixed $val ACF value.
	 * @return string
	 */
	private static function extract_url( $val ) {
		if ( is_string( $val ) && filter_var( $val, FILTER_VALIDATE_URL ) ) {
			return esc_url_raw( $val );
		}
		if ( is_array( $val ) && ! empty( $val['url'] ) ) {
			return esc_url_raw( (string) $val['url'] );
		}
		return '';
	}

	/**
	 * @param int    $post_id Post ID.
	 * @param string $field   ACF field.
	 * @return string
	 */
	private static function acf_string( $field, $post_id ) {
		if ( ! function_exists( 'get_field' ) ) {
			return '';
		}
		$val = get_field( $field, $post_id );
		if ( is_array( $val ) || is_object( $val ) ) {
			return '';
		}
		return trim( wp_strip_all_tags( (string) $val ) );
	}

	/**
	 * @param int $post_id Post ID.
	 * @return string
	 */
	private static function acf_host_names( $post_id ) {
		if ( ! function_exists( 'get_field' ) ) {
			return '';
		}
		$hosts = get_field( 'program_host', $post_id );
		return RadioUdaan_Rj_Profile::resolve_program_host_names( $hosts );
	}

	/**
	 * @param WP_Post $post       Post.
	 * @param string  $acf_body   Optional ACF body field key.
	 * @return string
	 */
	private static function summary_text( WP_Post $post, $acf_body = '' ) {
		if ( $acf_body && function_exists( 'get_field' ) ) {
			$body = get_field( $acf_body, $post->ID );
			if ( $body ) {
				return wp_trim_words( wp_strip_all_tags( (string) $body ), 40 );
			}
		}
		if ( $post->post_excerpt ) {
			return wp_trim_words( wp_strip_all_tags( $post->post_excerpt ), 40 );
		}
		return wp_trim_words( wp_strip_all_tags( $post->post_content ), 40 );
	}

	/**
	 * @param int    $post_id   Post ID.
	 * @param string $acf_image Optional ACF image field.
	 * @return string
	 */
	private static function thumbnail_url( $post_id, $acf_image = '' ) {
		if ( $acf_image && function_exists( 'get_field' ) ) {
			$img = get_field( $acf_image, $post_id );
			if ( is_array( $img ) && ! empty( $img['url'] ) ) {
				return esc_url_raw( $img['url'] );
			}
		}
		$url = get_the_post_thumbnail_url( $post_id, 'large' );
		return $url ? esc_url_raw( $url ) : '';
	}
}

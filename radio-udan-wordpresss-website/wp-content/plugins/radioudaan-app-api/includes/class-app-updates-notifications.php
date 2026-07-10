<?php
/**
 * Push + inbox when whats-new or community news posts are first published.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Notifies all device-registered users on new About-tab updates.
 */
class RadioUdaan_App_Updates_Notifications {

	/**
	 * Hook publish transitions for update CPTs.
	 */
	public static function init() {
		add_action( 'transition_post_status', array( __CLASS__, 'on_transition_post_status' ), 10, 3 );
	}

	/**
	 * @param string  $new_status New status.
	 * @param string  $old_status Old status.
	 * @param WP_Post $post       Post.
	 */
	public static function on_transition_post_status( $new_status, $old_status, $post ) {
		if ( 'publish' !== $new_status || 'publish' === $old_status ) {
			return;
		}

		if ( ! $post instanceof WP_Post ) {
			return;
		}

		$allowed = array(
			RadioUdaan_App_Library::CPT_WHATS_NEW,
			RadioUdaan_App_Library::CPT_COMMUNITY_NEWS,
		);
		if ( ! in_array( $post->post_type, $allowed, true ) ) {
			return;
		}

		$app_type = RadioUdaan_App_Library::CPT_COMMUNITY_NEWS === $post->post_type
			? 'latestcommunitynews'
			: 'whats-new';
		$title    = self::post_title( $post );
		$summary  = self::post_summary( $post );
		$body     = wp_trim_words( wp_strip_all_tags( $summary ), 24, '…' );

		$user_ids = RadioUdaan_App_Notifications::user_ids_with_devices();
		if ( empty( $user_ids ) ) {
			return;
		}

		$data = array(
			'route'     => 'whats_new_detail',
			'post_type' => $app_type,
			'post_id'   => (int) $post->ID,
		);

		$result = RadioUdaan_App_Notifications::create_for_users_force_push(
			$user_ids,
			$title,
			$body,
			'whats_new',
			$data
		);

		RadioUdaan_App_Logger::log(
			'whats_new_published_notify',
			array(
				'post_id'   => (int) $post->ID,
				'post_type' => $app_type,
				'created'   => (int) $result['created'],
				'push_sent' => (int) $result['push_sent'],
			)
		);
	}

	/**
	 * @param WP_Post $post Post.
	 * @return string
	 */
	private static function post_title( WP_Post $post ) {
		if ( function_exists( 'get_field' ) ) {
			$acf = get_field( 'title', $post->ID );
			if ( is_string( $acf ) && '' !== trim( $acf ) ) {
				return trim( wp_strip_all_tags( $acf ) );
			}
		}
		return get_the_title( $post );
	}

	/**
	 * @param WP_Post $post Post.
	 * @return string
	 */
	private static function post_summary( WP_Post $post ) {
		if ( function_exists( 'get_field' ) ) {
			$body = get_field( 'body', $post->ID );
			if ( $body ) {
				return wp_strip_all_tags( (string) $body );
			}
		}
		if ( $post->post_excerpt ) {
			return wp_strip_all_tags( $post->post_excerpt );
		}
		return wp_strip_all_tags( $post->post_content );
	}
}

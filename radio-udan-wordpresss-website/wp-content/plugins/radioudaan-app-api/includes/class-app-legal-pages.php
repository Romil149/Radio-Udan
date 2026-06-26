<?php
/**
 * In-app legal/about page bodies from selected WordPress pages (Elementor-aware).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Resolves page HTML for GET /config → legal_pages.
 */
class RadioUdaan_App_Legal_Pages {

	const OPTION_PRIVACY_PAGE_ID = 'radioudaan_legal_privacy_page_id';
	const OPTION_TERMS_PAGE_ID   = 'radioudaan_legal_terms_page_id';
	const OPTION_ABOUT_PAGE_ID   = 'radioudaan_legal_about_page_id';

	/**
	 * @return int
	 */
	public static function get_privacy_page_id() {
		return self::resolve_page_id(
			self::OPTION_PRIVACY_PAGE_ID,
			RadioUdaan_App_Settings::OPTION_PRIVACY_POLICY_URL,
			true
		);
	}

	/**
	 * @return int
	 */
	public static function get_terms_page_id() {
		return self::resolve_page_id(
			self::OPTION_TERMS_PAGE_ID,
			RadioUdaan_App_Settings::OPTION_TERMS_URL,
			false
		);
	}

	/**
	 * @return int
	 */
	public static function get_about_page_id() {
		return self::resolve_page_id(
			self::OPTION_ABOUT_PAGE_ID,
			RadioUdaan_App_Settings::OPTION_ABOUT_URL,
			false
		);
	}

	/**
	 * @param string $page_option Saved page ID option key.
	 * @param string $url_option  URL override option (fallback resolve via url_to_postid).
	 * @param bool   $use_wp_privacy Use WP privacy policy page when unset.
	 * @return int
	 */
	private static function resolve_page_id( $page_option, $url_option, $use_wp_privacy ) {
		$id = (int) get_option( $page_option, 0 );
		if ( $id > 0 ) {
			return $id;
		}

		$url = trim( (string) get_option( $url_option, '' ) );
		if ( $url ) {
			$resolved = url_to_postid( $url );
			if ( $resolved > 0 ) {
				return $resolved;
			}
		}

		if ( $use_wp_privacy && function_exists( 'get_option' ) ) {
			$wp_privacy_id = (int) get_option( 'wp_page_for_privacy_policy', 0 );
			if ( $wp_privacy_id > 0 ) {
				return $wp_privacy_id;
			}
		}

		return 0;
	}

	/**
	 * Render page body HTML (no theme header/footer). Elementor when available.
	 *
	 * @param int $page_id Page ID.
	 * @return string Safe HTML for the mobile app.
	 */
	public static function render_page_body_html( $page_id ) {
		$page_id = (int) $page_id;
		if ( $page_id <= 0 ) {
			return '';
		}

		$post = get_post( $page_id );
		if ( ! $post || 'publish' !== $post->post_status ) {
			return '';
		}

		$html = self::render_elementor_body( $page_id );
		if ( '' === trim( wp_strip_all_tags( $html ) ) ) {
			$html = self::render_classic_body( $post );
		}

		$html = trim( (string) $html );
		if ( '' === $html ) {
			return '';
		}

		return wp_kses_post( $html );
	}

	/**
	 * @param int $page_id Page ID.
	 * @return string
	 */
	private static function render_elementor_body( $page_id ) {
		if ( ! class_exists( '\Elementor\Plugin' ) ) {
			return '';
		}

		$plugin = \Elementor\Plugin::$instance;
		if ( ! $plugin || ! isset( $plugin->documents, $plugin->frontend ) ) {
			return '';
		}

		$document = $plugin->documents->get( $page_id );
		if ( ! $document || ! method_exists( $document, 'is_built_with_elementor' ) ) {
			return '';
		}
		if ( ! $document->is_built_with_elementor() ) {
			return '';
		}

		return (string) $plugin->frontend->get_builder_content_for_display( $page_id );
	}

	/**
	 * @param WP_Post $page_post Published page.
	 * @return string
	 */
	private static function render_classic_body( $page_post ) {
		global $post;
		$previous = $post;
		$post     = $page_post; // phpcs:ignore WordPress.WP.GlobalVariablesOverride.Prohibited
		setup_postdata( $page_post );
		$html = apply_filters( 'the_content', $page_post->post_content );
		wp_reset_postdata();
		$post = $previous; // phpcs:ignore WordPress.WP.GlobalVariablesOverride.Prohibited

		return (string) $html;
	}

	/**
	 * @param int $page_id Page ID.
	 * @return array<string,mixed>|null
	 */
	public static function get_page_payload( $page_id ) {
		$page_id = (int) $page_id;
		if ( $page_id <= 0 ) {
			return null;
		}

		$post = get_post( $page_id );
		if ( ! $post || 'publish' !== $post->post_status ) {
			return null;
		}

		$html = self::render_page_body_html( $page_id );
		if ( '' === trim( wp_strip_all_tags( $html ) ) ) {
			return null;
		}

		return array(
			'page_id'    => $page_id,
			'title'      => get_the_title( $page_id ),
			'html'       => $html,
			'page_url'   => get_permalink( $page_id ),
			'updated_at' => gmdate( 'c', strtotime( $post->post_modified_gmt ? $post->post_modified_gmt : $post->post_modified ) ),
		);
	}

	/**
	 * Public config blob for GET /config.
	 *
	 * @return array<string,array<string,mixed>|null>
	 */
	public static function get_config_payload() {
		return array(
			'privacy' => self::get_page_payload( self::get_privacy_page_id() ),
			'terms'   => self::get_page_payload( self::get_terms_page_id() ),
			'about'   => self::get_page_payload( self::get_about_page_id() ),
		);
	}
}

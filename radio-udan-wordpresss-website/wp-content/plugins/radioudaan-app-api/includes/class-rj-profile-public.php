<?php
/**
 * Public URLs for RJ profiles (/rj-profiles/, /rj-profiles/{nicename}/).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Rewrite rules + theme template loader for user-based RJ pages.
 */
class RadioUdaan_Rj_Profile_Public {

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'init', array( __CLASS__, 'register_rewrites' ), 20 );
		add_filter( 'query_vars', array( __CLASS__, 'register_query_vars' ) );
		add_action( 'template_redirect', array( __CLASS__, 'template_redirect' ), 0 );
		add_filter( 'template_include', array( __CLASS__, 'filter_legacy_cpt_single_template' ), 99 );
	}

	/**
	 * Register pretty permalinks (works after rj-profiles CPT is removed from CPT UI).
	 */
	public static function register_rewrites() {
		add_rewrite_rule(
			'^rj-profiles/?$',
			'index.php?' . RadioUdaan_Rj_Profile::QUERY_VAR_ARCHIVE . '=1',
			'top'
		);
		add_rewrite_rule(
			'^rj-profiles/([^/]+)/?$',
			'index.php?' . RadioUdaan_Rj_Profile::QUERY_VAR_NICENAME . '=$matches[1]',
			'top'
		);
	}

	/**
	 * @param string[] $vars Query vars.
	 * @return string[]
	 */
	public static function register_query_vars( $vars ) {
		$vars[] = RadioUdaan_Rj_Profile::QUERY_VAR_ARCHIVE;
		$vars[] = RadioUdaan_Rj_Profile::QUERY_VAR_NICENAME;
		return $vars;
	}

	/**
	 * Serve archive / single before legacy CPT routing can load the wrong template.
	 */
	public static function template_redirect() {
		if ( is_admin() || ( defined( 'REST_REQUEST' ) && REST_REQUEST ) ) {
			return;
		}

		if ( self::maybe_serve_archive() ) {
			return;
		}
		self::maybe_serve_single();
	}

	/**
	 * Legacy CPT singles still registered in rewrite rules: map post → migrated user.
	 *
	 * @param string $template Theme template path.
	 * @return string
	 */
	public static function filter_legacy_cpt_single_template( $template ) {
		if ( ! is_singular( 'rj-profiles' ) ) {
			return $template;
		}

		$post = get_queried_object();
		if ( ! ( $post instanceof WP_Post ) ) {
			return $template;
		}

		$user = RadioUdaan_Rj_Profile::find_user_by_legacy_post_id( (int) $post->ID );
		if ( ! $user || ! RadioUdaan_Rj_Profile::is_public_rj( $user ) ) {
			return $template;
		}

		$GLOBALS['radioudaan_rj_profile_user'] = $user;
		$resolved = locate_template( array( 'single-rj-profiles.php' ) );
		return $resolved ? $resolved : $template;
	}

	/**
	 * @return bool True when archive was served.
	 */
	private static function maybe_serve_archive() {
		if ( ! (int) get_query_var( RadioUdaan_Rj_Profile::QUERY_VAR_ARCHIVE ) ) {
			return false;
		}

		self::load_template( 'archive-rj-profiles.php' );
		return true;
	}

	/**
	 * Resolve nicename from query var or request path (CPT rewrite can hide our query var).
	 *
	 * @return string
	 */
	public static function resolve_request_nicename() {
		$nicename = sanitize_title( (string) get_query_var( RadioUdaan_Rj_Profile::QUERY_VAR_NICENAME ) );
		if ( $nicename !== '' && ! in_array( $nicename, array( 'feed' ), true ) ) {
			return $nicename;
		}

		return self::nicename_from_request_path();
	}

	/**
	 * Parse /rj-profiles/{slug}/ from the current request URI.
	 *
	 * @return string
	 */
	public static function nicename_from_request_path() {
		$path = wp_parse_url( isset( $_SERVER['REQUEST_URI'] ) ? wp_unslash( $_SERVER['REQUEST_URI'] ) : '', PHP_URL_PATH );
		if ( ! is_string( $path ) || $path === '' ) {
			return '';
		}

		$path = trim( $path, '/' );
		$home_path = wp_parse_url( home_url( '/' ), PHP_URL_PATH );
		$home_path = trim( (string) $home_path, '/' );
		if ( $home_path !== '' && strpos( $path, $home_path . '/' ) === 0 ) {
			$path = trim( substr( $path, strlen( $home_path ) ), '/' );
		}

		if ( ! preg_match( '#^rj-profiles/([^/]+)/?$#', $path, $matches ) ) {
			return '';
		}

		$nicename = sanitize_title( $matches[1] );
		if ( $nicename === '' || in_array( $nicename, array( 'feed' ), true ) ) {
			return '';
		}

		return $nicename;
	}

	/**
	 * @return bool True when single was served or 404 emitted.
	 */
	private static function maybe_serve_single() {
		$nicename = self::resolve_request_nicename();
		if ( $nicename === '' ) {
			return false;
		}

		$user = RadioUdaan_Rj_Profile::resolve_public_user_by_nicename( $nicename );
		if ( ! $user ) {
			self::render_not_found();
			return true;
		}

		$GLOBALS['radioudaan_rj_profile_user'] = $user;
		self::load_template( 'single-rj-profiles.php' );
		return true;
	}

	/**
	 * Safe 404 — never `include false` (that fatals on PHP 8+).
	 */
	private static function render_not_found() {
		global $wp_query;

		if ( $wp_query instanceof WP_Query ) {
			$wp_query->set_404();
		}

		status_header( 404 );
		nocache_headers();

		$template = get_query_template( '404' );
		if ( $template ) {
			include $template;
			exit;
		}

		wp_die(
			esc_html__( 'RJ profile not found.', 'radioudaan-app-api' ),
			esc_html__( 'Not found', 'radioudaan-app-api' ),
			array( 'response' => 404 )
		);
	}

	/**
	 * @param string $template_file Theme template basename.
	 */
	private static function load_template( $template_file ) {
		$template = locate_template( array( $template_file ) );
		if ( ! $template ) {
			wp_die(
				esc_html(
					sprintf(
						/* translators: %s: template file name */
						__( 'Theme template %s is missing.', 'radioudaan-app-api' ),
						$template_file
					)
				),
				esc_html__( 'RJ profile template missing', 'radioudaan-app-api' ),
				array( 'response' => 500 )
			);
		}

		load_template( $template );
		exit;
	}
}

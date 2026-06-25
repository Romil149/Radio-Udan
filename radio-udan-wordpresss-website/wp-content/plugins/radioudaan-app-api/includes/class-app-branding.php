<?php
/**
 * Mobile app branding and copy (WP admin → GET /config).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Branding + user-facing copy for the Flutter app.
 */
class RadioUdaan_App_Branding {

	const OPTION_APP_NAME           = 'radioudaan_branding_app_name';
	const OPTION_TAGLINE            = 'radioudaan_branding_tagline';
	const OPTION_LOGO_ATTACHMENT_ID = 'radioudaan_branding_logo_id';
	const OPTION_COLOR_PRIMARY      = 'radioudaan_branding_color_primary';
	const OPTION_COLOR_ON_PRIMARY   = 'radioudaan_branding_color_on_primary';
	const OPTION_COLOR_SECONDARY    = 'radioudaan_branding_color_secondary';
	const OPTION_COLOR_SURFACE      = 'radioudaan_branding_color_surface';
	const OPTION_COLOR_SURFACE_DARK = 'radioudaan_branding_color_surface_dark';
	const OPTION_COLOR_ERROR        = 'radioudaan_branding_color_error';

	const OPTION_COPY_BOOTSTRAP_LOADING = 'radioudaan_copy_bootstrap_loading';
	const OPTION_COPY_SIGN_IN_INTRO     = 'radioudaan_copy_sign_in_intro';
	const OPTION_COPY_RADIO_INTRO       = 'radioudaan_copy_radio_intro';
	const OPTION_COPY_RADIO_LIVE_LABEL  = 'radioudaan_copy_radio_live_label';
	const OPTION_COPY_TAB_RADIO         = 'radioudaan_copy_tab_radio';
	const OPTION_COPY_TAB_LIBRARY       = 'radioudaan_copy_tab_library';
	const OPTION_COPY_TAB_EVENTS        = 'radioudaan_copy_tab_events';
	const OPTION_COPY_TAB_MORE          = 'radioudaan_copy_tab_more';
	const OPTION_COPY_EVENTS_EMPTY      = 'radioudaan_copy_events_empty';
	const OPTION_COPY_LIBRARY_SHOWS     = 'radioudaan_copy_library_shows';
	const OPTION_COPY_LIBRARY_WHATS_NEW = 'radioudaan_copy_library_whats_new';
	const OPTION_COPY_VERIFY_INTRO                 = 'radioudaan_copy_verify_intro';
	const OPTION_COPY_SUBMIT_REGISTRATION          = 'radioudaan_copy_submit_registration';
	const OPTION_COPY_REGISTRATION_SUCCESS_PREFIX  = 'radioudaan_copy_registration_success_prefix';
	const OPTION_COPY_LIBRARY_SHOWS_EMPTY          = 'radioudaan_copy_library_shows_empty';
	const OPTION_COPY_LIBRARY_WHATS_NEW_EMPTY      = 'radioudaan_copy_library_whats_new_empty';
	const OPTION_COPY_UNSUPPORTED_FIELDS_NOTICE    = 'radioudaan_copy_unsupported_fields_notice';
	const OPTION_COPY_OVERRIDES                    = 'radioudaan_copy_overrides';

	/**
	 * Website-aligned defaults (radio-udaan.com theme).
	 *
	 * @return array<string,string>
	 */
	public static function default_colors() {
		return array(
			'primary'       => '#ff6b00',
			'on_primary'    => '#ffffff',
			'secondary'     => '#1d9e75',
			'surface'       => '#ffffff',
			'surface_dark'  => '#1a1a1a',
			'error'         => '#dc2626',
		);
	}

	/**
	 * Default copy strings (Flutter AppStrings catalog).
	 *
	 * @return array<string,string>
	 */
	public static function default_copy() {
		return RadioUdaan_App_Copy_Catalog::default_catalog();
	}

	/**
	 * @param string $hex Candidate color.
	 * @param string $fallback Valid hex if candidate invalid.
	 * @return string
	 */
	public static function sanitize_hex( $hex, $fallback ) {
		$hex = strtolower( trim( (string) $hex ) );
		if ( preg_match( '/^#([0-9a-f]{3}|[0-9a-f]{6})$/', $hex ) ) {
			if ( 4 === strlen( $hex ) ) {
				$r = $hex[1];
				$g = $hex[2];
				$b = $hex[3];
				$hex = '#' . $r . $r . $g . $g . $b . $b;
			}
			return $hex;
		}
		return self::sanitize_hex( $fallback, '#000000' );
	}

	/**
	 * @return string
	 */
	public static function get_app_name() {
		$name = trim( (string) get_option( self::OPTION_APP_NAME, '' ) );
		if ( $name ) {
			return $name;
		}
		return get_bloginfo( 'name' ) ? get_bloginfo( 'name' ) : 'Radio Udaan';
	}

	/**
	 * @return string
	 */
	public static function get_tagline() {
		$tagline = trim( (string) get_option( self::OPTION_TAGLINE, '' ) );
		if ( $tagline ) {
			return $tagline;
		}
		$desc = get_bloginfo( 'description' );
		return $desc ? $desc : __( 'Community radio by and for persons with disabilities', 'radioudaan-app-api' );
	}

	/**
	 * @return string
	 */
	public static function get_logo_url() {
		$attachment_id = (int) get_option( self::OPTION_LOGO_ATTACHMENT_ID, 0 );
		if ( $attachment_id > 0 ) {
			$url = wp_get_attachment_image_url( $attachment_id, 'medium' );
			if ( $url ) {
				return esc_url_raw( $url );
			}
		}

		/**
		 * Override logo URL without using the media library.
		 *
		 * @param string $url Empty string = use theme default.
		 */
		$filtered = apply_filters( 'radioudaan_app_branding_logo_url', '' );
		if ( $filtered ) {
			return esc_url_raw( $filtered );
		}

		$theme_logo = get_stylesheet_directory() . '/assets/images/logo.png';
		if ( file_exists( $theme_logo ) ) {
			return esc_url_raw( get_stylesheet_directory_uri() . '/assets/images/logo.png' );
		}

		return '';
	}

	/**
	 * @return array<string,string>
	 */
	public static function get_colors() {
		$defaults = self::default_colors();
		return array(
			'primary'      => self::sanitize_hex( get_option( self::OPTION_COLOR_PRIMARY, '' ), $defaults['primary'] ),
			'on_primary'   => self::sanitize_hex( get_option( self::OPTION_COLOR_ON_PRIMARY, '' ), $defaults['on_primary'] ),
			'secondary'    => self::sanitize_hex( get_option( self::OPTION_COLOR_SECONDARY, '' ), $defaults['secondary'] ),
			'surface'      => self::sanitize_hex( get_option( self::OPTION_COLOR_SURFACE, '' ), $defaults['surface'] ),
			'surface_dark' => self::sanitize_hex( get_option( self::OPTION_COLOR_SURFACE_DARK, '' ), $defaults['surface_dark'] ),
			'error'        => self::sanitize_hex( get_option( self::OPTION_COLOR_ERROR, '' ), $defaults['error'] ),
		);
	}

	/**
	 * Payload for GET /config → branding.
	 *
	 * @return array<string,mixed>
	 */
	public static function get_public_branding() {
		return array(
			'app_name' => self::get_app_name(),
			'tagline'  => self::get_tagline(),
			'logo_url' => self::get_logo_url(),
			'colors'   => self::get_colors(),
		);
	}

	/**
	 * Resolve one copy string: per-key option, legacy option, JSON overrides, then default.
	 *
	 * @param string               $key      Catalog key.
	 * @param string               $default  Default from catalog.
	 * @param array<string,string> $legacy   Legacy option => catalog key (inverted lookup built by caller).
	 * @param array<string,string> $overrides Optional JSON overrides.
	 * @return string
	 */
	private static function resolve_copy_value( $key, $default, array $legacy, array $overrides ) {
		if ( isset( $overrides[ $key ] ) ) {
			$override = trim( (string) $overrides[ $key ] );
			if ( $override !== '' ) {
				return $override;
			}
		}

		$per_key = trim( (string) get_option( RadioUdaan_App_Copy_Catalog::option_name( $key ), '' ) );
		if ( $per_key !== '' ) {
			return $per_key;
		}

		if ( isset( $legacy[ $key ] ) ) {
			$legacy_val = trim( (string) get_option( $legacy[ $key ], '' ) );
			if ( $legacy_val !== '' ) {
				return $legacy_val;
			}
		}

		return $default;
	}

	/**
	 * Payload for GET /config → copy (user-visible strings).
	 *
	 * @return array<string,string>
	 */
	public static function get_public_copy() {
		$defaults = self::default_copy();
		$legacy_by_key = array();
		foreach ( RadioUdaan_App_Copy_Catalog::legacy_option_map() as $option => $catalog_key ) {
			$legacy_by_key[ $catalog_key ] = $option;
		}

		$overrides = array();
		$raw_overrides = get_option( self::OPTION_COPY_OVERRIDES, '' );
		if ( is_string( $raw_overrides ) && $raw_overrides !== '' ) {
			$decoded = json_decode( $raw_overrides, true );
			if ( is_array( $decoded ) ) {
				foreach ( $decoded as $k => $v ) {
					if ( is_string( $k ) && is_scalar( $v ) ) {
						$overrides[ $k ] = (string) $v;
					}
				}
			}
		}

		$copy = array();
		foreach ( $defaults as $key => $default ) {
			$copy[ $key ] = self::resolve_copy_value( $key, $default, $legacy_by_key, $overrides );
		}

		return $copy;
	}
}

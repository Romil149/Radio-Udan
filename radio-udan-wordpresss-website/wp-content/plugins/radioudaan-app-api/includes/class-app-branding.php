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

	const OPTION_COLOR_PRIMARY              = 'radioudaan_branding_color_primary';
	const OPTION_COLOR_ON_PRIMARY           = 'radioudaan_branding_color_on_primary';
	const OPTION_COLOR_SECONDARY            = 'radioudaan_branding_color_secondary';
	const OPTION_COLOR_SURFACE              = 'radioudaan_branding_color_surface';
	const OPTION_COLOR_SURFACE_DARK         = 'radioudaan_branding_color_surface_dark';
	const OPTION_COLOR_ERROR                = 'radioudaan_branding_color_error';
	const OPTION_COLOR_BACKGROUND           = 'radioudaan_branding_color_background';
	const OPTION_COLOR_ON_BACKGROUND        = 'radioudaan_branding_color_on_background';
	const OPTION_COLOR_ON_SURFACE_VARIANT   = 'radioudaan_branding_color_on_surface_variant';
	const OPTION_COLOR_PRIMARY_GLOW         = 'radioudaan_branding_color_primary_glow';
	const OPTION_COLOR_OUTLINE_VARIANT      = 'radioudaan_branding_color_outline_variant';
	const OPTION_COLOR_SURFACE_CONTAINER_HIGH = 'radioudaan_branding_color_surface_container_high';
	const OPTION_COLOR_SURFACE_CONTAINER    = 'radioudaan_branding_color_surface_container';
	const OPTION_COLOR_HINT                 = 'radioudaan_branding_color_hint';
	const OPTION_COLOR_ON_SURFACE_MUTED     = 'radioudaan_branding_color_on_surface_muted';
	const OPTION_COLOR_ON_ERROR             = 'radioudaan_branding_color_on_error';
	const OPTION_COLOR_SCRIM                = 'radioudaan_branding_color_scrim';

	const OPTION_COPY_BOOTSTRAP_LOADING = 'radioudaan_copy_bootstrap_loading';
	const OPTION_COPY_SIGN_IN_INTRO     = 'radioudaan_copy_sign_in_intro';
	const OPTION_COPY_RADIO_INTRO       = 'radioudaan_copy_radio_intro';
	const OPTION_COPY_RADIO_LIVE_LABEL  = 'radioudaan_copy_radio_live_label';
	const OPTION_COPY_TAB_RADIO         = 'radioudaan_copy_tab_radio';
	const OPTION_COPY_TAB_LIBRARY       = 'radioudaan_copy_tab_library';
	const OPTION_COPY_TAB_EVENTS        = 'radioudaan_copy_tab_events';
	const OPTION_COPY_TAB_ABOUT         = 'radioudaan_copy_tab_about';
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
	 * Catalog key → WP option name (all colors editable in admin).
	 *
	 * @return array<string,string>
	 */
	public static function color_option_map() {
		return array(
			'primary'                => self::OPTION_COLOR_PRIMARY,
			'on_primary'             => self::OPTION_COLOR_ON_PRIMARY,
			'secondary'              => self::OPTION_COLOR_SECONDARY,
			'surface'                => self::OPTION_COLOR_SURFACE,
			'surface_dark'           => self::OPTION_COLOR_SURFACE_DARK,
			'error'                  => self::OPTION_COLOR_ERROR,
			'background'             => self::OPTION_COLOR_BACKGROUND,
			'on_background'          => self::OPTION_COLOR_ON_BACKGROUND,
			'on_surface_variant'     => self::OPTION_COLOR_ON_SURFACE_VARIANT,
			'primary_glow'           => self::OPTION_COLOR_PRIMARY_GLOW,
			'outline_variant'        => self::OPTION_COLOR_OUTLINE_VARIANT,
			'surface_container_high' => self::OPTION_COLOR_SURFACE_CONTAINER_HIGH,
			'surface_container'      => self::OPTION_COLOR_SURFACE_CONTAINER,
			'hint'                   => self::OPTION_COLOR_HINT,
			'on_surface_muted'       => self::OPTION_COLOR_ON_SURFACE_MUTED,
			'on_error'               => self::OPTION_COLOR_ON_ERROR,
			'scrim'                  => self::OPTION_COLOR_SCRIM,
		);
	}

	/**
	 * Admin labels for color pickers.
	 *
	 * @return array<string,string>
	 */
	public static function color_labels() {
		return array(
			'primary'                => __( 'Primary', 'radioudaan-app-api' ),
			'on_primary'             => __( 'On primary', 'radioudaan-app-api' ),
			'secondary'              => __( 'Secondary', 'radioudaan-app-api' ),
			'surface'                => __( 'Light surface', 'radioudaan-app-api' ),
			'surface_dark'           => __( 'Dark surface', 'radioudaan-app-api' ),
			'error'                  => __( 'Error', 'radioudaan-app-api' ),
			'background'             => __( 'App background', 'radioudaan-app-api' ),
			'on_background'          => __( 'On background', 'radioudaan-app-api' ),
			'on_surface_variant'     => __( 'Accent text', 'radioudaan-app-api' ),
			'primary_glow'           => __( 'Primary glow', 'radioudaan-app-api' ),
			'outline_variant'        => __( 'Borders', 'radioudaan-app-api' ),
			'surface_container_high' => __( 'Elevated surface', 'radioudaan-app-api' ),
			'surface_container'      => __( 'Card surface', 'radioudaan-app-api' ),
			'hint'                   => __( 'Hint text', 'radioudaan-app-api' ),
			'on_surface_muted'       => __( 'Muted text', 'radioudaan-app-api' ),
			'on_error'               => __( 'On error', 'radioudaan-app-api' ),
			'scrim'                  => __( 'Overlay scrim', 'radioudaan-app-api' ),
		);
	}

	/**
	 * Website-aligned defaults (radio-udaan.com theme + Stitch Udaan Core).
	 *
	 * @return array<string,string>
	 */
	public static function default_colors() {
		return array(
			'primary'                => '#ff6b00',
			'on_primary'             => '#ffffff',
			'secondary'              => '#1d9e75',
			'surface'                => '#ffffff',
			'surface_dark'           => '#1a1a1a',
			'error'                  => '#dc2626',
			'background'             => '#131313',
			'on_background'          => '#e5e2e1',
			'on_surface_variant'     => '#e3bfb1',
			'primary_glow'           => '#ffb598',
			'outline_variant'        => '#5b4137',
			'surface_container_high' => '#2a2a2a',
			'surface_container'      => '#20201f',
			'hint'                   => '#aa8a7d',
			'on_surface_muted'       => '#939494',
			'on_error'               => '#ffffff',
			'scrim'                  => '#cc000000',
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
	 * @param string $hex Candidate color (#rgb, #rrggbb, or #aarrggbb for scrim).
	 * @param string $fallback Valid hex if candidate invalid.
	 * @return string
	 */
	public static function sanitize_hex( $hex, $fallback ) {
		$hex = strtolower( trim( (string) $hex ) );
		if ( preg_match( '/^#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/', $hex ) ) {
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
		$colors   = array();
		foreach ( self::color_option_map() as $key => $option ) {
			$colors[ $key ] = self::sanitize_hex(
				get_option( $option, '' ),
				$defaults[ $key ] ?? '#000000'
			);
		}
		return $colors;
	}

	/**
	 * @return bool True when branding.app_name and copy.app_name differ.
	 */
	public static function branding_copy_app_name_mismatch() {
		$branding_name = self::get_app_name();
		$copy          = self::get_public_copy();
		$copy_name     = isset( $copy['app_name'] ) ? trim( (string) $copy['app_name'] ) : '';

		return '' !== $copy_name && $branding_name !== $copy_name;
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

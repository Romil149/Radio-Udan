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
	 * @return array<string,string>
	 */
	public static function default_copy() {
		return array(
			'bootstrap_loading' => __( 'READY TO LAUNCH', 'radioudaan-app-api' ),
			'sign_in_intro'     => __( 'Enter your mobile number. We will send a one-time code by SMS.', 'radioudaan-app-api' ),
			'radio_intro'       => __( 'Listen to Radio Udaan live — community radio by and for persons with disabilities.', 'radioudaan-app-api' ),
			'radio_live_label'  => __( 'Live now', 'radioudaan-app-api' ),
			'tab_radio'         => __( 'Live Radio', 'radioudaan-app-api' ),
			'tab_library'       => __( 'Library', 'radioudaan-app-api' ),
			'tab_events'        => __( 'Events', 'radioudaan-app-api' ),
			'tab_more'          => __( 'More', 'radioudaan-app-api' ),
			'events_empty'      => __( 'No open events right now. Check back soon.', 'radioudaan-app-api' ),
			'library_shows'     => __( 'Radio shows', 'radioudaan-app-api' ),
			'library_whats_new'           => __( "What's new", 'radioudaan-app-api' ),
			'verify_intro'                => __(
				'Enter the code sent to your number. Type the digits manually — the app does not read SMS.',
				'radioudaan-app-api'
			),
			'submit_registration'         => __( 'Submit registration', 'radioudaan-app-api' ),
			'registration_success_prefix'   => __(
				'Registration submitted successfully. Reference: entry',
				'radioudaan-app-api'
			),
			'library_shows_empty'           => __( 'No shows published yet.', 'radioudaan-app-api' ),
			'library_whats_new_empty'       => __( 'No updates yet.', 'radioudaan-app-api' ),
			'unsupported_fields_notice'   => __(
				'Some fields on this form are not supported in the app yet. Contact Radio Udaan if you need help completing them.',
				'radioudaan-app-api'
			),
		);
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
	 * @param string $option Option key.
	 * @param string $default Default string.
	 * @return string
	 */
	private static function get_copy_option( $option, $default ) {
		$val = trim( (string) get_option( $option, '' ) );
		return $val ? $val : $default;
	}

	/**
	 * Payload for GET /config → copy (user-visible strings).
	 *
	 * @return array<string,string>
	 */
	public static function get_public_copy() {
		$defaults = self::default_copy();
		return array(
			'bootstrap_loading' => self::get_copy_option( self::OPTION_COPY_BOOTSTRAP_LOADING, $defaults['bootstrap_loading'] ),
			'sign_in_intro'     => self::get_copy_option( self::OPTION_COPY_SIGN_IN_INTRO, $defaults['sign_in_intro'] ),
			'radio_intro'       => self::get_copy_option( self::OPTION_COPY_RADIO_INTRO, $defaults['radio_intro'] ),
			'radio_live_label'  => self::get_copy_option( self::OPTION_COPY_RADIO_LIVE_LABEL, $defaults['radio_live_label'] ),
			'tab_radio'         => self::get_copy_option( self::OPTION_COPY_TAB_RADIO, $defaults['tab_radio'] ),
			'tab_library'       => self::get_copy_option( self::OPTION_COPY_TAB_LIBRARY, $defaults['tab_library'] ),
			'tab_events'        => self::get_copy_option( self::OPTION_COPY_TAB_EVENTS, $defaults['tab_events'] ),
			'tab_more'          => self::get_copy_option( self::OPTION_COPY_TAB_MORE, $defaults['tab_more'] ),
			'events_empty'      => self::get_copy_option( self::OPTION_COPY_EVENTS_EMPTY, $defaults['events_empty'] ),
			'library_shows'     => self::get_copy_option( self::OPTION_COPY_LIBRARY_SHOWS, $defaults['library_shows'] ),
			'library_whats_new'           => self::get_copy_option( self::OPTION_COPY_LIBRARY_WHATS_NEW, $defaults['library_whats_new'] ),
			'verify_intro'                => self::get_copy_option( self::OPTION_COPY_VERIFY_INTRO, $defaults['verify_intro'] ),
			'submit_registration'         => self::get_copy_option( self::OPTION_COPY_SUBMIT_REGISTRATION, $defaults['submit_registration'] ),
			'registration_success_prefix' => self::get_copy_option( self::OPTION_COPY_REGISTRATION_SUCCESS_PREFIX, $defaults['registration_success_prefix'] ),
			'library_shows_empty'         => self::get_copy_option( self::OPTION_COPY_LIBRARY_SHOWS_EMPTY, $defaults['library_shows_empty'] ),
			'library_whats_new_empty'     => self::get_copy_option( self::OPTION_COPY_LIBRARY_WHATS_NEW_EMPTY, $defaults['library_whats_new_empty'] ),
			'unsupported_fields_notice'   => self::get_copy_option( self::OPTION_COPY_UNSUPPORTED_FIELDS_NOTICE, $defaults['unsupported_fields_notice'] ),
		);
	}
}

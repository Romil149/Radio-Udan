<?php
/**
 * Live radio home screen content (GET /config → live_radio).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Show info, hero image, and action buttons for the app Live tab.
 */
class RadioUdaan_App_Live_Radio {

	const OPTION_SHOW_TITLE           = 'radioudaan_live_show_title';
	const OPTION_SHOW_SUBTITLE        = 'radioudaan_live_show_subtitle';
	const OPTION_HERO_ATTACHMENT_ID   = 'radioudaan_live_hero_id';
	const OPTION_WHATSAPP_URL         = 'radioudaan_live_whatsapp_url';
	const OPTION_WHATSAPP_LABEL       = 'radioudaan_live_whatsapp_label';
	const OPTION_SHARE_LABEL          = 'radioudaan_live_share_label';
	const OPTION_SHARE_TEXT           = 'radioudaan_live_share_text';
	const OPTION_SHOW_WHATSAPP        = 'radioudaan_live_show_whatsapp';
	const OPTION_SHOW_SHARE           = 'radioudaan_live_show_share';
	const OPTION_SHOW_VOLUME          = 'radioudaan_live_show_volume';

	/**
	 * @return array<string,mixed>
	 */
	public static function defaults() {
		return array(
			'show_title'       => __( 'Udaan Morning Show', 'radioudaan-app-api' ),
			'show_subtitle'    => __( 'with RJ Karan & RJ Meera', 'radioudaan-app-api' ),
			'whatsapp_url'     => 'https://chat.whatsapp.com/BYOPTP8rLR3H53vlrnHSmF',
			'whatsapp_label'   => __( 'Join WhatsApp Channel', 'radioudaan-app-api' ),
			'share_label'      => __( 'Share', 'radioudaan-app-api' ),
			'share_text'       => __( 'Listen to Radio Udaan live!', 'radioudaan-app-api' ),
			'show_whatsapp'    => true,
			'show_share'       => true,
			'show_volume'      => true,
		);
	}

	/**
	 * @param string $option Option key.
	 * @param string $default Default value.
	 * @return string
	 */
	private static function text_option( $option, $default ) {
		$val = trim( (string) get_option( $option, '' ) );
		return $val !== '' ? $val : $default;
	}

	/**
	 * @return string
	 */
	public static function get_show_title() {
		return self::text_option( self::OPTION_SHOW_TITLE, self::defaults()['show_title'] );
	}

	/**
	 * @return string
	 */
	public static function get_show_subtitle() {
		return self::text_option( self::OPTION_SHOW_SUBTITLE, self::defaults()['show_subtitle'] );
	}

	/**
	 * @return string
	 */
	public static function get_hero_image_url() {
		$attachment_id = (int) get_option( self::OPTION_HERO_ATTACHMENT_ID, 0 );
		if ( $attachment_id > 0 ) {
			$url = wp_get_attachment_image_url( $attachment_id, 'large' );
			if ( $url ) {
				return esc_url_raw( $url );
			}
		}
		return '';
	}

	/**
	 * @return int
	 */
	public static function get_hero_attachment_id() {
		return (int) get_option( self::OPTION_HERO_ATTACHMENT_ID, 0 );
	}

	/**
	 * @return string
	 */
	public static function get_whatsapp_url() {
		return esc_url_raw(
			self::text_option( self::OPTION_WHATSAPP_URL, self::defaults()['whatsapp_url'] )
		);
	}

	/**
	 * @return string
	 */
	public static function get_whatsapp_label() {
		return self::text_option( self::OPTION_WHATSAPP_LABEL, self::defaults()['whatsapp_label'] );
	}

	/**
	 * @return string
	 */
	/**
	 * @return string
	 */
	public static function get_share_label() {
		return self::text_option( self::OPTION_SHARE_LABEL, self::defaults()['share_label'] );
	}

	/**
	 * @return string
	 */
	public static function get_share_text() {
		return self::text_option( self::OPTION_SHARE_TEXT, self::defaults()['share_text'] );
	}

	/**
	 * @return bool
	 */
	public static function show_whatsapp_button() {
		return (bool) get_option( self::OPTION_SHOW_WHATSAPP, 1 );
	}

	/**
	 * @return bool
	 */
	/**
	 * @return bool
	 */
	public static function show_share_button() {
		return (bool) get_option( self::OPTION_SHOW_SHARE, 1 );
	}

	/**
	 * @return bool
	 */
	public static function show_volume_slider() {
		return (bool) get_option( self::OPTION_SHOW_VOLUME, 1 );
	}

	/**
	 * Payload for GET /config.
	 *
	 * @return array<string,mixed>
	 */
	public static function get_public_config() {
		$config = array(
			'show_title'       => self::get_show_title(),
			'show_subtitle'    => self::get_show_subtitle(),
			'hero_image_url'   => self::get_hero_image_url(),
			'whatsapp_url'     => self::get_whatsapp_url(),
			'whatsapp_label'   => self::get_whatsapp_label(),
			'share_label'      => self::get_share_label(),
			'share_text'       => self::get_share_text(),
			'show_whatsapp'    => self::show_whatsapp_button(),
			'show_share'       => self::show_share_button(),
			'show_volume'      => self::show_volume_slider(),
			'menu_action'      => 'more',
			'profile_action'   => 'more',
		);

		$schedule = RadioUdaan_App_Radio_Schedule::build_schedule( 2 );
		$current  = ! empty( $schedule['on_air'] ) ? $schedule['on_air'] : null;
		if ( is_array( $current ) ) {
			if ( ! empty( $current['title'] ) ) {
				$config['show_title'] = (string) $current['title'];
			}
			$hosts_line = RadioUdaan_App_Radio_Schedule::format_hosts_subtitle( $current );
			if ( $hosts_line !== '' ) {
				$config['show_subtitle'] = $hosts_line;
			}
			if ( ! empty( $current['thumbnail_url'] ) ) {
				$config['hero_image_url'] = (string) $current['thumbnail_url'];
			}
		}

		return $config;
	}
}

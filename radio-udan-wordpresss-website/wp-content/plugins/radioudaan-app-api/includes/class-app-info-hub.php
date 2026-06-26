<?php
/**
 * About tab content: donate block + social links for GET /config.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * WordPress-managed donate + social payload for the mobile About tab.
 */
class RadioUdaan_App_Info_Hub {

	const OPTION_DONATE_BADGE              = 'radioudaan_donate_badge';
	const OPTION_DONATE_HEADLINE           = 'radioudaan_donate_headline';
	const OPTION_DONATE_INTRO              = 'radioudaan_donate_intro';
	const OPTION_DONATE_ACCESSIBILITY_NOTE = 'radioudaan_donate_accessibility_note';
	const OPTION_DONATE_UPI_ID             = 'radioudaan_donate_upi_id';
	const OPTION_DONATE_QR_ATTACHMENT_ID   = 'radioudaan_donate_qr_attachment_id';
	const OPTION_DONATE_ACCOUNT_NAME       = 'radioudaan_donate_account_name';
	const OPTION_DONATE_ACCOUNT_NUMBER     = 'radioudaan_donate_account_number';
	const OPTION_DONATE_BANK_NAME          = 'radioudaan_donate_bank_name';
	const OPTION_DONATE_BRANCH_NAME        = 'radioudaan_donate_branch_name';
	const OPTION_DONATE_IFSC               = 'radioudaan_donate_ifsc';
	const OPTION_DONATE_MICR               = 'radioudaan_donate_micr';
	const OPTION_DONATE_BANK_ADDRESS       = 'radioudaan_donate_bank_address';
	const OPTION_SOCIAL_FACEBOOK           = 'radioudaan_social_facebook_url';
	const OPTION_SOCIAL_INSTAGRAM          = 'radioudaan_social_instagram_url';
	const OPTION_SOCIAL_YOUTUBE            = 'radioudaan_social_youtube_url';
	const OPTION_SOCIAL_WEBSITE            = 'radioudaan_social_website_url';

	/**
	 * @return array<string,mixed>
	 */
	public static function get_config_payload() {
		$qr_id  = (int) get_option( self::OPTION_DONATE_QR_ATTACHMENT_ID, 0 );
		$qr_url = $qr_id > 0 ? wp_get_attachment_image_url( $qr_id, 'large' ) : '';

		return array(
			'donate'  => array(
				'badge'              => self::get_string( self::OPTION_DONATE_BADGE, __( 'Support Radio Udaan', 'radioudaan-app-api' ) ),
				'headline'           => self::get_string( self::OPTION_DONATE_HEADLINE, __( 'Help Make Radio Udaan Sustainable', 'radioudaan-app-api' ) ),
				'intro'              => self::get_text( self::OPTION_DONATE_INTRO, self::default_intro() ),
				'accessibility_note' => self::get_text( self::OPTION_DONATE_ACCESSIBILITY_NOTE, self::default_accessibility_note() ),
				'upi_id'             => self::get_string( self::OPTION_DONATE_UPI_ID, '' ),
				'qr_image_url'       => $qr_url ? esc_url_raw( $qr_url ) : '',
				'bank'               => array(
					'account_name'   => self::get_string( self::OPTION_DONATE_ACCOUNT_NAME, 'Udaan Empowerment Trust' ),
					'account_number' => self::get_string( self::OPTION_DONATE_ACCOUNT_NUMBER, '' ),
					'bank_name'      => self::get_string( self::OPTION_DONATE_BANK_NAME, 'HDFC Bank' ),
					'branch_name'    => self::get_string( self::OPTION_DONATE_BRANCH_NAME, '' ),
					'ifsc'           => self::get_string( self::OPTION_DONATE_IFSC, '' ),
					'micr'           => self::get_string( self::OPTION_DONATE_MICR, '' ),
					'address'        => self::get_text( self::OPTION_DONATE_BANK_ADDRESS, '' ),
				),
			),
			'social'  => self::get_social_links(),
		);
	}

	/**
	 * @return array<int,array<string,string>>
	 */
	private static function get_social_links() {
		$items = array(
			array(
				'id'    => 'facebook',
				'label' => __( 'Facebook', 'radioudaan-app-api' ),
				'url'   => self::get_url( self::OPTION_SOCIAL_FACEBOOK ),
			),
			array(
				'id'    => 'instagram',
				'label' => __( 'Instagram', 'radioudaan-app-api' ),
				'url'   => self::get_url( self::OPTION_SOCIAL_INSTAGRAM ),
			),
			array(
				'id'    => 'youtube',
				'label' => __( 'YouTube', 'radioudaan-app-api' ),
				'url'   => self::get_url( self::OPTION_SOCIAL_YOUTUBE ),
			),
			array(
				'id'    => 'website',
				'label' => __( 'Website', 'radioudaan-app-api' ),
				'url'   => self::get_url( self::OPTION_SOCIAL_WEBSITE, home_url( '/' ) ),
			),
		);

		$out = array();
		foreach ( $items as $item ) {
			if ( '' === $item['url'] ) {
				continue;
			}
			$out[] = $item;
		}

		return $out;
	}

	/**
	 * @param string $option Option key.
	 * @param string $default Default.
	 * @return string
	 */
	private static function get_string( $option, $default ) {
		$value = trim( (string) get_option( $option, '' ) );
		return $value !== '' ? $value : $default;
	}

	/**
	 * @param string $option Option key.
	 * @param string $default Default.
	 * @return string
	 */
	private static function get_text( $option, $default ) {
		$value = trim( (string) get_option( $option, '' ) );
		return $value !== '' ? $value : $default;
	}

	/**
	 * @param string      $option Option key.
	 * @param string|null $default Default URL.
	 * @return string
	 */
	private static function get_url( $option, $default = null ) {
		$value = trim( (string) get_option( $option, '' ) );
		if ( $value === '' ) {
			$value = null !== $default ? trim( (string) $default ) : '';
		}
		if ( $value === '' ) {
			return '';
		}
		return esc_url_raw( $value );
	}

	/**
	 * @return string
	 */
	private static function default_intro() {
		return __(
			'We need your continued support to help us change attitudes towards disability and amplify the voices of persons with disabilities through accessible community radio. Every contribution helps us continue creating inclusive content, empowering communities, and building equal participation in society.',
			'radioudaan-app-api'
		);
	}

	/**
	 * @return string
	 */
	private static function default_accessibility_note() {
		return __(
			'Accessibility Note: Screen reader users are advised to use NVDA for a better online payment experience.',
			'radioudaan-app-api'
		);
	}
}

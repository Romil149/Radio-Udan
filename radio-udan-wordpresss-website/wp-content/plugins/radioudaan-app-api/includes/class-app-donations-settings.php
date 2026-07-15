<?php
/**
 * Razorpay + 80G donation settings for the mobile Donate screen.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * WP options for online donations (keys never exposed in public config except key_id).
 */
class RadioUdaan_App_Donations_Settings {

	const OPTION_RAZORPAY_ENABLED              = 'radioudaan_donate_razorpay_enabled';
	const OPTION_RAZORPAY_KEY_ID               = 'radioudaan_donate_razorpay_key_id';
	const OPTION_RAZORPAY_KEY_SECRET           = 'radioudaan_donate_razorpay_key_secret';
	const OPTION_RAZORPAY_WEBHOOK_SECRET       = 'radioudaan_donate_razorpay_webhook_secret';
	const OPTION_RAZORPAY_CHECKOUT_NAME        = 'radioudaan_donate_razorpay_checkout_name';
	const OPTION_RAZORPAY_PRESET_AMOUNTS       = 'radioudaan_donate_razorpay_preset_amounts';
	const OPTION_IOS_SAFARI_PAYMENT_URL        = 'radioudaan_donate_ios_safari_payment_url';
	const OPTION_80G_ENABLED                   = 'radioudaan_donate_80g_enabled';
	const OPTION_80G_PDF_EMAIL                 = 'radioudaan_donate_80g_pdf_email';
	const OPTION_80G_REG_NUMBER                = 'radioudaan_donate_80g_reg_number';
	const OPTION_80G_LEGAL_TEXT                = 'radioudaan_donate_80g_legal_text';
	const OPTION_80G_TRUST_PAN                 = 'radioudaan_donate_80g_trust_pan';
	const OPTION_80G_SIGNATORY_ATTACHMENT_ID   = 'radioudaan_donate_80g_signatory_attachment_id';

	const DEFAULT_PRESET_AMOUNTS         = '100,500,1000,5000';
	const DEFAULT_IOS_SAFARI_PAYMENT_URL = 'https://rzp.io/rzp/dswNW5g';

	/**
	 * @return bool
	 */
	public static function is_razorpay_enabled() {
		return (bool) get_option( self::OPTION_RAZORPAY_ENABLED, 0 );
	}

	/**
	 * @return bool
	 */
	public static function is_80g_enabled() {
		return (bool) get_option( self::OPTION_80G_ENABLED, 0 );
	}

	/**
	 * @return bool
	 */
	public static function is_80g_pdf_email_enabled() {
		return self::is_80g_enabled() && (bool) get_option( self::OPTION_80G_PDF_EMAIL, 0 );
	}

	/**
	 * @return string
	 */
	public static function get_key_id() {
		return trim( (string) get_option( self::OPTION_RAZORPAY_KEY_ID, '' ) );
	}

	/**
	 * @return string
	 */
	public static function get_key_secret() {
		return trim( (string) get_option( self::OPTION_RAZORPAY_KEY_SECRET, '' ) );
	}

	/**
	 * @return string
	 */
	public static function get_webhook_secret() {
		return trim( (string) get_option( self::OPTION_RAZORPAY_WEBHOOK_SECRET, '' ) );
	}

	/**
	 * @return bool
	 */
	public static function is_configured() {
		return self::is_razorpay_enabled()
			&& '' !== self::get_key_id()
			&& '' !== self::get_key_secret();
	}

	/**
	 * @return string
	 */
	public static function get_checkout_name() {
		$name = trim( (string) get_option( self::OPTION_RAZORPAY_CHECKOUT_NAME, '' ) );
		if ( '' !== $name ) {
			return $name;
		}
		$fallback = trim( (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_ACCOUNT_NAME, '' ) );
		return '' !== $fallback ? $fallback : 'Radio Udaan';
	}

	/**
	 * @return array<int,int>
	 */
	public static function get_preset_amounts() {
		$raw = trim( (string) get_option( self::OPTION_RAZORPAY_PRESET_AMOUNTS, self::DEFAULT_PRESET_AMOUNTS ) );
		if ( '' === $raw ) {
			$raw = self::DEFAULT_PRESET_AMOUNTS;
		}
		$parts = preg_split( '/\s*,\s*/', $raw );
		$out   = array();
		foreach ( $parts as $part ) {
			$amount = (int) $part;
			if ( $amount > 0 ) {
				$out[] = $amount;
			}
		}
		return ! empty( $out ) ? array_values( array_unique( $out ) ) : array( 100, 500, 1000, 5000 );
	}

	/**
	 * Payment page opened in Safari on iPhone (App Store compliance).
	 * Not used for Android native checkout.
	 *
	 * @return string
	 */
	public static function get_ios_safari_payment_url() {
		$url = trim( (string) get_option( self::OPTION_IOS_SAFARI_PAYMENT_URL, '' ) );
		if ( '' === $url ) {
			return self::DEFAULT_IOS_SAFARI_PAYMENT_URL;
		}
		return esc_url_raw( $url );
	}

	/**
	 * Public slice for GET /config.
	 *
	 * @return array<string,mixed>
	 */
	public static function get_public_config() {
		if ( ! self::is_configured() ) {
			return array(
				'enabled'                    => false,
				'key_id'                     => '',
				'checkout_name'              => '',
				'preset_amounts'             => array(),
				'eighty_g_enabled'           => false,
				'eighty_g_pdf_email_enabled' => false,
				'ios_safari_payment_url'     => self::get_ios_safari_payment_url(),
			);
		}

		return array(
			'enabled'                    => true,
			'key_id'                     => self::get_key_id(),
			'checkout_name'              => self::get_checkout_name(),
			'preset_amounts'             => self::get_preset_amounts(),
			'eighty_g_enabled'           => self::is_80g_enabled(),
			'eighty_g_pdf_email_enabled' => self::is_80g_pdf_email_enabled(),
			'ios_safari_payment_url'     => self::get_ios_safari_payment_url(),
		);
	}

	/**
	 * @return string
	 */
	public static function get_80g_reg_number() {
		return trim( (string) get_option( self::OPTION_80G_REG_NUMBER, '' ) );
	}

	/**
	 * @return string
	 */
	public static function get_80g_legal_text() {
		return trim( (string) get_option( self::OPTION_80G_LEGAL_TEXT, '' ) );
	}

	/**
	 * @return string
	 */
	public static function get_80g_trust_pan() {
		return strtoupper( trim( (string) get_option( self::OPTION_80G_TRUST_PAN, '' ) ) );
	}

	/**
	 * @return string
	 */
	public static function get_80g_signatory_url() {
		$id = (int) get_option( self::OPTION_80G_SIGNATORY_ATTACHMENT_ID, 0 );
		if ( $id < 1 ) {
			return '';
		}
		$url = wp_get_attachment_image_url( $id, 'medium' );
		return $url ? esc_url_raw( $url ) : '';
	}

	/**
	 * @param string $pan Raw PAN.
	 * @return bool
	 */
	public static function is_valid_pan( $pan ) {
		$pan = strtoupper( preg_replace( '/\s+/', '', (string) $pan ) );
		return (bool) preg_match( '/^[A-Z]{5}[0-9]{4}[A-Z]$/', $pan );
	}

	/**
	 * @param string $pan Raw PAN.
	 * @return string
	 */
	public static function normalize_pan( $pan ) {
		return strtoupper( preg_replace( '/\s+/', '', (string) $pan ) );
	}

	/**
	 * @param string $pan Plain PAN.
	 * @return string
	 */
	public static function encrypt_pan( $pan ) {
		$pan = self::normalize_pan( $pan );
		if ( '' === $pan ) {
			return '';
		}
		$key = hash( 'sha256', wp_salt( 'auth' ), true );
		$iv  = random_bytes( 16 );
		$enc = openssl_encrypt( $pan, 'AES-256-CBC', $key, OPENSSL_RAW_DATA, $iv );
		if ( false === $enc ) {
			return '';
		}
		return base64_encode( $iv . $enc );
	}

	/**
	 * @param string $encrypted Stored value.
	 * @return string
	 */
	public static function decrypt_pan( $encrypted ) {
		$raw = base64_decode( (string) $encrypted, true );
		if ( false === $raw || strlen( $raw ) < 17 ) {
			return '';
		}
		$key = hash( 'sha256', wp_salt( 'auth' ), true );
		$iv  = substr( $raw, 0, 16 );
		$enc = substr( $raw, 16 );
		$pan = openssl_decrypt( $enc, 'AES-256-CBC', $key, OPENSSL_RAW_DATA, $iv );
		return is_string( $pan ) ? self::normalize_pan( $pan ) : '';
	}

	/**
	 * @param string $pan Plain PAN.
	 * @return string
	 */
	public static function mask_pan( $pan ) {
		$pan = self::normalize_pan( $pan );
		if ( strlen( $pan ) !== 10 ) {
			return '';
		}
		return substr( $pan, 0, 5 ) . '****' . substr( $pan, 9, 1 );
	}
}

<?php
/**
 * Razorpay Orders API client (server-side only).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Creates orders, payment links, and verifies signatures.
 */
class RadioUdaan_App_Razorpay_Client {

	const API_BASE = 'https://api.razorpay.com/v1/';

	/**
	 * @param int                  $amount_paise Amount in paise.
	 * @param string               $receipt      Receipt id.
	 * @param array<string,string> $notes        Metadata.
	 * @return array<string,mixed>|WP_Error
	 */
	public static function create_order( $amount_paise, $receipt, array $notes = array() ) {
		$body = array(
			'amount'   => (int) $amount_paise,
			'currency' => 'INR',
			'receipt'  => substr( sanitize_text_field( (string) $receipt ), 0, 40 ),
			'notes'    => self::stringify_notes( $notes ),
		);
		return self::request( 'POST', 'orders', $body );
	}

	/**
	 * Hosted checkout link for iOS Safari flow.
	 *
	 * @param int                  $amount_paise      Amount.
	 * @param array<string,string> $customer          name, email, contact.
	 * @param string               $reference_id      Reference.
	 * @param array<string,string> $notes             Notes.
	 * @param string               $callback_order_id Optional order id for deep-link return.
	 * @return array<string,mixed>|WP_Error
	 */
	public static function create_payment_link( $amount_paise, array $customer, $reference_id, array $notes = array(), $callback_order_id = '' ) {
		$name    = sanitize_text_field( (string) ( $customer['name'] ?? '' ) );
		$email   = sanitize_email( (string) ( $customer['email'] ?? '' ) );
		$contact = sanitize_text_field( (string) ( $customer['contact'] ?? '' ) );

		$customer_body = array();
		if ( '' !== $name ) {
			$customer_body['name'] = $name;
		}
		if ( '' !== $email ) {
			$customer_body['email'] = $email;
		}
		if ( '' !== $contact ) {
			$customer_body['contact'] = $contact;
		}

		// Never set notify.email=true without an email — Razorpay rejects the link.
		$callback = 'radioudaan://donate/verify';
		$order_id = sanitize_text_field( (string) $callback_order_id );
		if ( '' !== $order_id ) {
			$callback .= '?order_id=' . rawurlencode( $order_id );
		}

		$body = array(
			'amount'          => (int) $amount_paise,
			'currency'        => 'INR',
			'accept_partial'  => false,
			'reference_id'    => substr( sanitize_text_field( (string) $reference_id ), 0, 40 ),
			'description'     => __( 'Donation to Radio Udaan', 'radioudaan-app-api' ),
			'notify'          => array(
				'sms'   => false,
				'email' => '' !== $email,
			),
			'reminder_enable' => false,
			'callback_url'    => $callback,
			'callback_method' => 'get',
			'notes'           => self::stringify_notes( $notes ),
		);
		if ( ! empty( $customer_body ) ) {
			$body['customer'] = $customer_body;
		}
		return self::request( 'POST', 'payment_links', $body );
	}

	/**
	 * @param string $order_id Order id.
	 * @return array<string,mixed>|WP_Error
	 */
	public static function fetch_order( $order_id ) {
		return self::request( 'GET', 'orders/' . rawurlencode( sanitize_text_field( (string) $order_id ) ) );
	}

	/**
	 * @param string $order_id Order id.
	 * @return array<string,mixed>|WP_Error
	 */
	public static function fetch_order_payments( $order_id ) {
		return self::request(
			'GET',
			'orders/' . rawurlencode( sanitize_text_field( (string) $order_id ) ) . '/payments'
		);
	}

	/**
	 * @param string $payment_link_id Payment link id.
	 * @return array<string,mixed>|WP_Error
	 */
	public static function fetch_payment_link( $payment_link_id ) {
		return self::request(
			'GET',
			'payment_links/' . rawurlencode( sanitize_text_field( (string) $payment_link_id ) )
		);
	}

	/**
	 * @param string $order_id   Order id.
	 * @param string $payment_id Payment id.
	 * @param string $signature  Signature.
	 * @return bool
	 */
	public static function verify_payment_signature( $order_id, $payment_id, $signature ) {
		$secret = RadioUdaan_App_Donations_Settings::get_key_secret();
		if ( '' === $secret ) {
			return false;
		}
		$payload   = sanitize_text_field( (string) $order_id ) . '|' . sanitize_text_field( (string) $payment_id );
		$expected  = hash_hmac( 'sha256', $payload, $secret );
		return hash_equals( $expected, (string) $signature );
	}

	/**
	 * @param string $body      Raw body.
	 * @param string $signature Header signature.
	 * @return bool
	 */
	public static function verify_webhook_signature( $body, $signature ) {
		$secret = RadioUdaan_App_Donations_Settings::get_webhook_secret();
		if ( '' === $secret || '' === $signature ) {
			return false;
		}
		$expected = hash_hmac( 'sha256', (string) $body, $secret );
		return hash_equals( $expected, (string) $signature );
	}

	/**
	 * @param string               $method HTTP method.
	 * @param string               $path   API path.
	 * @param array<string,mixed>|null $body Body.
	 * @return array<string,mixed>|WP_Error
	 */
	private static function request( $method, $path, $body = null ) {
		$key_id     = RadioUdaan_App_Donations_Settings::get_key_id();
		$key_secret = RadioUdaan_App_Donations_Settings::get_key_secret();
		if ( '' === $key_id || '' === $key_secret ) {
			return new WP_Error( 'razorpay_not_configured', __( 'Online donations are not configured.', 'radioudaan-app-api' ), array( 'status' => 503 ) );
		}

		$args = array(
			'method'  => $method,
			'timeout' => 20,
			'headers' => array(
				'Authorization' => 'Basic ' . base64_encode( $key_id . ':' . $key_secret ),
				'Content-Type'  => 'application/json',
			),
		);
		if ( null !== $body ) {
			$args['body'] = wp_json_encode( $body );
		}

		$response = wp_remote_request( self::API_BASE . ltrim( $path, '/' ), $args );
		if ( is_wp_error( $response ) ) {
			return $response;
		}

		$code = (int) wp_remote_retrieve_response_code( $response );
		$raw  = wp_remote_retrieve_body( $response );
		$data = json_decode( $raw, true );
		if ( $code < 200 || $code >= 300 ) {
			$message = is_array( $data ) && isset( $data['error']['description'] )
				? (string) $data['error']['description']
				: __( 'Payment provider error.', 'radioudaan-app-api' );
			return new WP_Error( 'razorpay_api_error', $message, array( 'status' => 502 ) );
		}

		return is_array( $data ) ? $data : array();
	}

	/**
	 * @param array<string,mixed> $notes Notes.
	 * @return array<string,string>
	 */
	private static function stringify_notes( array $notes ) {
		$out = array();
		foreach ( $notes as $key => $value ) {
			$out[ sanitize_key( (string) $key ) ] = sanitize_text_field( (string) $value );
		}
		return $out;
	}
}

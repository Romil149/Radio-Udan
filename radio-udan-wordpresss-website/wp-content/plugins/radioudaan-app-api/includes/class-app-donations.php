<?php
/**
 * REST handlers for Razorpay donations.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Create orders, verify payments, and process webhooks.
 */
class RadioUdaan_App_Donations {

	/**
	 * Register hooks.
	 */
	public static function init() {
		RadioUdaan_App_Donations_Db::init();
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function create_order( WP_REST_Request $request ) {
		if ( ! RadioUdaan_App_Donations_Settings::is_configured() ) {
			return new WP_Error( 'donations_disabled', __( 'Online donations are not available.', 'radioudaan-app-api' ), array( 'status' => 503 ) );
		}

		$ip_key = 'donate_order:' . RadioUdaan_Rate_Limiter::get_client_ip();
		if ( RadioUdaan_Rate_Limiter::is_limited( $ip_key, 20, 3600 ) ) {
			return new WP_Error( 'rate_limited', __( 'Too many donation attempts. Please try again later.', 'radioudaan-app-api' ), array( 'status' => 429 ) );
		}
		RadioUdaan_Rate_Limiter::bump( $ip_key, 3600 );

		$amount_paise = (int) $request->get_param( 'amount_paise' );
		if ( $amount_paise < 100 ) {
			return new WP_Error( 'invalid_amount', __( 'Enter a valid donation amount.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		$want_80g = ! empty( $request->get_param( 'want_80g' ) );
		$pan      = RadioUdaan_App_Donations_Settings::normalize_pan( (string) $request->get_param( 'pan' ) );

		if ( $want_80g && RadioUdaan_App_Donations_Settings::is_80g_enabled() ) {
			if ( ! RadioUdaan_App_Donations_Settings::is_valid_pan( $pan ) ) {
				return new WP_Error( 'invalid_pan', __( 'Enter a valid PAN for your 80G receipt.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
			}
		} else {
			$want_80g = false;
			$pan      = '';
		}

		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		$name    = sanitize_text_field( (string) $request->get_param( 'name' ) );
		$email   = sanitize_email( (string) $request->get_param( 'email' ) );
		$phone   = sanitize_text_field( (string) $request->get_param( 'phone' ) );

		if ( $user_id ) {
			$user = RadioUdaan_App_Users::get_by_id( $user_id );
			if ( $user ) {
				if ( '' === $name && ! empty( $user->display_name ) ) {
					$name = (string) $user->display_name;
				}
				if ( '' === $email && ! empty( $user->email ) ) {
					$email = (string) $user->email;
				}
				if ( '' === $phone ) {
					$phone = (string) $user->phone_e164;
				}
			}
		}

		$receipt = 'donate_' . time() . '_' . wp_rand( 1000, 9999 );
		$notes   = array(
			'source' => 'app',
		);
		if ( $user_id ) {
			$notes['user_id'] = (string) $user_id;
		}

		$order = RadioUdaan_App_Razorpay_Client::create_order( $amount_paise, $receipt, $notes );
		if ( is_wp_error( $order ) ) {
			return $order;
		}

		$order_id = isset( $order['id'] ) ? (string) $order['id'] : '';
		if ( '' === $order_id ) {
			return new WP_Error( 'order_failed', __( 'Could not start payment.', 'radioudaan-app-api' ), array( 'status' => 502 ) );
		}

		$donation_id = RadioUdaan_App_Donations_Db::insert(
			array(
				'user_id'           => $user_id,
				'razorpay_order_id' => $order_id,
				'amount_paise'      => $amount_paise,
				'currency'          => 'INR',
				'status'            => RadioUdaan_App_Donations_Db::STATUS_CREATED,
				'donor_name'        => $name,
				'email'             => $email,
				'phone'             => $phone,
				'want_80g'          => $want_80g,
				'pan_encrypted'     => $want_80g ? RadioUdaan_App_Donations_Settings::encrypt_pan( $pan ) : '',
			)
		);

		$payment_link_url = '';
		$payment_link_id  = '';
		// iOS / web use hosted Payment Link (Safari). Android uses native Checkout + order_id only.
		$platform = sanitize_key( (string) $request->get_param( 'platform' ) );
		if ( 'android' !== $platform ) {
			$link_notes = array_merge(
				$notes,
				array(
					'donation_id' => (string) $donation_id,
					'order_id'    => $order_id,
				)
			);
			$link = RadioUdaan_App_Razorpay_Client::create_payment_link(
				$amount_paise,
				array(
					'name'    => $name,
					'email'   => $email,
					'contact' => $phone,
				),
				'donation_' . $donation_id,
				$link_notes,
				$order_id
			);
			if ( is_wp_error( $link ) ) {
				RadioUdaan_App_Logger::log(
					'donation_payment_link_failed',
					array(
						'donation_id' => $donation_id,
						'code'        => $link->get_error_code(),
					)
				);
				if ( 'ios' === $platform || 'web' === $platform ) {
					return $link;
				}
			} else {
				$payment_link_url = isset( $link['short_url'] ) ? (string) $link['short_url'] : '';
				$payment_link_id  = isset( $link['id'] ) ? (string) $link['id'] : '';
				if ( '' !== $payment_link_id && $donation_id > 0 ) {
					RadioUdaan_App_Donations_Db::update_payment_link_id( $donation_id, $payment_link_id );
				}
				if ( ( 'ios' === $platform || 'web' === $platform ) && '' === $payment_link_url ) {
					return new WP_Error( 'payment_link_failed', __( 'Could not start payment.', 'radioudaan-app-api' ), array( 'status' => 502 ) );
				}
			}
		}

		RadioUdaan_App_Logger::log(
			'donation_order_created',
			array(
				'donation_id' => $donation_id,
				'amount_paise'=> $amount_paise,
				'want_80g'    => $want_80g ? 1 : 0,
			)
		);

		return new WP_REST_Response(
			array(
				'donation_id'      => $donation_id,
				'order_id'         => $order_id,
				'key_id'           => RadioUdaan_App_Donations_Settings::get_key_id(),
				'amount'           => $amount_paise,
				'currency'         => 'INR',
				'checkout_name'    => RadioUdaan_App_Donations_Settings::get_checkout_name(),
				'payment_link'     => $payment_link_url,
				'payment_link_id'  => $payment_link_id,
				'prefill'          => array(
					'name'    => $name,
					'email'   => $email,
					'contact' => $phone,
				),
			),
			200
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function verify_payment( WP_REST_Request $request ) {
		$order_id   = sanitize_text_field( (string) $request->get_param( 'razorpay_order_id' ) );
		$payment_id = sanitize_text_field( (string) $request->get_param( 'razorpay_payment_id' ) );
		$signature  = sanitize_text_field( (string) $request->get_param( 'razorpay_signature' ) );

		if ( '' === $order_id ) {
			return new WP_Error( 'invalid_request', __( 'Missing order id.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		$donation = RadioUdaan_App_Donations_Db::get_by_order_id( $order_id );
		if ( ! $donation ) {
			return new WP_Error( 'not_found', __( 'Donation not found.', 'radioudaan-app-api' ), array( 'status' => 404 ) );
		}

		if ( RadioUdaan_App_Donations_Db::STATUS_CAPTURED === $donation->status ) {
			return new WP_REST_Response(
				array(
					'success'     => true,
					'donation_id' => (int) $donation->id,
					'status'      => $donation->status,
				),
				200
			);
		}

		$verified = false;
		if ( '' !== $payment_id && '' !== $signature ) {
			$verified = RadioUdaan_App_Razorpay_Client::verify_payment_signature( $order_id, $payment_id, $signature );
		}

		if ( ! $verified ) {
			$payments = RadioUdaan_App_Razorpay_Client::fetch_order_payments( $order_id );
			if ( ! is_wp_error( $payments ) && ! empty( $payments['items'] ) && is_array( $payments['items'] ) ) {
				foreach ( $payments['items'] as $item ) {
					if ( ! is_array( $item ) ) {
						continue;
					}
					$status = isset( $item['status'] ) ? (string) $item['status'] : '';
					if ( in_array( $status, array( 'captured', 'authorized' ), true ) ) {
						$payment_id = isset( $item['id'] ) ? (string) $item['id'] : $payment_id;
						$verified   = true;
						break;
					}
				}
			}
		}

		if ( ! $verified && ! empty( $donation->payment_link_id ) ) {
			$link = RadioUdaan_App_Razorpay_Client::fetch_payment_link( (string) $donation->payment_link_id );
			if ( ! is_wp_error( $link ) ) {
				$link_status = isset( $link['status'] ) ? (string) $link['status'] : '';
				if ( in_array( $link_status, array( 'paid', 'partially_paid' ), true ) ) {
					$verified = true;
					if ( '' === $payment_id && ! empty( $link['payments'] ) && is_array( $link['payments'] ) ) {
						$first = $link['payments'][0];
						if ( is_array( $first ) && ! empty( $first['payment_id'] ) ) {
							$payment_id = (string) $first['payment_id'];
						} elseif ( is_array( $first ) && ! empty( $first['id'] ) ) {
							$payment_id = (string) $first['id'];
						} elseif ( is_string( $first ) ) {
							$payment_id = $first;
						}
					}
					// Payment Link can be paid before payment_id is present in the payload.
					if ( '' === $payment_id ) {
						$payment_id = 'plink:' . sanitize_text_field( (string) $donation->payment_link_id );
					}
				}
			}
		}

		if ( ! $verified ) {
			return new WP_REST_Response(
				array(
					'success' => false,
					'status'  => $donation->status,
				),
				200
			);
		}

		self::capture_donation( $donation, $payment_id );

		$donation = RadioUdaan_App_Donations_Db::get_by_id( (int) $donation->id );
		return new WP_REST_Response(
			array(
				'success'     => true,
				'donation_id' => (int) $donation->id,
				'status'      => $donation->status,
			),
			200
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function handle_webhook( WP_REST_Request $request ) {
		$body      = $request->get_body();
		$signature = $request->get_header( 'x-razorpay-signature' );
		if ( ! RadioUdaan_App_Razorpay_Client::verify_webhook_signature( $body, (string) $signature ) ) {
			return new WP_Error( 'invalid_signature', __( 'Invalid webhook signature.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$payload = json_decode( (string) $body, true );
		if ( ! is_array( $payload ) ) {
			return new WP_Error( 'invalid_payload', __( 'Invalid webhook payload.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		$event = isset( $payload['event'] ) ? (string) $payload['event'] : '';
		$entity = isset( $payload['payload']['payment']['entity'] ) && is_array( $payload['payload']['payment']['entity'] )
			? $payload['payload']['payment']['entity']
			: array();

		if ( 'payment.captured' === $event && ! empty( $entity['order_id'] ) ) {
			$order_id   = (string) $entity['order_id'];
			$payment_id = isset( $entity['id'] ) ? (string) $entity['id'] : '';
			$donation   = RadioUdaan_App_Donations_Db::get_by_order_id( $order_id );
			if ( $donation && RadioUdaan_App_Donations_Db::STATUS_CAPTURED !== $donation->status ) {
				self::capture_donation( $donation, $payment_id );
			}
		}

		if ( 'payment.captured' === $event && empty( $entity['order_id'] ) ) {
			$donation = self::find_donation_from_payment_notes( $entity );
			if ( $donation && RadioUdaan_App_Donations_Db::STATUS_CAPTURED !== $donation->status ) {
				$payment_id = isset( $entity['id'] ) ? (string) $entity['id'] : '';
				self::capture_donation( $donation, $payment_id );
			}
		}

		if ( 'payment_link.paid' === $event ) {
			$link_entity = isset( $payload['payload']['payment_link']['entity'] ) && is_array( $payload['payload']['payment_link']['entity'] )
				? $payload['payload']['payment_link']['entity']
				: array();
			$donation    = self::find_donation_from_link_entity( $link_entity );
			if ( $donation && RadioUdaan_App_Donations_Db::STATUS_CAPTURED !== $donation->status ) {
				$payment_id = '';
				if ( ! empty( $link_entity['payments'] ) && is_array( $link_entity['payments'] ) ) {
					$first = $link_entity['payments'][0];
					if ( is_array( $first ) && ! empty( $first['payment_id'] ) ) {
						$payment_id = (string) $first['payment_id'];
					} elseif ( is_string( $first ) ) {
						$payment_id = $first;
					}
				}
				self::capture_donation( $donation, $payment_id );
			}
		}

		if ( 'payment.failed' === $event && ! empty( $entity['order_id'] ) ) {
			$order_id   = (string) $entity['order_id'];
			$payment_id = isset( $entity['id'] ) ? (string) $entity['id'] : '';
			$donation   = RadioUdaan_App_Donations_Db::get_by_order_id( $order_id );
			if ( $donation && RadioUdaan_App_Donations_Db::STATUS_CAPTURED !== $donation->status ) {
				RadioUdaan_App_Donations_Db::mark_failed( (int) $donation->id, $payment_id );
			}
		}

		return new WP_REST_Response( array( 'ok' => true ), 200 );
	}

	/**
	 * @param object $donation   Row.
	 * @param string $payment_id Payment id.
	 */
	private static function capture_donation( $donation, $payment_id ) {
		if ( ! $donation || RadioUdaan_App_Donations_Db::STATUS_CAPTURED === $donation->status ) {
			return;
		}
		RadioUdaan_App_Donations_Db::mark_captured( (int) $donation->id, $payment_id );
		$donation = RadioUdaan_App_Donations_Db::get_by_id( (int) $donation->id );
		RadioUdaan_App_Donations_80g_Pdf::maybe_send_receipt( $donation );
		RadioUdaan_App_Logger::log(
			'donation_captured',
			array(
				'donation_id' => (int) $donation->id,
				'amount_paise'=> (int) $donation->amount_paise,
			)
		);
	}

	/**
	 * @param array<string,mixed> $entity Payment entity.
	 * @return object|null
	 */
	private static function find_donation_from_payment_notes( array $entity ) {
		$notes = isset( $entity['notes'] ) && is_array( $entity['notes'] ) ? $entity['notes'] : array();
		if ( ! empty( $notes['donation_id'] ) ) {
			return RadioUdaan_App_Donations_Db::get_by_id( (int) $notes['donation_id'] );
		}
		if ( ! empty( $notes['order_id'] ) ) {
			return RadioUdaan_App_Donations_Db::get_by_order_id( (string) $notes['order_id'] );
		}
		return null;
	}

	/**
	 * @param array<string,mixed> $link_entity Payment link entity.
	 * @return object|null
	 */
	private static function find_donation_from_link_entity( array $link_entity ) {
		$notes = isset( $link_entity['notes'] ) && is_array( $link_entity['notes'] ) ? $link_entity['notes'] : array();
		if ( ! empty( $notes['donation_id'] ) ) {
			return RadioUdaan_App_Donations_Db::get_by_id( (int) $notes['donation_id'] );
		}
		if ( ! empty( $link_entity['id'] ) ) {
			return RadioUdaan_App_Donations_Db::get_by_payment_link_id( (string) $link_entity['id'] );
		}
		return null;
	}
}

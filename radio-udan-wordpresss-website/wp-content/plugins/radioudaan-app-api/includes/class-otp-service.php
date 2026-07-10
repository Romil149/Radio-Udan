<?php
/**
 * OTP request/verify (MSG91-ready) with purpose-aware flows.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * OTP façade with rate limits, verify attempt caps, and auth v2 purposes.
 */
class RadioUdaan_Otp_Service {

	const TRANSIENT_PREFIX = 'radioudaan_otp_';
	const OTP_TTL          = 300;

	const PURPOSE_LOGIN          = 'login';
	const PURPOSE_VERIFY_PHONE   = 'verify_phone';
	const PURPOSE_RESET_PASSWORD = 'reset_password';

	/**
	 * @param string               $phone_e164 E.164 phone.
	 * @param string               $purpose    login|verify_phone|reset_password.
	 * @param array<string,mixed>  $context    Optional metadata (e.g. user_id).
	 * @return array|WP_Error
	 */
	public static function request_otp( $phone_e164, $purpose = self::PURPOSE_LOGIN, array $context = array() ) {
		$phone = self::normalize_phone( $phone_e164 );
		if ( is_wp_error( $phone ) ) {
			return $phone;
		}

		if ( ! self::expose_dev_otp()
			&& class_exists( 'RadioUdaan_Otp_Msg91' )
			&& RadioUdaan_Otp_Msg91::is_configured()
			&& 0 !== strpos( $phone, '+91' )
		) {
			return new WP_Error(
				'otp_sms_unsupported_country',
				__(
					'Text message codes are only available for India mobile numbers, country code plus nine one. Sign in with your email and password instead, or use forgot password with your email address.',
					'radioudaan-app-api'
				),
				array( 'status' => 400 )
			);
		}

		$purpose = self::sanitize_purpose( $purpose );
		if ( is_wp_error( $purpose ) ) {
			return $purpose;
		}

		$precheck = self::precheck_purpose( $phone, $purpose );
		if ( is_wp_error( $precheck ) ) {
			return $precheck;
		}

		$resend_key = 'otp_resend_' . md5( $phone . '_' . $purpose );
		$last_sent  = (int) get_transient( $resend_key );
		$delay      = RadioUdaan_App_Settings::get_otp_resend_delay_sec();
		if ( $last_sent && ( time() - $last_sent ) < $delay ) {
			return new WP_Error(
				'otp_resend_wait',
				sprintf(
					/* translators: %d: seconds */
					__( 'Please wait %d seconds before requesting another code.', 'radioudaan-app-api' ),
					$delay - ( time() - $last_sent )
				),
				array( 'status' => 429 )
			);
		}

		if ( RadioUdaan_Rate_Limiter::is_limited(
			'otp_phone_' . $phone,
			RadioUdaan_App_Settings::get_otp_limit_per_hour(),
			HOUR_IN_SECONDS
		) ) {
			RadioUdaan_App_Logger::log( 'otp_rate_limited', array() );
			return new WP_Error(
				'otp_rate_limited',
				__( 'Too many OTP requests. Try again later.', 'radioudaan-app-api' ),
				array( 'status' => 429 )
			);
		}

		$ip = RadioUdaan_Rate_Limiter::get_client_ip();
		if ( RadioUdaan_Rate_Limiter::is_limited( 'otp_ip_' . $ip, 30, HOUR_IN_SECONDS ) ) {
			return new WP_Error(
				'otp_rate_limited',
				__( 'Too many OTP requests from this network.', 'radioudaan-app-api' ),
				array( 'status' => 429 )
			);
		}

		RadioUdaan_Rate_Limiter::bump( 'otp_phone_' . $phone, HOUR_IN_SECONDS );
		RadioUdaan_Rate_Limiter::bump( 'otp_ip_' . $ip, HOUR_IN_SECONDS );
		set_transient( $resend_key, time(), $delay );

		$request_id = 'otp_' . wp_generate_password( 16, false, false );
		$otp        = self::generate_otp();

		$user = RadioUdaan_App_Users::find_by_phone( $phone );
		if ( $user ) {
			$context['user_id'] = (int) $user->id;
		}

		set_transient(
			self::TRANSIENT_PREFIX . $request_id,
			array(
				'phone'    => $phone,
				'otp'      => $otp,
				'attempts' => 0,
				'purpose'  => $purpose,
				'context'  => $context,
			),
			self::OTP_TTL
		);

		$sent = self::dispatch_otp( $phone, $otp );
		if ( is_wp_error( $sent ) ) {
			return $sent;
		}

		$response = array(
			'request_id'       => $request_id,
			'expires_in_sec'   => self::OTP_TTL,
			'resend_after_sec' => $delay,
			'purpose'          => $purpose,
		);

		if ( self::expose_dev_otp() ) {
			$response['dev_otp'] = $otp;
		}

		return $response;
	}

	/**
	 * @param string $request_id Request id.
	 * @param string $otp        OTP code.
	 * @param string $purpose    Optional purpose override (must match stored).
	 * @return array|WP_Error
	 */
	public static function verify_otp( $request_id, $otp, $purpose = '' ) {
		$request_id = sanitize_text_field( $request_id );
		$otp        = sanitize_text_field( $otp );

		if ( ! $request_id || ! $otp ) {
			return new WP_Error(
				'otp_invalid',
				__( 'Request ID and OTP are required.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$stored = get_transient( self::TRANSIENT_PREFIX . $request_id );
		if ( ! is_array( $stored ) ) {
			return new WP_Error(
				'otp_expired',
				__( 'OTP expired or invalid request.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$stored_purpose = isset( $stored['purpose'] ) ? $stored['purpose'] : self::PURPOSE_LOGIN;
		if ( $purpose ) {
			$purpose = self::sanitize_purpose( $purpose );
			if ( is_wp_error( $purpose ) ) {
				return $purpose;
			}
			if ( $purpose !== $stored_purpose ) {
				return new WP_Error(
					'otp_purpose_mismatch',
					__( 'OTP purpose does not match this request.', 'radioudaan-app-api' ),
					array( 'status' => 400 )
				);
			}
		}

		$attempts = isset( $stored['attempts'] ) ? (int) $stored['attempts'] : 0;
		$max      = RadioUdaan_App_Settings::get_otp_verify_max_attempts();

		if ( $attempts >= $max ) {
			delete_transient( self::TRANSIENT_PREFIX . $request_id );
			return new WP_Error(
				'otp_attempts_exceeded',
				__( 'Too many incorrect attempts. Request a new code.', 'radioudaan-app-api' ),
				array( 'status' => 429 )
			);
		}

		if ( ! hash_equals( (string) $stored['otp'], $otp ) ) {
			$stored['attempts'] = $attempts + 1;
			set_transient( self::TRANSIENT_PREFIX . $request_id, $stored, self::OTP_TTL );
			RadioUdaan_App_Logger::log( 'otp_verify_failed', array( 'request_id' => $request_id ) );
			return new WP_Error(
				'otp_invalid',
				__( 'Incorrect OTP.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		delete_transient( self::TRANSIENT_PREFIX . $request_id );

		$phone   = $stored['phone'];
		$context = isset( $stored['context'] ) && is_array( $stored['context'] ) ? $stored['context'] : array();

		RadioUdaan_App_Logger::log( 'otp_verify_ok', array( 'purpose' => $stored_purpose ) );

		return self::complete_verify( $phone, $stored_purpose, $context, $otp );
	}

	/**
	 * @param string              $phone   E.164 phone.
	 * @param string              $purpose Purpose.
	 * @param array<string,mixed> $context Context from request.
	 * @param string              $otp     Plain OTP (reset_password only).
	 * @return array|WP_Error
	 */
	private static function complete_verify( $phone, $purpose, array $context, $otp ) {
		$user = RadioUdaan_App_Users::find_by_phone_for_auth( $phone );

		if ( self::is_paused_user( $user ) ) {
			return RadioUdaan_App_Users::account_paused_error();
		}

		if ( self::PURPOSE_VERIFY_PHONE === $purpose ) {
			if ( ! $user ) {
				return new WP_Error(
					'user_not_found',
					__( 'No account found for this mobile number.', 'radioudaan-app-api' ),
					array( 'status' => 404 )
				);
			}

			if ( RadioUdaan_App_Users::STATUS_PENDING === $user->status ) {
				return RadioUdaan_App_Password_Auth::activate_after_phone_verify( (int) $user->id );
			}

			if ( RadioUdaan_App_Users::STATUS_ACTIVE === $user->status && (int) $user->phone_verified ) {
				return RadioUdaan_App_Password_Auth::issue_session_for_user( $user );
			}

			return new WP_Error(
				'phone_verify_failed',
				__( 'Could not verify this mobile number.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		if ( self::PURPOSE_LOGIN === $purpose ) {
			if ( ! $user || RadioUdaan_App_Users::STATUS_ACTIVE !== $user->status ) {
				return new WP_Error(
					'account_inactive',
					__( 'No active account for this mobile number.', 'radioudaan-app-api' ),
					array( 'status' => 403 )
				);
			}

			if ( ! (int) $user->phone_verified ) {
				return new WP_Error(
					'phone_not_verified',
					__( 'Verify your mobile number to continue.', 'radioudaan-app-api' ),
					array( 'status' => 403 )
				);
			}

			// Email verification is manual: only sent when the user taps
			// "Send verification code" on the Verify Email screen. Login never
			// auto-sends an email code.
			return RadioUdaan_App_Password_Auth::issue_session_for_user( $user );
		}

		if ( self::PURPOSE_RESET_PASSWORD === $purpose ) {
			if ( ! $user || RadioUdaan_App_Users::STATUS_ACTIVE !== $user->status ) {
				return new WP_Error(
					'reset_invalid',
					__( 'Reset is not available for this number.', 'radioudaan-app-api' ),
					array( 'status' => 400 )
				);
			}

			if ( ! (int) $user->phone_verified ) {
				return new WP_Error(
					'reset_invalid',
					__( 'Reset is not available for this number.', 'radioudaan-app-api' ),
					array( 'status' => 400 )
				);
			}

			RadioUdaan_App_Password_Auth::store_phone_reset_otp( (int) $user->id, $phone, $otp );

			return array(
				'status'      => 'otp_verified',
				'purpose'     => $purpose,
				'phone_e164'  => $phone,
				'reset_ready' => true,
			);
		}

		return new WP_Error(
			'otp_invalid_purpose',
			__( 'Unknown OTP purpose.', 'radioudaan-app-api' ),
			array( 'status' => 400 )
		);
	}

	/**
	 * @param string $phone   Phone.
	 * @param string $purpose Purpose.
	 * @return true|WP_Error
	 */
	private static function precheck_purpose( $phone, $purpose ) {
		$user = RadioUdaan_App_Users::find_by_phone_for_auth( $phone );

		if ( self::is_paused_user( $user ) ) {
			return RadioUdaan_App_Users::account_paused_error();
		}

		if ( self::PURPOSE_LOGIN === $purpose ) {
			if ( ! $user || RadioUdaan_App_Users::STATUS_ACTIVE !== $user->status ) {
				return new WP_Error(
					'account_inactive',
					__( 'No active account for this mobile number.', 'radioudaan-app-api' ),
					array( 'status' => 403 )
				);
			}
		}

		if ( self::PURPOSE_VERIFY_PHONE === $purpose ) {
			if ( ! $user ) {
				return new WP_Error(
					'user_not_found',
					__( 'Register first, then verify your mobile number.', 'radioudaan-app-api' ),
					array( 'status' => 404 )
				);
			}
			if ( RadioUdaan_App_Users::STATUS_DELETED === $user->status ) {
				return new WP_Error(
					'account_deleted',
					__( 'This account was deleted.', 'radioudaan-app-api' ),
					array( 'status' => 403 )
				);
			}
		}

		if ( self::PURPOSE_RESET_PASSWORD === $purpose ) {
			if ( ! $user
				|| RadioUdaan_App_Users::STATUS_ACTIVE !== $user->status
				|| ! (int) $user->phone_verified ) {
				// Generic OK at forgot-password; direct OTP request may return this error.
				return new WP_Error(
					'reset_unavailable',
					__( 'Password reset is not available for this number.', 'radioudaan-app-api' ),
					array( 'status' => 400 )
				);
			}
		}

		return true;
	}

	/**
	 * @param object|null $user App user row.
	 * @return bool
	 */
	private static function is_paused_user( $user ) {
		return RadioUdaan_App_Users::is_paused( $user );
	}

	/**
	 * @param string $purpose Raw purpose.
	 * @return string|WP_Error
	 */
	private static function sanitize_purpose( $purpose ) {
		$purpose = sanitize_key( (string) $purpose );
		$allowed = array(
			self::PURPOSE_LOGIN,
			self::PURPOSE_VERIFY_PHONE,
			self::PURPOSE_RESET_PASSWORD,
		);

		if ( ! in_array( $purpose, $allowed, true ) ) {
			return new WP_Error(
				'otp_purpose_invalid',
				__( 'Invalid OTP purpose.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		return $purpose;
	}

	/**
	 * @param string $phone Phone.
	 * @return string|WP_Error
	 */
	private static function normalize_phone( $phone ) {
		$phone = preg_replace( '/\s+/', '', (string) $phone );
		if ( ! preg_match( '/^\+[1-9]\d{7,14}$/', $phone ) ) {
			return new WP_Error(
				'phone_invalid',
				__( 'Phone must be E.164 format, e.g. +919876543210.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		return $phone;
	}

	/**
	 * @return string
	 */
	private static function generate_otp() {
		if ( self::expose_dev_otp() ) {
			return '123456';
		}

		return (string) wp_rand( 100000, 999999 );
	}

	/**
	 * @return bool
	 */
	public static function expose_dev_otp_public() {
		return self::expose_dev_otp();
	}

	/**
	 * @return bool
	 */
	private static function expose_dev_otp() {
		return RadioUdaan_App_Settings::is_dev_otp_enabled();
	}

	/**
	 * @param string $phone Phone.
	 * @param string $otp   Code.
	 * @return true|WP_Error
	 */
	private static function dispatch_otp( $phone, $otp ) {
		do_action( 'radioudaan_app_api_send_otp', $phone, $otp );
		return true;
	}
}

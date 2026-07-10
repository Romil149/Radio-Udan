<?php
/**
 * Password + email auth for app accounts (v2).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-mailer.php';

/**
 * Registration, login, forgot/reset password, email verification.
 */
class RadioUdaan_App_Password_Auth {

	const EMAIL_CODE_TTL       = 900;
	const RESET_TOKEN_TTL      = 3600;
	const TRANSIENT_EMAIL_CODE = 'radioudaan_email_code_';
	const TRANSIENT_RESET      = 'radioudaan_pwd_reset_';

	/**
	 * @param array<string,mixed> $body Request JSON.
	 * @return array|WP_Error
	 */
	public static function register( array $body ) {
		$ip = RadioUdaan_Rate_Limiter::get_client_ip();
		if ( RadioUdaan_Rate_Limiter::is_limited( 'register_ip_' . $ip, 10, HOUR_IN_SECONDS ) ) {
			return new WP_Error(
				'rate_limited',
				__( 'Too many registration attempts. Please try again later.', 'radioudaan-app-api' ),
				array( 'status' => 429 )
			);
		}

		$name     = isset( $body['name'] ) ? sanitize_text_field( $body['name'] ) : '';
		$email    = isset( $body['email'] ) ? strtolower( sanitize_email( $body['email'] ) ) : '';
		$phone    = isset( $body['phone_e164'] ) ? self::normalize_phone( $body['phone_e164'] ) : '';
		$password = isset( $body['password'] ) ? (string) $body['password'] : '';

		if ( strlen( $name ) < 2 ) {
			return new WP_Error( 'name_invalid', __( 'Name is required.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}
		if ( ! is_email( $email ) ) {
			return new WP_Error( 'email_invalid', __( 'Valid email is required.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}
		if ( is_wp_error( $phone ) ) {
			return $phone;
		}
		$min = RadioUdaan_App_Settings::get_password_min_length();
		if ( strlen( $password ) < $min ) {
			return new WP_Error(
				'password_too_short',
				sprintf(
					/* translators: %d: minimum length */
					__( 'Password must be at least %d characters.', 'radioudaan-app-api' ),
					$min
				),
				array( 'status' => 400 )
			);
		}

		if ( RadioUdaan_Rate_Limiter::is_limited( 'register_phone_' . $phone, 5, HOUR_IN_SECONDS ) ) {
			return new WP_Error(
				'rate_limited',
				__( 'Too many registration attempts for this number. Please try again later.', 'radioudaan-app-api' ),
				array( 'status' => 429 )
			);
		}

		RadioUdaan_App_Users::purge_stale_pending_phone( $phone );

		if ( RadioUdaan_App_Users::phone_taken( $phone ) ) {
			return new WP_Error( 'phone_taken', __( 'This mobile number is already registered.', 'radioudaan-app-api' ), array( 'status' => 409 ) );
		}
		if ( RadioUdaan_App_Users::email_taken( $email ) ) {
			return new WP_Error( 'email_taken', __( 'This email is already registered.', 'radioudaan-app-api' ), array( 'status' => 409 ) );
		}

		$user_id = RadioUdaan_App_Users::create_pending(
			array(
				'display_name'  => $name,
				'email'         => $email,
				'phone_e164'    => $phone,
				'password_hash' => wp_hash_password( $password ),
			)
		);

		if ( ! $user_id ) {
			if ( ! RadioUdaan_App_Users::schema_ready() ) {
				return new WP_Error(
					'app_users_table_missing',
					__( 'Registration is temporarily unavailable on the server. Please try again in a few minutes or contact Radio Udaan support.', 'radioudaan-app-api' ),
					array( 'status' => 503 )
				);
			}

			return new WP_Error( 'register_failed', __( 'Could not create account.', 'radioudaan-app-api' ), array( 'status' => 500 ) );
		}

		RadioUdaan_Rate_Limiter::bump( 'register_ip_' . $ip, HOUR_IN_SECONDS );
		RadioUdaan_Rate_Limiter::bump( 'register_phone_' . $phone, HOUR_IN_SECONDS );

		RadioUdaan_App_Logger::log( 'register_pending', array( 'user_id' => $user_id ) );

		return array(
			'status'                   => 'pending_phone_verification',
			'needs_phone_verification' => true,
			'phone_e164'               => $phone,
			'user'                     => self::format_user( RadioUdaan_App_Users::get_by_id( $user_id ) ),
		);
	}

	/**
	 * @param array<string,mixed> $body Request JSON.
	 * @return array|WP_Error
	 */
	public static function login( array $body ) {
		$identifier = isset( $body['identifier'] ) ? trim( (string) $body['identifier'] ) : '';
		$password   = isset( $body['password'] ) ? (string) $body['password'] : '';

		if ( ! $identifier || ! $password ) {
			return new WP_Error( 'credentials_required', __( 'Identifier and password are required.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		$user = RadioUdaan_App_Users::find_by_identifier_for_auth( $identifier );
		if ( ! $user ) {
			return new WP_Error( 'invalid_credentials', __( 'Invalid email, mobile, or password.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}
		if ( RadioUdaan_App_Users::is_paused( $user ) ) {
			return RadioUdaan_App_Users::account_paused_error();
		}
		if ( 'active' !== $user->status ) {
			return new WP_Error( 'invalid_credentials', __( 'Invalid email, mobile, or password.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		if ( ! wp_check_password( $password, $user->password_hash ) ) {
			return new WP_Error( 'invalid_credentials', __( 'Invalid email, mobile, or password.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		if ( ! (int) $user->phone_verified ) {
			return new WP_Error( 'phone_not_verified', __( 'Verify your mobile number to continue.', 'radioudaan-app-api' ), array( 'status' => 403 ) );
		}

		// Email verification is manual: no code is sent at login. The user
		// requests it explicitly from the Verify Email screen.
		return self::issue_session_for_user( $user );
	}

	/**
	 * @param string $identifier Email or phone.
	 * @return array|WP_Error
	 */
	public static function forgot_password( $identifier ) {
		$user = RadioUdaan_App_Users::find_by_identifier( $identifier );
		if ( ! $user || 'active' !== $user->status ) {
			// Do not reveal whether account exists.
			return array( 'status' => 'ok' );
		}

		if ( strpos( $identifier, '@' ) !== false ) {
			return self::forgot_password_email( $user );
		}

		return self::forgot_password_phone( $user );
	}

	/**
	 * @param array<string,mixed> $body Request JSON.
	 * @return array|WP_Error
	 */
	public static function reset_password( array $body ) {
		$token    = isset( $body['token'] ) ? sanitize_text_field( $body['token'] ) : '';
		$password = isset( $body['password'] ) ? (string) $body['password'] : '';
		$otp      = isset( $body['otp'] ) ? sanitize_text_field( $body['otp'] ) : '';
		$phone    = isset( $body['phone_e164'] ) ? $body['phone_e164'] : '';

		$min = RadioUdaan_App_Settings::get_password_min_length();
		if ( strlen( $password ) < $min ) {
			return new WP_Error(
				'password_too_short',
				sprintf(
					/* translators: %d: minimum length */
					__( 'Password must be at least %d characters.', 'radioudaan-app-api' ),
					$min
				),
				array( 'status' => 400 )
			);
		}

		$user = null;
		if ( $token ) {
			$code   = isset( $body['code'] ) ? sanitize_text_field( $body['code'] ) : '';
			$stored = get_transient( self::TRANSIENT_RESET . md5( $token ) );
			if ( is_array( $stored ) && ! empty( $stored['user_id'] ) ) {
				if ( $code && isset( $stored['code'] ) && hash_equals( (string) $stored['code'], $code ) ) {
					$user = RadioUdaan_App_Users::get_by_id( (int) $stored['user_id'] );
				}
			}
		} elseif ( $otp && $phone ) {
			$phone_norm = self::normalize_phone( $phone );
			if ( is_wp_error( $phone_norm ) ) {
				return $phone_norm;
			}
			$key    = 'radioudaan_pwd_reset_otp_' . md5( $phone_norm );
			$stored = get_transient( $key );
			if ( is_array( $stored ) && hash_equals( (string) $stored['otp'], $otp ) ) {
				$user = RadioUdaan_App_Users::get_by_id( (int) $stored['user_id'] );
				delete_transient( $key );
			}
		}

		if ( ! $user || 'active' !== $user->status ) {
			return new WP_Error( 'reset_invalid', __( 'Reset link or code is invalid or expired.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		RadioUdaan_App_Users::update_password( (int) $user->id, wp_hash_password( $password ) );
		if ( $token ) {
			delete_transient( self::TRANSIENT_RESET . md5( $token ) );
		}
		RadioUdaan_App_Auth::revoke_all_tokens_for_user_id( (int) $user->id );

		return array( 'status' => 'password_reset' );
	}

	/**
	 * @param int $user_id User id.
	 * @return array|WP_Error
	 */
	public static function resend_email_verification( $user_id ) {
		$user = RadioUdaan_App_Users::get_by_id( $user_id );
		if ( ! $user || 'active' !== $user->status ) {
			return new WP_Error( 'user_not_found', __( 'Account not found.', 'radioudaan-app-api' ), array( 'status' => 404 ) );
		}
		if ( (int) $user->email_verified ) {
			return array( 'status' => 'already_verified' );
		}

		self::send_email_verification_code( $user );

		return array( 'status' => 'sent' );
	}

	/**
	 * @param array<string,mixed> $body Request JSON.
	 * @param int               $user_id Authenticated user.
	 * @return array|WP_Error
	 */
	public static function verify_email( array $body, $user_id ) {
		$code = isset( $body['code'] ) ? sanitize_text_field( $body['code'] ) : '';
		if ( strlen( $code ) !== 6 ) {
			return new WP_Error( 'code_invalid', __( 'Enter the 6-digit verification code.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		$user = RadioUdaan_App_Users::get_by_id( $user_id );
		if ( ! $user ) {
			return new WP_Error( 'user_not_found', __( 'Account not found.', 'radioudaan-app-api' ), array( 'status' => 404 ) );
		}

		$key    = self::TRANSIENT_EMAIL_CODE . (int) $user->id;
		$stored = get_transient( $key );
		if ( ! is_array( $stored ) || ! hash_equals( (string) $stored['code'], $code ) ) {
			return new WP_Error( 'code_invalid', __( 'Incorrect or expired verification code.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		delete_transient( $key );
		RadioUdaan_App_Users::mark_email_verified( (int) $user->id );
		$user = RadioUdaan_App_Users::get_by_id( (int) $user->id );

		return self::issue_session_for_user( $user );
	}

	/**
	 * Activate pending user after phone OTP.
	 *
	 * @param int $user_id User id.
	 * @return array|WP_Error
	 */
	public static function activate_after_phone_verify( $user_id ) {
		$user = RadioUdaan_App_Users::get_by_id( $user_id );
		if ( ! $user ) {
			return new WP_Error( 'user_not_found', __( 'Account not found.', 'radioudaan-app-api' ), array( 'status' => 404 ) );
		}

		RadioUdaan_App_Users::activate_phone( $user_id );
		$user = RadioUdaan_App_Users::get_by_id( $user_id );

		// Email verification is manual: activation no longer sends an email
		// code. The user requests it from the Verify Email screen.
		return self::issue_session_for_user( $user );
	}

	/**
	 * @param object $user User row.
	 * @return array
	 */
	public static function issue_session_for_user( $user ) {
		RadioUdaan_App_Users::record_login( (int) $user->id );
		$token_data = RadioUdaan_App_Auth::issue_token_for_user( $user );

		return array(
			'token'      => $token_data['token'],
			'expires_at' => $token_data['expires_at'],
			'user'       => self::format_user( $user ),
		);
	}

	/**
	 * @param object|null $user User row.
	 * @return array<string,mixed>|null
	 */
	public static function format_user( $user ) {
		if ( ! $user ) {
			return null;
		}

		$avatar_url = '';
		if ( ! empty( $user->avatar_attachment_id ) ) {
			$url = wp_get_attachment_url( (int) $user->avatar_attachment_id );
			if ( $url ) {
				$avatar_url = $url;
			}
		}

		return array(
			'id'              => (int) $user->id,
			'name'            => $user->display_name,
			'email'           => $user->email,
			'phone_e164'      => $user->phone_e164,
			'phone_verified'  => (bool) (int) $user->phone_verified,
			'email_verified'  => (bool) (int) $user->email_verified,
			'status'          => $user->status,
			'avatar_url'      => $avatar_url,
		);
	}

	/**
	 * @param object $user User row.
	 */
	private static function send_email_verification_code( $user ) {
		$code = (string) wp_rand( 100000, 999999 );
		if ( RadioUdaan_Otp_Service::expose_dev_otp_public() ) {
			$code = '123456';
		}

		set_transient(
			self::TRANSIENT_EMAIL_CODE . (int) $user->id,
			array( 'code' => $code ),
			self::EMAIL_CODE_TTL
		);

		RadioUdaan_App_Mailer::send_verification( $user, $code );
	}

	/**
	 * @param object $user User row.
	 * @return array
	 */
	private static function forgot_password_email( $user ) {
		// Only send reset mail to a verified inbox (anti-abuse; same generic ok if not).
		if ( ! (int) $user->email_verified ) {
			return array( 'status' => 'ok' );
		}

		$code  = (string) wp_rand( 100000, 999999 );
		$token = wp_generate_password( 32, false, false );

		if ( RadioUdaan_Otp_Service::expose_dev_otp_public() ) {
			$code = '123456';
		}

		set_transient(
			self::TRANSIENT_RESET . md5( $token ),
			array(
				'user_id' => (int) $user->id,
				'code'    => $code,
			),
			self::RESET_TOKEN_TTL
		);

		RadioUdaan_App_Mailer::send_password_reset( $user, $code, $token );

		return array( 'status' => 'ok', 'channel' => 'email' );
	}

	/**
	 * @param object $user User row.
	 * @return array|WP_Error
	 */
	private static function forgot_password_phone( $user ) {
		// SMS reset only for verified mobile on file (same generic ok if not).
		if ( ! (int) $user->phone_verified ) {
			return array( 'status' => 'ok' );
		}

		$result = RadioUdaan_Otp_Service::request_otp(
			$user->phone_e164,
			'reset_password',
			array( 'user_id' => (int) $user->id )
		);

		if ( is_array( $result ) ) {
			$result['phone_e164'] = $user->phone_e164;
		}

		return $result;
	}

	/**
	 * Store SMS reset OTP after user verifies OTP in app (called from OTP service).
	 *
	 * @param int    $user_id User id.
	 * @param string $phone   Phone.
	 * @param string $otp     Plain OTP.
	 */
	public static function store_phone_reset_otp( $user_id, $phone, $otp ) {
		set_transient(
			'radioudaan_pwd_reset_otp_' . md5( $phone ),
			array(
				'user_id' => (int) $user_id,
				'otp'     => $otp,
			),
			self::RESET_TOKEN_TTL
		);
	}

	/**
	 * @param string $phone Phone input.
	 * @return string|WP_Error
	 */
	public static function normalize_phone( $phone ) {
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
}

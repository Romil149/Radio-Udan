<?php
/**
 * App bearer token auth (post-login).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Session tokens for mobile app API.
 */
class RadioUdaan_App_Auth {

	const TRANSIENT_PREFIX = 'radioudaan_app_token_';
	const TOKEN_TTL        = 7 * DAY_IN_SECONDS;

	const DEV_USER_ID    = 1;
	const DEV_PHONE      = '+910000000000';

	/**
	 * REST permission callback for protected routes.
	 *
	 * @param WP_REST_Request $request Request.
	 * @return bool
	 */
	public static function require_auth( WP_REST_Request $request ) {
		if ( self::is_dev_auth_enabled() ) {
			return true;
		}

		$token = self::get_bearer_token( $request );
		return (bool) self::validate_token( $token );
	}

	/**
	 * @return bool
	 */
	public static function is_dev_auth_enabled() {
		return RadioUdaan_App_Settings::is_dev_auth_enabled();
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return string
	 */
	public static function get_bearer_token( WP_REST_Request $request ) {
		$header = $request->get_header( 'authorization' );
		if ( $header && preg_match( '/Bearer\s+(\S+)/i', $header, $m ) ) {
			return trim( $m[1] );
		}

		return '';
	}

	/**
	 * @param object $user User row.
	 * @return array{token:string,expires_at:string}
	 */
	public static function issue_token_for_user( $user ) {
		return self::issue_token( (int) $user->id, $user->phone_e164 );
	}

	/**
	 * @param int    $user_id    App user id.
	 * @param string $phone_e164 Phone.
	 * @return array{token:string,expires_at:string}
	 */
	public static function issue_token( $user_id, $phone_e164 ) {
		$token = wp_generate_password( 48, false, false );
		$data  = array(
			'user_id'    => (int) $user_id,
			'phone_e164' => $phone_e164,
			'created'    => time(),
		);

		set_transient( self::TRANSIENT_PREFIX . $token, $data, self::TOKEN_TTL );

		return array(
			'token'      => $token,
			'expires_at' => gmdate( 'c', time() + self::TOKEN_TTL ),
		);
	}

	/**
	 * @param string $token Token.
	 * @return array{user_id:int,phone_e164:string}|null
	 */
	public static function validate_token( $token ) {
		if ( ! $token ) {
			return null;
		}

		$data = get_transient( self::TRANSIENT_PREFIX . $token );
		if ( ! is_array( $data ) || empty( $data['user_id'] ) ) {
			return null;
		}

		$user = RadioUdaan_App_Users::get_by_id( (int) $data['user_id'] );
		if ( ! $user || RadioUdaan_App_Users::STATUS_ACTIVE !== $user->status ) {
			return null;
		}

		return array(
			'user_id'    => (int) $data['user_id'],
			'phone_e164' => isset( $data['phone_e164'] ) ? (string) $data['phone_e164'] : $user->phone_e164,
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return int|null
	 */
	public static function get_user_id_from_request( WP_REST_Request $request ) {
		if ( self::is_dev_auth_enabled() ) {
			return self::DEV_USER_ID;
		}

		$token = self::get_bearer_token( $request );
		$data  = self::validate_token( $token );

		return $data ? (int) $data['user_id'] : null;
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return string|null
	 */
	public static function get_phone_from_request( WP_REST_Request $request ) {
		if ( self::is_dev_auth_enabled() ) {
			return self::DEV_PHONE;
		}

		$token = self::get_bearer_token( $request );
		$data  = self::validate_token( $token );

		return $data ? $data['phone_e164'] : null;
	}

	/**
	 * @param string $token Bearer token.
	 */
	public static function revoke_token( $token ) {
		if ( $token ) {
			delete_transient( self::TRANSIENT_PREFIX . $token );
		}
	}

	/**
	 * Revoke every bearer session for a user (all devices).
	 *
	 * @param int $user_id User id.
	 * @return int Tokens removed.
	 */
	public static function revoke_all_tokens_for_user_id( $user_id ) {
		if ( ! $user_id ) {
			return 0;
		}

		global $wpdb;

		$like = $wpdb->esc_like( '_transient_' . self::TRANSIENT_PREFIX ) . '%';

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT option_name, option_value FROM {$wpdb->options} WHERE option_name LIKE %s",
				$like
			),
			ARRAY_A
		);

		$revoked = 0;
		foreach ( $rows as $row ) {
			$data = maybe_unserialize( $row['option_value'] );
			if ( ! is_array( $data ) || empty( $data['user_id'] ) || (int) $data['user_id'] !== (int) $user_id ) {
				continue;
			}

			$transient_name = substr( $row['option_name'], strlen( '_transient_' ) );
			$token          = substr( $transient_name, strlen( self::TRANSIENT_PREFIX ) );
			if ( $token ) {
				delete_transient( self::TRANSIENT_PREFIX . $token );
				$revoked++;
			}
		}

		return $revoked;
	}

	/**
	 * @deprecated Use revoke_all_tokens_for_user_id().
	 * @param string $phone_e164 Phone.
	 * @return int
	 */
	public static function revoke_all_tokens_for_phone( $phone_e164 ) {
		$user = RadioUdaan_App_Users::find_by_phone( $phone_e164 );
		if ( ! $user ) {
			return 0;
		}

		return self::revoke_all_tokens_for_user_id( (int) $user->id );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return array{user_id:int,phone_e164:string,expires_at:string,user:array|null}|null
	 */
	public static function get_session_from_request( WP_REST_Request $request ) {
		if ( self::is_dev_auth_enabled() ) {
			return array(
				'user_id'    => self::DEV_USER_ID,
				'phone_e164' => self::DEV_PHONE,
				'expires_at' => gmdate( 'c', time() + self::TOKEN_TTL ),
				'user'       => array(
					'id'             => self::DEV_USER_ID,
					'name'           => 'Dev User',
					'email'          => 'dev@radioudaan.local',
					'phone_e164'     => self::DEV_PHONE,
					'phone_verified' => true,
					'email_verified' => true,
					'status'         => RadioUdaan_App_Users::STATUS_ACTIVE,
					'avatar_url'     => '',
				),
			);
		}

		$token = self::get_bearer_token( $request );
		$data  = self::validate_token( $token );
		if ( ! $data ) {
			return null;
		}

		$user_row = RadioUdaan_App_Users::get_by_id( $data['user_id'] );

		return array(
			'user_id'    => $data['user_id'],
			'phone_e164' => $data['phone_e164'],
			'expires_at' => gmdate( 'c', time() + self::TOKEN_TTL ),
			'user'       => RadioUdaan_App_Password_Auth::format_user( $user_row ),
		);
	}
}

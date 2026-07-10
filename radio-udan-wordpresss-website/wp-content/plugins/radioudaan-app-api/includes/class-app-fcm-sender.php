<?php
/**
 * Firebase Cloud Messaging HTTP v1 sender (service account + OAuth2).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Sends push notifications via FCM HTTP v1 API.
 */
class RadioUdaan_App_Fcm_Sender {

	const OAUTH_TOKEN_URL = 'https://oauth2.googleapis.com/token';
	const FCM_SCOPE       = 'https://www.googleapis.com/auth/firebase.messaging';
	const TOKEN_TRANSIENT = 'radioudaan_fcm_oauth_token';
	const ANDROID_CHANNEL = 'radioudaan_alerts';

	/**
	 * Firebase project ID baked into the Flutter app (google-services / firebase_options).
	 * WP service account + FCM project ID must match this or tokens will never deliver.
	 */
	const EXPECTED_APP_PROJECT_ID = 'radio-udaan-72232';

	/**
	 * Clear cached OAuth access token (e.g. after credential rotation).
	 */
	public static function clear_oauth_cache() {
		delete_transient( self::TOKEN_TRANSIENT );
	}

	/**
	 * Whether the configured FCM project matches the mobile app Firebase project.
	 *
	 * @return bool
	 */
	public static function project_matches_app() {
		$configured = self::resolve_configured_project_id();
		return '' !== $configured && self::EXPECTED_APP_PROJECT_ID === $configured;
	}

	/**
	 * Project ID used for FCM HTTP v1 sends (setting or service-account JSON).
	 *
	 * @return string
	 */
	public static function resolve_configured_project_id() {
		$account = self::get_service_account();
		if ( ! $account ) {
			$from_setting = RadioUdaan_App_Settings::get_fcm_project_id();
			return '' !== $from_setting ? $from_setting : '';
		}

		return self::resolve_project_id( $account );
	}

	/**
	 * Verify service account credentials can obtain an OAuth token (does not send push).
	 *
	 * @return true|WP_Error
	 */
	public static function verify_oauth_connection() {
		$account = self::get_service_account();
		if ( ! $account ) {
			return new WP_Error( 'fcm_not_configured', __( 'FCM service account is not configured.', 'radioudaan-app-api' ) );
		}

		$token = self::get_access_token( $account );
		if ( is_wp_error( $token ) ) {
			return $token;
		}

		return true;
	}

	/**
	 * @return bool
	 */
	public static function is_configured() {
		$account = self::get_service_account();
		if ( ! $account ) {
			return false;
		}

		return '' !== self::resolve_project_id( $account );
	}

	/**
	 * @param string               $token    Device FCM token.
	 * @param string               $title    Notification title.
	 * @param string               $body     Notification body.
	 * @param array<string,string> $data     String payload for the app.
	 * @param string               $platform android|ios (optional; tunes delivery).
	 * @return true|WP_Error
	 */
	public static function send_to_token( $token, $title, $body, array $data = array(), $platform = '' ) {
		$account = self::get_service_account();
		if ( ! $account ) {
			return new WP_Error( 'fcm_not_configured', __( 'FCM is not configured.', 'radioudaan-app-api' ) );
		}

		$project_id = self::resolve_project_id( $account );
		if ( '' === $project_id ) {
			return new WP_Error( 'fcm_project_missing', __( 'FCM project ID is missing.', 'radioudaan-app-api' ) );
		}

		$access_token = self::get_access_token( $account );
		if ( is_wp_error( $access_token ) ) {
			return $access_token;
		}

		$message = array(
			'token' => (string) $token,
			'notification' => array(
				'title' => (string) $title,
				'body'  => (string) $body,
			),
		);

		$string_data = self::normalize_data_payload( $data );
		if ( ! empty( $string_data ) ) {
			$message['data'] = $string_data;
		}

		$message = self::apply_platform_delivery_options( $message, $title, $body, $platform );

		$url = sprintf(
			'https://fcm.googleapis.com/v1/projects/%s/messages:send',
			rawurlencode( $project_id )
		);

		$response = wp_remote_post(
			$url,
			array(
				'timeout' => 20,
				'headers' => array(
					'Authorization' => 'Bearer ' . $access_token,
					'Content-Type'  => 'application/json',
				),
				'body'    => wp_json_encode( array( 'message' => $message ) ),
			)
		);

		if ( is_wp_error( $response ) ) {
			return $response;
		}

		$code = (int) wp_remote_retrieve_response_code( $response );
		$raw  = (string) wp_remote_retrieve_body( $response );
		$json = json_decode( $raw, true );

		if ( $code >= 200 && $code < 300 ) {
			return true;
		}

		$error_status = '';
		if ( is_array( $json ) && isset( $json['error']['details'] ) && is_array( $json['error']['details'] ) ) {
			foreach ( $json['error']['details'] as $detail ) {
				if ( is_array( $detail ) && ! empty( $detail['errorCode'] ) ) {
					$error_status = (string) $detail['errorCode'];
					break;
				}
			}
		}

		if ( in_array( $error_status, array( 'UNREGISTERED', 'INVALID_ARGUMENT' ), true ) ) {
			return new WP_Error(
				'fcm_token_invalid',
				__( 'FCM device token is invalid or unregistered.', 'radioudaan-app-api' ),
				array(
					'status'     => $code,
					'error_code' => $error_status,
				)
			);
		}

		$message_text = is_array( $json ) && isset( $json['error']['message'] )
			? (string) $json['error']['message']
			: __( 'FCM request failed.', 'radioudaan-app-api' );

		return new WP_Error(
			'fcm_send_failed',
			$message_text,
			array(
				'status'     => $code,
				'error_code' => $error_status,
			)
		);
	}

	/**
	 * @param int                  $user_id User id.
	 * @param string               $title   Title.
	 * @param string               $body    Body.
	 * @param string               $type    Notification type slug.
	 * @param array<string,mixed>  $data    Payload.
	 * @return array{sent:int,failed:int,pruned:int,skipped:bool,ios_sent:int,ios_failed:int,android_sent:int,android_failed:int,last_error:string}
	 */
	public static function send_to_user_devices( $user_id, $title, $body, $type = 'general', array $data = array() ) {
		$result = array(
			'sent'           => 0,
			'failed'         => 0,
			'pruned'         => 0,
			'skipped'        => false,
			'ios_sent'       => 0,
			'ios_failed'     => 0,
			'android_sent'   => 0,
			'android_failed' => 0,
			'last_error'     => '',
		);

		if ( ! self::is_configured() ) {
			$result['skipped'] = true;
			return $result;
		}

		$tokens = RadioUdaan_App_Notifications::get_device_tokens_for_user( $user_id );
		if ( empty( $tokens ) ) {
			return $result;
		}

		$payload = array_merge(
			$data,
			array(
				'type' => (string) $type,
			)
		);

		foreach ( $tokens as $row ) {
			$token = isset( $row['fcm_token'] ) ? (string) $row['fcm_token'] : '';
			if ( strlen( $token ) < 20 ) {
				continue;
			}

			$device_platform = isset( $row['platform'] ) ? (string) $row['platform'] : '';
			$send             = self::send_to_token( $token, $title, $body, $payload, $device_platform );
			$is_ios           = RadioUdaan_App_Notifications::PLATFORM_IOS === $device_platform;
			$is_android       = RadioUdaan_App_Notifications::PLATFORM_ANDROID === $device_platform;

			if ( true === $send ) {
				++$result['sent'];
				if ( $is_ios ) {
					++$result['ios_sent'];
				} elseif ( $is_android ) {
					++$result['android_sent'];
				}
				continue;
			}

			++$result['failed'];
			if ( $is_ios ) {
				++$result['ios_failed'];
			} elseif ( $is_android ) {
				++$result['android_failed'];
			}

			if ( is_wp_error( $send ) ) {
				$result['last_error'] = $send->get_error_message();
				$error_data           = $send->get_error_data();
				if ( is_array( $error_data ) && ! empty( $error_data['error_code'] ) ) {
					$result['last_error'] = $error_data['error_code'] . ': ' . $result['last_error'];
				}

				if ( 'fcm_token_invalid' === $send->get_error_code() ) {
					$device_id = isset( $row['id'] ) ? (int) $row['id'] : 0;
					if ( $device_id > 0 && RadioUdaan_App_Notifications::delete_device( $device_id ) ) {
						++$result['pruned'];
					}
				}
			}
		}

		return $result;
	}

	/**
	 * @return array<string,string>|null
	 */
	private static function get_service_account() {
		$raw = '';

		if ( defined( 'RADIOUDAAN_FCM_SERVICE_ACCOUNT_JSON' ) ) {
			$raw = (string) RADIOUDAAN_FCM_SERVICE_ACCOUNT_JSON;
		} elseif ( defined( 'RADIOUDAAN_FCM_SERVICE_ACCOUNT_PATH' ) ) {
			$path = (string) RADIOUDAAN_FCM_SERVICE_ACCOUNT_PATH;
			if ( is_readable( $path ) ) {
				$raw = (string) file_get_contents( $path ); // phpcs:ignore WordPress.WP.AlternativeFunctions.file_get_contents_file_get_contents
			}
		} else {
			$raw = (string) get_option( RadioUdaan_App_Settings::OPTION_FCM_SERVICE_ACCOUNT, '' );
		}

		return self::parse_service_account_json( $raw );
	}

	/**
	 * @param string $raw JSON string.
	 * @return array<string,string>|null
	 */
	public static function parse_service_account_json( $raw ) {
		$raw = trim( (string) $raw );
		if ( '' === $raw ) {
			return null;
		}

		$decoded = json_decode( $raw, true );
		if ( ! is_array( $decoded ) ) {
			return null;
		}

		if ( empty( $decoded['type'] ) || 'service_account' !== $decoded['type'] ) {
			return null;
		}

		$client_email = isset( $decoded['client_email'] ) ? trim( (string) $decoded['client_email'] ) : '';
		$private_key  = isset( $decoded['private_key'] ) ? (string) $decoded['private_key'] : '';
		$project_id   = isset( $decoded['project_id'] ) ? sanitize_text_field( (string) $decoded['project_id'] ) : '';

		if ( '' === $client_email || '' === $private_key ) {
			return null;
		}

		return array(
			'client_email' => $client_email,
			'private_key'  => $private_key,
			'project_id'   => $project_id,
		);
	}

	/**
	 * @param array<string,string> $account Service account.
	 * @return string
	 */
	private static function resolve_project_id( array $account ) {
		$from_setting = RadioUdaan_App_Settings::get_fcm_project_id();
		if ( '' !== $from_setting ) {
			return $from_setting;
		}

		return isset( $account['project_id'] ) ? (string) $account['project_id'] : '';
	}

	/**
	 * @param array<string,string> $account Service account.
	 * @return string|WP_Error
	 */
	private static function get_access_token( array $account ) {
		$cached = get_transient( self::TOKEN_TRANSIENT );
		if ( is_array( $cached ) && ! empty( $cached['token'] ) && ! empty( $cached['exp'] ) && (int) $cached['exp'] > time() + 60 ) {
			return (string) $cached['token'];
		}

		$jwt = self::build_jwt( $account['client_email'], $account['private_key'] );
		if ( is_wp_error( $jwt ) ) {
			return $jwt;
		}

		$response = wp_remote_post(
			self::OAUTH_TOKEN_URL,
			array(
				'timeout' => 15,
				'headers' => array(
					'Content-Type' => 'application/x-www-form-urlencoded',
				),
				'body'    => array(
					'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
					'assertion'  => $jwt,
				),
			)
		);

		if ( is_wp_error( $response ) ) {
			return $response;
		}

		$code = (int) wp_remote_retrieve_response_code( $response );
		$raw  = (string) wp_remote_retrieve_body( $response );
		$json = json_decode( $raw, true );

		if ( $code < 200 || $code >= 300 || ! is_array( $json ) || empty( $json['access_token'] ) ) {
			$message = is_array( $json ) && isset( $json['error_description'] )
				? (string) $json['error_description']
				: __( 'Could not obtain FCM access token.', 'radioudaan-app-api' );

			return new WP_Error( 'fcm_oauth_failed', $message, array( 'status' => $code ) );
		}

		$token     = (string) $json['access_token'];
		$expires_in = isset( $json['expires_in'] ) ? max( 300, (int) $json['expires_in'] ) : 3600;

		set_transient(
			self::TOKEN_TRANSIENT,
			array(
				'token' => $token,
				'exp'   => time() + $expires_in,
			),
			$expires_in - 120
		);

		return $token;
	}

	/**
	 * @param string $client_email Service account email.
	 * @param string $private_key  PEM private key.
	 * @return string|WP_Error
	 */
	private static function build_jwt( $client_email, $private_key ) {
		$now = time();

		$header = self::base64url_encode(
			wp_json_encode(
				array(
					'alg' => 'RS256',
					'typ' => 'JWT',
				)
			)
		);

		$claims = self::base64url_encode(
			wp_json_encode(
				array(
					'iss'   => $client_email,
					'sub'   => $client_email,
					'aud'   => self::OAUTH_TOKEN_URL,
					'iat'   => $now,
					'exp'   => $now + 3600,
					'scope' => self::FCM_SCOPE,
				)
			)
		);

		$unsigned = $header . '.' . $claims;
		$key      = openssl_pkey_get_private( $private_key );

		if ( false === $key ) {
			return new WP_Error( 'fcm_key_invalid', __( 'FCM service account private key is invalid.', 'radioudaan-app-api' ) );
		}

		$signature = '';
		$signed    = openssl_sign( $unsigned, $signature, $key, OPENSSL_ALGO_SHA256 );
		openssl_free_key( $key );

		if ( ! $signed ) {
			return new WP_Error( 'fcm_jwt_failed', __( 'Could not sign FCM OAuth JWT.', 'radioudaan-app-api' ) );
		}

		return $unsigned . '.' . self::base64url_encode( $signature );
	}

	/**
	 * Android high-priority channel + iOS APNs alert headers (Swiggy/Zomato-style delivery).
	 *
	 * @param array<string,mixed> $message  FCM message body.
	 * @param string              $title    Alert title.
	 * @param string              $body     Alert body.
	 * @param string              $platform android|ios|''.
	 * @return array<string,mixed>
	 */
	private static function apply_platform_delivery_options( array $message, $title, $body, $platform = '' ) {
		$platform = sanitize_key( (string) $platform );

		$android = array(
			'priority'     => 'HIGH',
			'notification' => array(
				'channel_id'            => self::ANDROID_CHANNEL,
				'notification_priority' => 'PRIORITY_HIGH',
				'default_sound'         => true,
				'visibility'            => 'PUBLIC',
			),
		);

		$apns = array(
			'headers' => array(
				'apns-priority' => '10',
				'apns-push-type' => 'alert',
			),
			'payload' => array(
				'aps' => array(
					'alert' => array(
						'title' => (string) $title,
						'body'  => (string) $body,
					),
					'sound' => 'default',
				),
			),
		);

		if ( '' === $platform || RadioUdaan_App_Notifications::PLATFORM_ANDROID === $platform ) {
			$message['android'] = $android;
		}

		if ( '' === $platform || RadioUdaan_App_Notifications::PLATFORM_IOS === $platform ) {
			$message['apns'] = $apns;
		}

		return $message;
	}

	/**
	 * @param array<string,mixed> $data Mixed payload.
	 * @return array<string,string>
	 */
	private static function normalize_data_payload( array $data ) {
		$out = array();
		foreach ( $data as $key => $value ) {
			$key = sanitize_key( (string) $key );
			if ( '' === $key ) {
				continue;
			}

			if ( is_scalar( $value ) || null === $value ) {
				$out[ $key ] = (string) $value;
			} else {
				$out[ $key ] = wp_json_encode( $value );
			}
		}

		return $out;
	}

	/**
	 * @param string $value Raw value.
	 * @return string
	 */
	private static function base64url_encode( $value ) {
		return rtrim( strtr( base64_encode( (string) $value ), '+/', '-_' ), '=' );
	}
}

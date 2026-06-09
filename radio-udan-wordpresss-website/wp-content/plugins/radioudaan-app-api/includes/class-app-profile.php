<?php
/**
 * Profile updates, password change, and avatar upload.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Authenticated profile management for app users.
 */
class RadioUdaan_App_Profile {

	const AVATAR_MAX_MB = 5;

	/**
	 * @param int               $user_id User id.
	 * @param array<string,mixed> $body  Request JSON.
	 * @return array|WP_Error
	 */
	public static function update_profile( $user_id, array $body ) {
		$user = RadioUdaan_App_Users::get_by_id( $user_id );
		if ( ! $user || RadioUdaan_App_Users::STATUS_ACTIVE !== $user->status ) {
			return new WP_Error( 'user_not_found', __( 'Account not found.', 'radioudaan-app-api' ), array( 'status' => 404 ) );
		}

		$updates = array();

		if ( array_key_exists( 'name', $body ) ) {
			$name = sanitize_text_field( (string) $body['name'] );
			if ( strlen( $name ) < 2 ) {
				return new WP_Error( 'name_invalid', __( 'Name is required.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
			}
			$updates['display_name'] = $name;
		}

		if ( array_key_exists( 'email', $body ) ) {
			$email = strtolower( sanitize_email( (string) $body['email'] ) );
			if ( ! is_email( $email ) ) {
				return new WP_Error( 'email_invalid', __( 'Valid email is required.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
			}
			if ( $email !== $user->email ) {
				if ( RadioUdaan_App_Users::email_taken( $email ) ) {
					return new WP_Error( 'email_taken', __( 'This email is already registered.', 'radioudaan-app-api' ), array( 'status' => 409 ) );
				}
				$updates['email']          = $email;
				$updates['email_verified'] = 0;
			}
		}

		if ( array_key_exists( 'phone_e164', $body ) ) {
			$phone = RadioUdaan_App_Password_Auth::normalize_phone( $body['phone_e164'] );
			if ( is_wp_error( $phone ) ) {
				return $phone;
			}
			if ( $phone !== $user->phone_e164 ) {
				return new WP_Error(
					'phone_not_changeable',
					__( 'Mobile number cannot be changed in the app. Contact support if you need help.', 'radioudaan-app-api' ),
					array( 'status' => 400 )
				);
			}
		}

		if ( empty( $updates ) ) {
			return new WP_Error( 'no_changes', __( 'No profile fields to update.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		$updated = RadioUdaan_App_Users::update_fields( $user_id, $updates );
		if ( ! $updated ) {
			return new WP_Error( 'update_failed', __( 'Could not update profile.', 'radioudaan-app-api' ), array( 'status' => 500 ) );
		}

		$fresh = RadioUdaan_App_Users::get_by_id( $user_id );

		$email_verification_sent = false;
		if ( ! empty( $updates['email'] ) ) {
			$send = RadioUdaan_App_Password_Auth::resend_email_verification( $user_id );
			if ( ! is_wp_error( $send ) && isset( $send['status'] ) && 'sent' === $send['status'] ) {
				$email_verification_sent = true;
			}
		}

		RadioUdaan_App_Logger::log( 'profile_updated', array( 'user_id' => $user_id ) );

		return array(
			'status'                  => 'updated',
			'user'                    => RadioUdaan_App_Password_Auth::format_user( $fresh ),
			'email_verification_sent' => $email_verification_sent,
		);
	}

	/**
	 * @param int               $user_id User id.
	 * @param array<string,mixed> $body  Request JSON.
	 * @return array|WP_Error
	 */
	public static function change_password( $user_id, array $body ) {
		$user = RadioUdaan_App_Users::get_by_id( $user_id );
		if ( ! $user || RadioUdaan_App_Users::STATUS_ACTIVE !== $user->status ) {
			return new WP_Error( 'user_not_found', __( 'Account not found.', 'radioudaan-app-api' ), array( 'status' => 404 ) );
		}

		$current = isset( $body['current_password'] ) ? (string) $body['current_password'] : '';
		$new     = isset( $body['new_password'] ) ? (string) $body['new_password'] : '';

		if ( ! $current || ! $new ) {
			return new WP_Error(
				'password_required',
				__( 'Current and new password are required.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		if ( ! wp_check_password( $current, $user->password_hash ) ) {
			return new WP_Error(
				'password_incorrect',
				__( 'Current password is incorrect.', 'radioudaan-app-api' ),
				array( 'status' => 401 )
			);
		}

		$min = RadioUdaan_App_Settings::get_password_min_length();
		if ( strlen( $new ) < $min ) {
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

		if ( ! RadioUdaan_App_Users::update_password( $user_id, wp_hash_password( $new ) ) ) {
			return new WP_Error( 'update_failed', __( 'Could not change password.', 'radioudaan-app-api' ), array( 'status' => 500 ) );
		}

		RadioUdaan_App_Auth::revoke_all_tokens_for_user_id( $user_id );
		RadioUdaan_App_Logger::log( 'password_changed', array( 'user_id' => $user_id ) );

		return array( 'status' => 'password_changed' );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function handle_avatar_upload( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$files = $request->get_file_params();
		if ( empty( $files['file'] ) || empty( $files['file']['tmp_name'] ) ) {
			return new WP_Error(
				'upload_missing',
				__( 'File is required (multipart field name: file).', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$ip = RadioUdaan_Rate_Limiter::get_client_ip();
		if ( RadioUdaan_Rate_Limiter::is_limited( 'avatar_ip_' . $ip, 20, HOUR_IN_SECONDS ) ) {
			return new WP_Error(
				'upload_rate_limited',
				__( 'Too many uploads. Try again later.', 'radioudaan-app-api' ),
				array( 'status' => 429 )
			);
		}
		RadioUdaan_Rate_Limiter::bump( 'avatar_ip_' . $ip, HOUR_IN_SECONDS );

		$result = self::store_avatar( $files['file'], $user_id );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param array $file    $_FILES slice.
	 * @param int   $user_id User id.
	 * @return array|WP_Error
	 */
	public static function store_avatar( $file, $user_id ) {
		if ( ! empty( $file['error'] ) ) {
			return new WP_Error( 'upload_error', __( 'Upload failed.', 'radioudaan-app-api' ), array( 'status' => 400 ) );
		}

		$max_mb = (int) apply_filters( 'radioudaan_app_avatar_max_mb', self::AVATAR_MAX_MB );
		$max_b  = max( 1, $max_mb ) * 1024 * 1024;
		if ( ! empty( $file['size'] ) && (int) $file['size'] > $max_b ) {
			return new WP_Error(
				'upload_too_large',
				sprintf(
					/* translators: %d: megabytes */
					__( 'Image exceeds %d MB limit.', 'radioudaan-app-api' ),
					$max_mb
				),
				array( 'status' => 400 )
			);
		}

		require_once ABSPATH . 'wp-admin/includes/file.php';
		require_once ABSPATH . 'wp-admin/includes/media.php';
		require_once ABSPATH . 'wp-admin/includes/image.php';

		$mimes = array(
			'jpg|jpeg|jpe' => 'image/jpeg',
			'png'          => 'image/png',
			'webp'         => 'image/webp',
		);

		$upload = wp_handle_upload(
			$file,
			array(
				'test_form' => false,
				'mimes'     => $mimes,
			)
		);

		if ( isset( $upload['error'] ) ) {
			return new WP_Error( 'upload_rejected', $upload['error'], array( 'status' => 400 ) );
		}

		$attachment_id = wp_insert_attachment(
			array(
				'post_mime_type' => $upload['type'],
				'post_title'     => sanitize_file_name( 'avatar-' . $user_id ),
				'post_content'   => '',
				'post_status'    => 'inherit',
			),
			$upload['file']
		);

		if ( is_wp_error( $attachment_id ) || ! $attachment_id ) {
			return new WP_Error( 'upload_save_failed', __( 'Could not save avatar.', 'radioudaan-app-api' ), array( 'status' => 500 ) );
		}

		$meta = wp_generate_attachment_metadata( $attachment_id, $upload['file'] );
		wp_update_attachment_metadata( $attachment_id, $meta );

		$user = RadioUdaan_App_Users::get_by_id( $user_id );
		if ( $user && ! empty( $user->avatar_attachment_id ) ) {
			wp_delete_attachment( (int) $user->avatar_attachment_id, true );
		}

		RadioUdaan_App_Users::update_fields(
			$user_id,
			array(
				'avatar_attachment_id' => (int) $attachment_id,
			)
		);

		$url = wp_get_attachment_url( $attachment_id );

		RadioUdaan_App_Logger::log( 'avatar_updated', array( 'user_id' => $user_id ) );

		return array(
			'status'        => 'avatar_updated',
			'avatar_url'    => $url ? $url : '',
			'attachment_id' => (int) $attachment_id,
			'user'          => RadioUdaan_App_Password_Auth::format_user( RadioUdaan_App_Users::get_by_id( $user_id ) ),
		);
	}
}

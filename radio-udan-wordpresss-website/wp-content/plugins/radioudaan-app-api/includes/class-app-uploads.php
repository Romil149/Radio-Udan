<?php
/**
 * Staged file uploads for app registrations.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Upload staging (upload_id → attachment + paths for Forminator).
 */
class RadioUdaan_App_Uploads {

	const TRANSIENT_PREFIX = 'radioudaan_upload_';
	const UPLOAD_TTL       = DAY_IN_SECONDS;

	/**
	 * Handle REST upload.
	 *
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function handle_rest_upload( WP_REST_Request $request ) {
		$files = $request->get_file_params();
		if ( empty( $files['file'] ) || empty( $files['file']['tmp_name'] ) ) {
			return new WP_Error(
				'upload_missing',
				__( 'File is required (multipart field name: file).', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$event_id  = (int) $request->get_param( 'event_id' );
		$field_key = sanitize_text_field( (string) $request->get_param( 'field_key' ) );

		$event = RadioUdaan_Event_Registry::get_event( $event_id );
		if ( ! $event ) {
			return new WP_Error(
				'event_not_found',
				__( 'Invalid event_id.', 'radioudaan-app-api' ),
				array( 'status' => 404 )
			);
		}

		$open_check = RadioUdaan_Registration_Guard::assert_event_open( $event );
		if ( is_wp_error( $open_check ) ) {
			return $open_check;
		}

		$phone = RadioUdaan_App_Auth::get_phone_from_request( $request );
		if ( ! $phone ) {
			return new WP_Error(
				'unauthorized',
				__( 'Authentication required.', 'radioudaan-app-api' ),
				array( 'status' => 401 )
			);
		}

		$ip = RadioUdaan_Rate_Limiter::get_client_ip();
		if ( RadioUdaan_Rate_Limiter::is_limited( 'upload_ip_' . $ip, 60, HOUR_IN_SECONDS ) ) {
			return new WP_Error(
				'upload_rate_limited',
				__( 'Too many uploads. Try again later.', 'radioudaan-app-api' ),
				array( 'status' => 429 )
			);
		}
		RadioUdaan_Rate_Limiter::bump( 'upload_ip_' . $ip, HOUR_IN_SECONDS );

		$result = self::store_file(
			$files['file'],
			(int) $event['form_id'],
			$field_key,
			$phone
		);

		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response(
			array(
				'items' => array( $result ),
			),
			201
		);
	}

	/**
	 * @param array  $file      $_FILES slice.
	 * @param int    $form_id   Forminator form ID.
	 * @param string $field_key Field element id.
	 * @param string $phone     Owner phone.
	 * @return array|WP_Error
	 */
	public static function store_file( $file, $form_id, $field_key, $phone ) {
		if ( ! empty( $file['error'] ) ) {
			return new WP_Error(
				'upload_error',
				__( 'Upload failed.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$max_mb = RadioUdaan_App_Settings::get_max_upload_mb();
		$max_b  = $max_mb * 1024 * 1024;
		if ( ! empty( $file['size'] ) && (int) $file['size'] > $max_b ) {
			return new WP_Error(
				'upload_too_large',
				sprintf(
					/* translators: %d: megabytes */
					__( 'File exceeds %d MB limit.', 'radioudaan-app-api' ),
					$max_mb
				),
				array( 'status' => 400 )
			);
		}

		$private = RadioUdaan_App_Settings::use_private_uploads();
		$filter  = null;
		if ( $private ) {
			$filter = static function ( $dirs ) {
				$subdir = '/radioudaan-app-private/' . gmdate( 'Y/m' );
				$dirs['path']   = $dirs['basedir'] . $subdir;
				$dirs['url']    = $dirs['basedir'] . $subdir;
				$dirs['subdir'] = $subdir;
				if ( ! is_dir( $dirs['path'] ) ) {
					wp_mkdir_p( $dirs['path'] );
					// phpcs:ignore WordPress.WP.AlternativeFunctions.file_system_operations_file_put_contents
					@file_put_contents( $dirs['path'] . '/.htaccess', "Deny from all\n" );
					// phpcs:ignore WordPress.WP.AlternativeFunctions.file_system_operations_file_put_contents
					@file_put_contents( $dirs['path'] . '/index.php', "<?php\n// Silence.\n" );
				}
				return $dirs;
			};
			add_filter( 'upload_dir', $filter );
		}

		require_once ABSPATH . 'wp-admin/includes/file.php';
		require_once ABSPATH . 'wp-admin/includes/media.php';
		require_once ABSPATH . 'wp-admin/includes/image.php';

		$mimes          = RadioUdaan_App_Settings::get_allowed_mimes_map();
		$mime_filter_cb = static function ( $existing ) use ( $mimes ) {
			return array_merge( $existing, $mimes );
		};
		add_filter( 'upload_mimes', $mime_filter_cb );

		$upload = wp_handle_upload(
			$file,
			array(
				'test_form' => false,
				'mimes'     => $mimes,
			)
		);

		remove_filter( 'upload_mimes', $mime_filter_cb );
		if ( $filter ) {
			remove_filter( 'upload_dir', $filter );
		}

		if ( isset( $upload['error'] ) ) {
			return new WP_Error(
				'upload_rejected',
				$upload['error'],
				array( 'status' => 400 )
			);
		}

		$attachment_id = wp_insert_attachment(
			array(
				'post_mime_type' => $upload['type'],
				'post_title'     => sanitize_file_name( $file['name'] ),
				'post_content'   => '',
				'post_status'    => $private ? 'private' : 'inherit',
			),
			$upload['file']
		);

		if ( is_wp_error( $attachment_id ) || ! $attachment_id ) {
			return new WP_Error(
				'upload_save_failed',
				__( 'Could not save upload.', 'radioudaan-app-api' ),
				array( 'status' => 500 )
			);
		}

		$upload_id = 'up_' . wp_generate_password( 12, false, false );

		$record = array(
			'upload_id'     => $upload_id,
			'attachment_id' => (int) $attachment_id,
			'file_name'     => basename( $upload['file'] ),
			'file_path'     => $upload['file'],
			'file_url'      => $private ? '' : $upload['url'],
			'mime'          => $upload['type'],
			'size_bytes'    => (int) filesize( $upload['file'] ),
			'form_id'       => (int) $form_id,
			'field_key'     => $field_key,
			'phone_e164'    => $phone,
			'created'       => time(),
			'private'       => $private,
		);

		set_transient( self::TRANSIENT_PREFIX . $upload_id, $record, self::UPLOAD_TTL );

		return array(
			'upload_id'  => $upload_id,
			'file_name'  => $record['file_name'],
			'mime'       => $record['mime'],
			'size_bytes' => $record['size_bytes'],
		);
	}

	/**
	 * @param string $upload_id Upload id.
	 * @param string $phone     Expected owner phone.
	 * @param int    $form_id   Expected form id.
	 * @return array|WP_Error
	 */
	public static function resolve_upload( $upload_id, $phone, $form_id ) {
		$record = get_transient( self::TRANSIENT_PREFIX . sanitize_text_field( $upload_id ) );
		if ( ! is_array( $record ) ) {
			return new WP_Error(
				'upload_not_found',
				__( 'Upload not found or expired.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		if ( ! RadioUdaan_App_Auth::is_dev_auth_enabled() && $record['phone_e164'] !== $phone ) {
			return new WP_Error(
				'upload_forbidden',
				__( 'Upload does not belong to this session.', 'radioudaan-app-api' ),
				array( 'status' => 403 )
			);
		}

		if ( (int) $record['form_id'] !== (int) $form_id ) {
			return new WP_Error(
				'upload_form_mismatch',
				__( 'Upload was created for a different form.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		return $record;
	}

	/**
	 * Forminator upload field value shape.
	 *
	 * @param array $record Upload record.
	 * @return array
	 */
	public static function to_forminator_value( $record ) {
		$url = ! empty( $record['file_url'] ) ? $record['file_url'] : '';
		if ( ! $url && ! empty( $record['file_path'] ) ) {
			$url = $record['file_path'];
		}

		return array(
			'file' => array(
				'file_url'  => $url,
				'file_path' => $record['file_path'],
			),
		);
	}
}

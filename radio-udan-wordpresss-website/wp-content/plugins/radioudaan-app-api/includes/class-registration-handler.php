<?php
/**
 * Submit app registrations into Forminator.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Validates payload and creates Forminator entries tagged source=app.
 */
class RadioUdaan_Registration_Handler {

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function submit( WP_REST_Request $request ) {
		$event = RadioUdaan_Event_Registry::get_event( (int) $request['id'] );
		if ( ! $event ) {
			return new WP_Error(
				'event_not_found',
				__( 'Event not found.', 'radioudaan-app-api' ),
				array( 'status' => 404 )
			);
		}

		$open_check = RadioUdaan_Registration_Guard::assert_event_open( $event );
		if ( is_wp_error( $open_check ) ) {
			return $open_check;
		}

		$body = $request->get_json_params();
		if ( empty( $body['payload'] ) || ! is_array( $body['payload'] ) ) {
			return new WP_Error(
				'payload_required',
				__( 'payload object is required.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$phone = RadioUdaan_App_Auth::get_phone_from_request( $request );
		if ( ! $phone ) {
			return new WP_Error(
				'unauthorized',
				__( 'Authentication required.', 'radioudaan-app-api' ),
				array( 'status' => 401 )
			);
		}

		$email = self::get_authenticated_email( $request );

		$rate = RadioUdaan_Registration_Guard::check_rate_limits( $phone, $request );
		if ( is_wp_error( $rate ) ) {
			return $rate;
		}

		$form_id = (int) $event['form_id'];

		$dup = RadioUdaan_Registration_Guard::check_duplicate(
			$event,
			$form_id,
			$email
		);
		if ( is_wp_error( $dup ) ) {
			return $dup;
		}
		$schema  = RadioUdaan_Form_Schema_Builder::build_for_form(
			$form_id,
			array(
				'event_id'   => $event['event_id'],
				'event_code' => $event['event_code'],
				'title'      => $event['title'],
			)
		);

		if ( is_wp_error( $schema ) ) {
			return $schema;
		}

		$entry_meta = self::build_entry_meta(
			$schema['fields'],
			$body['payload'],
			$form_id,
			$phone
		);

		if ( is_wp_error( $entry_meta ) ) {
			return $entry_meta;
		}

		$client = isset( $body['client'] ) && is_array( $body['client'] ) ? $body['client'] : array();

		$entry_meta[] = array(
			'name'  => RadioUdaan_Entry_Source::META_KEY,
			'value' => RadioUdaan_Entry_Source::SOURCE_APP,
		);
		$entry_meta[] = array(
			'name'  => '_radioudaan_event_id',
			'value' => (int) $event['event_id'],
		);
		$entry_meta[] = array(
			'name'  => '_radioudaan_event_code',
			'value' => $event['event_code'],
		);
		$entry_meta[] = array(
			'name'  => '_radioudaan_phone_e164',
			'value' => $phone,
		);
		if ( $email ) {
			$entry_meta[] = array(
				'name'  => '_radioudaan_email',
				'value' => $email,
			);
		}
		if ( ! empty( $client['platform'] ) ) {
			$entry_meta[] = array(
				'name'  => '_radioudaan_client_platform',
				'value' => sanitize_text_field( $client['platform'] ),
			);
		}
		if ( ! empty( $client['app_version'] ) ) {
			$entry_meta[] = array(
				'name'  => '_radioudaan_client_version',
				'value' => sanitize_text_field( $client['app_version'] ),
			);
		}

		if ( ! class_exists( 'Forminator_API' ) ) {
			return new WP_Error(
				'forminator_inactive',
				__( 'Forminator is not available.', 'radioudaan-app-api' ),
				array( 'status' => 503 )
			);
		}

		Forminator_API::initialize();
		$entry_id = Forminator_API::add_form_entry( $form_id, $entry_meta );

		if ( is_wp_error( $entry_id ) ) {
			return $entry_id;
		}

		/**
		 * Fires after an app registration is stored in Forminator.
		 *
		 * @param int   $entry_id Forminator entry id.
		 * @param int   $form_id  Forminator form id.
		 * @param array $event    Event summary.
		 */
		do_action( 'radioudaan_app_api_registration_submitted', $entry_id, $form_id, $event );

		RadioUdaan_App_Logger::log(
			'registration_submitted',
			array(
				'event_id' => (int) $event['event_id'],
				'entry_id' => (int) $entry_id,
				'phone_e164' => $phone,
			)
		);

		return new WP_REST_Response(
			array(
				'submission_id' => 'reg_' . (int) $entry_id,
				'entry_id'      => (int) $entry_id,
				'status'        => 'submitted',
			),
			201
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return string Normalized email or empty string.
	 */
	private static function get_authenticated_email( WP_REST_Request $request ) {
		$session = RadioUdaan_App_Auth::get_session_from_request( $request );
		if ( ! $session || empty( $session['user']['email'] ) ) {
			return '';
		}

		return strtolower( sanitize_email( (string) $session['user']['email'] ) );
	}

	/**
	 * @param array  $schema_fields Schema fields.
	 * @param array  $payload       Client payload (keys = element_id).
	 * @param int    $form_id       Forminator form id.
	 * @param string $phone         Session phone.
	 * @return array|WP_Error
	 */
	private static function build_entry_meta( $schema_fields, $payload, $form_id, $phone ) {
		$entry_meta = array();

		foreach ( $schema_fields as $field ) {
			$key = $field['key'];
			if ( ! array_key_exists( $key, $payload ) ) {
				if ( ! empty( $field['required'] ) ) {
					return new WP_Error(
						'field_required',
						sprintf(
							/* translators: %s: field key */
							__( 'Required field missing: %s', 'radioudaan-app-api' ),
							$key
						),
						array( 'status' => 400 )
					);
				}
				continue;
			}

			$value = $payload[ $key ];
			if ( self::is_empty_value( $value ) ) {
				if ( ! empty( $field['required'] ) ) {
					return new WP_Error(
						'field_required',
						sprintf(
							/* translators: %s: field key */
							__( 'Required field empty: %s', 'radioudaan-app-api' ),
							$key
						),
						array( 'status' => 400 )
					);
				}
				continue;
			}

			if ( 'upload' === $field['type'] ) {
				$resolved = self::resolve_upload_value( $value, $phone, $form_id );
				if ( is_wp_error( $resolved ) ) {
					return $resolved;
				}
				$entry_meta[] = array(
					'name'  => $key,
					'value' => $resolved,
				);
				continue;
			}

			$entry_meta[] = array(
				'name'  => $key,
				'value' => self::sanitize_scalar( $value, $field['type'] ),
			);
		}

		return $entry_meta;
	}

	/**
	 * @param mixed $value Value.
	 * @return bool
	 */
	private static function is_empty_value( $value ) {
		if ( is_array( $value ) && empty( $value ) ) {
			return true;
		}

		return '' === $value || null === $value;
	}

	/**
	 * @param mixed  $value Field value or upload ref(s).
	 * @param string $phone Phone.
	 * @param int    $form_id Form id.
	 * @return array|WP_Error
	 */
	private static function resolve_upload_value( $value, $phone, $form_id ) {
		$upload_id = '';

		if ( is_string( $value ) ) {
			$upload_id = $value;
		} elseif ( is_array( $value ) ) {
			if ( isset( $value['upload_id'] ) ) {
				$upload_id = $value['upload_id'];
			} elseif ( isset( $value[0]['upload_id'] ) ) {
				$upload_id = $value[0]['upload_id'];
			}
		}

		if ( ! $upload_id ) {
			return new WP_Error(
				'upload_ref_invalid',
				__( 'Upload field must include upload_id.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$record = RadioUdaan_App_Uploads::resolve_upload( $upload_id, $phone, $form_id );
		if ( is_wp_error( $record ) ) {
			return $record;
		}

		return RadioUdaan_App_Uploads::to_forminator_value( $record );
	}

	/**
	 * @param mixed  $value Value.
	 * @param string $type  App field type.
	 * @return string|array
	 */
	private static function sanitize_scalar( $value, $type ) {
		if ( is_array( $value ) ) {
			return array_map( 'sanitize_text_field', $value );
		}

		if ( 'email' === $type ) {
			return sanitize_email( (string) $value );
		}

		return sanitize_text_field( (string) $value );
	}
}

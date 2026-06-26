<?php
/**
 * Submit app registrations into Forminator.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

require_once RADIOUDAAN_APP_API_PATH . 'includes/class-form-visibility.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-form-field-validator.php';

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

		$schema = RadioUdaan_Form_Schema_Builder::build_for_form(
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

		if ( empty( $schema['app_submittable'] ) ) {
			$warnings = ! empty( $schema['form_warnings'] ) && is_array( $schema['form_warnings'] )
				? $schema['form_warnings']
				: array( __( 'This form cannot be submitted in the app.', 'radioudaan-app-api' ) );

			return new WP_Error(
				'form_not_submittable',
				implode( ' ', $warnings ),
				array(
					'status'   => 400,
					'warnings' => $warnings,
				)
			);
		}

		$unsupported_block = self::blocking_unsupported_message( $schema['unsupported_fields'] ?? array() );
		if ( $unsupported_block ) {
			return new WP_Error(
				'form_not_submittable',
				$unsupported_block,
				array( 'status' => 400 )
			);
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
				'event_id'   => (int) $event['event_id'],
				'entry_id'   => (int) $entry_id,
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
		$entry_meta   = array();
		$fields_index = RadioUdaan_Form_Visibility::index_fields( $schema_fields );

		foreach ( $schema_fields as $field ) {
			$key  = $field['key'];
			$type = isset( $field['type'] ) ? (string) $field['type'] : 'text';

			if ( 'info' === $type ) {
				continue;
			}

			if ( ! RadioUdaan_Form_Visibility::is_field_visible( $field, $fields_index, $payload ) ) {
				continue;
			}

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
			if ( self::is_empty_value( $value, $field ) ) {
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

			$validated = RadioUdaan_Form_Field_Validator::validate_field( $field, $value );
			if ( is_wp_error( $validated ) ) {
				return $validated;
			}

			if ( 'upload' === $type ) {
				$resolved = self::resolve_upload_value( $value, $phone, $form_id, $field );
				if ( is_wp_error( $resolved ) ) {
					return $resolved;
				}
				$entry_meta[] = array(
					'name'  => $key,
					'value' => $resolved,
				);
				continue;
			}

			if ( in_array( $type, array( 'address', 'name' ), true ) ) {
				$converted = self::convert_subfield_value( $field, $value );
				$entry_meta[] = array(
					'name'  => $key,
					'value' => maybe_serialize( $converted ),
				);
				continue;
			}

			$entry_meta[] = array(
				'name'  => $key,
				'value' => self::sanitize_scalar( $value, $type ),
			);
		}

		return $entry_meta;
	}

	/**
	 * @param array<string,mixed> $field Schema field.
	 * @param mixed               $value Map payload.
	 * @return array<string,string>
	 */
	private static function convert_subfield_value( $field, $value ) {
		$map     = is_array( $value ) ? $value : array();
		$allowed = array();

		if ( ! empty( $field['subfields'] ) && is_array( $field['subfields'] ) ) {
			foreach ( $field['subfields'] as $sub ) {
				if ( empty( $sub['key'] ) ) {
					continue;
				}
				$allowed[ (string) $sub['key'] ] = true;
			}
		}

		$out = array();
		foreach ( $map as $sub_key => $sub_value ) {
			$key = (string) $sub_key;
			if ( ! empty( $allowed ) && empty( $allowed[ $key ] ) ) {
				continue;
			}
			$out[ $key ] = sanitize_text_field( (string) $sub_value );
		}

		return $out;
	}

	/**
	 * @param mixed               $value Value.
	 * @param array<string,mixed> $field Field schema.
	 * @return bool
	 */
	private static function is_empty_value( $value, $field ) {
		if ( is_array( $value ) && empty( $value ) ) {
			return true;
		}

		if ( is_bool( $value ) ) {
			$type = isset( $field['type'] ) ? (string) $field['type'] : 'text';
			if ( 'checkbox' === $type ) {
				return ! $value;
			}
		}

		if ( is_array( $value ) && self::is_assoc_map( $value ) ) {
			foreach ( $value as $item ) {
				if ( null !== $item && '' !== trim( (string) $item ) ) {
					return false;
				}
			}
			return true;
		}

		return '' === $value || null === $value;
	}

	/**
	 * @param mixed               $value Field value or upload ref(s).
	 * @param string              $phone Phone.
	 * @param int                 $form_id Form id.
	 * @param array<string,mixed> $field Schema field.
	 * @return array|WP_Error
	 */
	private static function resolve_upload_value( $value, $phone, $form_id, $field ) {
		$upload_ids = self::extract_upload_ids( $value );
		if ( empty( $upload_ids ) ) {
			return new WP_Error(
				'upload_ref_invalid',
				__( 'Upload field must include upload_id.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$max_files = ! empty( $field['max_files'] ) ? (int) $field['max_files'] : 1;
		if ( count( $upload_ids ) > $max_files ) {
			return new WP_Error(
				'upload_too_many',
				sprintf(
					/* translators: %d: max files */
					__( 'Too many files uploaded. Maximum is %d.', 'radioudaan-app-api' ),
					$max_files
				),
				array( 'status' => 400 )
			);
		}

		$resolved = array();
		foreach ( $upload_ids as $upload_id ) {
			$record = RadioUdaan_App_Uploads::resolve_upload( $upload_id, $phone, $form_id );
			if ( is_wp_error( $record ) ) {
				return $record;
			}
			$resolved[] = RadioUdaan_App_Uploads::to_forminator_value( $record );
		}

		if ( 1 === count( $resolved ) ) {
			return $resolved[0];
		}

		return $resolved;
	}

	/**
	 * @param mixed $value Upload payload.
	 * @return string[]
	 */
	private static function extract_upload_ids( $value ) {
		$ids = array();

		if ( is_string( $value ) && '' !== trim( $value ) ) {
			return array( sanitize_text_field( $value ) );
		}

		if ( ! is_array( $value ) ) {
			return $ids;
		}

		if ( isset( $value['upload_id'] ) ) {
			return array( sanitize_text_field( (string) $value['upload_id'] ) );
		}

		foreach ( $value as $item ) {
			if ( is_string( $item ) && '' !== trim( $item ) ) {
				$ids[] = sanitize_text_field( $item );
				continue;
			}
			if ( is_array( $item ) && ! empty( $item['upload_id'] ) ) {
				$ids[] = sanitize_text_field( (string) $item['upload_id'] );
			}
		}

		return $ids;
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

		if ( 'checkbox' === $type ) {
			if ( true === $value || '1' === (string) $value ) {
				return '1';
			}
		}

		return sanitize_text_field( (string) $value );
	}

	/**
	 * @param array<mixed> $value Value.
	 * @return bool
	 */
	private static function is_assoc_map( $value ) {
		foreach ( array_keys( $value ) as $key ) {
			if ( ! is_int( $key ) ) {
				return true;
			}
		}
		return false;
	}

	/**
	 * @param array<int,array<string,mixed>> $unsupported Unsupported fields from schema.
	 * @return string Empty when submit is allowed.
	 */
	private static function blocking_unsupported_message( $unsupported ) {
		foreach ( $unsupported as $field ) {
			if ( empty( $field['required'] ) && empty( $field['blocks_submit'] ) ) {
				continue;
			}
			$label = isset( $field['label'] ) ? (string) $field['label'] : '';
			$type  = isset( $field['type'] ) ? (string) $field['type'] : '';
			return sprintf(
				/* translators: 1: field label, 2: field type */
				__( 'This form cannot be submitted in the app until unsupported field %1$s (%2$s) is removed or made optional.', 'radioudaan-app-api' ),
				$label ? $label : (string) ( $field['key'] ?? '' ),
				$type
			);
		}

		return '';
	}
}

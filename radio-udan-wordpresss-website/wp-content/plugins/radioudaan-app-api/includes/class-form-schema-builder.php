<?php
/**
 * Build mobile form schema JSON from Forminator forms.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Converts Forminator field definitions to app schema.
 */
class RadioUdaan_Form_Schema_Builder {

	const SUPPORTED_FIELD_TYPES_VERSION = 1;

	/**
	 * Layout-only types (not in fields[]).
	 *
	 * @var string[]
	 */
	private static $layout_types = array(
		'section',
		'group',
		'pagination',
	);

	/**
	 * Skipped Forminator field types (non-input).
	 *
	 * @var string[]
	 */
	private static $skip_types = array(
		'html',
		'captcha',
		'stripe',
		'stripe-ocs',
		'paypal',
		'calculation',
		'hidden',
		'button',
	);

	/**
	 * @param int   $form_id     Forminator form post ID.
	 * @param array $event_summary Event block for response.
	 * @return array|WP_Error
	 */
	public static function build_for_form( $form_id, $event_summary ) {
		if ( ! class_exists( 'Forminator_Form_Model' ) ) {
			return new WP_Error(
				'forminator_inactive',
				__( 'Forminator is not available.', 'radioudaan-app-api' ),
				array( 'status' => 503 )
			);
		}

		$model = Forminator_Form_Model::model()->load( (int) $form_id );
		if ( ! $model ) {
			return new WP_Error(
				'form_not_found',
				__( 'Form not found.', 'radioudaan-app-api' ),
				array( 'status' => 404 )
			);
		}

		$fields_raw       = $model->get_real_fields();
		$fields           = array();
		$sections         = array();
		$pages            = array();
		$unsupported      = array();
		$current_section  = 'default';
		$max_upload       = 10;

		if ( ! self::has_section_id( $sections, 'default' ) ) {
			$sections[] = array(
				'id'    => 'default',
				'title' => __( 'Details', 'radioudaan-app-api' ),
			);
		}

		foreach ( $fields_raw as $field ) {
			$arr  = $field->to_formatted_array();
			$type = isset( $arr['type'] ) ? (string) $arr['type'] : '';

			if ( 'section' === $type || 'group' === $type ) {
				$sid = self::element_id( $arr, $type );
				$sections[] = array(
					'id'    => $sid,
					'title' => self::field_label( $arr, $type ),
				);
				$current_section = $sid;
				continue;
			}

			if ( 'pagination' === $type ) {
				$pages[] = array(
					'id'    => self::element_id( $arr, 'page' ),
					'title' => self::field_label( $arr, $type ),
				);
				continue;
			}

			if ( in_array( $type, self::$skip_types, true ) ) {
				continue;
			}

			$mapped = self::map_field( $arr, $type, $current_section );
			if ( $mapped ) {
				$fields[] = $mapped;
				if ( 'upload' === $mapped['type'] && ! empty( $mapped['max_size_mb'] ) ) {
					$max_upload = max( $max_upload, (int) $mapped['max_size_mb'] );
				}
			} elseif ( $type ) {
				$unsupported[] = array(
					'key'   => self::element_id( $arr, $type ),
					'label' => self::field_label( $arr, $type ),
					'type'  => $type,
				);
			}
		}

		if ( empty( $fields ) ) {
			return new WP_Error(
				'form_empty',
				__( 'Form has no supported fields.', 'radioudaan-app-api' ),
				array( 'status' => 500 )
			);
		}

		$form_post = get_post( (int) $form_id );

		return array(
			'event'                         => $event_summary,
			'form'                          => array(
				'form_id'    => (int) $form_id,
				'name'       => $model->name,
				'updated_at' => $form_post
					? gmdate( 'c', strtotime( $form_post->post_modified_gmt ? $form_post->post_modified_gmt : $form_post->post_modified ) )
					: gmdate( 'c' ),
			),
			'supported_field_types_version' => self::SUPPORTED_FIELD_TYPES_VERSION,
			'upload_constraints'            => array(
				'max_file_mb'         => max( $max_upload, RadioUdaan_App_Settings::get_max_upload_mb() ),
				'max_files_per_field' => RadioUdaan_App_Settings::get_max_files_per_field(),
				'allowed_mime'        => RadioUdaan_App_Settings::get_allowed_mime_list(),
			),
			'sections'                      => $sections,
			'pages'                         => $pages,
			'fields'                        => $fields,
			'unsupported_fields'            => $unsupported,
		);
	}

	/**
	 * @param array  $sections Sections.
	 * @param string $id       Section id.
	 * @return bool
	 */
	private static function has_section_id( $sections, $id ) {
		foreach ( $sections as $section ) {
			if ( isset( $section['id'] ) && $section['id'] === $id ) {
				return true;
			}
		}
		return false;
	}

	/**
	 * @param array  $arr  Field settings.
	 * @param string $type Type slug.
	 * @return string
	 */
	private static function element_id( $arr, $type ) {
		if ( ! empty( $arr['element_id'] ) ) {
			return (string) $arr['element_id'];
		}
		if ( ! empty( $arr['id'] ) ) {
			return (string) $arr['id'];
		}
		return 'field_' . sanitize_key( $type ) . '_' . wp_rand( 1000, 9999 );
	}

	/**
	 * @param array  $arr          Field settings.
	 * @param string $type         Forminator type.
	 * @param string $section_id   Current section.
	 * @return array<string,mixed>|null
	 */
	private static function map_field( $arr, $type, $section_id ) {
		$element_id = self::element_id( $arr, $type );

		$app_type = self::map_field_type( $type );
		if ( ! $app_type ) {
			return null;
		}

		$label = self::field_label( $arr, $type );
		$out   = array(
			'key'        => $element_id,
			'label'      => $label,
			'type'       => $app_type,
			'required'   => ! empty( $arr['required'] ),
			'section_id' => $section_id,
		);

		if ( in_array( $app_type, array( 'radio', 'select', 'checkbox' ), true ) ) {
			$out['options'] = self::field_options( $arr, $type );
		}

		if ( 'upload' === $app_type ) {
			$out['max_size_mb'] = ! empty( $arr['upload-limit'] ) ? (int) $arr['upload-limit'] : 10;
			$out['allowed_ext'] = self::parse_upload_extensions( $arr );
			$out['max_files']   = RadioUdaan_App_Settings::get_max_files_per_field();
		}

		if ( 'number' === $app_type ) {
			if ( isset( $arr['limit_min'] ) && '' !== $arr['limit_min'] ) {
				$out['min'] = (float) $arr['limit_min'];
			}
			if ( isset( $arr['limit_max'] ) && '' !== $arr['limit_max'] ) {
				$out['max'] = (float) $arr['limit_max'];
			}
			if ( ! isset( $out['min'] ) && ! empty( $arr['required'] ) ) {
				$out['min'] = 0;
			}
			if ( ! isset( $out['max'] ) && false !== strpos( strtolower( $label ), 'percentage' ) ) {
				$out['max'] = 100;
			}
		}

		if ( ! empty( $arr['placeholder'] ) ) {
			$out['placeholder'] = (string) $arr['placeholder'];
		}

		return $out;
	}

	/**
	 * @param array  $arr  Field settings.
	 * @param string $type Forminator type.
	 * @return string
	 */
	private static function field_label( $arr, $type ) {
		$label = isset( $arr['field_label'] ) ? wp_strip_all_tags( (string) $arr['field_label'] ) : '';
		$label = trim( $label );

		if ( '' === $label && 'select' === $type ) {
			return __( 'Type of Disability', 'radioudaan-app-api' );
		}

		if ( '' === $label && ! empty( $arr['label'] ) ) {
			$label = wp_strip_all_tags( (string) $arr['label'] );
		}

		return $label ? $label : $type;
	}

	/**
	 * @param string $forminator_type Forminator slug.
	 * @return string|null App type.
	 */
	private static function map_field_type( $forminator_type ) {
		$map = array(
			'text'           => 'text',
			'textarea'       => 'textarea',
			'email'          => 'email',
			'phone'          => 'phone',
			'number'         => 'number',
			'currency'       => 'number',
			'date'           => 'date',
			'time'           => 'time',
			'datetime'       => 'datetime',
			'select'         => 'select',
			'radio'          => 'radio',
			'checkbox'       => 'checkbox',
			'multiselect'    => 'checkbox',
			'upload'         => 'upload',
			'url'            => 'url',
			'name'           => 'text',
			'address'        => 'address',
			'postdata'       => 'text',
			'consent'        => 'checkbox',
		);

		return isset( $map[ $forminator_type ] ) ? $map[ $forminator_type ] : null;
	}

	/**
	 * @param array  $arr  Field settings.
	 * @param string $type Type.
	 * @return string[]
	 */
	private static function field_options( $arr, $type ) {
		$options = array();

		if ( 'radio' === $type && ! empty( $arr['options'] ) && is_array( $arr['options'] ) ) {
			foreach ( $arr['options'] as $opt ) {
				if ( is_array( $opt ) && isset( $opt['label'] ) ) {
					$options[] = (string) $opt['label'];
				} elseif ( is_string( $opt ) ) {
					$options[] = $opt;
				}
			}
			return $options;
		}

		if ( ! empty( $arr['options'] ) && is_array( $arr['options'] ) ) {
			foreach ( $arr['options'] as $opt ) {
				if ( is_array( $opt ) ) {
					$val = isset( $opt['value'] ) && '' !== $opt['value'] ? $opt['value'] : ( $opt['label'] ?? '' );
					if ( '' !== $val ) {
						$options[] = (string) $val;
					}
				}
			}
		}

		return $options;
	}

	/**
	 * @param array $arr Field settings.
	 * @return string[]
	 */
	private static function parse_upload_extensions( $arr ) {
		$ext = array();
		if ( empty( $arr['filetypes'] ) || ! is_array( $arr['filetypes'] ) ) {
			return array( 'pdf', 'jpg', 'jpeg', 'png', 'mp3', 'wav', 'm4a' );
		}

		foreach ( $arr['filetypes'] as $ft ) {
			$parts = explode( '|', (string) $ft );
			foreach ( $parts as $part ) {
				$part = strtolower( trim( $part ) );
				if ( $part && ! in_array( $part, $ext, true ) ) {
					$ext[] = $part;
				}
			}
		}

		return $ext ? $ext : array( 'pdf', 'jpg', 'jpeg', 'png' );
	}
}

<?php
/**
 * Build mobile form schema JSON from Forminator forms.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

require_once RADIOUDAAN_APP_API_PATH . 'includes/class-form-visibility.php';

/**
 * Converts Forminator field definitions to app schema.
 */
class RadioUdaan_Form_Schema_Builder {

	const SUPPORTED_FIELD_TYPES_VERSION = 2;

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
	 * Unsupported Forminator types tracked in unsupported_fields[].
	 *
	 * @var string[]
	 */
	private static $unsupported_types = array(
		'captcha',
		'stripe',
		'stripe-ocs',
		'paypal',
		'calculation',
		'hidden',
		'password',
		'custom',
	);

	/**
	 * Types that block app submission when present.
	 *
	 * @var string[]
	 */
	private static $blocking_types = array(
		'captcha',
		'stripe',
		'stripe-ocs',
		'paypal',
	);

	/**
	 * Skipped without unsupported entry.
	 *
	 * @var string[]
	 */
	private static $skip_silent_types = array(
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

		$audit = self::audit_form_compatibility( $model );

		$fields_raw      = $model->get_real_fields();
		$fields          = array();
		$sections        = array();
		$pages           = array();
		$unsupported     = array();
		$current_section = 'default';
		$current_page    = 0;
		$max_upload      = 10;

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
				++$current_page;
				continue;
			}

			if ( in_array( $type, self::$skip_silent_types, true ) ) {
				continue;
			}

			if ( in_array( $type, self::$unsupported_types, true ) ) {
				$unsupported[] = self::unsupported_field_entry( $arr, $type );
				continue;
			}

			if ( 'html' === $type ) {
				$mapped = self::map_html_field( $arr, $current_section, $current_page );
				if ( $mapped ) {
					$fields[] = $mapped;
				}
				continue;
			}

			$mapped = self::map_field( $arr, $type, $current_section, $current_page );
			if ( $mapped ) {
				$fields[] = $mapped;
				if ( 'upload' === $mapped['type'] && ! empty( $mapped['max_size_mb'] ) ) {
					$max_upload = max( $max_upload, (int) $mapped['max_size_mb'] );
				}
			} elseif ( $type ) {
				$unsupported[] = self::unsupported_field_entry( $arr, $type );
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
			'form_warnings'                 => $audit['warnings'],
			'app_submittable'               => $audit['app_submittable'],
			'form_compatibility'            => array(
				'app_submittable'           => $audit['app_submittable'],
				'supported_field_count'     => count( $fields ),
				'conditional_field_count'   => self::count_conditional_fields( $fields ),
				'page_count'                => count( $pages ),
				'unsupported_field_count'   => count( $unsupported ),
				'schema_version'            => self::SUPPORTED_FIELD_TYPES_VERSION,
			),
		);
	}

	/**
	 * Audit a Forminator form for app compatibility.
	 *
	 * @param Forminator_Form_Model $model Form model.
	 * @return array{warnings:string[],app_submittable:bool,conditional_field_count:int}
	 */
	public static function audit_form_compatibility( $model ) {
		$warnings                 = array();
		$app_submittable          = true;
		$conditional_field_count  = 0;
		$fields_raw               = $model->get_real_fields();

		foreach ( $fields_raw as $field ) {
			$arr  = $field->to_formatted_array();
			$type = isset( $arr['type'] ) ? (string) $arr['type'] : '';

			if ( ! empty( $arr['conditions'] ) && is_array( $arr['conditions'] ) ) {
				++$conditional_field_count;
			}

			if ( in_array( $type, self::$layout_types, true ) || in_array( $type, self::$skip_silent_types, true ) ) {
				continue;
			}

			if ( 'html' === $type ) {
				continue;
			}

			if ( in_array( $type, self::$unsupported_types, true ) ) {
				$entry = self::unsupported_field_entry( $arr, $type );
				$label = $entry['label'];
				if ( ! empty( $entry['blocks_submit'] ) || ! empty( $entry['required'] ) ) {
					$app_submittable = false;
				}
				if ( ! empty( $entry['blocks_submit'] ) ) {
					$warnings[] = sprintf(
						/* translators: 1: field label, 2: field type */
						__( 'The form includes %1$s (%2$s), which cannot be completed in the app.', 'radioudaan-app-api' ),
						$label,
						$type
					);
				} elseif ( ! empty( $entry['required'] ) ) {
					$warnings[] = sprintf(
						/* translators: 1: field label, 2: field type */
						__( 'Required field %1$s (%2$s) is not supported in the app.', 'radioudaan-app-api' ),
						$label,
						$type
					);
				}
				continue;
			}

			$app_type = self::map_field_type( $type );
			if ( ! $app_type ) {
				$entry = self::unsupported_field_entry( $arr, $type );
				if ( ! empty( $entry['required'] ) ) {
					$app_submittable = false;
					$warnings[] = sprintf(
						/* translators: 1: field label, 2: field type */
						__( 'Required field %1$s (%2$s) is not supported in the app.', 'radioudaan-app-api' ),
						$entry['label'],
						$type
					);
				}
			}
		}

		return array(
			'warnings'                => $warnings,
			'app_submittable'         => $app_submittable,
			'conditional_field_count' => $conditional_field_count,
		);
	}

	/**
	 * Compatibility audit for a Forminator form ID (wp-admin).
	 *
	 * @param int $form_id Forminator form post ID.
	 * @return array<string,mixed>|null
	 */
	public static function get_compatibility_report( $form_id ) {
		if ( ! class_exists( 'Forminator_Form_Model' ) || $form_id <= 0 ) {
			return null;
		}

		$model = Forminator_Form_Model::model()->load( (int) $form_id );
		if ( ! $model ) {
			return null;
		}

		$built = self::build_for_form(
			(int) $form_id,
			array(
				'event_id' => 0,
				'title'      => $model->name,
			)
		);

		if ( is_wp_error( $built ) ) {
			return array(
				'app_submittable' => false,
				'warnings'        => array( $built->get_error_message() ),
				'error'           => $built->get_error_code(),
			);
		}

		return array(
			'app_submittable'         => ! empty( $built['app_submittable'] ),
			'warnings'                => $built['form_warnings'] ?? array(),
			'form_compatibility'      => $built['form_compatibility'] ?? array(),
			'unsupported_fields'      => $built['unsupported_fields'] ?? array(),
			'conditional_field_count' => $built['form_compatibility']['conditional_field_count'] ?? 0,
		);
	}

	/**
	 * @param array<int,array<string,mixed>> $fields Schema fields.
	 * @return int
	 */
	private static function count_conditional_fields( $fields ) {
		$count = 0;
		foreach ( $fields as $field ) {
			if ( ! empty( $field['visibility'] ) ) {
				++$count;
			}
		}
		return $count;
	}

	/**
	 * Lookup a mapped schema field by element key (for uploads and validation).
	 *
	 * @param int    $form_id   Forminator form id.
	 * @param string $field_key Element id.
	 * @return array<string,mixed>|null
	 */
	public static function get_field_by_key( $form_id, $field_key ) {
		if ( ! class_exists( 'Forminator_Form_Model' ) ) {
			return null;
		}

		$model = Forminator_Form_Model::model()->load( (int) $form_id );
		if ( ! $model ) {
			return null;
		}

		$current_section = 'default';
		$current_page    = 0;

		foreach ( $model->get_real_fields() as $field ) {
			$arr  = $field->to_formatted_array();
			$type = isset( $arr['type'] ) ? (string) $arr['type'] : '';

			if ( 'section' === $type || 'group' === $type ) {
				$current_section = self::element_id( $arr, $type );
				continue;
			}

			if ( 'pagination' === $type ) {
				++$current_page;
				continue;
			}

			if ( self::element_id( $arr, $type ) !== (string) $field_key ) {
				continue;
			}

			if ( 'html' === $type ) {
				return self::map_html_field( $arr, $current_section, $current_page );
			}

			return self::map_field( $arr, $type, $current_section, $current_page );
		}

		return null;
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
	 * @return array<string,mixed>
	 */
	private static function unsupported_field_entry( $arr, $type ) {
		return array(
			'key'           => self::element_id( $arr, $type ),
			'label'         => self::field_label( $arr, $type ),
			'type'          => $type,
			'required'      => ! empty( $arr['required'] ),
			'blocks_submit' => in_array( $type, self::$blocking_types, true ),
		);
	}

	/**
	 * @param array  $arr          Field settings.
	 * @param string $section_id   Current section.
	 * @param int    $page_index   Current page index.
	 * @return array<string,mixed>|null
	 */
	private static function map_html_field( $arr, $section_id, $page_index ) {
		$html = '';
		if ( ! empty( $arr['variations'] ) && is_array( $arr['variations'] ) ) {
			foreach ( $arr['variations'] as $variation ) {
				if ( ! empty( $variation['content'] ) ) {
					$html .= (string) $variation['content'];
				}
			}
		}
		if ( '' === $html && ! empty( $arr['content'] ) ) {
			$html = (string) $arr['content'];
		}

		return array(
			'key'        => self::element_id( $arr, 'html' ),
			'label'      => self::field_label( $arr, 'html' ),
			'type'       => 'info',
			'required'   => false,
			'section_id' => $section_id,
			'page_index' => (int) $page_index,
			'html'       => self::sanitize_info_html( $html ),
		);
	}

	/**
	 * @param string $html Raw HTML.
	 * @return string
	 */
	private static function sanitize_info_html( $html ) {
		$allowed = array(
			'a'      => array(
				'href'   => true,
				'title'  => true,
				'target' => true,
				'rel'    => true,
			),
			'br'     => array(),
			'em'     => array(),
			'strong' => array(),
			'p'      => array(),
			'ul'     => array(),
			'ol'     => array(),
			'li'     => array(),
			'span'   => array(),
		);

		return trim( wp_kses( (string) $html, $allowed ) );
	}

	/**
	 * @param array  $arr          Field settings.
	 * @param string $type         Forminator type.
	 * @param string $section_id   Current section.
	 * @param int    $page_index   Current page index.
	 * @return array<string,mixed>|null
	 */
	private static function map_field( $arr, $type, $section_id, $page_index ) {
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
			'page_index' => (int) $page_index,
		);

		if ( in_array( $app_type, array( 'radio', 'select', 'checkbox' ), true ) ) {
			$choice_options           = self::choice_options( $arr, $type );
			$out['choice_options']    = $choice_options;
			$out['options']           = self::options_labels( $choice_options );
		}

		if ( 'address' === $app_type ) {
			$out['subfields'] = self::address_subfields( $arr );
		}

		if ( 'name' === $app_type ) {
			$out['subfields'] = self::name_subfields( $arr );
		}

		if ( in_array( $type, array( 'consent', 'gdprcheckbox' ), true ) && ! empty( $arr['required_message'] ) ) {
			$out['consent_html'] = self::sanitize_info_html( (string) $arr['required_message'] );
		}

		if ( 'upload' === $app_type ) {
			$out['max_size_mb'] = ! empty( $arr['upload-limit'] ) ? (int) $arr['upload-limit'] : 10;
			$out['allowed_ext'] = self::parse_upload_extensions( $arr );
			$out['max_files']   = self::upload_max_files( $arr );
		}

		if ( in_array( $app_type, array( 'number', 'slider' ), true ) ) {
			if ( isset( $arr['limit_min'] ) && '' !== $arr['limit_min'] ) {
				$out['min'] = (float) $arr['limit_min'];
			}
			if ( isset( $arr['limit_max'] ) && '' !== $arr['limit_max'] ) {
				$out['max'] = (float) $arr['limit_max'];
			}
			if ( 'slider' === $app_type && isset( $arr['limit_step'] ) && '' !== $arr['limit_step'] ) {
				$out['step'] = (float) $arr['limit_step'];
			}
			if ( ! isset( $out['min'] ) && ! empty( $arr['required'] ) ) {
				$out['min'] = 0;
			}
			if ( ! isset( $out['max'] ) && false !== strpos( strtolower( $label ), 'percentage' ) ) {
				$out['max'] = 100;
			}
		}

		if ( 'rating' === $app_type ) {
			$max_rating = isset( $arr['max_rating'] ) ? (int) $arr['max_rating'] : 5;
			$max_rating = max( 1, min( 50, $max_rating ) );
			$out['max']   = (float) $max_rating;
			$choices      = array();
			for ( $i = 1; $i <= $max_rating; $i++ ) {
				$choices[] = array(
					'value' => (string) $i,
					'label' => (string) $i,
				);
			}
			$out['choice_options'] = $choices;
			$out['options']        = self::options_labels( $choices );
		}

		if ( ! empty( $arr['placeholder'] ) ) {
			$out['placeholder'] = (string) $arr['placeholder'];
		}

		$visibility = RadioUdaan_Form_Visibility::export_from_field( $arr );
		if ( $visibility ) {
			$out['visibility'] = $visibility;
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

		if ( '' === $label && in_array( $type, array( 'consent', 'gdprcheckbox' ), true ) && ! empty( $arr['required_message'] ) ) {
			$label = wp_strip_all_tags( (string) $arr['required_message'] );
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
			'name'           => 'name',
			'address'        => 'address',
			'postdata'       => 'text',
			'consent'        => 'checkbox',
			'gdprcheckbox'   => 'checkbox',
			'slider'         => 'slider',
			'rating'         => 'rating',
		);

		return isset( $map[ $forminator_type ] ) ? $map[ $forminator_type ] : null;
	}

	/**
	 * @param array  $arr  Field settings.
	 * @param string $type Type.
	 * @return array<int,array{value:string,label:string}>
	 */
	private static function choice_options( $arr, $type ) {
		$options = array();

		if ( 'radio' === $type && ! empty( $arr['options'] ) && is_array( $arr['options'] ) ) {
			foreach ( $arr['options'] as $opt ) {
				if ( is_array( $opt ) ) {
					$label = isset( $opt['label'] ) ? (string) $opt['label'] : '';
					$value = isset( $opt['value'] ) && '' !== $opt['value'] ? (string) $opt['value'] : $label;
					if ( '' !== $value ) {
						$options[] = array(
							'value' => $value,
							'label' => $label ? $label : $value,
						);
					}
				} elseif ( is_string( $opt ) && '' !== $opt ) {
					$options[] = array(
						'value' => $opt,
						'label' => $opt,
					);
				}
			}
			return $options;
		}

		if ( ! empty( $arr['options'] ) && is_array( $arr['options'] ) ) {
			foreach ( $arr['options'] as $opt ) {
				if ( ! is_array( $opt ) ) {
					continue;
				}
				$label = isset( $opt['label'] ) ? (string) $opt['label'] : '';
				$value = isset( $opt['value'] ) && '' !== $opt['value'] ? (string) $opt['value'] : $label;
				if ( '' !== $value ) {
					$options[] = array(
						'value' => $value,
						'label' => $label ? $label : $value,
					);
				}
			}
		}

		return $options;
	}

	/**
	 * @param array<int,array{value:string,label:string}> $choice_options Options.
	 * @return string[]
	 */
	private static function options_labels( $choice_options ) {
		$labels = array();
		foreach ( $choice_options as $opt ) {
			$labels[] = ! empty( $opt['label'] ) ? (string) $opt['label'] : (string) $opt['value'];
		}
		return $labels;
	}

	/**
	 * @param array $arr Field settings.
	 * @return array<int,array{key:string,label:string,required:bool}>
	 */
	private static function address_subfields( $arr ) {
		$parts = array(
			array(
				'key'          => 'street_address',
				'setting'      => 'street_address',
				'label_key'    => 'street_address_label',
				'default'      => __( 'Street Address', 'radioudaan-app-api' ),
				'required_key' => 'street_address_required',
			),
			array(
				'key'          => 'address_line',
				'setting'      => 'address_line',
				'label_key'    => 'address_line_label',
				'default'      => __( 'Apartment, suite, etc', 'radioudaan-app-api' ),
				'required_key' => 'address_line_required',
			),
			array(
				'key'          => 'address_city',
				'setting'      => 'address_city',
				'label_key'    => 'address_city_label',
				'default'      => __( 'City', 'radioudaan-app-api' ),
				'required_key' => 'address_city_required',
			),
			array(
				'key'          => 'address_state',
				'setting'      => 'address_state',
				'label_key'    => 'address_state_label',
				'default'      => __( 'State/Province', 'radioudaan-app-api' ),
				'required_key' => 'address_state_required',
			),
			array(
				'key'          => 'address_zip',
				'setting'      => 'address_zip',
				'label_key'    => 'address_zip_label',
				'default'      => __( 'ZIP / Postal Code', 'radioudaan-app-api' ),
				'required_key' => 'address_zip_required',
			),
			array(
				'key'          => 'address_country',
				'setting'      => 'address_country',
				'label_key'    => 'address_country_label',
				'default'      => __( 'Country', 'radioudaan-app-api' ),
				'required_key' => 'address_country_required',
			),
		);

		$parent_required = ! empty( $arr['required'] );
		$subfields       = array();

		foreach ( $parts as $part ) {
			if ( ! self::subfield_enabled( $arr, $part['setting'] ) ) {
				continue;
			}

			$label = ! empty( $arr[ $part['label_key'] ] )
				? wp_strip_all_tags( (string) $arr[ $part['label_key'] ] )
				: $part['default'];

			$required = self::subfield_required( $arr, $part['required_key'], $parent_required );

			$subfields[] = array(
				'key'      => $part['key'],
				'label'    => $label,
				'required' => $required,
			);
		}

		return $subfields;
	}

	/**
	 * @param array $arr Field settings.
	 * @return array<int,array{key:string,label:string,required:bool}>
	 */
	private static function name_subfields( $arr ) {
		$parts = array(
			array(
				'key'          => 'prefix',
				'setting'      => 'prefix',
				'label_key'    => 'prefix_label',
				'default'      => __( 'Prefix', 'radioudaan-app-api' ),
				'required_key' => 'prefix_required',
			),
			array(
				'key'          => 'first-name',
				'setting'      => 'fname',
				'label_key'    => 'fname_label',
				'default'      => __( 'First Name', 'radioudaan-app-api' ),
				'required_key' => 'fname_required',
			),
			array(
				'key'          => 'middle-name',
				'setting'      => 'mname',
				'label_key'    => 'mname_label',
				'default'      => __( 'Middle Name', 'radioudaan-app-api' ),
				'required_key' => 'mname_required',
			),
			array(
				'key'          => 'last-name',
				'setting'      => 'lname',
				'label_key'    => 'lname_label',
				'default'      => __( 'Last Name', 'radioudaan-app-api' ),
				'required_key' => 'lname_required',
			),
		);

		$parent_required = ! empty( $arr['required'] );
		$subfields       = array();

		foreach ( $parts as $part ) {
			if ( ! self::subfield_enabled( $arr, $part['setting'] ) ) {
				continue;
			}

			$label = ! empty( $arr[ $part['label_key'] ] )
				? wp_strip_all_tags( (string) $arr[ $part['label_key'] ] )
				: $part['default'];

			$required = self::subfield_required( $arr, $part['required_key'], $parent_required );

			$subfields[] = array(
				'key'      => $part['key'],
				'label'    => $label,
				'required' => $required,
			);
		}

		return $subfields;
	}

	/**
	 * @param array  $arr     Field settings.
	 * @param string $setting Subfield enable key.
	 * @return bool
	 */
	private static function subfield_enabled( $arr, $setting ) {
		if ( ! array_key_exists( $setting, $arr ) ) {
			return false;
		}

		$value = $arr[ $setting ];
		return 'true' === $value || true === $value || '1' === $value || 1 === $value;
	}

	/**
	 * @param array  $arr            Field settings.
	 * @param string $required_key   Subfield required flag key.
	 * @param bool   $parent_required Parent required flag.
	 * @return bool
	 */
	private static function subfield_required( $arr, $required_key, $parent_required ) {
		if ( array_key_exists( $required_key, $arr ) ) {
			$value = $arr[ $required_key ];
			if ( 'true' === $value || true === $value || '1' === $value || 1 === $value ) {
				return true;
			}
			if ( 'false' === $value || false === $value || '0' === $value || 0 === $value ) {
				return false;
			}
		}

		$message_key = $required_key . '_message';
		if ( ! empty( $arr[ $message_key ] ) ) {
			return true;
		}

		return $parent_required;
	}

	/**
	 * @param array $arr Field settings.
	 * @return int
	 */
	private static function upload_max_files( $arr ) {
		if ( ! empty( $arr['multiple'] ) && ( 'true' === $arr['multiple'] || true === $arr['multiple'] || '1' === $arr['multiple'] ) ) {
			$limit = ! empty( $arr['limit'] ) ? (int) $arr['limit'] : 0;
			if ( $limit > 0 ) {
				return $limit;
			}
			return max( 2, RadioUdaan_App_Settings::get_max_files_per_field() );
		}

		return 1;
	}

	/**
	 * @param array  $arr  Field settings.
	 * @param string $type Type.
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
	 * @param array  $arr  Field settings.
	 * @param string $type Type.
	 * @return string[]
	 */
	private static function field_options( $arr, $type ) {
		return self::options_labels( self::choice_options( $arr, $type ) );
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

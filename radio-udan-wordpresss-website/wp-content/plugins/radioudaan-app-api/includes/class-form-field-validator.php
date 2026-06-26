<?php
/**
 * Server-side validation for app registration form fields.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Validates submitted values against exported schema field definitions.
 */
class RadioUdaan_Form_Field_Validator {

	/**
	 * Validate a single field value.
	 *
	 * @param array<string,mixed> $field Schema field.
	 * @param mixed               $value Submitted value.
	 * @return true|WP_Error
	 */
	public static function validate_field( $field, $value ) {
		$type = isset( $field['type'] ) ? (string) $field['type'] : 'text';
		$key  = isset( $field['key'] ) ? (string) $field['key'] : 'field';

		if ( ! empty( $field['subfields'] ) && is_array( $field['subfields'] ) ) {
			return self::validate_subfields( $field, $value );
		}

		if ( self::is_empty_value( $value, $field ) ) {
			if ( ! empty( $field['required'] ) ) {
				return self::required_error( $field );
			}
			return true;
		}

		switch ( $type ) {
			case 'email':
				if ( ! is_email( (string) $value ) ) {
					return new WP_Error(
						'field_invalid',
						__( 'Enter a valid email address.', 'radioudaan-app-api' ),
						array( 'status' => 400, 'field' => $key )
					);
				}
				break;

			case 'phone':
				if ( ! self::is_valid_phone( $value ) ) {
					return new WP_Error(
						'field_invalid',
						__( 'Enter a valid mobile number.', 'radioudaan-app-api' ),
						array( 'status' => 400, 'field' => $key )
					);
				}
				break;

			case 'url':
				if ( ! self::is_valid_url( (string) $value ) ) {
					return new WP_Error(
						'field_invalid',
						__( 'Enter a valid URL starting with http:// or https://.', 'radioudaan-app-api' ),
						array( 'status' => 400, 'field' => $key )
					);
				}
				break;

			case 'number':
			case 'slider':
				if ( ! is_numeric( $value ) ) {
					return new WP_Error(
						'field_invalid',
						__( 'Enter a valid number.', 'radioudaan-app-api' ),
						array( 'status' => 400, 'field' => $key )
					);
				}
				$num = (float) $value;
				if ( isset( $field['min'] ) && $num < (float) $field['min'] ) {
					return new WP_Error(
						'field_invalid',
						sprintf(
							/* translators: %s: minimum number */
							__( 'Minimum value is %s.', 'radioudaan-app-api' ),
							(string) $field['min']
						),
						array( 'status' => 400, 'field' => $key )
					);
				}
				if ( isset( $field['max'] ) && $num > (float) $field['max'] ) {
					return new WP_Error(
						'field_invalid',
						sprintf(
							/* translators: %s: maximum number */
							__( 'Maximum value is %s.', 'radioudaan-app-api' ),
							(string) $field['max']
						),
						array( 'status' => 400, 'field' => $key )
					);
				}
				break;

			case 'radio':
			case 'select':
			case 'rating':
				if ( ! self::validate_choice_value( $field, $value ) ) {
					return new WP_Error(
						'field_invalid',
						__( 'Invalid selection.', 'radioudaan-app-api' ),
						array( 'status' => 400, 'field' => $key )
					);
				}
				break;

			case 'checkbox':
				$choices = self::effective_choice_options( $field );
				if ( count( $choices ) > 1 ) {
					if ( ! is_array( $value ) ) {
						return new WP_Error(
							'field_invalid',
							__( 'Invalid selection.', 'radioudaan-app-api' ),
							array( 'status' => 400, 'field' => $key )
						);
					}
					foreach ( $value as $item ) {
						if ( ! self::validate_choice_value( $field, $item ) ) {
							return new WP_Error(
								'field_invalid',
								__( 'Invalid selection.', 'radioudaan-app-api' ),
								array( 'status' => 400, 'field' => $key )
							);
						}
					}
				} elseif ( ! empty( $field['required'] ) && ! self::is_truthy_consent( $value ) ) {
					return self::required_error( $field );
				}
				break;
		}

		return true;
	}

	/**
	 * Whether a choice value is allowed for radio/select/checkbox fields.
	 *
	 * @param array<string,mixed> $field Schema field.
	 * @param mixed               $value Selected value.
	 * @return bool
	 */
	public static function validate_choice_value( $field, $value ) {
		$selected = strtolower( trim( (string) $value ) );
		if ( '' === $selected ) {
			return true;
		}

		$options = self::effective_choice_options( $field );
		if ( empty( $options ) ) {
			return true;
		}

		foreach ( $options as $opt ) {
			$opt_value = strtolower( (string) ( $opt['value'] ?? '' ) );
			$opt_label = strtolower( (string) ( $opt['label'] ?? '' ) );
			if ( $selected === $opt_value || $selected === $opt_label ) {
				return true;
			}
		}

		return false;
	}

	/**
	 * @param array<string,mixed> $field Schema field.
	 * @param mixed               $value Map payload.
	 * @return true|WP_Error
	 */
	private static function validate_subfields( $field, $value ) {
		$key = isset( $field['key'] ) ? (string) $field['key'] : 'field';
		$map = is_array( $value ) ? $value : array();

		foreach ( $field['subfields'] as $sub ) {
			if ( empty( $sub['key'] ) ) {
				continue;
			}
			$sub_key = (string) $sub['key'];
			$raw     = isset( $map[ $sub_key ] ) ? $map[ $sub_key ] : '';
			$text    = trim( (string) $raw );

			if ( ! empty( $sub['required'] ) && '' === $text ) {
				$label = ! empty( $sub['label'] ) ? wp_strip_all_tags( (string) $sub['label'] ) : $sub_key;
				return new WP_Error(
					'field_required',
					sprintf(
						/* translators: %s: subfield label */
						__( '%s. This field is required.', 'radioudaan-app-api' ),
						$label
					),
					array( 'status' => 400, 'field' => $key )
				);
			}
		}

		if ( ! empty( $field['required'] ) ) {
			$any_filled = false;
			foreach ( $field['subfields'] as $sub ) {
				if ( empty( $sub['key'] ) ) {
					continue;
				}
				$sub_key = (string) $sub['key'];
				$text    = isset( $map[ $sub_key ] ) ? trim( (string) $map[ $sub_key ] ) : '';
				if ( '' !== $text ) {
					$any_filled = true;
					break;
				}
			}
			if ( ! $any_filled ) {
				return self::required_error( $field );
			}
		}

		return true;
	}

	/**
	 * @param array<string,mixed> $field Field.
	 * @return array<int,array{value:string,label:string}>
	 */
	private static function effective_choice_options( $field ) {
		if ( ! empty( $field['choice_options'] ) && is_array( $field['choice_options'] ) ) {
			return $field['choice_options'];
		}

		$legacy = array();
		if ( ! empty( $field['options'] ) && is_array( $field['options'] ) ) {
			foreach ( $field['options'] as $opt ) {
				$legacy[] = array(
					'value' => (string) $opt,
					'label' => (string) $opt,
				);
			}
		}

		return $legacy;
	}

	/**
	 * @param mixed               $value Value.
	 * @param array<string,mixed> $field Field.
	 * @return bool
	 */
	private static function is_empty_value( $value, $field ) {
		if ( null === $value ) {
			return true;
		}

		$type = isset( $field['type'] ) ? (string) $field['type'] : 'text';

		if ( is_bool( $value ) ) {
			if ( 'checkbox' === $type && count( self::effective_choice_options( $field ) ) <= 1 ) {
				return ! $value;
			}
		}

		if ( is_array( $value ) ) {
			if ( empty( $value ) ) {
				return true;
			}
			if ( self::is_assoc_map( $value ) ) {
				foreach ( $value as $item ) {
					if ( null !== $item && '' !== trim( (string) $item ) ) {
						return false;
					}
				}
				return true;
			}
		}

		return '' === trim( (string) $value );
	}

	/**
	 * @param mixed $value Value.
	 * @return bool
	 */
	private static function is_truthy_consent( $value ) {
		if ( true === $value ) {
			return true;
		}
		if ( is_numeric( $value ) && 1 === (int) $value ) {
			return true;
		}
		$text = strtolower( trim( (string) $value ) );
		return in_array( $text, array( '1', 'true', 'yes', 'checked', 'on' ), true );
	}

	/**
	 * Lenient E.164 (+country) or 10-digit India mobile.
	 *
	 * @param mixed $value Phone value.
	 * @return bool
	 */
	private static function is_valid_phone( $value ) {
		$raw = preg_replace( '/[\s\-().]/', '', (string) $value );
		if ( '' === $raw ) {
			return false;
		}

		if ( preg_match( '/^\+[1-9]\d{7,14}$/', $raw ) ) {
			return true;
		}

		if ( preg_match( '/^91[6-9]\d{9}$/', $raw ) ) {
			return true;
		}

		return (bool) preg_match( '/^[6-9]\d{9}$/', $raw );
	}

	/**
	 * @param string $raw URL.
	 * @return bool
	 */
	private static function is_valid_url( $raw ) {
		$trimmed = trim( $raw );
		if ( '' === $trimmed ) {
			return false;
		}

		$filtered = filter_var( $trimmed, FILTER_VALIDATE_URL );
		if ( false === $filtered ) {
			return false;
		}

		$parts = wp_parse_url( $trimmed );
		if ( empty( $parts['scheme'] ) ) {
			return false;
		}

		return in_array( strtolower( (string) $parts['scheme'] ), array( 'http', 'https' ), true );
	}

	/**
	 * @param array<string,mixed> $field Field.
	 * @return WP_Error
	 */
	private static function required_error( $field ) {
		$key   = isset( $field['key'] ) ? (string) $field['key'] : 'field';
		$label = isset( $field['label'] ) ? trim( preg_replace( '/\s*\*+\s*$/', '', wp_strip_all_tags( (string) $field['label'] ) ) ) : '';

		$message = '' !== $label
			? sprintf(
				/* translators: %s: field label */
				__( '%s. This field is required.', 'radioudaan-app-api' ),
				$label
			)
			: __( 'This field is required.', 'radioudaan-app-api' );

		return new WP_Error(
			'field_required',
			$message,
			array( 'status' => 400, 'field' => $key )
		);
	}

	/**
	 * @param array<mixed> $value Value.
	 * @return bool
	 */
	private static function is_assoc_map( $value ) {
		if ( ! is_array( $value ) ) {
			return false;
		}
		foreach ( array_keys( $value ) as $key ) {
			if ( ! is_int( $key ) ) {
				return true;
			}
		}
		return false;
	}
}

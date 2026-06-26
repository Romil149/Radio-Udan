<?php
/**
 * Forminator field visibility (conditions) for app schema and registration validation.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Exports and evaluates show/hide rules aligned with Forminator front-end behaviour.
 */
class RadioUdaan_Form_Visibility {

	/**
	 * Date operators handled by {@see match_condition_value()}.
	 *
	 * @var string[]
	 */
	private static $date_operators = array(
		'day_is',
		'day_is_not',
		'month_is',
		'month_is_not',
		'is_before',
		'is_after',
		'is_before_n_or_more_days',
		'is_before_less_than_n_days',
		'is_after_n_or_more_days',
		'is_after_less_than_n_days',
	);

	/**
	 * @param array<string,mixed> $field_settings Forminator field array.
	 * @return array<string,mixed>|null
	 */
	public static function export_from_field( $field_settings ) {
		if ( empty( $field_settings['conditions'] ) || ! is_array( $field_settings['conditions'] ) ) {
			return null;
		}

		$when = array();
		foreach ( $field_settings['conditions'] as $condition ) {
			if ( empty( $condition['element_id'] ) ) {
				continue;
			}
			$when[] = array(
				'field'    => (string) $condition['element_id'],
				'operator' => (string) ( $condition['rule'] ?? 'is' ),
				'value'    => isset( $condition['value'] ) ? (string) $condition['value'] : '',
			);
		}

		if ( empty( $when ) ) {
			return null;
		}

		return array(
			'action' => (string) ( $field_settings['condition_action'] ?? 'show' ),
			'match'  => (string) ( $field_settings['condition_rule'] ?? 'all' ),
			'when'   => $when,
		);
	}

	/**
	 * @param array<string,mixed> $field        Schema field (includes key, visibility).
	 * @param array<string,array<string,mixed>> $fields_by_key All schema fields keyed by element id.
	 * @param array<string,mixed>               $payload       Submitted values.
	 * @param array<string,bool>                $visiting      Cycle guard.
	 * @return bool
	 */
	public static function is_field_visible( $field, $fields_by_key, $payload, $visiting = array() ) {
		$key = isset( $field['key'] ) ? (string) $field['key'] : '';
		if ( '' === $key ) {
			return true;
		}

		if ( isset( $visiting[ $key ] ) ) {
			return true;
		}

		$visibility = isset( $field['visibility'] ) && is_array( $field['visibility'] )
			? $field['visibility']
			: null;

		if ( empty( $visibility['when'] ) || ! is_array( $visibility['when'] ) ) {
			return true;
		}

		$visiting[ $key ] = true;
		$matched            = self::conditions_matched(
			$visibility,
			$fields_by_key,
			$payload,
			$visiting
		);
		unset( $visiting[ $key ] );

		$action = isset( $visibility['action'] ) ? (string) $visibility['action'] : 'show';
		if ( 'show' === $action ) {
			return $matched;
		}

		return ! $matched;
	}

	/**
	 * Evaluate a single visibility rule against a payload value.
	 *
	 * @param string              $field_key     Dependent field key.
	 * @param mixed               $payload_value Current answer.
	 * @param string              $operator      Forminator rule operator.
	 * @param string              $expected      Expected rule value.
	 * @param array<string,mixed>|null $dep_field Optional schema field for choice matching.
	 * @return bool
	 */
	public static function match_condition_value( $field_key, $payload_value, $operator, $expected, $dep_field = null ) {
		unset( $field_key );

		$operator = (string) $operator;
		$expected = (string) $expected;

		if ( in_array( $operator, self::$date_operators, true ) ) {
			return self::date_rule_matches( $operator, $payload_value, $expected );
		}

		$value         = self::normalize_value( $payload_value );
		$expected_norm = strtolower( trim( $expected ) );

		switch ( $operator ) {
			case 'is':
				return self::match_choice_value( $dep_field, $payload_value, $expected_norm );

			case 'is_not':
				return ! self::match_choice_value( $dep_field, $payload_value, $expected_norm );

			case 'is_great':
				return is_numeric( $value ) && is_numeric( $expected_norm )
					&& (float) $value > (float) $expected_norm;

			case 'is_less':
				return is_numeric( $value ) && is_numeric( $expected_norm )
					&& (float) $value < (float) $expected_norm;

			case 'contains':
				if ( is_array( $value ) ) {
					foreach ( $value as $item ) {
						if ( false !== stripos( (string) $item, $expected_norm ) ) {
							return true;
						}
					}
					return false;
				}
				return false !== stripos( (string) $value, $expected_norm );

			case 'does_not_contain':
				if ( is_array( $value ) ) {
					foreach ( $value as $item ) {
						if ( false !== stripos( (string) $item, $expected_norm ) ) {
							return false;
						}
					}
					return true;
				}
				return false === stripos( (string) $value, $expected_norm );

			case 'starts':
				if ( is_array( $value ) ) {
					foreach ( $value as $item ) {
						if ( 0 === stripos( (string) $item, $expected_norm ) ) {
							return true;
						}
					}
					return false;
				}
				return 0 === stripos( (string) $value, $expected_norm );

			case 'ends':
				if ( is_array( $value ) ) {
					foreach ( $value as $item ) {
						$item = (string) $item;
						if ( strlen( $expected_norm ) <= strlen( $item )
							&& substr( $item, - strlen( $expected_norm ) ) === $expected_norm ) {
							return true;
						}
					}
					return false;
				}
				$str = (string) $value;
				return strlen( $expected_norm ) <= strlen( $str )
					&& substr( $str, - strlen( $expected_norm ) ) === $expected_norm;

			default:
				return false;
		}
	}

	/**
	 * Compare stored choice against expected rule value using value and label.
	 *
	 * @param array<string,mixed>|null $field    Schema field.
	 * @param mixed                    $raw      Payload value.
	 * @param string                   $expected Normalized expected value.
	 * @return bool
	 */
	public static function match_choice_value( $field, $raw, $expected ) {
		$expected = strtolower( trim( (string) $expected ) );
		if ( '' === $expected ) {
			return false;
		}

		if ( is_array( $raw ) && ! self::is_assoc_map( $raw ) ) {
			foreach ( $raw as $item ) {
				if ( self::match_choice_value( $field, $item, $expected ) ) {
					return true;
				}
			}
			return false;
		}

		$value = self::normalize_value( $raw );
		if ( is_array( $value ) ) {
			foreach ( $value as $item ) {
				if ( self::match_choice_value( $field, $item, $expected ) ) {
					return true;
				}
			}
			return false;
		}

		$stored = (string) $value;
		if ( $stored === $expected ) {
			return true;
		}

		$options = self::field_choice_options( $field );
		if ( empty( $options ) ) {
			if ( is_numeric( $stored ) && is_numeric( $expected ) ) {
				return (float) $stored === (float) $expected;
			}
			return false;
		}

		foreach ( $options as $opt ) {
			$opt_value = strtolower( (string) ( $opt['value'] ?? '' ) );
			$opt_label = strtolower( (string) ( $opt['label'] ?? '' ) );
			$value_match = ( $stored === $opt_value || $stored === $opt_label );
			if ( ! $value_match ) {
				continue;
			}
			if ( $expected === $opt_value || $expected === $opt_label ) {
				return true;
			}
		}

		return false;
	}

	/**
	 * @param array<string,mixed>                 $visibility    Visibility block.
	 * @param array<string,array<string,mixed>>   $fields_by_key Fields index.
	 * @param array<string,mixed>                 $payload       Values.
	 * @param array<string,bool>                  $visiting      Cycle guard.
	 * @return bool
	 */
	private static function conditions_matched( $visibility, $fields_by_key, $payload, $visiting ) {
		$rules = $visibility['when'];
		$match = isset( $visibility['match'] ) ? (string) $visibility['match'] : 'all';
		$fulfilled = 0;
		$count     = 0;

		foreach ( $rules as $rule ) {
			if ( empty( $rule['field'] ) ) {
				continue;
			}
			++$count;

			$dep_key = (string) $rule['field'];
			$dep     = $fields_by_key[ $dep_key ] ?? null;
			if ( $dep && ! self::is_field_visible( $dep, $fields_by_key, $payload, $visiting ) ) {
				if ( 'all' === $match ) {
					return false;
				}
				continue;
			}

			$raw = array_key_exists( $dep_key, $payload ) ? $payload[ $dep_key ] : '';
			$is_matched = self::match_condition_value(
				$dep_key,
				$raw,
				isset( $rule['operator'] ) ? (string) $rule['operator'] : 'is',
				isset( $rule['value'] ) ? (string) $rule['value'] : '',
				$dep
			);

			if ( $is_matched ) {
				++$fulfilled;
			} elseif ( 'all' === $match ) {
				return false;
			}

			if ( 'any' === $match && $fulfilled > 0 ) {
				return true;
			}
		}

		if ( 0 === $count ) {
			return true;
		}

		if ( 'any' === $match ) {
			return $fulfilled > 0;
		}

		return $fulfilled === $count;
	}

	/**
	 * @param string $operator Operator.
	 * @param mixed  $raw      Payload date value.
	 * @param string $expected Expected rule value.
	 * @return bool
	 */
	private static function date_rule_matches( $operator, $raw, $expected ) {
		$parsed = self::parse_flexible_date( $raw );
		if ( ! $parsed ) {
			return in_array( $operator, array( 'day_is_not', 'month_is_not' ), true );
		}

		$expected = strtolower( trim( $expected ) );

		switch ( $operator ) {
			case 'day_is':
				return (int) gmdate( 'w', $parsed ) === self::parse_day_token( $expected );
			case 'day_is_not':
				return (int) gmdate( 'w', $parsed ) !== self::parse_day_token( $expected );
			case 'month_is':
				return ( (int) gmdate( 'n', $parsed ) - 1 ) === self::parse_month_token( $expected );
			case 'month_is_not':
				return ( (int) gmdate( 'n', $parsed ) - 1 ) !== self::parse_month_token( $expected );
			case 'is_before':
				$target = self::parse_flexible_date( $expected );
				if ( ! $target ) {
					return false;
				}
				return self::date_only( $parsed ) < self::date_only( $target );
			case 'is_after':
				$target = self::parse_flexible_date( $expected );
				if ( ! $target ) {
					return false;
				}
				return self::date_only( $parsed ) > self::date_only( $target );
			case 'is_before_n_or_more_days':
				$n    = (int) $expected;
				$diff = self::days_between( self::date_only( $parsed ), self::today() );
				if ( 0 === $n ) {
					return 0 === $diff;
				}
				return $diff >= $n;
			case 'is_before_less_than_n_days':
				$n    = (int) $expected;
				$diff = self::days_between( self::date_only( $parsed ), self::today() );
				return $diff > 0 && $diff < $n;
			case 'is_after_n_or_more_days':
				$n    = (int) $expected;
				$diff = self::days_between( self::today(), self::date_only( $parsed ) );
				if ( 0 === $n ) {
					return 0 === $diff;
				}
				return $diff >= $n;
			case 'is_after_less_than_n_days':
				$n    = (int) $expected;
				$diff = self::days_between( self::today(), self::date_only( $parsed ) );
				return $diff > 0 && $diff < $n;
			default:
				return false;
		}
	}

	/**
	 * Parse app date strings (Y-m-d, ISO, d/m/Y).
	 *
	 * @param mixed $raw Raw value.
	 * @return int|null Unix timestamp at midnight UTC for date-only comparisons.
	 */
	public static function parse_flexible_date( $raw ) {
		if ( null === $raw ) {
			return null;
		}

		$text = trim( (string) $raw );
		if ( '' === $text ) {
			return null;
		}

		$text = preg_replace( '/\s+/', ' ', $text );
		if ( preg_match( '/^\d{4}-\d{2}-\d{2}/', $text ) ) {
			$date_part = substr( $text, 0, 10 );
			$dt        = DateTimeImmutable::createFromFormat( 'Y-m-d', $date_part, new DateTimeZone( 'UTC' ) );
			if ( $dt instanceof DateTimeImmutable ) {
				return $dt->getTimestamp();
			}
		}

		$iso = strtotime( $text );
		if ( false !== $iso ) {
			return self::date_only( $iso );
		}

		if ( preg_match( '/^(\d{2})[\/\-.](\d{2})[\/\-.](\d{2,4})$/', $text, $matches ) ) {
			$day   = (int) $matches[1];
			$month = (int) $matches[2];
			$year  = (int) $matches[3];
			if ( $year < 100 ) {
				$year += 2000;
			}
			$dt = DateTimeImmutable::createFromFormat(
				'Y-n-j',
				sprintf( '%d-%d-%d', $year, $month, $day ),
				new DateTimeZone( 'UTC' )
			);
			if ( $dt instanceof DateTimeImmutable ) {
				return $dt->getTimestamp();
			}
		}

		return null;
	}

	/**
	 * @param int $timestamp Unix timestamp.
	 * @return int
	 */
	private static function date_only( $timestamp ) {
		return gmmktime( 0, 0, 0, (int) gmdate( 'n', $timestamp ), (int) gmdate( 'j', $timestamp ), (int) gmdate( 'Y', $timestamp ) );
	}

	/**
	 * @return int
	 */
	private static function today() {
		return self::date_only( time() );
	}

	/**
	 * @param int $from Timestamp.
	 * @param int $to   Timestamp.
	 * @return int
	 */
	private static function days_between( $from, $to ) {
		return (int) floor( ( $to - $from ) / DAY_IN_SECONDS );
	}

	/**
	 * @param string $token Day token.
	 * @return int PHP w format (0=Sunday).
	 */
	private static function parse_day_token( $token ) {
		$days = array(
			'su'  => 0,
			'sun' => 0,
			'mo'  => 1,
			'mon' => 1,
			'tu'  => 2,
			'tue' => 2,
			'we'  => 3,
			'wed' => 3,
			'th'  => 4,
			'thu' => 4,
			'fr'  => 5,
			'fri' => 5,
			'sa'  => 6,
			'sat' => 6,
		);

		if ( isset( $days[ $token ] ) ) {
			return $days[ $token ];
		}

		if ( is_numeric( $token ) ) {
			$n = (int) $token;
			if ( $n >= 0 && $n <= 6 ) {
				return $n;
			}
		}

		return 0;
	}

	/**
	 * @param string $token Month token.
	 * @return int Zero-based month index.
	 */
	private static function parse_month_token( $token ) {
		$months = array(
			'jan' => 0,
			'feb' => 1,
			'mar' => 2,
			'apr' => 3,
			'may' => 4,
			'jun' => 5,
			'jul' => 6,
			'aug' => 7,
			'sep' => 8,
			'oct' => 9,
			'nov' => 10,
			'dec' => 11,
		);

		if ( isset( $months[ $token ] ) ) {
			return $months[ $token ];
		}

		if ( is_numeric( $token ) ) {
			$n = (int) $token;
			if ( $n >= 0 && $n <= 11 ) {
				return $n;
			}
		}

		return 0;
	}

	/**
	 * @param mixed $raw Payload value.
	 * @return mixed
	 */
	private static function normalize_value( $raw ) {
		if ( is_array( $raw ) ) {
			return array_map(
				static function ( $item ) {
					return strtolower( trim( (string) $item ) );
				},
				$raw
			);
		}
		if ( is_bool( $raw ) ) {
			return $raw ? '1' : '';
		}
		if ( is_numeric( $raw ) ) {
			return (string) $raw;
		}
		return strtolower( trim( (string) $raw ) );
	}

	/**
	 * @param array<string,mixed>|null $field Schema field.
	 * @return array<int,array{value:string,label:string}>
	 */
	private static function field_choice_options( $field ) {
		if ( ! is_array( $field ) ) {
			return array();
		}

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
	 * @param array<int,array<string,mixed>> $schema_fields Schema fields list.
	 * @return array<string,array<string,mixed>>
	 */
	public static function index_fields( $schema_fields ) {
		$index = array();
		foreach ( $schema_fields as $field ) {
			if ( empty( $field['key'] ) ) {
				continue;
			}
			$index[ (string) $field['key'] ] = $field;
		}
		return $index;
	}
}

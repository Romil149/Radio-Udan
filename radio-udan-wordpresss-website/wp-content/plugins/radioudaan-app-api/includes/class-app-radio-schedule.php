<?php
/**
 * Radio show schedule for the mobile Live tab (GET /library/schedule).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Expands radio-shows CPT + ACF broadcast fields into upcoming segment buckets.
 */
class RadioUdaan_App_Radio_Schedule {

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response
	 */
	public static function get_schedule( WP_REST_Request $request ) {
		$days_count = min( 14, max( 1, (int) $request->get_param( 'days' ) ) );

		return new WP_REST_Response( self::build_schedule( $days_count ), 200 );
	}

	/**
	 * Expand radio-shows into schedule buckets (shared by REST + live_radio config).
	 *
	 * @param int $days_count Inclusive calendar days from today.
	 * @return array<string,mixed>
	 */
	public static function build_schedule( $days_count = 2 ) {
		$days_count = min( 14, max( 1, (int) $days_count ) );
		$tz         = wp_timezone();
		$now        = new DateTimeImmutable( 'now', $tz );
		$timezone   = wp_timezone_string();

		$query = new WP_Query(
			array(
				'post_type'      => 'radio-shows',
				'post_status'    => 'publish',
				'posts_per_page' => -1,
				'orderby'        => 'title',
				'order'          => 'ASC',
			)
		);

		$shows = array();
		foreach ( $query->posts as $post ) {
			$shows[] = self::map_show_source( $post );
		}

		$occurrences = array();
		for ( $offset = 0; $offset < $days_count; $offset++ ) {
			$day_date = $now->modify( '+' . $offset . ' days' )->setTime( 0, 0, 0 );
			$weekday  = $day_date->format( 'l' );
			$date_key = $day_date->format( 'Y-m-d' );

			foreach ( $shows as $show ) {
				foreach ( $show['primary_days'] as $day_name ) {
					if ( ! self::weekday_matches( $day_name, $weekday ) ) {
						continue;
					}
					$starts_at = self::parse_broadcast_time( $date_key, $show['broadcast_time'], $tz );
					if ( ! $starts_at ) {
						continue;
					}
					$occurrences[] = self::build_occurrence( $show, $starts_at, false );
				}

				foreach ( $show['repeat_days'] as $day_name ) {
					if ( ! self::weekday_matches( $day_name, $weekday ) ) {
						continue;
					}
					$starts_at = self::parse_broadcast_time( $date_key, $show['repeat_broadcast_time'], $tz );
					if ( ! $starts_at ) {
						continue;
					}
					$occurrences[] = self::build_occurrence( $show, $starts_at, true );
				}
			}
		}

		usort(
			$occurrences,
			static function ( $a, $b ) {
				return strcmp( $a['starts_at'], $b['starts_at'] );
			}
		);

		$now_iso = $now->format( 'c' );
		$on_air  = null;
		$next    = null;

		// Latest segment that already started; holds until the next slot begins.
		foreach ( $occurrences as $occurrence ) {
			if ( $occurrence['starts_at'] > $now_iso ) {
				$next = $occurrence;
				break;
			}
			$on_air = $occurrence;
		}

		$days = array();
		for ( $offset = 0; $offset < $days_count; $offset++ ) {
			$day_date = $now->modify( '+' . $offset . ' days' )->setTime( 0, 0, 0 );
			$date_key = $day_date->format( 'Y-m-d' );
			$items    = array();

			foreach ( $occurrences as $occurrence ) {
				if ( substr( $occurrence['starts_at'], 0, 10 ) !== $date_key ) {
					continue;
				}
				$items[] = $occurrence;
			}

			$days[] = array(
				'date'  => $date_key,
				'label' => self::day_label( $day_date, $offset, $tz ),
				'items' => $items,
			);
		}

		return array(
			'timezone' => $timezone,
			'on_air'   => $on_air,
			'next'     => $next,
			'days'     => $days,
		);
	}

	/**
	 * @param array<string,mixed>|null $occurrence Schedule segment row.
	 * @return string
	 */
	public static function format_hosts_subtitle( $occurrence ) {
		if ( ! is_array( $occurrence ) ) {
			return '';
		}
		$hosts = trim( (string) ( $occurrence['program_host'] ?? '' ) );
		if ( $hosts === '' ) {
			return '';
		}
		if ( stripos( $hosts, 'with ' ) === 0 ) {
			return $hosts;
		}
		return sprintf(
			/* translators: %s: RJ / host name(s) */
			__( 'with %s', 'radioudaan-app-api' ),
			$hosts
		);
	}

	/**
	 * @param WP_Post $post Post.
	 * @return array<string,mixed>
	 */
	private static function map_show_source( WP_Post $post ) {
		$acf_title = self::acf_string( 'title', $post->ID );
		$title     = $acf_title ? $acf_title : get_the_title( $post );

		return array(
			'id'                     => (int) $post->ID,
			'title'                  => $title,
			'summary'                => self::summary_text( $post, 'description' ),
			'thumbnail_url'          => self::thumbnail_url( $post->ID ),
			'program_category'       => self::acf_string( 'program_category', $post->ID ),
			'program_host'           => self::acf_host_names( $post->ID ),
			'broadcast_time'         => self::acf_string( 'broadcast_time', $post->ID ),
			'repeat_broadcast_time'  => self::acf_string( 'repeat_broadcast_time', $post->ID ),
			'primary_days'           => self::acf_days( 'broadcasting_day', $post->ID ),
			'repeat_days'            => self::acf_days( 'repeat_broadcasting_day', $post->ID ),
		);
	}

	/**
	 * @param array<string,mixed> $show      Show source row.
	 * @param DateTimeImmutable   $starts_at Slot start.
	 * @param bool                $is_repeat Repeat slot flag.
	 * @return array<string,mixed>
	 */
	private static function build_occurrence( array $show, DateTimeImmutable $starts_at, $is_repeat ) {
		$time_display = $is_repeat ? $show['repeat_broadcast_time'] : $show['broadcast_time'];

		return array(
			'id'               => $show['id'],
			'title'            => $show['title'],
			'summary'          => $show['summary'],
			'thumbnail_url'    => $show['thumbnail_url'],
			'program_category' => $show['program_category'],
			'program_host'     => $show['program_host'],
			'broadcast_time'   => $time_display,
			'starts_at'        => $starts_at->format( 'c' ),
			'is_repeat'        => $is_repeat,
		);
	}

	/**
	 * @param DateTimeImmutable $day_date Day at midnight site TZ.
	 * @param int               $offset   Days from today.
	 * @param DateTimeZone      $tz       Site timezone.
	 * @return string
	 */
	private static function day_label( DateTimeImmutable $day_date, $offset, DateTimeZone $tz ) {
		if ( 0 === $offset ) {
			return __( 'Today', 'radioudaan-app-api' );
		}
		if ( 1 === $offset ) {
			return __( 'Tomorrow', 'radioudaan-app-api' );
		}
		return wp_date( 'l, M j', $day_date->getTimestamp(), $tz );
	}

	/**
	 * @param string $day_name        ACF day value.
	 * @param string $target_weekday  PHP weekday name (e.g. Friday).
	 * @return bool
	 */
	private static function weekday_matches( $day_name, $target_weekday ) {
		return strcasecmp( trim( (string) $day_name ), $target_weekday ) === 0;
	}

	/**
	 * @param string       $date_ymd Date (Y-m-d).
	 * @param string       $time_str Display time (e.g. 10:00 AM).
	 * @param DateTimeZone $tz       Site timezone.
	 * @return DateTimeImmutable|null
	 */
	private static function parse_broadcast_time( $date_ymd, $time_str, DateTimeZone $tz ) {
		$time_str = trim( (string) $time_str );
		if ( $time_str === '' ) {
			return null;
		}

		$formats = array( 'g:i A', 'g:i a', 'H:i', 'G:i' );
		foreach ( $formats as $format ) {
			$dt = DateTimeImmutable::createFromFormat( 'Y-m-d ' . $format, $date_ymd . ' ' . $time_str, $tz );
			if ( $dt instanceof DateTimeImmutable ) {
				return $dt;
			}
		}

		return null;
	}

	/**
	 * @param string $field   ACF field key.
	 * @param int    $post_id Post ID.
	 * @return string[]
	 */
	private static function acf_days( $field, $post_id ) {
		if ( ! function_exists( 'get_field' ) ) {
			return array();
		}

		$val = get_field( $field, $post_id );
		if ( is_array( $val ) ) {
			$days = array();
			foreach ( $val as $day ) {
				if ( is_array( $day ) || is_object( $day ) ) {
					continue;
				}
				$day = trim( (string) $day );
				if ( $day !== '' ) {
					$days[] = $day;
				}
			}
			return $days;
		}

		if ( is_string( $val ) && $val !== '' ) {
			if ( strpos( $val, ',' ) !== false ) {
				return array_values(
					array_filter(
						array_map( 'trim', explode( ',', $val ) )
					)
				);
			}
			return array( trim( $val ) );
		}

		return array();
	}

	/**
	 * @param string $field   ACF field.
	 * @param int    $post_id Post ID.
	 * @return string
	 */
	private static function acf_string( $field, $post_id ) {
		if ( ! function_exists( 'get_field' ) ) {
			return '';
		}
		$val = get_field( $field, $post_id );
		if ( is_array( $val ) || is_object( $val ) ) {
			return '';
		}
		return trim( wp_strip_all_tags( (string) $val ) );
	}

	/**
	 * @param int $post_id Post ID.
	 * @return string
	 */
	private static function acf_host_names( $post_id ) {
		if ( ! function_exists( 'get_field' ) ) {
			return '';
		}
		$hosts = get_field( 'program_host', $post_id );
		return RadioUdaan_Rj_Profile::resolve_program_host_names( $hosts );
	}

	/**
	 * @param WP_Post $post     Post.
	 * @param string  $acf_body Optional ACF body field key.
	 * @return string
	 */
	private static function summary_text( WP_Post $post, $acf_body = '' ) {
		$ellipsis = "\u{2026}";
		if ( $acf_body && function_exists( 'get_field' ) ) {
			$body = get_field( $acf_body, $post->ID );
			if ( $body ) {
				return wp_trim_words( wp_strip_all_tags( (string) $body ), 40, $ellipsis );
			}
		}
		if ( $post->post_excerpt ) {
			return wp_trim_words( wp_strip_all_tags( $post->post_excerpt ), 40, $ellipsis );
		}
		return wp_trim_words( wp_strip_all_tags( $post->post_content ), 40, $ellipsis );
	}

	/**
	 * @param int $post_id Post ID.
	 * @return string
	 */
	private static function thumbnail_url( $post_id ) {
		$url = get_the_post_thumbnail_url( $post_id, 'large' );
		return $url ? esc_url_raw( $url ) : '';
	}
}

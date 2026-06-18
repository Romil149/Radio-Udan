<?php
/**
 * Registration eligibility, rate limits, duplicates.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Guards for POST /events/{id}/registrations.
 */
class RadioUdaan_Registration_Guard {

	/**
	 * @param array<string,mixed> $event Event from registry.
	 * @return true|WP_Error
	 */
	public static function assert_event_open( $event ) {
		$status = isset( $event['status'] ) ? $event['status'] : 'open';
		if ( 'open' === $status ) {
			return true;
		}

		$message = 'closed' === $status
			? __( 'Registration for this event is closed.', 'radioudaan-app-api' )
			: __( 'This event is not accepting registrations.', 'radioudaan-app-api' );

		return new WP_Error(
			'registration_closed',
			$message,
			array( 'status' => 403 )
		);
	}

	/**
	 * @param string            $phone   E.164 phone.
	 * @param WP_REST_Request   $request Request.
	 * @return true|WP_Error
	 */
	public static function check_rate_limits( $phone, WP_REST_Request $request ) {
		$ip = RadioUdaan_Rate_Limiter::get_client_ip();

		if ( RadioUdaan_Rate_Limiter::is_limited(
			'reg_phone_' . $phone,
			RadioUdaan_App_Settings::get_registration_limit_per_phone_hour(),
			HOUR_IN_SECONDS
		) ) {
			return new WP_Error(
				'registration_rate_limited',
				__( 'Too many registration attempts. Try again later.', 'radioudaan-app-api' ),
				array( 'status' => 429 )
			);
		}

		if ( RadioUdaan_Rate_Limiter::is_limited(
			'reg_ip_' . $ip,
			RadioUdaan_App_Settings::get_registration_limit_per_ip_hour(),
			HOUR_IN_SECONDS
		) ) {
			return new WP_Error(
				'registration_rate_limited',
				__( 'Too many requests from this network. Try again later.', 'radioudaan-app-api' ),
				array( 'status' => 429 )
			);
		}

		RadioUdaan_Rate_Limiter::bump( 'reg_phone_' . $phone, HOUR_IN_SECONDS );
		RadioUdaan_Rate_Limiter::bump( 'reg_ip_' . $ip, HOUR_IN_SECONDS );

		return true;
	}

	/**
	 * @param array<string,mixed> $event   Event from registry.
	 * @param int                 $form_id Forminator form id.
	 * @param string              $email   Authenticated app user email.
	 * @return true|WP_Error
	 */
	public static function check_duplicate( $event, $form_id, $email ) {
		if ( ! RadioUdaan_App_Settings::prevent_duplicate_registration() ) {
			return true;
		}

		if ( ! empty( $event['allow_multiple_registrations'] ) ) {
			return true;
		}

		$email = strtolower( sanitize_email( (string) $email ) );
		if ( ! $email ) {
			return true;
		}

		$event_id = isset( $event['event_id'] ) ? (int) $event['event_id'] : 0;
		if ( $event_id <= 0 ) {
			return true;
		}

		if ( self::has_existing_entry( $event_id, $form_id, $email ) ) {
			return new WP_Error(
				'registration_duplicate',
				__( 'You have already registered for this event.', 'radioudaan-app-api' ),
				array( 'status' => 409 )
			);
		}

		return true;
	}

	/**
	 * @param int    $event_id Event id.
	 * @param int    $form_id  Form id.
	 * @param string $email    Normalized email.
	 * @return bool
	 */
	public static function has_existing_entry( $event_id, $form_id, $email ) {
		global $wpdb;

		$meta_table  = $wpdb->prefix . 'frmt_form_entry_meta';
		$entry_table = $wpdb->prefix . 'frmt_form_entry';

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$found = $wpdb->get_var(
			$wpdb->prepare(
				"SELECT e.entry_id FROM {$entry_table} e
				INNER JOIN {$meta_table} m_event ON m_event.entry_id = e.entry_id AND m_event.meta_key = %s AND m_event.meta_value = %s
				INNER JOIN {$meta_table} m_email ON m_email.entry_id = e.entry_id AND m_email.meta_key = %s AND m_email.meta_value = %s
				INNER JOIN {$meta_table} m_src ON m_src.entry_id = e.entry_id AND m_src.meta_key = %s AND m_src.meta_value = %s
				WHERE e.form_id = %d
				LIMIT 1",
				'_radioudaan_event_id',
				(string) (int) $event_id,
				'_radioudaan_email',
				$email,
				RadioUdaan_Entry_Source::META_KEY,
				RadioUdaan_Entry_Source::SOURCE_APP,
				(int) $form_id
			)
		);

		return (bool) $found;
	}
}

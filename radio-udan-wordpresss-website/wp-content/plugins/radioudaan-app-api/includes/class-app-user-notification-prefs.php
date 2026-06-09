<?php
/**
 * Per-user notification opt-in preferences (stored on app user row).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Notification preference keys synced with the Flutter Settings screen.
 */
class RadioUdaan_App_User_Notification_Prefs {

	/**
	 * @param int $user_id User id.
	 * @return array<string,bool>
	 */
	public static function get_for_user( $user_id ) {
		$user = RadioUdaan_App_Users::get_by_id( $user_id );
		if ( ! $user ) {
			return self::defaults();
		}

		$raw = isset( $user->notification_prefs ) ? (string) $user->notification_prefs : '';
		if ( '' === trim( $raw ) ) {
			return self::defaults();
		}

		$decoded = json_decode( $raw, true );
		if ( ! is_array( $decoded ) ) {
			return self::defaults();
		}

		$defaults = self::defaults();
		return array(
			'live_broadcasts_enabled' => isset( $decoded['live_broadcasts_enabled'] )
				? (bool) $decoded['live_broadcasts_enabled']
				: $defaults['live_broadcasts_enabled'],
			'events_enabled'          => isset( $decoded['events_enabled'] )
				? (bool) $decoded['events_enabled']
				: $defaults['events_enabled'],
			'promotions_enabled'      => isset( $decoded['promotions_enabled'] )
				? (bool) $decoded['promotions_enabled']
				: $defaults['promotions_enabled'],
		);
	}

	/**
	 * @param int               $user_id User id.
	 * @param array<string,mixed> $body  Partial update.
	 * @return array<string,bool>|WP_Error
	 */
	public static function update_for_user( $user_id, array $body ) {
		$current = self::get_for_user( $user_id );
		$next    = $current;

		if ( array_key_exists( 'live_broadcasts_enabled', $body ) ) {
			$next['live_broadcasts_enabled'] = (bool) $body['live_broadcasts_enabled'];
		}
		if ( array_key_exists( 'events_enabled', $body ) ) {
			$next['events_enabled'] = (bool) $body['events_enabled'];
		}
		if ( array_key_exists( 'promotions_enabled', $body ) ) {
			$next['promotions_enabled'] = (bool) $body['promotions_enabled'];
		}

		if ( $next === $current ) {
			return new WP_Error(
				'no_changes',
				__( 'No notification preferences to update.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$json = wp_json_encode( $next );
		$ok   = RadioUdaan_App_Users::update_fields(
			$user_id,
			array( 'notification_prefs' => $json )
		);

		if ( ! $ok ) {
			return new WP_Error(
				'prefs_save_failed',
				__( 'Could not save notification preferences.', 'radioudaan-app-api' ),
				array( 'status' => 500 )
			);
		}

		RadioUdaan_App_Logger::log( 'notification_prefs_updated', array( 'user_id' => (int) $user_id ) );

		return $next;
	}

	/**
	 * @return array<string,bool>
	 */
	public static function defaults() {
		$wp = RadioUdaan_App_Settings::get_notification_preferences_defaults();

		return array(
			'live_broadcasts_enabled' => ! empty( $wp['library_enabled'] ),
			'events_enabled'          => ! empty( $wp['events_enabled'] ),
			'promotions_enabled'      => ! empty( $wp['promotions_enabled'] ),
		);
	}
}

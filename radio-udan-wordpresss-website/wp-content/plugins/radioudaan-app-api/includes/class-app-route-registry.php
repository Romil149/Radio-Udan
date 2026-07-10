<?php
/**
 * Canonical list of REST routes for admin docs and smoke tests.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Static registry of /radioudaan/v1 endpoints.
 */
class RadioUdaan_App_Route_Registry {

	/**
	 * @return array<int,array{methods:string,path:string,description:string,auth:bool}>
	 */
	public static function get_routes() {
		return array(
			array(
				'methods'     => 'GET',
				'path'        => '/health',
				'description' => __( 'API status and dependency checks', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/config',
				'description' => __( 'App config (stream, legal URLs, upload rules, branding)', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/register',
				'description' => __( 'Create app account (password + OTP)', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/login',
				'description' => __( 'Sign in with email or mobile + password', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/forgot-password',
				'description' => __( 'Request password reset (email or SMS OTP)', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/reset-password',
				'description' => __( 'Complete password reset', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/otp/request',
				'description' => __( 'Send login OTP', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/otp/verify',
				'description' => __( 'Verify OTP → bearer token', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET, PATCH',
				'path'        => '/auth/me',
				'description' => __( 'Current session profile', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/change-password',
				'description' => __( 'Change password while signed in', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'GET, PATCH',
				'path'        => '/auth/notification-preferences',
				'description' => __( 'Push notification opt-in flags', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/avatar',
				'description' => __( 'Upload profile photo', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/email/resend',
				'description' => __( 'Resend email verification code', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/email/verify',
				'description' => __( 'Verify email with code', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/logout',
				'description' => __( 'Revoke bearer token', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/auth/account/delete',
				'description' => __( 'Delete app account (Apple 5.1.1(v))', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/support/contact',
				'description' => __( 'Contact form from app', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/devices/register',
				'description' => __( 'Register FCM device token', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/notifications',
				'description' => __( 'In-app notification inbox', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'PATCH',
				'path'        => '/notifications/{id}',
				'description' => __( 'Mark one notification read', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/notifications/read-all',
				'description' => __( 'Mark all notifications read', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'GET, POST',
				'path'        => '/me/favorites',
				'description' => __( 'List or sync radio show favorites', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/me/favorites/toggle',
				'description' => __( 'Add or remove one favorite show', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/events',
				'description' => __( 'List events (default status=open)', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/events/{id}',
				'description' => __( 'Event details', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/events/{id}/form',
				'description' => __( 'Dynamic Forminator form schema', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/events/{id}/registrations',
				'description' => __( 'Submit event registration', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/uploads',
				'description' => __( 'Stage file upload (multipart)', 'radioudaan-app-api' ),
				'auth'        => true,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/shows',
				'description' => __( 'Podcast / show catalog', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/whats-new',
				'description' => __( "What's new feed", 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/updates',
				'description' => __( 'Updates hub (announcements + community news)', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/updates/whats-new/{id}',
				'description' => __( "What's new article detail", 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/updates/latestcommunitynews/{id}',
				'description' => __( 'Community news article detail', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/schedule',
				'description' => __( 'Radio schedule (on-air + upcoming)', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/youtube/recent',
				'description' => __( 'Recent @radioudaan uploads', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/youtube/playlists',
				'description' => __( 'All channel playlists', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/youtube/playlists/featured',
				'description' => __( 'Featured playlists (auto)', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/youtube/playlists/{id}/videos',
				'description' => __( 'Videos in a playlist', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'GET',
				'path'        => '/library/youtube/search',
				'description' => __( 'Channel-scoped video search (?q=)', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/donate/orders',
				'description' => __( 'Create Razorpay donation order', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/donate/verify',
				'description' => __( 'Verify Razorpay payment signature', 'radioudaan-app-api' ),
				'auth'        => false,
			),
			array(
				'methods'     => 'POST',
				'path'        => '/donate/webhook',
				'description' => __( 'Razorpay webhook', 'radioudaan-app-api' ),
				'auth'        => false,
			),
		);
	}

	/**
	 * Legacy tuple shape for admin endpoint lists: [method, path, description, auth].
	 *
	 * @return array<int,array{0:string,1:string,2:string,3:bool}>
	 */
	public static function get_admin_endpoint_tuples() {
		$tuples = array();
		foreach ( self::get_routes() as $route ) {
			$tuples[] = array(
				$route['methods'],
				$route['path'],
				$route['description'],
				$route['auth'],
			);
		}
		return $tuples;
	}
}

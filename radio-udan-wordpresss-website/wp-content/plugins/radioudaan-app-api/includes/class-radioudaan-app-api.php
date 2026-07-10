<?php
/**
 * Main plugin bootstrap.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

require_once RADIOUDAAN_APP_API_PATH . 'includes/class-event-registry.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-form-schema-builder.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-auth.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-password-auth.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-otp-service.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-uploads.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-registration-handler.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-rate-limiter.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-registration-guard.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-config.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-logger.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-profile.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-support.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-notifications.php';

/**
 * Radio Udaan App API singleton.
 */
final class RadioUdaan_App_Api {

	/**
	 * @var self|null
	 */
	private static $instance = null;

	/**
	 * @return self
	 */
	public static function instance() {
		if ( null === self::$instance ) {
			self::$instance = new self();
		}
		return self::$instance;
	}

	/**
	 * Register hooks.
	 */
	public function init() {
		add_action( 'rest_api_init', array( $this, 'register_rest_routes' ) );
		if ( is_admin() ) {
			require_once RADIOUDAAN_APP_API_PATH . 'includes/class-admin-form-migration.php';
			RadioUdaan_Admin_Form_Migration::init();
			// RadioUdaan_Admin_App_Hub::init() is called from radioudaan-app-api.php.
		}
	}

	/**
	 * Register REST routes under /wp-json/radioudaan/v1.
	 */
	public function register_rest_routes() {
		register_rest_route(
			'radioudaan/v1',
			'/config',
			array(
				'methods'             => 'GET',
				'callback'            => array( $this, 'get_config' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/me',
			array(
				array(
					'methods'             => 'GET',
					'callback'            => array( $this, 'auth_me' ),
					'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
				),
				array(
					'methods'             => 'PATCH',
					'callback'            => array( $this, 'auth_me_update' ),
					'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/change-password',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'auth_change_password' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/notification-preferences',
			array(
				array(
					'methods'             => 'GET',
					'callback'            => array( $this, 'get_notification_preferences' ),
					'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
				),
				array(
					'methods'             => 'PATCH',
					'callback'            => array( $this, 'patch_notification_preferences' ),
					'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/avatar',
			array(
				'methods'             => 'POST',
				'callback'            => array( 'RadioUdaan_App_Profile', 'handle_avatar_upload' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/support/contact',
			array(
				'methods'             => 'POST',
				'callback'            => array( 'RadioUdaan_App_Support', 'handle_contact' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/devices/register',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'devices_register' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/notifications',
			array(
				'methods'             => 'GET',
				'callback'            => array( $this, 'list_notifications' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
				'args'                => array(
					'page'     => array(
						'default'           => 1,
						'sanitize_callback' => 'absint',
					),
					'per_page' => array(
						'default'           => 20,
						'sanitize_callback' => 'absint',
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/notifications/(?P<id>\d+)',
			array(
				'methods'             => 'PATCH',
				'callback'            => array( $this, 'mark_notification_read' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
				'args'                => array(
					'id' => array(
						'validate_callback' => array( $this, 'validate_positive_int' ),
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/notifications/read-all',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'notifications_mark_all_read' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/me/favorites',
			array(
				array(
					'methods'             => 'GET',
					'callback'            => array( $this, 'me_favorites_list' ),
					'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
				),
				array(
					'methods'             => 'POST',
					'callback'            => array( $this, 'me_favorites_sync' ),
					'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/me/favorites/toggle',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'me_favorites_toggle' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/register',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'auth_register' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/login',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'auth_login' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/forgot-password',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'auth_forgot_password' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/reset-password',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'auth_reset_password' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/email/resend',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'auth_email_resend' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/email/verify',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'auth_email_verify' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/logout',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'auth_logout' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/account/delete',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'auth_account_delete' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/health',
			array(
				'methods'             => 'GET',
				'callback'            => array( $this, 'health' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/otp/request',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'otp_request' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/auth/otp/verify',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'otp_verify' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/events',
			array(
				'methods'             => 'GET',
				'callback'            => array( $this, 'list_events' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'status' => array(
						'default'           => 'open',
						'sanitize_callback' => 'sanitize_key',
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/events/(?P<id>\d+)',
			array(
				'methods'             => 'GET',
				'callback'            => array( $this, 'get_event' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'id' => array(
						'validate_callback' => array( $this, 'validate_positive_int' ),
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/events/(?P<id>\d+)/form',
			array(
				'methods'             => 'GET',
				'callback'            => array( $this, 'get_event_form' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'id' => array(
						'validate_callback' => array( $this, 'validate_positive_int' ),
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/events/(?P<id>\d+)/registrations',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'submit_registration' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
				'args'                => array(
					'id' => array(
						'validate_callback' => array( $this, 'validate_positive_int' ),
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/shows',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Library', 'list_shows' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'per_page' => array(
						'default'           => 20,
						'sanitize_callback' => 'absint',
					),
					'page'     => array(
						'default'           => 1,
						'sanitize_callback' => 'absint',
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/whats-new',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Library', 'list_whats_new' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'per_page' => array(
						'default'           => 20,
						'sanitize_callback' => 'absint',
					),
					'page'     => array(
						'default'           => 1,
						'sanitize_callback' => 'absint',
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/updates',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Library', 'list_updates' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'per_page' => array(
						'default'           => 50,
						'sanitize_callback' => 'absint',
					),
					'page'     => array(
						'default'           => 1,
						'sanitize_callback' => 'absint',
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/updates/whats-new/(?P<id>\d+)',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Library', 'get_whats_new_detail' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'id' => array(
						'validate_callback' => static function ( $value ) {
							return is_numeric( $value ) && (int) $value > 0;
						},
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/updates/latestcommunitynews/(?P<id>\d+)',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Library', 'get_community_news_detail' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'id' => array(
						'validate_callback' => static function ( $value ) {
							return is_numeric( $value ) && (int) $value > 0;
						},
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/donate/orders',
			array(
				'methods'             => 'POST',
				'callback'            => array( 'RadioUdaan_App_Donations', 'create_order' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/donate/verify',
			array(
				'methods'             => 'POST',
				'callback'            => array( 'RadioUdaan_App_Donations', 'verify_payment' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/donate/webhook',
			array(
				'methods'             => 'POST',
				'callback'            => array( 'RadioUdaan_App_Donations', 'handle_webhook' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/schedule',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Radio_Schedule', 'get_schedule' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'days' => array(
						'default'           => 2,
						'sanitize_callback' => 'absint',
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/youtube/recent',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Youtube_Library', 'rest_recent' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'per_page' => array(
						'default'           => 20,
						'sanitize_callback' => 'absint',
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/youtube/playlists/featured',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Youtube_Library', 'rest_featured_playlists' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/youtube/playlists/(?P<id>[A-Za-z0-9_-]+)/videos',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Youtube_Library', 'rest_playlist_videos' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'id' => array(
						'required'          => true,
						'sanitize_callback' => 'sanitize_text_field',
					),
					'per_page' => array(
						'default'           => 20,
						'sanitize_callback' => 'absint',
					),
					'page' => array(
						'default'           => 1,
						'sanitize_callback' => 'absint',
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/youtube/playlists',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Youtube_Library', 'rest_playlists' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/library/youtube/search',
			array(
				'methods'             => 'GET',
				'callback'            => array( 'RadioUdaan_App_Youtube_Library', 'rest_search' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'q' => array(
						'required'          => true,
						'sanitize_callback' => 'sanitize_text_field',
					),
					'per_page' => array(
						'default'           => 20,
						'sanitize_callback' => 'absint',
					),
					'page' => array(
						'default'           => 1,
						'sanitize_callback' => 'absint',
					),
				),
			)
		);

		register_rest_route(
			'radioudaan/v1',
			'/uploads',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'upload_file' ),
				'permission_callback' => array( 'RadioUdaan_App_Auth', 'require_auth' ),
				'args'                => array(
					'event_id'  => array(
						'required'          => true,
						'validate_callback' => array( $this, 'validate_positive_int' ),
					),
					'field_key' => array(
						'sanitize_callback' => 'sanitize_text_field',
					),
				),
			)
		);
	}

	/**
	 * @param mixed $param Param.
	 * @return bool
	 */
	public function validate_positive_int( $param ) {
		return is_numeric( $param ) && (int) $param > 0;
	}

	/**
	 * @return WP_REST_Response
	 */
	public function health() {
		$app_users_ok = RadioUdaan_App_Users::ensure_schema();
		$auto_inc     = $app_users_ok && RadioUdaan_App_Users::primary_key_auto_increments();

		return new WP_REST_Response(
			array(
				'status'  => ( $app_users_ok && $auto_inc ) ? 'ok' : 'degraded',
				'version' => RADIOUDAAN_APP_API_VERSION,
				'checks'  => array(
					'app_users_table'             => $app_users_ok,
					'app_users_auto_inc'          => $auto_inc,
					'app_users_row_count'         => RadioUdaan_App_Users::row_count(),
					'app_users_active_count'      => RadioUdaan_App_Users::count_by_status( RadioUdaan_App_Users::STATUS_ACTIVE ),
					'app_users_pending_count'     => RadioUdaan_App_Users::count_by_status( RadioUdaan_App_Users::STATUS_PENDING ),
					'app_users_deleted_count'     => RadioUdaan_App_Users::count_by_status( RadioUdaan_App_Users::STATUS_DELETED ),
					'fcm_configured'              => RadioUdaan_App_Fcm_Sender::is_configured(),
					'fcm_project_id'              => RadioUdaan_App_Settings::get_fcm_project_id(),
					'push_devices_registered'     => RadioUdaan_App_Notifications::count_registered_devices(),
				),
			),
			( $app_users_ok && $auto_inc ) ? 200 : 503
		);
	}

	/**
	 * @return WP_REST_Response
	 */
	public function get_config() {
		$response = new WP_REST_Response( RadioUdaan_App_Config::get_public_config(), 200 );
		$response->header( 'Cache-Control', 'public, max-age=' . (int) RadioUdaan_App_Config::CACHE_TTL );
		return $response;
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function auth_me( WP_REST_Request $request ) {
		$session = RadioUdaan_App_Auth::get_session_from_request( $request );
		if ( ! $session ) {
			return new WP_Error(
				'unauthorized',
				__( 'Authentication required.', 'radioudaan-app-api' ),
				array( 'status' => 401 )
			);
		}

		return new WP_REST_Response(
			array(
				'user'       => isset( $session['user'] ) ? $session['user'] : null,
				'expires_at' => $session['expires_at'],
			),
			200
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function auth_me_update( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$body   = $request->get_json_params();
		$result = RadioUdaan_App_Profile::update_profile( $user_id, is_array( $body ) ? $body : array() );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function auth_change_password( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$body   = $request->get_json_params();
		$result = RadioUdaan_App_Profile::change_password( $user_id, is_array( $body ) ? $body : array() );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function get_notification_preferences( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		return new WP_REST_Response(
			array(
				'preferences' => RadioUdaan_App_User_Notification_Prefs::get_for_user( $user_id ),
			),
			200
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function patch_notification_preferences( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$body   = $request->get_json_params();
		$result = RadioUdaan_App_User_Notification_Prefs::update_for_user(
			$user_id,
			is_array( $body ) ? $body : array()
		);
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response(
			array(
				'status'      => 'updated',
				'preferences' => $result,
			),
			200
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function devices_register( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$body   = $request->get_json_params();
		$result = RadioUdaan_App_Notifications::register_device( $user_id, is_array( $body ) ? $body : array() );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function list_notifications( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$result = RadioUdaan_App_Notifications::list_for_user(
			$user_id,
			(int) $request->get_param( 'page' ),
			(int) $request->get_param( 'per_page' )
		);

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function mark_notification_read( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$result = RadioUdaan_App_Notifications::mark_read( $user_id, (int) $request['id'] );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response
	 */
	public function auth_logout( WP_REST_Request $request ) {
		$token = RadioUdaan_App_Auth::get_bearer_token( $request );
		RadioUdaan_App_Auth::revoke_token( $token );

		return new WP_REST_Response(
			array(
				'status' => 'logged_out',
			),
			200
		);
	}

	/**
	 * Delete app account: remove wp_ru_app_users row and revoke all bearer tokens for the phone.
	 *
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function auth_account_delete( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error(
				'unauthorized',
				__( 'Authentication required.', 'radioudaan-app-api' ),
				array( 'status' => 401 )
			);
		}

		$user    = RadioUdaan_App_Users::get_by_id( $user_id );
		$phone   = $user ? $user->phone_e164 : '';
		RadioUdaan_App_Notifications::delete_devices_for_user( $user_id );
		RadioUdaan_App_Notifications::anonymize_notifications_for_user( $user_id );
		RadioUdaan_App_Favorites::delete_for_user( $user_id );
		$removed = RadioUdaan_App_Users::soft_delete( $user_id );

		RadioUdaan_App_Auth::revoke_all_tokens_for_user_id( $user_id );

		/**
		 * Fires after an app user deletes their account via the API.
		 *
		 * @param string $phone_e164 E.164 phone (may be empty after soft-delete).
		 * @param bool   $removed    Whether the user was soft-deleted.
		 */
		do_action( 'radioudaan_app_account_deleted', $phone, $removed );

		return new WP_REST_Response(
			array(
				'status'  => 'account_deleted',
				'removed' => $removed,
			),
			200
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function me_favorites_list( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		return new WP_REST_Response(
			array( 'items' => RadioUdaan_App_Favorites::list_for_user( $user_id ) ),
			200
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function me_favorites_sync( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$body   = $request->get_json_params();
		$result = RadioUdaan_App_Favorites::sync( $user_id, is_array( $body ) ? $body : array() );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function me_favorites_toggle( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$body   = $request->get_json_params();
		$result = RadioUdaan_App_Favorites::toggle( $user_id, is_array( $body ) ? $body : array() );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function notifications_mark_all_read( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		return new WP_REST_Response(
			RadioUdaan_App_Notifications::mark_all_read( $user_id ),
			200
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function auth_register( WP_REST_Request $request ) {
		$body   = $request->get_json_params();
		$result = RadioUdaan_App_Password_Auth::register( is_array( $body ) ? $body : array() );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 201 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function auth_login( WP_REST_Request $request ) {
		$body   = $request->get_json_params();
		$result = RadioUdaan_App_Password_Auth::login( is_array( $body ) ? $body : array() );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function auth_forgot_password( WP_REST_Request $request ) {
		$body       = $request->get_json_params();
		$identifier = isset( $body['identifier'] ) ? $body['identifier'] : '';
		$result     = RadioUdaan_App_Password_Auth::forgot_password( $identifier );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function auth_reset_password( WP_REST_Request $request ) {
		$body   = $request->get_json_params();
		$result = RadioUdaan_App_Password_Auth::reset_password( is_array( $body ) ? $body : array() );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function auth_email_resend( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$result = RadioUdaan_App_Password_Auth::resend_email_verification( $user_id );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function auth_email_verify( WP_REST_Request $request ) {
		$user_id = RadioUdaan_App_Auth::get_user_id_from_request( $request );
		if ( ! $user_id ) {
			return new WP_Error( 'unauthorized', __( 'Authentication required.', 'radioudaan-app-api' ), array( 'status' => 401 ) );
		}

		$body   = $request->get_json_params();
		$result = RadioUdaan_App_Password_Auth::verify_email( is_array( $body ) ? $body : array(), $user_id );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function otp_request( WP_REST_Request $request ) {
		$body    = $request->get_json_params();
		$phone   = isset( $body['phone_e164'] ) ? $body['phone_e164'] : '';
		$purpose = isset( $body['purpose'] ) ? $body['purpose'] : RadioUdaan_Otp_Service::PURPOSE_LOGIN;

		$result = RadioUdaan_Otp_Service::request_otp( $phone, $purpose );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function otp_verify( WP_REST_Request $request ) {
		$body = $request->get_json_params();

		$result = RadioUdaan_Otp_Service::verify_otp(
			isset( $body['request_id'] ) ? $body['request_id'] : '',
			isset( $body['otp'] ) ? $body['otp'] : '',
			isset( $body['purpose'] ) ? $body['purpose'] : ''
		);

		if ( is_wp_error( $result ) ) {
			return $result;
		}

		return new WP_REST_Response( $result, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response
	 */
	public function list_events( WP_REST_Request $request ) {
		$status = $request->get_param( 'status' );
		$items  = RadioUdaan_Event_Registry::list_events( $status ? $status : 'open' );

		return new WP_REST_Response(
			array(
				'items' => $items,
			),
			200
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function get_event( WP_REST_Request $request ) {
		$event = RadioUdaan_Event_Registry::get_event( (int) $request['id'] );

		if ( ! $event ) {
			return new WP_Error(
				'event_not_found',
				__( 'Event not found.', 'radioudaan-app-api' ),
				array( 'status' => 404 )
			);
		}

		return new WP_REST_Response( $event, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function get_event_form( WP_REST_Request $request ) {
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

		$summary = array(
			'event_id'         => $event['event_id'],
			'event_code'       => $event['event_code'],
			'title'            => $event['title'],
			'summary'          => isset( $event['summary'] ) ? (string) $event['summary'] : '',
			'event_type'       => isset( $event['event_type'] ) ? (string) $event['event_type'] : 'other',
			'event_type_label' => isset( $event['event_type_label'] ) ? (string) $event['event_type_label'] : '',
			'start_at'         => isset( $event['start_at'] ) ? $event['start_at'] : null,
			'banner_image'     => isset( $event['banner_image'] ) ? $event['banner_image'] : null,
		);

		$schema = RadioUdaan_Form_Schema_Builder::build_for_form( (int) $event['form_id'], $summary );

		if ( is_wp_error( $schema ) ) {
			return $schema;
		}

		return new WP_REST_Response( $schema, 200 );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function submit_registration( WP_REST_Request $request ) {
		return RadioUdaan_Registration_Handler::submit( $request );
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function upload_file( WP_REST_Request $request ) {
		return RadioUdaan_App_Uploads::handle_rest_upload( $request );
	}
}

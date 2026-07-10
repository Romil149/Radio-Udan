<?php
/**
 * Plugin Name: Radio Udaan App
 * Description: Mobile app admin dashboard + REST API (events, dynamic forms, registrations, uploads, OTP).
 * Version: 1.0.0
 * Author: Radio Udaan
 * Requires at least: 6.0
 * Requires PHP: 7.4
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

define( 'RADIOUDAAN_APP_API_VERSION', '1.0.0' );
define( 'RADIOUDAAN_APP_API_URL', plugin_dir_url( __FILE__ ) );

/**
 * Local dev helpers (optional — add to wp-config.php instead if preferred):
 * define( 'RADIOUDAAN_APP_API_DEV_AUTH', true );  // skip bearer token on protected routes
 * define( 'RADIOUDAAN_APP_API_DEV_OTP', true );   // OTP always 123456 + returned in response
 * define( 'RADIOUDAAN_APP_API_DEV_CORS', true );  // allow any origin on /radioudaan/* (local Flutter web)
 * define( 'RADIOUDAAN_FCM_SERVICE_ACCOUNT_JSON', '{...}' ); // or RADIOUDAAN_FCM_SERVICE_ACCOUNT_PATH
 * define( 'RADIOUDAAN_FCM_PROJECT_ID', 'your-firebase-project-id' ); // optional if present in JSON
 */
define( 'RADIOUDAAN_APP_API_FILE', __FILE__ );
define( 'RADIOUDAAN_APP_API_PATH', plugin_dir_path( __FILE__ ) );

require_once RADIOUDAAN_APP_API_PATH . 'includes/class-rate-limiter.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-logger.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-registration-guard.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-copy-catalog.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-branding.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-live-radio.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-azuracast-now-playing.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-route-registry.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-config.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-upload-cleanup.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-mailer.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-users.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-admin-audit.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-password-auth.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-entry-source.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-event-meta-ui.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-settings.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-legal-pages.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-info-hub.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-cpt-ru-event.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-event-sync.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-otp-msg91.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-admin-app-hub.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-library.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-youtube-library.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-radio-schedule.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-rj-profile.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-rj-profile-public.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-rj-profile-admin.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-rj-profile-migration.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-cors.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-profile.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-user-notification-prefs.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-support.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-fcm-sender.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-notifications.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-updates-notifications.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-favorites.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-donations-settings.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-donations-db.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-razorpay-client.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-donations-80g-pdf.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-donations.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-app-version-policy.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-donations.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/class-radioudaan-app-api.php';

/**
 * Bootstrap plugin.
 */
function radioudaan_app_api_init() {
	RadioUdaan_Cpt_Ru_Event::init();
	RadioUdaan_App_Users::init();
	RadioUdaan_App_Admin_Audit::init();
	RadioUdaan_App_Support::init();
	RadioUdaan_App_Notifications::init();
	RadioUdaan_App_Updates_Notifications::init();
	RadioUdaan_App_Favorites::init();
	RadioUdaan_App_Donations::init();
	RadioUdaan_Upload_Cleanup::init();
	RadioUdaan_Event_Meta_Ui::init();
	RadioUdaan_Entry_Source::init();
	RadioUdaan_Event_Sync::init();
	RadioUdaan_Otp_Msg91::init();
	if ( class_exists( 'RadioUdaan_Admin_App_Hub', false ) ) {
		add_action( 'admin_post_radioudaan_save_app_settings', array( 'RadioUdaan_Admin_App_Hub', 'handle_save_settings' ) );
	}
	if ( is_admin() ) {
		if ( class_exists( 'RadioUdaan_Admin_App_Hub', false ) ) {
			RadioUdaan_Admin_App_Hub::init();
		} else {
			add_action(
				'admin_notices',
				static function () {
					$path = RADIOUDAAN_APP_API_PATH . 'includes/class-admin-app-hub.php';
					echo '<div class="notice notice-error"><p><strong>Radio Udaan App:</strong> ';
					echo esc_html__(
						'Plugin files are incomplete on the server. Re-upload the full radioudaan-app-api folder (see dist/radioudaan-app-api-staging.zip).',
						'radioudaan-app-api'
					);
					echo ' <code>' . esc_html( $path ) . '</code></p></div>';
				}
			);
		}
	}
	RadioUdaan_App_Cors::init();
	RadioUdaan_App_Live_Radio::maybe_remove_legacy_show_title_options();
	RadioUdaan_Rj_Profile::init();
	RadioUdaan_App_Api::instance()->init();
}
add_action( 'plugins_loaded', 'radioudaan_app_api_init' );

/**
 * One-time / versioned sync of registry → ru_event CPT.
 */
function radioudaan_app_api_maybe_sync_events() {
	if ( ! class_exists( 'RadioUdaan_Event_Sync' ) ) {
		return;
	}

	$synced_version = get_option( 'radioudaan_ru_events_sync_version', '' );
	if ( $synced_version === RADIOUDAAN_APP_API_VERSION ) {
		return;
	}

	RadioUdaan_Event_Sync::sync_all();
	update_option( 'radioudaan_ru_events_sync_version', RADIOUDAAN_APP_API_VERSION );
}
add_action( 'init', 'radioudaan_app_api_maybe_sync_events', 25 );

register_activation_hook(
	RADIOUDAAN_APP_API_FILE,
	static function () {
		RadioUdaan_Cpt_Ru_Event::register_post_type();
		RadioUdaan_App_Users::maybe_create_table();
		RadioUdaan_App_Users::maybe_migrate_columns();
		RadioUdaan_App_Admin_Audit::maybe_create_table();
		RadioUdaan_App_Support::maybe_create_table();
		RadioUdaan_App_Notifications::maybe_create_tables();
		RadioUdaan_App_Donations_Db::maybe_create_tables();
		RadioUdaan_Rj_Profile::ensure_role();
		RadioUdaan_Rj_Profile_Public::register_rewrites();
		flush_rewrite_rules();
		delete_option( 'radioudaan_ru_events_sync_version' );
	}
);

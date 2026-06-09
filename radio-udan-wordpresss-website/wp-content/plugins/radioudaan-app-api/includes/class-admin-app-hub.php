<?php
/**
 * Mobile app admin dashboard — menu registration & actions.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-assets.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-layout.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-event-editor.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-entry-viewer.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-help.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-app-users.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-data.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-settings-page.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-pages.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-export.php';
require_once RADIOUDAAN_APP_API_PATH . 'includes/admin/class-admin-notifications.php';

/**
 * Top-level WordPress admin for the Radio Udaan mobile app.
 */
class RadioUdaan_Admin_App_Hub {

	const MENU_SLUG          = 'radioudaan-app';
	const EVENTS_SLUG        = 'radioudaan-app-events';
	const EDIT_EVENT_SLUG    = 'radioudaan-app-edit-event';
	/** Event form entries (not app login). */
	const EVENT_ENTRIES_SLUG = 'radioudaan-app-registrations';

	/** @deprecated Use EVENT_ENTRIES_SLUG */
	const EVENT_SIGNUPS_SLUG = 'radioudaan-app-registrations';

	/** @deprecated Use EVENT_ENTRIES_SLUG */
	const REGISTRATIONS_SLUG = 'radioudaan-app-registrations';

	const APP_USERS_SLUG     = 'radioudaan-app-users';
	const VIEW_ENTRY_SLUG    = 'radioudaan-app-view-entry';
	const SETTINGS_SLUG      = 'radioudaan-app-settings';
	const HELP_SLUG          = 'radioudaan-app-help';
	const API_SLUG           = 'radioudaan-app-api';
	const NOTIFICATIONS_SLUG = 'radioudaan-app-notifications';

	/**
	 * Register admin UI.
	 */
	public static function init() {
		RadioUdaan_Admin_Assets::init();
		RadioUdaan_Admin_Export::init();
		RadioUdaan_App_Youtube_Library::init_admin();

		add_action( 'admin_menu', array( __CLASS__, 'register_menus' ), 9 );
		add_action( 'admin_init', array( __CLASS__, 'register_settings' ) );
		add_action( 'admin_post_radioudaan_save_app_settings', array( __CLASS__, 'handle_save_settings' ) );
		add_action( 'admin_post_radioudaan_send_app_notification', array( 'RadioUdaan_Admin_Notifications', 'handle_send' ) );
		add_action( 'admin_post_radioudaan_event_status', array( __CLASS__, 'handle_event_status' ) );
		add_action( 'admin_post_radioudaan_save_event', array( 'RadioUdaan_Admin_Event_Editor', 'handle_save' ) );
		add_action( 'wp_ajax_radioudaan_save_event_order', array( 'RadioUdaan_Admin_Data', 'ajax_save_event_order' ) );
	}

	/**
	 * Menus and submenus.
	 */
	public static function register_menus() {
		add_menu_page(
			__( 'Radio Udaan App', 'radioudaan-app-api' ),
			__( 'Radio Udaan App', 'radioudaan-app-api' ),
			'manage_options',
			self::MENU_SLUG,
			array( 'RadioUdaan_Admin_Pages', 'render_dashboard' ),
			'dashicons-smartphone',
			3
		);

		add_submenu_page(
			self::MENU_SLUG,
			__( 'Dashboard', 'radioudaan-app-api' ),
			__( 'Dashboard', 'radioudaan-app-api' ),
			'manage_options',
			self::MENU_SLUG,
			array( 'RadioUdaan_Admin_Pages', 'render_dashboard' )
		);

		add_submenu_page(
			self::MENU_SLUG,
			__( 'Events', 'radioudaan-app-api' ),
			__( 'Events', 'radioudaan-app-api' ),
			'manage_options',
			self::EVENTS_SLUG,
			array( 'RadioUdaan_Admin_Pages', 'render_events' )
		);

		add_submenu_page(
			self::MENU_SLUG,
			__( 'Registrations', 'radioudaan-app-api' ),
			__( 'Registrations', 'radioudaan-app-api' ),
			'manage_options',
			self::APP_USERS_SLUG,
			array( 'RadioUdaan_Admin_App_Users', 'render_page' )
		);

		add_submenu_page(
			self::MENU_SLUG,
			__( 'Event entries', 'radioudaan-app-api' ),
			__( 'Event entries', 'radioudaan-app-api' ),
			'manage_options',
			self::EVENT_ENTRIES_SLUG,
			array( 'RadioUdaan_Admin_Pages', 'render_event_entries' )
		);

		add_submenu_page(
			self::MENU_SLUG,
			__( 'Send notification', 'radioudaan-app-api' ),
			__( 'Send notification', 'radioudaan-app-api' ),
			'manage_options',
			self::NOTIFICATIONS_SLUG,
			array( 'RadioUdaan_Admin_Notifications', 'render_page' )
		);

		add_submenu_page(
			self::MENU_SLUG,
			__( 'Settings', 'radioudaan-app-api' ),
			__( 'Settings', 'radioudaan-app-api' ),
			'manage_options',
			self::SETTINGS_SLUG,
			array( 'RadioUdaan_Admin_Pages', 'render_settings' )
		);

		add_submenu_page(
			self::MENU_SLUG,
			__( 'Help', 'radioudaan-app-api' ),
			__( 'Help', 'radioudaan-app-api' ),
			'manage_options',
			self::HELP_SLUG,
			array( 'RadioUdaan_Admin_Help', 'render_page' )
		);

		// Hidden screens (linked from Events / Registrations).
		add_submenu_page(
			null,
			__( 'Edit event', 'radioudaan-app-api' ),
			__( 'Edit event', 'radioudaan-app-api' ),
			'manage_options',
			self::EDIT_EVENT_SLUG,
			array( 'RadioUdaan_Admin_Event_Editor', 'render_page' )
		);

		add_submenu_page(
			null,
			__( 'View event entry', 'radioudaan-app-api' ),
			__( 'View event entry', 'radioudaan-app-api' ),
			'manage_options',
			self::VIEW_ENTRY_SLUG,
			array( 'RadioUdaan_Admin_Entry_Viewer', 'render_page' )
		);

		if ( class_exists( 'RadioUdaan_Admin_Form_Migration' ) ) {
			add_submenu_page(
				self::MENU_SLUG,
				__( 'Advanced tools', 'radioudaan-app-api' ),
				__( 'Advanced tools', 'radioudaan-app-api' ),
				'manage_options',
				RadioUdaan_Admin_Form_Migration::PAGE_SLUG,
				array( 'RadioUdaan_Admin_Form_Migration', 'render_page' )
			);
		}

		add_submenu_page(
			self::MENU_SLUG,
			__( 'Developer API', 'radioudaan-app-api' ),
			__( 'Developer API', 'radioudaan-app-api' ),
			'manage_options',
			self::API_SLUG,
			array( 'RadioUdaan_Admin_Pages', 'render_api' )
		);
	}

	/**
	 * Register options.
	 */
	public static function register_settings() {
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_MAX_UPLOAD_MB );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_DEV_OTP );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_DEV_AUTH );
		register_setting( 'radioudaan_app_settings', 'radioudaan_msg91_auth_key' );
		register_setting( 'radioudaan_app_settings', 'radioudaan_msg91_sender_id' );
		register_setting( 'radioudaan_app_settings', 'radioudaan_msg91_template_id' );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_PRIVACY_POLICY_URL );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_TERMS_URL );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_ABOUT_URL );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_CONTACT_URL );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_SUPPORT_HELPLINE_PHONE );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_SUPPORT_EMAIL );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_FCM_SERVICE_ACCOUNT );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_FCM_PROJECT_ID );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_NOTIF_EVENTS_DEFAULT );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_NOTIF_LIBRARY_DEFAULT );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_NOTIF_PROMOTIONS_DEFAULT );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_REQUIRE_UNIQUE_EMAIL );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_REQUIRE_EMAIL_VERIFICATION );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_PASSWORD_MIN_LENGTH );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_EMAIL_VERIFY_SUBJECT );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_EMAIL_VERIFY_BODY );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_EMAIL_RESET_SUBJECT );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Settings::OPTION_EMAIL_RESET_BODY );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_APP_NAME );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_TAGLINE );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_LOGO_ATTACHMENT_ID );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COLOR_PRIMARY );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COLOR_ON_PRIMARY );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COLOR_SECONDARY );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COLOR_SURFACE );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COLOR_SURFACE_DARK );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COLOR_ERROR );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COPY_VERIFY_INTRO );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COPY_SUBMIT_REGISTRATION );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COPY_REGISTRATION_SUCCESS_PREFIX );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COPY_LIBRARY_SHOWS_EMPTY );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COPY_LIBRARY_WHATS_NEW_EMPTY );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Branding::OPTION_COPY_UNSUPPORTED_FIELDS_NOTICE );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Youtube_Library::OPTION_API_KEY );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Youtube_Library::OPTION_CHANNEL );
		register_setting( 'radioudaan_app_settings', RadioUdaan_App_Youtube_Library::OPTION_FEATURED_PLAYLISTS );
	}

	/**
	 * Save settings form.
	 */
	public static function handle_save_settings() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( 'radioudaan_save_app_settings' );

		if ( isset( $_POST['max_upload_mb'] ) ) {
			$mb = max( 1, min( 200, (int) $_POST['max_upload_mb'] ) );
			update_option( RadioUdaan_App_Settings::OPTION_MAX_UPLOAD_MB, $mb );
		}

		if ( ! defined( 'RADIOUDAAN_APP_API_DEV_OTP' ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_DEV_OTP, ! empty( $_POST['dev_otp'] ) ? 1 : 0 );
		}

		if ( ! defined( 'RADIOUDAAN_APP_API_DEV_AUTH' ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_DEV_AUTH, ! empty( $_POST['dev_auth'] ) ? 1 : 0 );
		}

		if ( ! defined( 'RADIOUDAAN_MSG91_AUTH_KEY' ) && isset( $_POST['msg91_auth_key'] ) ) {
			update_option( 'radioudaan_msg91_auth_key', sanitize_text_field( wp_unslash( $_POST['msg91_auth_key'] ) ) );
		}
		if ( isset( $_POST['msg91_sender_id'] ) ) {
			update_option( 'radioudaan_msg91_sender_id', sanitize_text_field( wp_unslash( $_POST['msg91_sender_id'] ) ) );
		}
		if ( isset( $_POST['msg91_template_id'] ) ) {
			update_option( 'radioudaan_msg91_template_id', sanitize_text_field( wp_unslash( $_POST['msg91_template_id'] ) ) );
		}

		if ( isset( $_POST['otp_limit_hour'] ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_OTP_LIMIT_HOUR, max( 1, (int) $_POST['otp_limit_hour'] ) );
		}
		if ( isset( $_POST['otp_verify_max'] ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_OTP_VERIFY_MAX, max( 1, (int) $_POST['otp_verify_max'] ) );
		}
		if ( isset( $_POST['otp_resend_delay'] ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_OTP_RESEND_DELAY, max( 30, (int) $_POST['otp_resend_delay'] ) );
		}
		if ( isset( $_POST['reg_limit_phone'] ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_REG_LIMIT_PHONE_HOUR, max( 1, (int) $_POST['reg_limit_phone'] ) );
		}
		if ( isset( $_POST['reg_limit_ip'] ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_REG_LIMIT_IP_HOUR, max( 1, (int) $_POST['reg_limit_ip'] ) );
		}
		if ( isset( $_POST['allowed_mime'] ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_ALLOWED_MIME, sanitize_textarea_field( wp_unslash( $_POST['allowed_mime'] ) ) );
		}
		if ( isset( $_POST['max_files_per_field'] ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_MAX_FILES_PER_FIELD, max( 1, (int) $_POST['max_files_per_field'] ) );
		}
		update_option( RadioUdaan_App_Settings::OPTION_PREVENT_DUPLICATE_REG, ! empty( $_POST['prevent_duplicate'] ) ? 1 : 0 );
		if ( isset( $_POST['upload_retention_days'] ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_UPLOAD_RETENTION_DAYS, max( 1, (int) $_POST['upload_retention_days'] ) );
		}
		if ( isset( $_POST['stream_url'] ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_STREAM_URL, esc_url_raw( wp_unslash( $_POST['stream_url'] ) ) );
		}
		if ( isset( $_POST['api_base_url'] ) ) {
			$url = esc_url_raw( trim( wp_unslash( $_POST['api_base_url'] ) ) );
			update_option( RadioUdaan_App_Settings::OPTION_API_BASE_URL, $url );
		}
		update_option( RadioUdaan_App_Settings::OPTION_PRIVATE_UPLOADS, ! empty( $_POST['private_uploads'] ) ? 1 : 0 );

		if ( isset( $_POST['password_min_length'] ) ) {
			update_option( RadioUdaan_App_Settings::OPTION_PASSWORD_MIN_LENGTH, max( 8, (int) $_POST['password_min_length'] ) );
		}
		update_option( RadioUdaan_App_Settings::OPTION_REQUIRE_UNIQUE_EMAIL, ! empty( $_POST['require_unique_email'] ) ? 1 : 0 );
		update_option( RadioUdaan_App_Settings::OPTION_REQUIRE_EMAIL_VERIFICATION, ! empty( $_POST['require_email_verification'] ) ? 1 : 0 );

		$auth_text_fields = array(
			'email_verify_subject' => RadioUdaan_App_Settings::OPTION_EMAIL_VERIFY_SUBJECT,
			'email_verify_body'    => RadioUdaan_App_Settings::OPTION_EMAIL_VERIFY_BODY,
			'email_reset_subject'  => RadioUdaan_App_Settings::OPTION_EMAIL_RESET_SUBJECT,
			'email_reset_body'     => RadioUdaan_App_Settings::OPTION_EMAIL_RESET_BODY,
		);
		foreach ( $auth_text_fields as $post_key => $option_key ) {
			if ( isset( $_POST[ $post_key ] ) ) {
				update_option( $option_key, sanitize_textarea_field( wp_unslash( $_POST[ $post_key ] ) ) );
			}
		}

		$url_fields = array(
			'privacy_policy_url' => RadioUdaan_App_Settings::OPTION_PRIVACY_POLICY_URL,
			'terms_url'          => RadioUdaan_App_Settings::OPTION_TERMS_URL,
			'about_url'          => RadioUdaan_App_Settings::OPTION_ABOUT_URL,
			'contact_url'        => RadioUdaan_App_Settings::OPTION_CONTACT_URL,
		);
		foreach ( $url_fields as $post_key => $option_key ) {
			if ( isset( $_POST[ $post_key ] ) ) {
				update_option( $option_key, esc_url_raw( trim( wp_unslash( $_POST[ $post_key ] ) ) ) );
			}
		}

		if ( isset( $_POST['support_helpline_phone'] ) ) {
			$phone = preg_replace( '/\s+/', '', sanitize_text_field( wp_unslash( $_POST['support_helpline_phone'] ) ) );
			update_option( RadioUdaan_App_Settings::OPTION_SUPPORT_HELPLINE_PHONE, $phone );
		}
		if ( isset( $_POST['support_email'] ) ) {
			update_option(
				RadioUdaan_App_Settings::OPTION_SUPPORT_EMAIL,
				strtolower( sanitize_email( wp_unslash( $_POST['support_email'] ) ) )
			);
		}
		if ( isset( $_POST['fcm_project_id'] ) ) {
			update_option(
				RadioUdaan_App_Settings::OPTION_FCM_PROJECT_ID,
				sanitize_text_field( wp_unslash( $_POST['fcm_project_id'] ) )
			);
		}
		if (
			! defined( 'RADIOUDAAN_FCM_SERVICE_ACCOUNT_JSON' )
			&& ! defined( 'RADIOUDAAN_FCM_SERVICE_ACCOUNT_PATH' )
			&& isset( $_POST['fcm_service_account_json'] )
		) {
			$json = trim( wp_unslash( $_POST['fcm_service_account_json'] ) );
			if ( '' !== $json ) {
				$account = RadioUdaan_App_Fcm_Sender::parse_service_account_json( $json );
				if ( ! $account ) {
					wp_die( esc_html__( 'Invalid Firebase service account JSON.', 'radioudaan-app-api' ) );
				}

				update_option( RadioUdaan_App_Settings::OPTION_FCM_SERVICE_ACCOUNT, $json );

				if ( '' === RadioUdaan_App_Settings::get_fcm_project_id() && ! empty( $account['project_id'] ) ) {
					update_option( RadioUdaan_App_Settings::OPTION_FCM_PROJECT_ID, $account['project_id'] );
				}

				RadioUdaan_App_Fcm_Sender::clear_oauth_cache();
			}
		}
		update_option( RadioUdaan_App_Settings::OPTION_NOTIF_EVENTS_DEFAULT, ! empty( $_POST['notif_events_default'] ) ? 1 : 0 );
		update_option( RadioUdaan_App_Settings::OPTION_NOTIF_LIBRARY_DEFAULT, ! empty( $_POST['notif_library_default'] ) ? 1 : 0 );
		update_option( RadioUdaan_App_Settings::OPTION_NOTIF_PROMOTIONS_DEFAULT, ! empty( $_POST['notif_promotions_default'] ) ? 1 : 0 );

		if ( isset( $_POST['branding_app_name'] ) ) {
			update_option( RadioUdaan_App_Branding::OPTION_APP_NAME, sanitize_text_field( wp_unslash( $_POST['branding_app_name'] ) ) );
		}
		if ( isset( $_POST['branding_tagline'] ) ) {
			update_option( RadioUdaan_App_Branding::OPTION_TAGLINE, sanitize_text_field( wp_unslash( $_POST['branding_tagline'] ) ) );
		}
		if ( isset( $_POST['branding_logo_id'] ) ) {
			update_option( RadioUdaan_App_Branding::OPTION_LOGO_ATTACHMENT_ID, max( 0, (int) $_POST['branding_logo_id'] ) );
		}

		$color_map = array(
			'branding_color_primary'      => array( RadioUdaan_App_Branding::OPTION_COLOR_PRIMARY, 'primary' ),
			'branding_color_on_primary'   => array( RadioUdaan_App_Branding::OPTION_COLOR_ON_PRIMARY, 'on_primary' ),
			'branding_color_secondary'    => array( RadioUdaan_App_Branding::OPTION_COLOR_SECONDARY, 'secondary' ),
			'branding_color_surface'      => array( RadioUdaan_App_Branding::OPTION_COLOR_SURFACE, 'surface' ),
			'branding_color_surface_dark' => array( RadioUdaan_App_Branding::OPTION_COLOR_SURFACE_DARK, 'surface_dark' ),
			'branding_color_error'        => array( RadioUdaan_App_Branding::OPTION_COLOR_ERROR, 'error' ),
		);
		$color_defaults = RadioUdaan_App_Branding::default_colors();
		foreach ( $color_map as $post_key => $meta ) {
			if ( isset( $_POST[ $post_key ] ) ) {
				$fallback = $color_defaults[ $meta[1] ] ?? '#000000';
				update_option(
					$meta[0],
					RadioUdaan_App_Branding::sanitize_hex( wp_unslash( $_POST[ $post_key ] ), $fallback )
				);
			}
		}

		$copy_fields = array(
			'copy_bootstrap_loading' => RadioUdaan_App_Branding::OPTION_COPY_BOOTSTRAP_LOADING,
			'copy_sign_in_intro'     => RadioUdaan_App_Branding::OPTION_COPY_SIGN_IN_INTRO,
			'copy_radio_intro'       => RadioUdaan_App_Branding::OPTION_COPY_RADIO_INTRO,
			'copy_radio_live_label'  => RadioUdaan_App_Branding::OPTION_COPY_RADIO_LIVE_LABEL,
			'copy_tab_radio'         => RadioUdaan_App_Branding::OPTION_COPY_TAB_RADIO,
			'copy_tab_library'       => RadioUdaan_App_Branding::OPTION_COPY_TAB_LIBRARY,
			'copy_tab_events'        => RadioUdaan_App_Branding::OPTION_COPY_TAB_EVENTS,
			'copy_tab_more'          => RadioUdaan_App_Branding::OPTION_COPY_TAB_MORE,
			'copy_events_empty'      => RadioUdaan_App_Branding::OPTION_COPY_EVENTS_EMPTY,
			'copy_library_shows'     => RadioUdaan_App_Branding::OPTION_COPY_LIBRARY_SHOWS,
			'copy_library_whats_new'      => RadioUdaan_App_Branding::OPTION_COPY_LIBRARY_WHATS_NEW,
			'copy_verify_intro'           => RadioUdaan_App_Branding::OPTION_COPY_VERIFY_INTRO,
			'copy_submit_registration'    => RadioUdaan_App_Branding::OPTION_COPY_SUBMIT_REGISTRATION,
			'copy_registration_success'   => RadioUdaan_App_Branding::OPTION_COPY_REGISTRATION_SUCCESS_PREFIX,
			'copy_library_shows_empty'    => RadioUdaan_App_Branding::OPTION_COPY_LIBRARY_SHOWS_EMPTY,
			'copy_library_whats_new_empty' => RadioUdaan_App_Branding::OPTION_COPY_LIBRARY_WHATS_NEW_EMPTY,
			'copy_unsupported_fields'     => RadioUdaan_App_Branding::OPTION_COPY_UNSUPPORTED_FIELDS_NOTICE,
		);
		foreach ( $copy_fields as $post_key => $option_key ) {
			if ( isset( $_POST[ $post_key ] ) ) {
				update_option( $option_key, sanitize_text_field( wp_unslash( $_POST[ $post_key ] ) ) );
			}
		}

		$live_text_fields = array(
			'live_show_title'    => RadioUdaan_App_Live_Radio::OPTION_SHOW_TITLE,
			'live_show_subtitle' => RadioUdaan_App_Live_Radio::OPTION_SHOW_SUBTITLE,
			'live_whatsapp_url'  => RadioUdaan_App_Live_Radio::OPTION_WHATSAPP_URL,
			'live_whatsapp_label' => RadioUdaan_App_Live_Radio::OPTION_WHATSAPP_LABEL,
			'live_share_label'   => RadioUdaan_App_Live_Radio::OPTION_SHARE_LABEL,
			'live_share_text'    => RadioUdaan_App_Live_Radio::OPTION_SHARE_TEXT,
		);
		foreach ( $live_text_fields as $post_key => $option_key ) {
			if ( isset( $_POST[ $post_key ] ) ) {
				$raw = wp_unslash( $_POST[ $post_key ] );
				if ( strpos( $post_key, '_url' ) !== false ) {
					update_option( $option_key, esc_url_raw( trim( $raw ) ) );
				} else {
					update_option( $option_key, sanitize_text_field( $raw ) );
				}
			}
		}
		if ( isset( $_POST['live_hero_id'] ) ) {
			update_option(
				RadioUdaan_App_Live_Radio::OPTION_HERO_ATTACHMENT_ID,
				max( 0, (int) $_POST['live_hero_id'] )
			);
		}
		update_option( RadioUdaan_App_Live_Radio::OPTION_SHOW_WHATSAPP, ! empty( $_POST['live_show_whatsapp'] ) ? 1 : 0 );
		update_option( RadioUdaan_App_Live_Radio::OPTION_SHOW_SHARE, ! empty( $_POST['live_show_share'] ) ? 1 : 0 );
		update_option( RadioUdaan_App_Live_Radio::OPTION_SHOW_VOLUME, ! empty( $_POST['live_show_volume'] ) ? 1 : 0 );

		if ( isset( $_POST['youtube_api_key'] ) ) {
			update_option(
				RadioUdaan_App_Youtube_Library::OPTION_API_KEY,
				sanitize_text_field( wp_unslash( $_POST['youtube_api_key'] ) )
			);
		}
		if ( isset( $_POST['youtube_channel'] ) ) {
			update_option(
				RadioUdaan_App_Youtube_Library::OPTION_CHANNEL,
				sanitize_text_field( wp_unslash( $_POST['youtube_channel'] ) )
			);
		}
		$featured_playlists = array();
		if ( isset( $_POST['youtube_featured_playlists'] ) && is_array( $_POST['youtube_featured_playlists'] ) ) {
			foreach ( $_POST['youtube_featured_playlists'] as $playlist_id ) {
				$playlist_id = sanitize_text_field( wp_unslash( $playlist_id ) );
				if ( $playlist_id !== '' ) {
					$featured_playlists[] = $playlist_id;
				}
			}
		}
		// Preserve admin drag-and-drop order (dedupe while keeping first occurrence).
		$featured_playlists = array_values( array_unique( $featured_playlists ) );
		update_option(
			RadioUdaan_App_Youtube_Library::OPTION_FEATURED_PLAYLISTS,
			wp_json_encode( $featured_playlists )
		);
		RadioUdaan_App_Youtube_Library::invalidate_cache();

		RadioUdaan_App_Config::invalidate_cache();

		wp_safe_redirect(
			add_query_arg(
				array(
					'page'             => self::SETTINGS_SLUG,
					'settings-updated' => 'true',
				),
				admin_url( 'admin.php' )
			)
		);
		exit;
	}

	/**
	 * Quick event status change from Events page.
	 */
	public static function handle_event_status() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$event_id = isset( $_POST['event_id'] ) ? (int) $_POST['event_id'] : 0;
		$status   = isset( $_POST['status'] ) ? sanitize_key( wp_unslash( $_POST['status'] ) ) : '';

		check_admin_referer( 'radioudaan_event_status_' . $event_id );

		if ( ! $event_id || ! in_array( $status, array( 'open', 'closed', 'draft' ), true ) ) {
			wp_die( esc_html__( 'Invalid request.', 'radioudaan-app-api' ) );
		}

		$post = get_post( $event_id );
		if ( ! $post || RadioUdaan_Cpt_Ru_Event::POST_TYPE !== $post->post_type ) {
			wp_die( esc_html__( 'Event not found.', 'radioudaan-app-api' ) );
		}

		update_post_meta( $event_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_STATUS, $status );

		wp_safe_redirect(
			add_query_arg(
				array(
					'page'              => self::EVENTS_SLUG,
					'radioudaan_notice' => 'success',
					'radioudaan_detail' => rawurlencode(
						sprintf(
							/* translators: 1: event title, 2: status */
							__( '%1$s is now %2$s in the app.', 'radioudaan-app-api' ),
							get_the_title( $event_id ),
							$status
						)
					),
				),
				admin_url( 'admin.php' )
			)
		);
		exit;
	}
}

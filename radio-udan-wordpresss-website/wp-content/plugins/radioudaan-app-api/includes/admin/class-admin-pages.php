<?php
/**
 * Admin page renderers (dashboard, events, registrations, settings, API).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Mobile app admin dashboard pages.
 */
class RadioUdaan_Admin_Pages {

	/**
	 * Dashboard home.
	 */
	public static function render_dashboard() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$stats    = RadioUdaan_Admin_Data::get_dashboard_stats();
		$events   = array_slice( RadioUdaan_Admin_Data::get_managed_events(), 0, 5 );
		$api_base = RadioUdaan_App_Settings::get_api_base_url();
		$health   = RadioUdaan_Admin_Data::fetch_health();

		RadioUdaan_Admin_Layout::render_open( 'dashboard', __( 'Dashboard', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'Overview', 'radioudaan-app-api' ) . '</strong> — ' .
			esc_html__( 'Events, registrations, and API health at a glance. Use Quick actions on the right for common tasks.', 'radioudaan-app-api' )
		);

		self::render_stats_row( $stats );
		self::render_production_warnings();
		?>
		<div class="ru-admin__grid">
			<div>
				<div class="ru-admin__panel">
					<div class="ru-admin__panel-head">
						<h2><?php esc_html_e( 'Events on the app', 'radioudaan-app-api' ); ?></h2>
						<a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENTS_SLUG ) ); ?>" class="button button-small"><?php esc_html_e( 'View all', 'radioudaan-app-api' ); ?></a>
					</div>
					<div class="ru-admin__panel-body">
						<?php self::render_event_cards( $events, false ); ?>
					</div>
				</div>

				<div class="ru-admin__panel" style="margin-top:20px;">
					<div class="ru-admin__panel-head">
						<h2><?php esc_html_e( 'Latest event entries', 'radioudaan-app-api' ); ?></h2>
						<a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENT_ENTRIES_SLUG ) ); ?>" class="button button-small"><?php esc_html_e( 'View all', 'radioudaan-app-api' ); ?></a>
					</div>
					<div class="ru-admin__panel-body" style="padding:0;">
						<?php self::render_registrations_table( RadioUdaan_Admin_Data::get_recent_registrations( 8, 'all' ) ); ?>
					</div>
				</div>
			</div>

			<div>
				<?php self::render_quick_actions_panel(); ?>
				<?php self::render_status_panel( $stats ); ?>
				<?php self::render_help_panel(); ?>
			</div>
		</div>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * Events management.
	 */
	public static function render_events() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$events = RadioUdaan_Admin_Data::get_managed_events();

		RadioUdaan_Admin_Layout::render_open( 'events', __( 'Events', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'Tip', 'radioudaan-app-api' ) . '</strong> — ' .
			esc_html__( 'Use Open, Closed, or Hidden on each event. Open = accepting registrations in the app. Drag events to set the order shown in the mobile app.', 'radioudaan-app-api' )
		);
		?>
		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'All app events', 'radioudaan-app-api' ); ?></h2>
				<div class="ru-admin__panel-head-actions">
					<span id="ru-events-order-status" class="ru-events-order-status description" aria-live="polite"></span>
					<a href="<?php echo esc_url( RadioUdaan_Admin_Event_Editor::edit_url( 0 ) ); ?>" class="button button-primary ru-btn-large"><?php esc_html_e( 'Add new event', 'radioudaan-app-api' ); ?></a>
				</div>
			</div>
			<div class="ru-admin__panel-body">
				<?php self::render_event_cards( $events, true ); ?>
			</div>
		</div>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * Event form submissions (not app login).
	 */
	public static function render_event_entries() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$filter = isset( $_GET['source'] ) ? sanitize_key( wp_unslash( $_GET['source'] ) ) : 'all';
		if ( ! in_array( $filter, array( 'all', 'app', 'web' ), true ) ) {
			$filter = 'all';
		}
		$rows           = RadioUdaan_Admin_Data::get_recent_registrations( 50, $filter );
		$base_url = admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENT_ENTRIES_SLUG );

		RadioUdaan_Admin_Layout::render_open( 'event-entries', __( 'Event entries', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'Event entries', 'radioudaan-app-api' ) . '</strong> — ' .
			esc_html__( 'Form submissions after someone registers for an event (not the same as app login / OTP).', 'radioudaan-app-api' )
		);
		?>
		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Event entries', 'radioudaan-app-api' ); ?></h2>
				<nav class="ru-filter-tabs" aria-label="<?php esc_attr_e( 'Filter by source', 'radioudaan-app-api' ); ?>">
					<a href="<?php echo esc_url( $base_url ); ?>" class="ru-filter-tabs__link <?php echo 'all' === $filter ? 'is-active' : ''; ?>"><?php esc_html_e( 'All', 'radioudaan-app-api' ); ?></a>
					<a href="<?php echo esc_url( add_query_arg( 'source', 'app', $base_url ) ); ?>" class="ru-filter-tabs__link <?php echo 'app' === $filter ? 'is-active' : ''; ?>"><?php esc_html_e( 'Mobile app', 'radioudaan-app-api' ); ?></a>
					<a href="<?php echo esc_url( add_query_arg( 'source', 'web', $base_url ) ); ?>" class="ru-filter-tabs__link <?php echo 'web' === $filter ? 'is-active' : ''; ?>"><?php esc_html_e( 'Website', 'radioudaan-app-api' ); ?></a>
					<a href="<?php echo esc_url( RadioUdaan_Admin_Export::export_url( $filter ) ); ?>" class="ru-filter-tabs__link"><?php esc_html_e( 'Export CSV', 'radioudaan-app-api' ); ?></a>
				</nav>
			</div>
			<div class="ru-admin__panel-body" style="padding:0;">
				<?php self::render_registrations_table( $rows ); ?>
			</div>
		</div>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * Settings.
	 */
	public static function render_settings() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$max_mb       = (int) get_option( RadioUdaan_App_Settings::OPTION_MAX_UPLOAD_MB, 25 );
		$dev_otp_stored = (bool) get_option( RadioUdaan_App_Settings::OPTION_DEV_OTP, false );
		$dev_auth_stored = (bool) get_option( RadioUdaan_App_Settings::OPTION_DEV_AUTH, false );
		$dev_otp_effective = RadioUdaan_App_Settings::is_dev_otp_enabled();
		$dev_auth_effective = RadioUdaan_App_Settings::is_dev_auth_enabled();
		$dev_bypass_locked = RadioUdaan_App_Settings::dev_bypass_is_locked();
		$dev_otp      = $dev_otp_stored;
		$dev_auth     = $dev_auth_stored;
		$msg91_key    = (string) get_option( 'radioudaan_msg91_auth_key', '' );
		$msg91_snd    = (string) get_option( 'radioudaan_msg91_sender_id', 'RADIO' );
		$msg91_tpl    = (string) get_option( 'radioudaan_msg91_template_id', '' );
		$otp_limit    = RadioUdaan_App_Settings::get_otp_limit_per_hour();
		$otp_verify   = RadioUdaan_App_Settings::get_otp_verify_max_attempts();
		$otp_resend   = RadioUdaan_App_Settings::get_otp_resend_delay_sec();
		$reg_phone    = RadioUdaan_App_Settings::get_registration_limit_per_phone_hour();
		$reg_ip       = RadioUdaan_App_Settings::get_registration_limit_per_ip_hour();
		$allowed_mime = RadioUdaan_App_Settings::get_allowed_mime_csv();
		$max_files    = RadioUdaan_App_Settings::get_max_files_per_field();
		$prevent_dup  = RadioUdaan_App_Settings::prevent_duplicate_registration();
		$retention    = RadioUdaan_App_Settings::get_upload_retention_days();
		$stream_url   = RadioUdaan_App_Settings::get_stream_url();
		$api_base     = RadioUdaan_App_Settings::get_api_base_url();
		$api_override = trim( (string) get_option( RadioUdaan_App_Settings::OPTION_API_BASE_URL, '' ) );
		$private_up   = RadioUdaan_App_Settings::use_private_uploads();
		$privacy_url  = RadioUdaan_App_Settings::get_privacy_policy_url();
		$terms_url    = RadioUdaan_App_Settings::get_terms_url();
		$about_url    = RadioUdaan_App_Settings::get_about_url();
		$contact_url  = RadioUdaan_App_Settings::get_contact_url();
		$privacy_ov   = trim( (string) get_option( RadioUdaan_App_Settings::OPTION_PRIVACY_POLICY_URL, '' ) );
		$terms_ov     = trim( (string) get_option( RadioUdaan_App_Settings::OPTION_TERMS_URL, '' ) );
		$about_ov     = trim( (string) get_option( RadioUdaan_App_Settings::OPTION_ABOUT_URL, '' ) );
		$contact_ov   = trim( (string) get_option( RadioUdaan_App_Settings::OPTION_CONTACT_URL, '' ) );
		$legal_privacy_page_id = (int) get_option( RadioUdaan_App_Legal_Pages::OPTION_PRIVACY_PAGE_ID, 0 );
		$legal_terms_page_id   = (int) get_option( RadioUdaan_App_Legal_Pages::OPTION_TERMS_PAGE_ID, 0 );
		$legal_about_page_id   = (int) get_option( RadioUdaan_App_Legal_Pages::OPTION_ABOUT_PAGE_ID, 0 );
		$page_choices          = RadioUdaan_Event_Meta_Ui::get_page_choices();
		$support_helpline = RadioUdaan_App_Settings::get_support_helpline_phone();
		$support_email    = RadioUdaan_App_Settings::get_support_email();
		$donate_badge              = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_BADGE, '' );
		$donate_headline           = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_HEADLINE, '' );
		$donate_intro              = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_INTRO, '' );
		$donate_accessibility_note = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_ACCESSIBILITY_NOTE, '' );
		$donate_upi_id             = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_UPI_ID, '' );
		$donate_qr_attachment_id   = (int) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_QR_ATTACHMENT_ID, 0 );
		$donate_qr_url             = $donate_qr_attachment_id > 0
			? wp_get_attachment_image_url( $donate_qr_attachment_id, 'medium' )
			: '';
		$donate_account_name       = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_ACCOUNT_NAME, '' );
		$donate_account_number     = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_ACCOUNT_NUMBER, '' );
		$donate_bank_name          = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_BANK_NAME, '' );
		$donate_branch_name        = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_BRANCH_NAME, '' );
		$donate_ifsc               = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_IFSC, '' );
		$donate_micr               = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_MICR, '' );
		$donate_bank_address       = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_BANK_ADDRESS, '' );
		$social_facebook_url       = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_SOCIAL_FACEBOOK, '' );
		$social_instagram_url      = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_SOCIAL_INSTAGRAM, '' );
		$social_x_url              = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_SOCIAL_X, '' );
		$social_youtube_url        = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_SOCIAL_YOUTUBE, '' );
		$social_website_url        = (string) get_option( RadioUdaan_App_Info_Hub::OPTION_SOCIAL_WEBSITE, '' );
		$fcm_project_id   = RadioUdaan_App_Settings::get_fcm_project_id();
		$fcm_account_set  = RadioUdaan_App_Settings::is_fcm_service_account_set();
		$notif_defaults   = RadioUdaan_App_Settings::get_notification_preferences_defaults();

		$brand_name   = trim( (string) get_option( RadioUdaan_App_Branding::OPTION_APP_NAME, '' ) );
		$brand_tag    = trim( (string) get_option( RadioUdaan_App_Branding::OPTION_TAGLINE, '' ) );
		$brand_logo   = (int) get_option( RadioUdaan_App_Branding::OPTION_LOGO_ATTACHMENT_ID, 0 );
		$brand_logo_u = $brand_logo ? wp_get_attachment_image_url( $brand_logo, 'medium' ) : RadioUdaan_App_Branding::get_logo_url();
		$brand_colors  = RadioUdaan_App_Branding::get_colors();
		$copy_defaults = RadioUdaan_App_Branding::default_copy();

		$otp_const   = defined( 'RADIOUDAAN_APP_API_DEV_OTP' );
		$auth_const  = defined( 'RADIOUDAAN_APP_API_DEV_AUTH' );
		$msg91_const = defined( 'RADIOUDAAN_MSG91_AUTH_KEY' );

		$password_min              = RadioUdaan_App_Settings::get_password_min_length();
		$require_unique_email      = RadioUdaan_App_Settings::require_unique_email();
		$require_email_verification = RadioUdaan_App_Settings::require_email_verification();
		$email_verify_subject      = trim( (string) get_option( RadioUdaan_App_Settings::OPTION_EMAIL_VERIFY_SUBJECT, '' ) );
		$email_verify_body         = (string) get_option( RadioUdaan_App_Settings::OPTION_EMAIL_VERIFY_BODY, '' );
		$email_reset_subject       = trim( (string) get_option( RadioUdaan_App_Settings::OPTION_EMAIL_RESET_SUBJECT, '' ) );
		$email_reset_body          = (string) get_option( RadioUdaan_App_Settings::OPTION_EMAIL_RESET_BODY, '' );

		$live_defaults   = RadioUdaan_App_Live_Radio::defaults();
		$live_hero_id    = RadioUdaan_App_Live_Radio::get_hero_attachment_id();
		$live_hero_url   = RadioUdaan_App_Live_Radio::get_hero_image_url();

		$youtube_api_key            = RadioUdaan_App_Youtube_Library::get_api_key();
		$youtube_channel            = RadioUdaan_App_Youtube_Library::get_channel_input();
		$youtube_featured_playlists      = RadioUdaan_App_Youtube_Library::get_featured_playlist_ids();
		$youtube_featured_playlist_items = RadioUdaan_App_Youtube_Library::get_featured_playlist_admin_items();

		RadioUdaan_Admin_Layout::render_open( 'settings', __( 'Settings', 'radioudaan-app-api' ) );
		?>
		<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" class="ru-settings-form">
			<?php wp_nonce_field( 'radioudaan_save_app_settings' ); ?>
			<input type="hidden" name="action" value="radioudaan_save_app_settings" />
			<?php
			RadioUdaan_Admin_Settings_Page::render(
				array(
					'max_mb'        => $max_mb,
					'dev_otp'       => $dev_otp,
					'dev_auth'      => $dev_auth,
					'dev_otp_effective'  => $dev_otp_effective,
					'dev_auth_effective' => $dev_auth_effective,
					'dev_bypass_locked'  => $dev_bypass_locked,
					'msg91_key'     => $msg91_key,
					'msg91_snd'     => $msg91_snd,
					'msg91_tpl'     => $msg91_tpl,
					'otp_limit'     => $otp_limit,
					'otp_verify'    => $otp_verify,
					'otp_resend'    => $otp_resend,
					'reg_phone'     => $reg_phone,
					'reg_ip'        => $reg_ip,
					'allowed_mime'  => $allowed_mime,
					'max_files'     => $max_files,
					'prevent_dup'   => $prevent_dup,
					'retention'     => $retention,
					'stream_url'    => $stream_url,
					'api_base'      => $api_base,
					'api_override'  => $api_override,
					'private_up'    => $private_up,
					'privacy_ov'    => $privacy_ov,
					'terms_ov'      => $terms_ov,
					'about_ov'      => $about_ov,
					'contact_ov'    => $contact_ov,
					'legal_privacy_page_id' => $legal_privacy_page_id,
					'legal_terms_page_id'   => $legal_terms_page_id,
					'legal_about_page_id'   => $legal_about_page_id,
					'page_choices'          => $page_choices,
					'privacy_url'   => $privacy_url,
					'terms_url'     => $terms_url,
					'about_url'     => $about_url,
					'contact_url'   => $contact_url,
					'support_helpline' => $support_helpline,
					'support_email'    => $support_email,
					'donate_badge'              => $donate_badge,
					'donate_headline'           => $donate_headline,
					'donate_intro'              => $donate_intro,
					'donate_accessibility_note' => $donate_accessibility_note,
					'donate_upi_id'             => $donate_upi_id,
					'donate_qr_attachment_id'   => $donate_qr_attachment_id,
					'donate_qr_url'             => $donate_qr_url,
					'donate_account_name'       => $donate_account_name,
					'donate_account_number'     => $donate_account_number,
					'donate_bank_name'          => $donate_bank_name,
					'donate_branch_name'        => $donate_branch_name,
					'donate_ifsc'               => $donate_ifsc,
					'donate_micr'               => $donate_micr,
					'donate_bank_address'       => $donate_bank_address,
					'social_facebook_url'       => $social_facebook_url,
					'social_instagram_url'      => $social_instagram_url,
					'social_x_url'              => $social_x_url,
					'social_youtube_url'        => $social_youtube_url,
					'social_website_url'        => $social_website_url,
					'fcm_project_id'    => $fcm_project_id,
					'fcm_account_set'   => $fcm_account_set,
					'notif_events'     => ! empty( $notif_defaults['events_enabled'] ),
					'notif_library'    => ! empty( $notif_defaults['library_enabled'] ),
					'notif_promotions' => ! empty( $notif_defaults['promotions_enabled'] ),
					'brand_name'    => $brand_name,
					'brand_tag'     => $brand_tag,
					'brand_logo'    => $brand_logo,
					'brand_logo_u'  => $brand_logo_u,
					'brand_colors'  => $brand_colors,
					'copy_defaults' => $copy_defaults,
					'otp_const'                  => $otp_const,
					'auth_const'                 => $auth_const,
					'msg91_const'                => $msg91_const,
					'password_min'               => $password_min,
					'require_unique_email'       => $require_unique_email,
					'require_email_verification' => $require_email_verification,
					'email_verify_subject'       => $email_verify_subject,
					'email_verify_body'          => $email_verify_body,
					'email_reset_subject'        => $email_reset_subject,
					'email_reset_body'           => $email_reset_body,
					'live_defaults'              => $live_defaults,
					'live_show_title'            => RadioUdaan_App_Live_Radio::get_show_title(),
					'live_show_subtitle'         => RadioUdaan_App_Live_Radio::get_show_subtitle(),
					'live_hero_id'               => $live_hero_id,
					'live_hero_url'              => $live_hero_url,
					'live_whatsapp_url'          => RadioUdaan_App_Live_Radio::get_whatsapp_url(),
					'live_whatsapp_label'        => RadioUdaan_App_Live_Radio::get_whatsapp_label(),
					'live_share_label'           => RadioUdaan_App_Live_Radio::get_share_label(),
					'live_share_text'            => RadioUdaan_App_Live_Radio::get_share_text(),
					'live_show_whatsapp'         => RadioUdaan_App_Live_Radio::show_whatsapp_button(),
					'live_show_share'            => RadioUdaan_App_Live_Radio::show_share_button(),
					'live_show_volume'           => RadioUdaan_App_Live_Radio::show_volume_slider(),
					'youtube_api_key'            => $youtube_api_key,
					'youtube_channel'            => $youtube_channel,
					'youtube_featured_playlists'      => $youtube_featured_playlists,
					'youtube_featured_playlist_items' => $youtube_featured_playlist_items,
				)
			);
			?>
		</form>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}


	/**
	 * API reference.
	 */
	public static function render_api() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$api_base = RadioUdaan_App_Settings::get_api_base_url();
		$health   = RadioUdaan_Admin_Data::fetch_health();

		$endpoints = array(
			array( 'GET', '/health', __( 'API status', 'radioudaan-app-api' ), false ),
			array( 'GET', '/config', __( 'App config (stream, legal URLs, upload rules)', 'radioudaan-app-api' ), false ),
			array( 'POST', '/auth/otp/request', __( 'Send login OTP', 'radioudaan-app-api' ), false ),
			array( 'POST', '/auth/otp/verify', __( 'Verify OTP → bearer token', 'radioudaan-app-api' ), false ),
			array( 'GET', '/auth/me', __( 'Current session', 'radioudaan-app-api' ), true ),
			array( 'POST', '/auth/logout', __( 'Revoke token', 'radioudaan-app-api' ), true ),
			array( 'POST', '/auth/account/delete', __( 'Delete app account (Apple 5.1.1(v))', 'radioudaan-app-api' ), true ),
			array( 'GET', '/events', __( 'List open events', 'radioudaan-app-api' ), false ),
			array( 'GET', '/events/{id}', __( 'Event details', 'radioudaan-app-api' ), false ),
			array( 'GET', '/events/{id}/form', __( 'Dynamic form schema', 'radioudaan-app-api' ), false ),
			array( 'POST', '/uploads', __( 'Stage file (multipart)', 'radioudaan-app-api' ), true ),
			array( 'POST', '/events/{id}/registrations', __( 'Submit registration', 'radioudaan-app-api' ), true ),
			array( 'GET', '/library/youtube/recent', __( 'Recent @radioudaan uploads', 'radioudaan-app-api' ), false ),
			array( 'GET', '/library/youtube/playlists', __( 'All channel playlists', 'radioudaan-app-api' ), false ),
			array( 'GET', '/library/youtube/playlists/featured', __( 'Admin-picked featured playlists', 'radioudaan-app-api' ), false ),
			array( 'GET', '/library/youtube/playlists/{id}/videos', __( 'Videos in a playlist', 'radioudaan-app-api' ), false ),
			array( 'GET', '/library/youtube/search?q=', __( 'Channel-scoped video search', 'radioudaan-app-api' ), false ),
		);

		RadioUdaan_Admin_Layout::render_open( 'api', __( 'API', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'Developer reference', 'radioudaan-app-api' ) . '</strong> — ' .
			esc_html__( 'REST base URL and endpoints used by the Flutter app. Copy the URL for Postman or debugging.', 'radioudaan-app-api' )
		);
		?>
		<div class="ru-admin__grid">
			<div>
				<?php self::render_api_panel( $api_base, $health ); ?>
				<div class="ru-admin__panel" style="margin-top:20px;">
					<div class="ru-admin__panel-head">
						<h2><?php esc_html_e( 'Endpoints', 'radioudaan-app-api' ); ?></h2>
					</div>
					<div class="ru-admin__panel-body">
						<?php foreach ( $endpoints as $ep ) : ?>
							<div class="ru-admin__endpoint">
								<span class="ru-admin__method ru-admin__method--<?php echo esc_attr( strtolower( $ep[0] ) ); ?>"><?php echo esc_html( $ep[0] ); ?></span>
								<code><?php echo esc_html( $ep[1] ); ?></code>
								— <?php echo esc_html( $ep[2] ); ?>
								<?php if ( $ep[3] ) : ?>
									<span class="ru-admin__badge ru-admin__badge--draft" style="margin-left:6px;"><?php esc_html_e( 'Auth required', 'radioudaan-app-api' ); ?></span>
								<?php endif; ?>
							</div>
						<?php endforeach; ?>
						<p class="description" style="margin-top:16px;">
							<?php esc_html_e( 'Protected routes need header: Authorization: Bearer {token}', 'radioudaan-app-api' ); ?>
						</p>
					</div>
				</div>
			</div>
			<div>
				<?php self::render_help_panel(); ?>
			</div>
		</div>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * Production safety notices.
	 */
	private static function render_production_warnings() {
		$warnings = RadioUdaan_App_Settings::get_production_warnings();
		if ( empty( $warnings ) ) {
			return;
		}
		$items = '';
		foreach ( $warnings as $warning ) {
			$items .= '<li>' . esc_html( $warning ) . '</li>';
		}
		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'Before production', 'radioudaan-app-api' ) . '</strong><ul class="ru-help-list" style="margin:8px 0 12px;">' . $items . '</ul>' .
			'<a href="' . esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::SETTINGS_SLUG ) ) . '" class="button button-primary">' . esc_html__( 'Open settings', 'radioudaan-app-api' ) . '</a>',
			'warning'
		);
	}

	/**
	 * @param array<string,mixed> $stats Stats.
	 */
	private static function render_stats_row( $stats ) {
		?>
		<div class="ru-admin__stats">
			<div class="ru-admin__stat">
				<div class="ru-admin__stat-label"><?php esc_html_e( 'Events', 'radioudaan-app-api' ); ?></div>
				<div class="ru-admin__stat-value"><?php echo (int) $stats['events_open']; ?> <span style="font-size:16px;color:var(--ru-muted);">/ <?php echo (int) $stats['events_total']; ?></span></div>
				<div class="ru-admin__stat-hint"><?php esc_html_e( 'Open / total', 'radioudaan-app-api' ); ?></div>
			</div>
			<div class="ru-admin__stat">
				<div class="ru-admin__stat-label"><?php esc_html_e( 'Registrations', 'radioudaan-app-api' ); ?></div>
				<div class="ru-admin__stat-value"><?php echo (int) $stats['app_users']; ?></div>
				<div class="ru-admin__stat-hint">
					<a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::APP_USERS_SLUG ) ); ?>"><?php esc_html_e( 'Logged in with OTP', 'radioudaan-app-api' ); ?></a>
				</div>
			</div>
			<div class="ru-admin__stat">
				<div class="ru-admin__stat-label"><?php esc_html_e( 'Event entries', 'radioudaan-app-api' ); ?></div>
				<div class="ru-admin__stat-value" style="font-size:18px;">
					<?php echo (int) $stats['app_entries']; ?> <?php esc_html_e( 'app', 'radioudaan-app-api' ); ?>
					· <?php echo (int) $stats['web_entries']; ?> <?php esc_html_e( 'web', 'radioudaan-app-api' ); ?>
				</div>
				<div class="ru-admin__stat-hint">
					<a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENT_ENTRIES_SLUG ) ); ?>"><?php esc_html_e( 'Form submissions', 'radioudaan-app-api' ); ?></a>
				</div>
			</div>
			<div class="ru-admin__stat">
				<div class="ru-admin__stat-label"><?php esc_html_e( 'API', 'radioudaan-app-api' ); ?></div>
				<div class="ru-admin__stat-value" style="font-size:18px;">
					<?php echo $stats['api_ok'] ? esc_html__( 'Online', 'radioudaan-app-api' ) : esc_html__( 'Offline', 'radioudaan-app-api' ); ?>
				</div>
				<div class="ru-admin__stat-hint">v<?php echo esc_html( $stats['api_version'] ? $stats['api_version'] : '—' ); ?></div>
			</div>
			<div class="ru-admin__stat">
				<div class="ru-admin__stat-label"><?php esc_html_e( 'Login SMS', 'radioudaan-app-api' ); ?></div>
				<div class="ru-admin__stat-value" style="font-size:16px;">
					<?php
					if ( $stats['dev_otp'] ) {
						esc_html_e( 'Dev OTP', 'radioudaan-app-api' );
					} elseif ( $stats['msg91'] ) {
						esc_html_e( 'MSG91', 'radioudaan-app-api' );
					} else {
						esc_html_e( 'Not set', 'radioudaan-app-api' );
					}
					?>
				</div>
				<div class="ru-admin__stat-hint">
					<a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::SETTINGS_SLUG ) ); ?>"><?php esc_html_e( 'Settings', 'radioudaan-app-api' ); ?></a>
				</div>
			</div>
		</div>
		<?php
	}

	/**
	 * @param array<int,array<string,mixed>> $events Events.
	 * @param bool                           $full   Show status toggles.
	 */
	private static function render_event_cards( $events, $full ) {
		if ( empty( $events ) ) {
			?>
			<div class="ru-admin__empty">
				<span class="dashicons dashicons-calendar-alt"></span>
				<p><?php esc_html_e( 'No events yet.', 'radioudaan-app-api' ); ?></p>
				<a href="<?php echo esc_url( admin_url( 'post-new.php?post_type=' . RadioUdaan_Cpt_Ru_Event::POST_TYPE ) ); ?>" class="button button-primary"><?php esc_html_e( 'Create your first event', 'radioudaan-app-api' ); ?></a>
			</div>
			<?php
			return;
		}

		$list_id = $full ? 'ru-events-sortable' : '';
		echo '<div class="ru-admin__events' . ( $full ? ' ru-admin__events--sortable' : '' ) . '"' . ( $list_id ? ' id="' . esc_attr( $list_id ) . '"' : '' ) . '>';
		foreach ( $events as $event ) {
			self::render_event_card( $event, $full );
		}
		echo '</div>';
	}

	/**
	 * @param array<string,mixed> $event Event row.
	 * @param bool                $full  Full controls.
	 */
	private static function render_event_card( $event, $full ) {
		$status = isset( $event['status'] ) ? $event['status'] : 'open';
		$form_id = (int) ( $event['form_id'] ?? 0 );
		$event_id = (int) ( $event['event_id'] ?? 0 );
		?>
		<article class="ru-admin__event-card<?php echo $full ? ' ru-admin__event-card--sortable' : ''; ?>" data-event-id="<?php echo (int) $event_id; ?>">
			<?php if ( $full ) : ?>
				<span class="ru-admin__event-drag dashicons dashicons-menu"
					role="button" tabindex="0"
					aria-label="<?php esc_attr_e( 'Drag to reorder', 'radioudaan-app-api' ); ?>"
					title="<?php esc_attr_e( 'Drag to reorder', 'radioudaan-app-api' ); ?>"></span>
			<?php endif; ?>
			<div class="ru-admin__event-thumb">
				<?php if ( ! empty( $event['thumb'] ) ) : ?>
					<img src="<?php echo esc_url( $event['thumb'] ); ?>" alt="" width="72" height="72" style="width:72px;height:72px;border-radius:8px;object-fit:cover;" />
				<?php else : ?>
					<span class="dashicons dashicons-calendar-alt"></span>
				<?php endif; ?>
			</div>
			<div>
				<h3 class="ru-admin__event-title"><?php echo esc_html( $event['title'] ); ?></h3>
				<div class="ru-admin__event-meta">
					<span class="ru-admin__badge ru-admin__badge--<?php echo esc_attr( $status ); ?>"><?php echo esc_html( $status ); ?></span>
					&nbsp;·&nbsp; ID <code><?php echo (int) $event_id; ?></code>
					<?php if ( ! empty( $event['event_code'] ) ) : ?>
						· <code><?php echo esc_html( $event['event_code'] ); ?></code>
					<?php endif; ?>
					<?php if ( $form_id ) : ?>
						· <?php echo (int) ( $event['entries_app'] ?? 0 ); ?> <?php esc_html_e( 'mobile', 'radioudaan-app-api' ); ?>
						· <?php echo (int) ( $event['entries_web'] ?? 0 ); ?> <?php esc_html_e( 'web', 'radioudaan-app-api' ); ?>
						· <?php echo (int) ( $event['entries_all'] ?? 0 ); ?> <?php esc_html_e( 'total', 'radioudaan-app-api' ); ?>
					<?php endif; ?>
				</div>
			</div>
			<div class="ru-admin__event-actions">
				<?php if ( $full ) : ?>
					<?php self::render_status_toggle( $event_id, $status ); ?>
				<?php endif; ?>
				<?php if ( ! empty( $event['edit_url'] ) ) : ?>
					<a class="button ru-btn-large" href="<?php echo esc_url( $event['edit_url'] ); ?>"><?php esc_html_e( 'Edit event', 'radioudaan-app-api' ); ?></a>
				<?php endif; ?>
				<?php if ( $form_id ) : ?>
					<a class="button ru-btn-large" href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENT_ENTRIES_SLUG . '&event_form=' . $form_id ) ); ?>"><?php esc_html_e( 'View entries', 'radioudaan-app-api' ); ?></a>
				<?php endif; ?>
			</div>
		</article>
		<?php
	}

	/**
	 * Quick open/closed/draft toggle.
	 *
	 * @param int    $event_id Post ID.
	 * @param string $current  Current status.
	 */
	private static function render_status_toggle( $event_id, $current ) {
		$statuses = array(
			'open'   => __( 'Open', 'radioudaan-app-api' ),
			'closed' => __( 'Closed', 'radioudaan-app-api' ),
			'draft'  => __( 'Hidden', 'radioudaan-app-api' ),
		);
		?>
		<div class="ru-admin__btn-group" role="group" aria-label="<?php esc_attr_e( 'Registration status', 'radioudaan-app-api' ); ?>">
			<?php foreach ( $statuses as $status => $label ) : ?>
				<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
					<?php wp_nonce_field( 'radioudaan_event_status_' . $event_id ); ?>
					<input type="hidden" name="action" value="radioudaan_event_status" />
					<input type="hidden" name="event_id" value="<?php echo (int) $event_id; ?>" />
					<input type="hidden" name="status" value="<?php echo esc_attr( $status ); ?>" />
					<button type="submit" class="button ru-btn-large <?php echo $current === $status ? 'is-active' : ''; ?>" <?php disabled( $current, $status ); ?>>
						<?php echo esc_html( $label ); ?>
					</button>
				</form>
			<?php endforeach; ?>
		</div>
		<?php
	}

	/**
	 * @param string $source app|web|''.
	 */
	private static function render_source_badge( $source ) {
		$class = 'ru-admin__badge--draft';
		if ( RadioUdaan_Entry_Source::SOURCE_APP === $source ) {
			$class = 'ru-admin__badge--open';
		} elseif ( RadioUdaan_Entry_Source::SOURCE_WEB === $source ) {
			$class = 'ru-admin__badge--closed';
		}
		echo '<span class="ru-admin__badge ' . esc_attr( $class ) . '">' . esc_html( RadioUdaan_Entry_Source::label_for( $source ) ) . '</span>';
	}

	/**
	 * @param array<int,array<string,mixed>> $rows Rows.
	 */
	private static function render_registrations_table( $rows ) {
		if ( empty( $rows ) ) {
			echo '<div class="ru-admin__empty"><p>' . esc_html__( 'No event entries yet.', 'radioudaan-app-api' ) . '</p></div>';
			return;
		}
		?>
		<table class="ru-admin__table">
			<thead>
				<tr>
					<th><?php esc_html_e( 'Date', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( 'Source', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( 'Event', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( 'Phone', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( 'Action', 'radioudaan-app-api' ); ?></th>
				</tr>
			</thead>
			<tbody>
			<?php foreach ( $rows as $row ) : ?>
				<tr>
					<td><?php echo esc_html( $row['date'] ); ?></td>
					<td><?php self::render_source_badge( isset( $row['source'] ) ? $row['source'] : '' ); ?></td>
					<td>
						<strong><?php echo esc_html( $row['event_title'] ); ?></strong>
						<?php if ( ! empty( $row['event_code'] ) ) : ?>
							<br /><code><?php echo esc_html( $row['event_code'] ); ?></code>
						<?php endif; ?>
					</td>
					<td><?php echo esc_html( $row['phone'] ); ?></td>
					<td>
						<a class="button ru-btn-large" href="<?php echo esc_url( $row['view_url'] ); ?>"><?php esc_html_e( 'View details', 'radioudaan-app-api' ); ?></a>
					</td>
				</tr>
			<?php endforeach; ?>
			</tbody>
		</table>
		<?php
	}

	/**
	 * @param string               $api_base Base URL.
	 * @param array<string,mixed>  $health   Health.
	 */
	private static function render_api_panel( $api_base, $health ) {
		?>
		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'REST API', 'radioudaan-app-api' ); ?></h2>
				<?php if ( $health['ok'] ) : ?>
					<span class="ru-admin__badge ru-admin__badge--ok"><?php esc_html_e( 'Online', 'radioudaan-app-api' ); ?></span>
				<?php else : ?>
					<span class="ru-admin__badge ru-admin__badge--off"><?php esc_html_e( 'Offline', 'radioudaan-app-api' ); ?></span>
				<?php endif; ?>
			</div>
			<div class="ru-admin__panel-body">
				<div class="ru-admin__api-box">
					<code id="ru-api-base-url"><?php echo esc_html( $api_base ); ?></code>
					<button type="button" class="button button-small" data-ru-copy="ru-api-base-url" data-copied-label="<?php esc_attr_e( 'Copied!', 'radioudaan-app-api' ); ?>"><?php esc_html_e( 'Copy', 'radioudaan-app-api' ); ?></button>
				</div>
				<p style="margin-top:12px;">
					<a class="button button-small" href="<?php echo esc_url( $api_base . '/health' ); ?>" target="_blank" rel="noopener"><?php esc_html_e( 'Health', 'radioudaan-app-api' ); ?></a>
					<a class="button button-small" href="<?php echo esc_url( $api_base . '/events' ); ?>" target="_blank" rel="noopener"><?php esc_html_e( 'Events JSON', 'radioudaan-app-api' ); ?></a>
				</p>
			</div>
		</div>
		<?php
	}

	/**
	 * @param array<string,mixed> $stats Stats.
	 */
	private static function render_status_panel( $stats ) {
		?>
		<div class="ru-admin__panel" style="margin-top:20px;">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'System status', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
				<ul style="margin:0;padding:0;list-style:none;">
					<li style="padding:8px 0;border-bottom:1px solid var(--ru-border);">
						Forminator
						<?php echo $stats['forminator_ok'] ? '<span class="ru-admin__badge ru-admin__badge--ok" style="float:right;">OK</span>' : '<span class="ru-admin__badge ru-admin__badge--off" style="float:right;">Missing</span>'; ?>
					</li>
					<li style="padding:8px 0;border-bottom:1px solid var(--ru-border);">
						<?php esc_html_e( 'Dev OTP', 'radioudaan-app-api' ); ?>
						<?php echo $stats['dev_otp'] ? '<span class="ru-admin__badge ru-admin__badge--draft" style="float:right;">On</span>' : '<span class="ru-admin__badge ru-admin__badge--ok" style="float:right;">Off</span>'; ?>
					</li>
					<li style="padding:8px 0;">
						<?php esc_html_e( 'Skip auth (dev)', 'radioudaan-app-api' ); ?>
						<?php echo $stats['dev_auth'] ? '<span class="ru-admin__badge ru-admin__badge--closed" style="float:right;">On</span>' : '<span class="ru-admin__badge ru-admin__badge--ok" style="float:right;">Off</span>'; ?>
					</li>
				</ul>
			</div>
		</div>
		<?php
	}

	/**
	 * Sidebar help.
	 */
	private static function render_quick_actions_panel() {
		?>
		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Quick actions', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
				<p><a href="<?php echo esc_url( RadioUdaan_Admin_Event_Editor::edit_url( 0 ) ); ?>" class="button button-primary ru-btn-large"><?php esc_html_e( 'Add new event', 'radioudaan-app-api' ); ?></a></p>
				<p><a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::APP_USERS_SLUG ) ); ?>" class="button ru-btn-large"><?php esc_html_e( 'Registrations (app login)', 'radioudaan-app-api' ); ?></a></p>
				<p><a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENT_ENTRIES_SLUG ) ); ?>" class="button ru-btn-large"><?php esc_html_e( 'Event entries', 'radioudaan-app-api' ); ?></a></p>
				<p><a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::SETTINGS_SLUG ) ); ?>" class="button ru-btn-large"><?php esc_html_e( 'Login & SMS settings', 'radioudaan-app-api' ); ?></a></p>
			</div>
		</div>
		<?php
	}

	/**
	 * Sidebar help.
	 */
	private static function render_help_panel() {
		?>
		<div class="ru-admin__panel" style="margin-top:20px;">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Need help?', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
				<p class="ru-help-lead"><?php esc_html_e( 'Step-by-step guide in plain language.', 'radioudaan-app-api' ); ?></p>
				<p><a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::HELP_SLUG ) ); ?>" class="button button-primary ru-btn-large"><?php esc_html_e( 'Open help guide', 'radioudaan-app-api' ); ?></a></p>
			</div>
		</div>
		<?php
	}
}

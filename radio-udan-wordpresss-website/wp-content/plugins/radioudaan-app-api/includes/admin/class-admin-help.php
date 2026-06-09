<?php
/**
 * Plain-language help for non-technical staff.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Help page inside the app dashboard.
 */
class RadioUdaan_Admin_Help {

	/**
	 * Render help.
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		RadioUdaan_Admin_Layout::render_open( 'help', __( 'Help', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'Staff guide', 'radioudaan-app-api' ) . '</strong> — ' .
			esc_html__( 'Plain-language steps for daily work. You do not need other WordPress menus for the mobile app.', 'radioudaan-app-api' )
		);
		?>
		<div class="ru-admin__panel ru-help-panel">
			<div class="ru-admin__panel-body">
				<section class="ru-help-section">
				<h2 class="ru-help-heading"><?php esc_html_e( 'What this dashboard controls', 'radioudaan-app-api' ); ?></h2>

				<ol class="ru-help-steps">
					<li>
						<strong><?php esc_html_e( 'Events', 'radioudaan-app-api' ); ?></strong> —
						<?php esc_html_e( 'Turn registrations on or off, edit event name and description, choose the form. Use large buttons: Open, Closed, or Hidden.', 'radioudaan-app-api' ); ?>
					</li>
					<li>
						<strong><?php esc_html_e( 'Registrations', 'radioudaan-app-api' ); ?></strong> —
						<?php esc_html_e( 'App accounts (email or mobile + password, with SMS OTP when needed). This is not the same as event form entries.', 'radioudaan-app-api' ); ?>
					</li>
					<li>
						<strong><?php esc_html_e( 'Event entries', 'radioudaan-app-api' ); ?></strong> —
						<?php esc_html_e( 'People who filled an event form. Filter Mobile app or Website. Click View details.', 'radioudaan-app-api' ); ?>
					</li>
					<li>
						<strong><?php esc_html_e( 'Settings', 'radioudaan-app-api' ); ?></strong> —
						<?php esc_html_e( 'Login text messages (SMS), and maximum upload size for files in the app.', 'radioudaan-app-api' ); ?>
					</li>
				</ol>
				</section>

				<section class="ru-help-section">
				<h2 class="ru-help-heading"><?php esc_html_e( 'Two different things (important)', 'radioudaan-app-api' ); ?></h2>
				<div class="ru-help-cards">
					<div class="ru-help-card">
						<h3><?php esc_html_e( '1. App login (password + OTP)', 'radioudaan-app-api' ); ?></h3>
						<p><?php esc_html_e( 'The listener signs up or signs in with email or mobile and a password. SMS OTP verifies the phone at signup and for mobile password reset. Email password reset is sent only to a verified email address. This is not an event registration.', 'radioudaan-app-api' ); ?></p>
					</div>
					<div class="ru-help-card">
						<h3><?php esc_html_e( '2. Event registration (form)', 'radioudaan-app-api' ); ?></h3>
						<p><?php esc_html_e( 'After login, they fill the event form (name, documents, audio, etc.). Each submit appears under Event entries.', 'radioudaan-app-api' ); ?></p>
					</div>
				</div>
				</section>

				<section class="ru-help-section">
				<h2 class="ru-help-heading"><?php esc_html_e( 'In-app account deletion (App Store)', 'radioudaan-app-api' ); ?></h2>
				<p>
					<?php
					esc_html_e(
						'When a listener uses Delete account in the mobile app, the API soft-deletes their App user record (marks deleted, clears phone, email, and password so the number can be reused), and revokes the current session. Event entries and uploaded files tied to registrations are not deleted automatically.',
						'radioudaan-app-api'
					);
					?>
				</p>
				<p class="description">
					<?php
					printf(
						/* translators: %s: path to markdown doc inside plugin */
						esc_html__( 'Technical scope for reviewers: %s', 'radioudaan-app-api' ),
						'<code>docs/account-deletion.md</code>'
					);
					?>
				</p>
				</section>

				<section class="ru-help-section">
				<h2 class="ru-help-heading"><?php esc_html_e( 'Accessibility tips', 'radioudaan-app-api' ); ?></h2>
				<ul class="ru-help-list">
					<li><?php esc_html_e( 'Use Tab on the keyboard to move between buttons.', 'radioudaan-app-api' ); ?></li>
					<li><?php esc_html_e( 'Screen readers: each page has a clear title at the top.', 'radioudaan-app-api' ); ?></li>
					<li><?php esc_html_e( 'Buttons and text are enlarged on these pages for easier reading.', 'radioudaan-app-api' ); ?></li>
				</ul>
				</section>

				<div class="ru-form-sticky-footer">
					<p class="ru-form-sticky-footer__hint"><?php esc_html_e( 'Ready to manage events or entries?', 'radioudaan-app-api' ); ?></p>
					<a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::MENU_SLUG ) ); ?>" class="button button-primary ru-btn-large"><?php esc_html_e( 'Go to Dashboard', 'radioudaan-app-api' ); ?></a>
				</div>
			</div>
		</div>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}
}

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
	 * @return array<int,array{q:string,a:string,tags:string}>
	 */
	private static function faq_items() {
		return array(
			array(
				'q'    => __( 'What is an App user?', 'radioudaan-app-api' ),
				'a'    => __( 'Someone who signed up in the mobile app with email or mobile + password. SMS OTP verifies the phone at signup. App users are listed under App users — not under Event entries.', 'radioudaan-app-api' ),
				'tags' => 'app users login account registration otp password',
			),
			array(
				'q'    => __( 'How do I pause an app user?', 'radioudaan-app-api' ),
				'a'    => sprintf(
					/* translators: %s: admin page name */
					__( 'Open App users, select the account, choose Pause from bulk actions, and type PAUSE to confirm. Paused users cannot sign in until you Resume them. You can also pause from the user detail screen.', 'radioudaan-app-api' ),
					''
				),
				'tags' => 'pause suspend block app users bulk',
			),
			array(
				'q'    => __( 'How do I delete an app user?', 'radioudaan-app-api' ),
				'a'    => __( 'From App users, select the account, choose Delete permanently, and type DELETE to confirm. This revokes sessions and clears phone/email so the number can be reused. Event form entries and uploaded files are not deleted automatically.', 'radioudaan-app-api' ),
				'tags' => 'delete remove account app users bulk',
			),
			array(
				'q'    => __( 'What is the admin audit log?', 'radioudaan-app-api' ),
				'a'    => __( 'When staff pause, resume, delete, or send a notification to an app user, the action is recorded with date, WordPress admin name, and target user. View recent entries on the Send notification page under Recent admin sends, or on a user’s detail page under Activity.', 'radioudaan-app-api' ),
				'tags' => 'audit log history pause delete notify activity',
			),
			array(
				'q'    => __( 'What is an Event entry?', 'radioudaan-app-api' ),
				'a'    => __( 'A Forminator form submission after someone registers for an event (from the app or website). Filter by Mobile app or Website on the Event entries page.', 'radioudaan-app-api' ),
				'tags' => 'event entries form registration submission',
			),
			array(
				'q'    => __( 'How do I open or close registrations?', 'radioudaan-app-api' ),
				'a'    => __( 'On Events, use the large Open, Closed, or Hidden buttons on each event card. Open = accepting registrations in the app. Hidden events do not appear in the app list.', 'radioudaan-app-api' ),
				'tags' => 'events open closed hidden status',
			),
			array(
				'q'    => __( 'How do I send a push notification?', 'radioudaan-app-api' ),
				'a'    => __( 'Go to Send notification, compose a title and message, choose All users or one app user, then send. Users need a registered device and FCM must be configured under Settings → Notifications.', 'radioudaan-app-api' ),
				'tags' => 'notification push fcm send bell',
			),
			array(
				'q'    => __( 'Where do I change SMS / OTP settings?', 'radioudaan-app-api' ),
				'a'    => __( 'Settings → OTP & limits for rate limits. Settings → SMS (MSG91) for production SMS. Never enable Fixed OTP 123456 on production.', 'radioudaan-app-api' ),
				'tags' => 'sms msg91 otp settings login',
			),
			array(
				'q'    => __( 'What happens when a listener deletes their account in the app?', 'radioudaan-app-api' ),
				'a'    => __( 'The API soft-deletes the App user record, clears phone/email/password, and revokes the session. Event entries and files tied to registrations remain unless you remove them separately.', 'radioudaan-app-api' ),
				'tags' => 'delete account app store listener',
			),
			array(
				'q'    => __( 'How do I export event entries?', 'radioudaan-app-api' ),
				'a'    => __( 'On Event entries, use Export CSV in the filter bar. You can filter by source or event first.', 'radioudaan-app-api' ),
				'tags' => 'export csv event entries download',
			),
		);
	}

	/**
	 * Render help.
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$faq = self::faq_items();

		RadioUdaan_Admin_Layout::render_open( 'help', __( 'Help', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'Staff guide', 'radioudaan-app-api' ) . '</strong> — ' .
			esc_html__( 'Plain-language steps for daily work. You do not need other WordPress menus for the mobile app.', 'radioudaan-app-api' )
		);
		?>
		<div class="ru-admin__panel ru-help-panel">
			<div class="ru-admin__panel-body">
				<section class="ru-help-section">
					<h2 class="ru-help-heading"><?php esc_html_e( 'Frequently asked questions', 'radioudaan-app-api' ); ?></h2>
					<div class="ru-help-faq-toolbar">
						<label for="ru-help-faq-search" class="screen-reader-text"><?php esc_html_e( 'Search help topics', 'radioudaan-app-api' ); ?></label>
						<input
							type="search"
							id="ru-help-faq-search"
							class="ru-admin__search-input widefat"
							placeholder="<?php esc_attr_e( 'Search help… (e.g. pause, delete, audit)', 'radioudaan-app-api' ); ?>"
							autocomplete="off"
						/>
					</div>
					<p class="ru-help-faq-empty description" hidden><?php esc_html_e( 'No matching topics. Try another word like pause, delete, or notification.', 'radioudaan-app-api' ); ?></p>
					<div class="ru-help-faq-list">
						<?php foreach ( $faq as $item ) : ?>
							<?php
							$search_blob = strtolower( $item['q'] . ' ' . $item['a'] . ' ' . $item['tags'] );
							?>
							<article class="ru-help-faq-item" data-ru-search="<?php echo esc_attr( $search_blob ); ?>">
								<h3 class="ru-help-faq-item__q"><?php echo esc_html( $item['q'] ); ?></h3>
								<p class="ru-help-faq-item__a"><?php echo esc_html( $item['a'] ); ?></p>
							</article>
						<?php endforeach; ?>
					</div>
				</section>

				<section class="ru-help-section">
				<h2 class="ru-help-heading"><?php esc_html_e( 'What this dashboard controls', 'radioudaan-app-api' ); ?></h2>

				<ol class="ru-help-steps">
					<li>
						<strong><?php esc_html_e( 'Events', 'radioudaan-app-api' ); ?></strong> —
						<?php esc_html_e( 'Turn registrations on or off, edit event name and description, choose the form. Use large buttons: Open, Closed, or Hidden.', 'radioudaan-app-api' ); ?>
					</li>
					<li>
						<strong><?php esc_html_e( 'App users', 'radioudaan-app-api' ); ?></strong> —
						<?php esc_html_e( 'App accounts (email or mobile + password). Pause, resume, or delete from the list. Every action is written to the audit log.', 'radioudaan-app-api' ); ?>
					</li>
					<li>
						<strong><?php esc_html_e( 'Event entries', 'radioudaan-app-api' ); ?></strong> —
						<?php esc_html_e( 'People who filled an event form. Filter Mobile app or Website. Click View details.', 'radioudaan-app-api' ); ?>
					</li>
					<li>
						<strong><?php esc_html_e( 'Settings', 'radioudaan-app-api' ); ?></strong> —
						<?php esc_html_e( 'Login text messages (SMS), branding, and maximum upload size for files in the app.', 'radioudaan-app-api' ); ?>
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
				<h2 class="ru-help-heading"><?php esc_html_e( 'Developer API', 'radioudaan-app-api' ); ?></h2>
				<p>
					<?php esc_html_e( 'The mobile app talks to WordPress over REST. Base URL:', 'radioudaan-app-api' ); ?>
					<code><?php echo esc_html( RadioUdaan_App_Settings::get_api_base_url() ); ?></code>
				</p>
				<p>
					<a class="button" href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::API_SLUG ) ); ?>">
						<?php esc_html_e( 'Open full API reference', 'radioudaan-app-api' ); ?>
					</a>
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

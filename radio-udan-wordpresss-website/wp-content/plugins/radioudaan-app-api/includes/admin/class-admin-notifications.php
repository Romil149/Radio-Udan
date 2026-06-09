<?php
/**
 * Admin: send push + in-app notifications to app users.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Send notifications from WP admin.
 */
class RadioUdaan_Admin_Notifications {

	/**
	 * Render send form.
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$fcm_ready     = RadioUdaan_App_Fcm_Sender::is_configured();
		$device_count  = RadioUdaan_App_Notifications::count_registered_devices();
		$users_devices = RadioUdaan_App_Notifications::list_users_with_devices();
		$sent          = isset( $_GET['sent'] ) ? sanitize_text_field( wp_unslash( $_GET['sent'] ) ) : '';
		$created       = isset( $_GET['created'] ) ? (int) $_GET['created'] : 0;

		RadioUdaan_Admin_Layout::render_open( 'notifications', __( 'Send notification', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			esc_html__( 'Sends an in-app inbox item and a push notification (FCM HTTP v1) to registered devices. Users can control event, live, and promo pushes in the app Settings screen.', 'radioudaan-app-api' )
		);

		if ( '1' === $sent ) {
			?>
			<div class="ru-admin__notice notice notice-success is-dismissible" role="status" aria-live="polite">
				<p class="ru-notice-text">
					<?php
					echo esc_html(
						sprintf(
							/* translators: %d: number of inbox rows created */
							__( 'Created %d notification(s). Check registered devices for push delivery.', 'radioudaan-app-api' ),
							$created
						)
					);
					?>
				</p>
			</div>
			<?php
		}

		?>
		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'FCM status', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
				<ul class="ru-admin__meta-list">
					<li>
						<strong><?php esc_html_e( 'HTTP v1 configured', 'radioudaan-app-api' ); ?>:</strong>
						<?php echo $fcm_ready ? esc_html__( 'Yes', 'radioudaan-app-api' ) : esc_html__( 'No — add service account in Settings → Notifications', 'radioudaan-app-api' ); ?>
					</li>
					<li>
						<strong><?php esc_html_e( 'Registered devices', 'radioudaan-app-api' ); ?>:</strong>
						<?php echo (int) $device_count; ?>
					</li>
					<li>
						<strong><?php esc_html_e( 'Users with devices', 'radioudaan-app-api' ); ?>:</strong>
						<?php echo count( $users_devices ); ?>
					</li>
				</ul>
				<?php if ( 0 === $device_count ) : ?>
					<p class="description">
						<?php esc_html_e( 'No devices yet. Open the app on a phone, log in, and allow notifications — the device registers automatically.', 'radioudaan-app-api' ); ?>
					</p>
				<?php endif; ?>
			</div>
		</div>

		<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" class="ru-admin__panel">
			<?php wp_nonce_field( 'radioudaan_send_app_notification' ); ?>
			<input type="hidden" name="action" value="radioudaan_send_app_notification" />
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Compose notification', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
				<div class="ru-admin__field">
					<label for="notif_target"><strong><?php esc_html_e( 'Send to', 'radioudaan-app-api' ); ?></strong></label>
					<select name="notif_target" id="notif_target" class="regular-text">
						<option value="all"><?php esc_html_e( 'All users with registered devices', 'radioudaan-app-api' ); ?></option>
						<option value="user"><?php esc_html_e( 'One app user', 'radioudaan-app-api' ); ?></option>
					</select>
				</div>
				<div class="ru-admin__field" id="ru-notif-user-wrap">
					<label for="notif_user_id"><strong><?php esc_html_e( 'App user', 'radioudaan-app-api' ); ?></strong></label>
					<select name="notif_user_id" id="notif_user_id" class="regular-text">
						<option value=""><?php esc_html_e( 'Select user…', 'radioudaan-app-api' ); ?></option>
						<?php foreach ( $users_devices as $row ) : ?>
							<option value="<?php echo (int) $row['id']; ?>">
								<?php
								echo esc_html(
									sprintf(
										'%s (%s) — %d device(s)',
										$row['display_name'],
										$row['email'],
										(int) $row['device_count']
									)
								);
								?>
							</option>
						<?php endforeach; ?>
					</select>
				</div>
				<div class="ru-admin__field">
					<label for="notif_type"><strong><?php esc_html_e( 'Type', 'radioudaan-app-api' ); ?></strong></label>
					<select name="notif_type" id="notif_type" class="regular-text">
						<option value="general"><?php esc_html_e( 'General (always delivers push)', 'radioudaan-app-api' ); ?></option>
						<option value="events"><?php esc_html_e( 'Events (respects user Events toggle)', 'radioudaan-app-api' ); ?></option>
						<option value="live_broadcast"><?php esc_html_e( 'Live broadcast (respects Live toggle)', 'radioudaan-app-api' ); ?></option>
						<option value="promotions"><?php esc_html_e( 'Promotions (respects Promotions toggle)', 'radioudaan-app-api' ); ?></option>
					</select>
				</div>
				<div class="ru-admin__field">
					<label for="notif_title"><strong><?php esc_html_e( 'Title', 'radioudaan-app-api' ); ?></strong></label>
					<input type="text" name="notif_title" id="notif_title" class="large-text" maxlength="200" required />
				</div>
				<div class="ru-admin__field">
					<label for="notif_body"><strong><?php esc_html_e( 'Message', 'radioudaan-app-api' ); ?></strong></label>
					<textarea name="notif_body" id="notif_body" class="large-text" rows="4" maxlength="1000" required></textarea>
				</div>
			</div>
			<div class="ru-admin__panel-foot">
				<?php submit_button( __( 'Send notification', 'radioudaan-app-api' ), 'primary ru-btn-large', 'submit', false ); ?>
			</div>
		</form>
		<script>
		(function () {
			var target = document.getElementById('notif_target');
			var wrap = document.getElementById('ru-notif-user-wrap');
			if (!target || !wrap) return;
			function sync() {
				wrap.style.display = target.value === 'user' ? 'block' : 'none';
			}
			target.addEventListener('change', sync);
			sync();
		})();
		</script>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * Handle admin form submit.
	 */
	public static function handle_send() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( 'radioudaan_send_app_notification' );

		$title  = isset( $_POST['notif_title'] ) ? sanitize_text_field( wp_unslash( $_POST['notif_title'] ) ) : '';
		$body   = isset( $_POST['notif_body'] ) ? sanitize_textarea_field( wp_unslash( $_POST['notif_body'] ) ) : '';
		$type   = isset( $_POST['notif_type'] ) ? sanitize_key( wp_unslash( $_POST['notif_type'] ) ) : 'general';
		$target = isset( $_POST['notif_target'] ) ? sanitize_key( wp_unslash( $_POST['notif_target'] ) ) : 'all';

		if ( '' === $title || '' === $body ) {
			wp_die( esc_html__( 'Title and message are required.', 'radioudaan-app-api' ) );
		}

		if ( 'user' === $target ) {
			$user_id = isset( $_POST['notif_user_id'] ) ? (int) $_POST['notif_user_id'] : 0;
			if ( $user_id < 1 ) {
				wp_die( esc_html__( 'Select an app user.', 'radioudaan-app-api' ) );
			}
			$user_ids = array( $user_id );
		} else {
			$user_ids = RadioUdaan_App_Notifications::user_ids_with_devices();
		}

		if ( empty( $user_ids ) ) {
			wp_die( esc_html__( 'No registered devices to notify.', 'radioudaan-app-api' ) );
		}

		$result = RadioUdaan_App_Notifications::create_for_users(
			$user_ids,
			$title,
			$body,
			$type,
			array(
				'source' => 'wp_admin',
			)
		);

		RadioUdaan_App_Logger::log(
			'admin_notification_sent',
			array(
				'type'    => $type,
				'target'  => $target,
				'created' => (int) $result['created'],
				'users'   => count( $user_ids ),
			)
		);

		$redirect = add_query_arg(
			array(
				'page'    => RadioUdaan_Admin_App_Hub::NOTIFICATIONS_SLUG,
				'sent'    => '1',
				'created' => (int) $result['created'],
			),
			admin_url( 'admin.php' )
		);

		wp_safe_redirect( $redirect );
		exit;
	}
}

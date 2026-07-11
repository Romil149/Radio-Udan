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

		$fcm_ready           = RadioUdaan_App_Fcm_Sender::is_configured();
		$fcm_project_id      = RadioUdaan_App_Fcm_Sender::resolve_configured_project_id();
		$fcm_project_matches = RadioUdaan_App_Fcm_Sender::project_matches_app();
		$device_count        = RadioUdaan_App_Notifications::count_registered_devices();
		$users_devices       = RadioUdaan_App_Notifications::list_users_with_devices();
		$sent          = isset( $_GET['sent'] ) ? sanitize_text_field( wp_unslash( $_GET['sent'] ) ) : '';
		$created       = isset( $_GET['created'] ) ? (int) $_GET['created'] : 0;
		$push_sent     = isset( $_GET['push_sent'] ) ? (int) $_GET['push_sent'] : 0;
		$push_failed   = isset( $_GET['push_failed'] ) ? (int) $_GET['push_failed'] : 0;
		$ios_sent      = isset( $_GET['ios_sent'] ) ? (int) $_GET['ios_sent'] : 0;
		$ios_failed    = isset( $_GET['ios_failed'] ) ? (int) $_GET['ios_failed'] : 0;
		$android_sent  = isset( $_GET['android_sent'] ) ? (int) $_GET['android_sent'] : 0;
		$android_failed = isset( $_GET['android_failed'] ) ? (int) $_GET['android_failed'] : 0;
		$last_error    = isset( $_GET['last_error'] ) ? sanitize_text_field( wp_unslash( $_GET['last_error'] ) ) : '';
		$fcm_skipped   = isset( $_GET['fcm_skipped'] ) ? (int) $_GET['fcm_skipped'] : 0;
		$prefill_user  = isset( $_GET['user_id'] ) ? (int) $_GET['user_id'] : 0;
		$broadcast_log = self::list_broadcast_history( 15 );

		if ( $prefill_user > 0 ) {
			$found = false;
			foreach ( $users_devices as $row ) {
				if ( (int) $row['id'] === $prefill_user ) {
					$found = true;
					break;
				}
			}
			if ( ! $found ) {
				$prefill_row = RadioUdaan_App_Users::get_by_id( $prefill_user );
				if ( $prefill_row && RadioUdaan_App_Users::STATUS_DELETED !== $prefill_row->status ) {
					$users_devices[] = array(
						'id'           => (int) $prefill_row->id,
						'display_name' => $prefill_row->display_name,
						'email'        => $prefill_row->email,
						'device_count' => 0,
					);
				}
			}
		}

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
							/* translators: 1: inbox rows created, 2: push deliveries succeeded */
							__( 'Created %1$d notification(s). Push delivered to %2$d device(s).', 'radioudaan-app-api' ),
							$created,
							$push_sent
						)
					);
					?>
				</p>
			</div>
			<?php
			if ( $fcm_skipped ) {
				?>
				<div class="ru-admin__notice notice notice-error is-dismissible" role="alert">
					<p class="ru-notice-text">
						<?php esc_html_e( 'Push was not sent — FCM is not configured. Paste the Firebase service account JSON under Settings → Notifications, then send again.', 'radioudaan-app-api' ); ?>
					</p>
				</div>
				<?php
			} elseif ( $push_sent < 1 && $push_failed < 1 && $device_count > 0 ) {
				?>
				<div class="ru-admin__notice notice notice-warning is-dismissible" role="alert">
					<p class="ru-notice-text">
						<?php esc_html_e( 'In-app inbox updated but no push reached a device. Check user notification toggles, invalid tokens, or Firebase APNs setup for iOS.', 'radioudaan-app-api' ); ?>
					</p>
				</div>
				<?php
			} elseif ( $push_failed > 0 ) {
				?>
				<div class="ru-admin__notice notice notice-warning is-dismissible" role="alert">
					<p class="ru-notice-text">
						<?php
						echo esc_html(
							sprintf(
								/* translators: 1: failed count, 2: iOS sent, 3: iOS failed, 4: Android sent, 5: Android failed */
								__( '%1$d push attempt(s) failed (iOS ok %2$d / fail %3$d · Android ok %4$d / fail %5$d). If iOS fails while Android works, upload the APNs Auth Key in Firebase project radio-udaan-72232 for this iOS app.', 'radioudaan-app-api' ),
								$push_failed,
								$ios_sent,
								$ios_failed,
								$android_sent,
								$android_failed
							)
						);
						?>
					</p>
					<?php if ( '' !== $last_error ) : ?>
						<p class="ru-notice-text"><code><?php echo esc_html( $last_error ); ?></code></p>
					<?php endif; ?>
				</div>
				<?php
			} elseif ( $ios_sent > 0 || $android_sent > 0 ) {
				?>
				<div class="ru-admin__notice notice notice-info is-dismissible" role="status">
					<p class="ru-notice-text">
						<?php
						echo esc_html(
							sprintf(
								/* translators: 1: iOS delivered, 2: Android delivered */
								__( 'Platform breakdown — iOS: %1$d · Android: %2$d.', 'radioudaan-app-api' ),
								$ios_sent,
								$android_sent
							)
						);
						?>
					</p>
				</div>
				<?php
			}
		}

		if ( ! $fcm_ready ) {
			?>
			<div class="ru-admin__notice notice notice-error" role="alert">
				<p class="ru-notice-text">
					<?php esc_html_e( 'FCM is not configured — notifications will save to the in-app inbox only until you add the Firebase service account JSON in Settings → Notifications.', 'radioudaan-app-api' ); ?>
				</p>
			</div>
			<?php
		} elseif ( ! $fcm_project_matches ) {
			?>
			<div class="ru-admin__notice notice notice-error" role="alert">
				<p class="ru-notice-text">
					<?php
					echo esc_html(
						sprintf(
							/* translators: 1: configured FCM project ID, 2: expected app Firebase project ID */
							__( 'FCM project mismatch: server is %1$s but the mobile app uses %2$s. Paste the service account JSON from the same Firebase project as the app, or pushes will never reach devices.', 'radioudaan-app-api' ),
							'' !== $fcm_project_id ? $fcm_project_id : __( '(empty)', 'radioudaan-app-api' ),
							RadioUdaan_App_Fcm_Sender::EXPECTED_APP_PROJECT_ID
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
						<strong><?php esc_html_e( 'FCM project ID', 'radioudaan-app-api' ); ?>:</strong>
						<?php echo '' !== $fcm_project_id ? esc_html( $fcm_project_id ) : esc_html__( '(not set)', 'radioudaan-app-api' ); ?>
						<?php if ( $fcm_ready && $fcm_project_matches ) : ?>
							— <?php esc_html_e( 'matches app', 'radioudaan-app-api' ); ?>
						<?php elseif ( $fcm_ready ) : ?>
							— <?php esc_html_e( 'does not match app', 'radioudaan-app-api' ); ?>
						<?php endif; ?>
					</li>
					<li>
						<strong><?php esc_html_e( 'App Firebase project', 'radioudaan-app-api' ); ?>:</strong>
						<?php echo esc_html( RadioUdaan_App_Fcm_Sender::EXPECTED_APP_PROJECT_ID ); ?>
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
						<?php esc_html_e( 'No devices yet. Open the app on a phone, log in, and allow notifications — the device registers automatically. Use Settings → Push diagnostics in the app if registration fails.', 'radioudaan-app-api' ); ?>
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
						<option value="all" <?php selected( $prefill_user < 1 ); ?>><?php esc_html_e( 'All active app users (inbox for all; push only where a device is registered)', 'radioudaan-app-api' ); ?></option>
						<option value="user" <?php selected( $prefill_user > 0 ); ?>><?php esc_html_e( 'One app user', 'radioudaan-app-api' ); ?></option>
					</select>
				</div>
				<div class="ru-admin__field" id="ru-notif-user-wrap">
					<label for="notif_user_id"><strong><?php esc_html_e( 'App user', 'radioudaan-app-api' ); ?></strong></label>
					<select name="notif_user_id" id="notif_user_id" class="regular-text">
						<option value=""><?php esc_html_e( 'Select user…', 'radioudaan-app-api' ); ?></option>
						<?php foreach ( $users_devices as $row ) : ?>
							<option value="<?php echo (int) $row['id']; ?>" <?php selected( $prefill_user, (int) $row['id'] ); ?>>
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
				<div class="ru-admin__field">
					<label for="notif_open_in_app"><strong><?php esc_html_e( 'Open in app (optional)', 'radioudaan-app-api' ); ?></strong></label>
					<select name="notif_open_in_app" id="notif_open_in_app" class="regular-text">
						<option value="none"><?php esc_html_e( 'None — message only', 'radioudaan-app-api' ); ?></option>
						<option value="radio"><?php esc_html_e( 'Live Radio tab', 'radioudaan-app-api' ); ?></option>
						<option value="events"><?php esc_html_e( 'Events tab', 'radioudaan-app-api' ); ?></option>
						<option value="whats_new"><?php esc_html_e( "What's New / community post", 'radioudaan-app-api' ); ?></option>
						<option value="url"><?php esc_html_e( 'External HTTPS link', 'radioudaan-app-api' ); ?></option>
					</select>
					<p class="description"><?php esc_html_e( 'Adds an Open button on the notification detail screen in the app.', 'radioudaan-app-api' ); ?></p>
				</div>
				<div class="ru-admin__field" id="ru-notif-whats-new-wrap" style="display:none;">
					<label for="notif_post_id"><strong><?php esc_html_e( 'WordPress post ID', 'radioudaan-app-api' ); ?></strong></label>
					<input type="number" name="notif_post_id" id="notif_post_id" class="small-text" min="1" step="1" />
					<label for="notif_post_type" style="margin-top:8px;display:block;"><strong><?php esc_html_e( 'Post type', 'radioudaan-app-api' ); ?></strong></label>
					<select name="notif_post_type" id="notif_post_type" class="regular-text">
						<option value="whats-new"><?php esc_html_e( "What's New", 'radioudaan-app-api' ); ?></option>
						<option value="latestcommunitynews"><?php esc_html_e( 'Community News', 'radioudaan-app-api' ); ?></option>
					</select>
				</div>
				<div class="ru-admin__field" id="ru-notif-url-wrap" style="display:none;">
					<label for="notif_open_url"><strong><?php esc_html_e( 'HTTPS URL', 'radioudaan-app-api' ); ?></strong></label>
					<input type="url" name="notif_open_url" id="notif_open_url" class="large-text" placeholder="https://example.com/page" />
				</div>
				<?php
				$prefill_inbox = array( 'total' => 0, 'unread_count' => 0 );
				if ( $prefill_user > 0 ) {
					$prefill_inbox = RadioUdaan_App_Notifications::list_for_user( $prefill_user, 1, 1 );
				}
				?>
				<p class="description" id="ru-notif-user-inbox-meta" style="<?php echo $prefill_user > 0 ? '' : 'display:none;'; ?>">
					<?php
					if ( $prefill_user > 0 ) {
						printf(
							/* translators: 1: total inbox count, 2: unread count */
							esc_html__( 'This user has %1$d notification(s) in inbox (%2$d unread). New sends are appended — history is not replaced.', 'radioudaan-app-api' ),
							(int) $prefill_inbox['total'],
							(int) $prefill_inbox['unread_count']
						);
					}
					?>
				</p>
				<div class="ru-admin__panel ru-notif-preview-panel" style="margin-top:16px;">
					<div class="ru-admin__panel-head">
						<h3><?php esc_html_e( 'Preview before send', 'radioudaan-app-api' ); ?></h3>
					</div>
					<div class="ru-admin__panel-body">
						<p class="description" style="margin-top:0;"><?php esc_html_e( 'Approximate look on the phone lock screen and in-app inbox.', 'radioudaan-app-api' ); ?></p>
						<div class="ru-notif-preview" aria-live="polite">
							<div class="ru-notif-preview__app"><?php echo esc_html( RadioUdaan_App_Branding::get_app_name() ); ?></div>
							<div class="ru-notif-preview__title" id="ru-notif-preview-title"><?php esc_html_e( 'Notification title', 'radioudaan-app-api' ); ?></div>
							<div class="ru-notif-preview__body" id="ru-notif-preview-body"><?php esc_html_e( 'Message body appears here as you type.', 'radioudaan-app-api' ); ?></div>
						</div>
					</div>
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
			if (target && wrap) {
				function syncTarget() {
					wrap.style.display = target.value === 'user' ? 'block' : 'none';
				}
				target.addEventListener('change', syncTarget);
				syncTarget();
			}

			var titleInput = document.getElementById('notif_title');
			var bodyInput = document.getElementById('notif_body');
			var previewTitle = document.getElementById('ru-notif-preview-title');
			var previewBody = document.getElementById('ru-notif-preview-body');
			if (!titleInput || !bodyInput || !previewTitle || !previewBody) {
				return;
			}

			var titleDefault = previewTitle.textContent;
			var bodyDefault = previewBody.textContent;

			function syncPreview() {
				var title = titleInput.value.trim();
				var body = bodyInput.value.trim();
				previewTitle.textContent = title || titleDefault;
				previewBody.textContent = body || bodyDefault;
			}

			titleInput.addEventListener('input', syncPreview);
			bodyInput.addEventListener('input', syncPreview);
			syncPreview();

			var openInApp = document.getElementById('notif_open_in_app');
			var whatsNewWrap = document.getElementById('ru-notif-whats-new-wrap');
			var urlWrap = document.getElementById('ru-notif-url-wrap');
			if (openInApp && whatsNewWrap && urlWrap) {
				function syncOpenInApp() {
					var value = openInApp.value;
					whatsNewWrap.style.display = value === 'whats_new' ? 'block' : 'none';
					urlWrap.style.display = value === 'url' ? 'block' : 'none';
				}
				openInApp.addEventListener('change', syncOpenInApp);
				syncOpenInApp();
			}
		})();
		</script>

		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Recent admin sends', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body" style="padding:0;">
				<?php if ( empty( $broadcast_log ) ) : ?>
					<div class="ru-admin__empty">
						<p><?php esc_html_e( 'No admin notification history yet.', 'radioudaan-app-api' ); ?></p>
					</div>
				<?php else : ?>
					<table class="ru-admin__table">
						<thead>
							<tr>
								<th><?php esc_html_e( 'When', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Action', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Admin', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Target', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Details', 'radioudaan-app-api' ); ?></th>
							</tr>
						</thead>
						<tbody>
						<?php foreach ( $broadcast_log as $row ) : ?>
							<tr>
								<td><?php echo esc_html( RadioUdaan_Admin_App_Users::format_date( $row['created_at'] ) ); ?></td>
								<td><?php echo esc_html( $row['action_label'] ); ?></td>
								<td><?php echo esc_html( $row['admin_label'] ); ?></td>
								<td>
									<?php if ( ! empty( $row['target_url'] ) ) : ?>
										<a href="<?php echo esc_url( $row['target_url'] ); ?>"><?php echo esc_html( $row['target_label'] ); ?></a>
									<?php else : ?>
										<?php echo esc_html( $row['target_label'] ); ?>
									<?php endif; ?>
								</td>
								<td><?php echo esc_html( $row['details_label'] ); ?></td>
							</tr>
						<?php endforeach; ?>
						</tbody>
					</table>
				<?php endif; ?>
			</div>
		</div>
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
			global $wpdb;

			$table = RadioUdaan_App_Users::table_name();

			// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
			$rows = $wpdb->get_col(
				$wpdb->prepare(
					"SELECT id FROM {$table} WHERE status = %s ORDER BY id ASC",
					RadioUdaan_App_Users::STATUS_ACTIVE
				)
			);

			$user_ids = array_map( 'intval', is_array( $rows ) ? $rows : array() );
		}

		if ( empty( $user_ids ) ) {
			wp_die( esc_html__( 'No app users to notify.', 'radioudaan-app-api' ) );
		}

		$open_in_app = isset( $_POST['notif_open_in_app'] ) ? sanitize_key( wp_unslash( $_POST['notif_open_in_app'] ) ) : 'none';
		$action_data = RadioUdaan_App_Notifications::build_admin_action_data(
			$open_in_app,
			array(
				'post_id'   => isset( $_POST['notif_post_id'] ) ? (int) $_POST['notif_post_id'] : 0,
				'post_type' => isset( $_POST['notif_post_type'] ) ? sanitize_key( wp_unslash( $_POST['notif_post_type'] ) ) : 'whats-new',
				'open_url'  => isset( $_POST['notif_open_url'] ) ? esc_url_raw( wp_unslash( $_POST['notif_open_url'] ) ) : '',
			)
		);

		$result = RadioUdaan_App_Notifications::create_for_users(
			$user_ids,
			$title,
			$body,
			$type,
			$action_data
		);

		RadioUdaan_App_Logger::log(
			'admin_notification_sent',
			array(
				'type'        => $type,
				'target'      => $target,
				'created'     => (int) $result['created'],
				'push_sent'   => (int) $result['push_sent'],
				'push_failed' => (int) $result['push_failed'],
				'fcm_skipped' => ! empty( $result['fcm_skipped'] ),
				'users'       => count( $user_ids ),
			)
		);

		if ( 'user' === $target && count( $user_ids ) === 1 ) {
			RadioUdaan_App_Admin_Audit::log(
				RadioUdaan_App_Admin_Audit::ACTION_USER_NOTIFIED,
				get_current_user_id(),
				(int) $user_ids[0],
				array(
					'type'    => $type,
					'created' => (int) $result['created'],
					'push_sent' => (int) $result['push_sent'],
				)
			);
		} else {
			RadioUdaan_App_Admin_Audit::log(
				RadioUdaan_App_Admin_Audit::ACTION_BULK_NOTIFIED,
				get_current_user_id(),
				null,
				array(
					'type'    => $type,
					'count'   => count( $user_ids ),
					'created' => (int) $result['created'],
					'push_sent' => (int) $result['push_sent'],
				)
			);
		}

		$redirect = add_query_arg(
			array(
				'page'           => RadioUdaan_Admin_App_Hub::NOTIFICATIONS_SLUG,
				'sent'           => '1',
				'created'        => (int) $result['created'],
				'push_sent'      => (int) $result['push_sent'],
				'push_failed'    => (int) $result['push_failed'],
				'ios_sent'       => isset( $result['ios_sent'] ) ? (int) $result['ios_sent'] : 0,
				'ios_failed'     => isset( $result['ios_failed'] ) ? (int) $result['ios_failed'] : 0,
				'android_sent'   => isset( $result['android_sent'] ) ? (int) $result['android_sent'] : 0,
				'android_failed' => isset( $result['android_failed'] ) ? (int) $result['android_failed'] : 0,
				'last_error'     => isset( $result['last_error'] ) ? substr( (string) $result['last_error'], 0, 180 ) : '',
				'fcm_skipped'    => ! empty( $result['fcm_skipped'] ) ? 1 : 0,
			),
			admin_url( 'admin.php' )
		);

		wp_safe_redirect( $redirect );
		exit;
	}

	/**
	 * Deep link to notify a specific app user.
	 *
	 * @param int $user_id App user id.
	 * @return string
	 */
	public static function notify_user_url( $user_id ) {
		return add_query_arg(
			array(
				'page'    => RadioUdaan_Admin_App_Hub::NOTIFICATIONS_SLUG,
				'user_id' => (int) $user_id,
			),
			admin_url( 'admin.php' )
		);
	}

	/**
	 * Recent admin notification audit rows for the history panel.
	 *
	 * @param int $limit Max rows.
	 * @return array<int,array<string,mixed>>
	 */
	public static function list_broadcast_history( $limit = 15 ) {
		$rows = RadioUdaan_App_Admin_Audit::list_recent( max( 1, min( 100, (int) $limit ) * 3 ) );
		$out  = array();

		$notify_actions = array(
			RadioUdaan_App_Admin_Audit::ACTION_USER_NOTIFIED,
			RadioUdaan_App_Admin_Audit::ACTION_BULK_NOTIFIED,
		);

		foreach ( $rows as $row ) {
			if ( ! in_array( $row->action, $notify_actions, true ) ) {
				continue;
			}

			$details = array();
			if ( ! empty( $row->details ) ) {
				$decoded = json_decode( (string) $row->details, true );
				if ( is_array( $decoded ) ) {
					$details = $decoded;
				}
			}

			$admin_label = __( 'System', 'radioudaan-app-api' );
			if ( ! empty( $row->admin_user_id ) ) {
				$wp_user = get_userdata( (int) $row->admin_user_id );
				$admin_label = $wp_user ? $wp_user->display_name : sprintf( '#%d', (int) $row->admin_user_id );
			}

			$target_label = __( 'Multiple users', 'radioudaan-app-api' );
			$target_url   = '';
			if ( ! empty( $row->target_user_id ) ) {
				$app_user = RadioUdaan_App_Users::get_by_id( (int) $row->target_user_id );
				$target_label = $app_user ? $app_user->display_name : sprintf( '#%d', (int) $row->target_user_id );
				$target_url   = RadioUdaan_Admin_App_User_Detail::view_url( (int) $row->target_user_id );
			}

			$action_labels = array(
				RadioUdaan_App_Admin_Audit::ACTION_USER_NOTIFIED  => __( 'User notified', 'radioudaan-app-api' ),
				RadioUdaan_App_Admin_Audit::ACTION_BULK_NOTIFIED => __( 'Broadcast', 'radioudaan-app-api' ),
			);

			$detail_parts = array();
			if ( isset( $details['type'] ) ) {
				$detail_parts[] = sprintf(
					/* translators: %s: notification type */
					__( 'Type: %s', 'radioudaan-app-api' ),
					sanitize_key( (string) $details['type'] )
				);
			}
			if ( isset( $details['count'] ) ) {
				$detail_parts[] = sprintf(
					/* translators: %d: user count */
					__( '%d users', 'radioudaan-app-api' ),
					(int) $details['count']
				);
			}
			if ( isset( $details['created'] ) ) {
				$detail_parts[] = sprintf(
					/* translators: %d: inbox rows created */
					__( '%d inbox', 'radioudaan-app-api' ),
					(int) $details['created']
				);
			}
			if ( isset( $details['push_sent'] ) ) {
				$detail_parts[] = sprintf(
					/* translators: %d: push deliveries */
					__( '%d push', 'radioudaan-app-api' ),
					(int) $details['push_sent']
				);
			}

			$out[] = array(
				'created_at'    => $row->created_at,
				'action_label'  => isset( $action_labels[ $row->action ] ) ? $action_labels[ $row->action ] : $row->action,
				'admin_label'   => $admin_label,
				'target_label'  => $target_label,
				'target_url'    => $target_url,
				'details_label' => ! empty( $detail_parts ) ? implode( ' · ', $detail_parts ) : '—',
			);

			if ( count( $out ) >= (int) $limit ) {
				break;
			}
		}

		return $out;
	}
}

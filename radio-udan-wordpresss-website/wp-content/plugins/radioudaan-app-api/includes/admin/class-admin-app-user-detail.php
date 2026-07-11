<?php
/**
 * Admin detail view for a single app user.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Hidden submenu: app user profile, devices, entries, notifications.
 */
class RadioUdaan_Admin_App_User_Detail {

	/**
	 * Render detail page.
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$user_id = isset( $_GET['user_id'] ) ? (int) $_GET['user_id'] : 0;
		$user    = $user_id > 0 ? RadioUdaan_App_Users::get_by_id( $user_id ) : null;

		if ( ! $user ) {
			wp_die( esc_html__( 'App user not found.', 'radioudaan-app-api' ) );
		}

		$devices       = self::list_devices( $user_id );
		$notifications = RadioUdaan_App_Notifications::list_for_user( $user_id, 1, 10 );
		$entries       = RadioUdaan_Admin_Data::get_entries_for_phone( $user->phone_e164, 25 );
		$list_url      = admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::APP_USERS_SLUG );

		RadioUdaan_Admin_Layout::render_open( 'registrations', __( 'App user details', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			sprintf(
				/* translators: %s: user display name */
				esc_html__( 'Profile and activity for %s.', 'radioudaan-app-api' ),
				$user->display_name
			)
		);

		self::render_action_bar( $user, $list_url );
		?>
		<div class="ru-admin__grid ru-admin__grid--user-detail">
			<div class="ru-admin__grid-main">
				<div class="ru-admin__panel">
					<div class="ru-admin__panel-head">
						<h2><?php esc_html_e( 'Profile', 'radioudaan-app-api' ); ?></h2>
						<?php RadioUdaan_Admin_App_Users::render_status_badge( $user->status ); ?>
					</div>
					<div class="ru-admin__panel-body">
						<ul class="ru-admin__meta-list ru-admin__meta-list--grid">
							<li><strong><?php esc_html_e( 'Name', 'radioudaan-app-api' ); ?>:</strong> <?php echo esc_html( $user->display_name ); ?></li>
							<li><strong><?php esc_html_e( 'Email', 'radioudaan-app-api' ); ?>:</strong> <?php echo esc_html( $user->email ? $user->email : '—' ); ?></li>
							<li><strong><?php esc_html_e( 'Mobile', 'radioudaan-app-api' ); ?>:</strong> <?php echo esc_html( RadioUdaan_Admin_App_Users::mask_phone( $user->phone_e164 ) ); ?></li>
							<li><strong><?php esc_html_e( 'Phone verified', 'radioudaan-app-api' ); ?>:</strong> <?php echo ! empty( $user->phone_verified ) ? esc_html__( 'Yes', 'radioudaan-app-api' ) : esc_html__( 'No', 'radioudaan-app-api' ); ?></li>
							<li><strong><?php esc_html_e( 'Email verified', 'radioudaan-app-api' ); ?>:</strong> <?php echo ! empty( $user->email_verified ) ? esc_html__( 'Yes', 'radioudaan-app-api' ) : esc_html__( 'No', 'radioudaan-app-api' ); ?></li>
							<li><strong><?php esc_html_e( 'Login count', 'radioudaan-app-api' ); ?>:</strong> <?php echo (int) $user->login_count; ?></li>
							<li><strong><?php esc_html_e( 'First login', 'radioudaan-app-api' ); ?>:</strong> <?php echo esc_html( RadioUdaan_Admin_App_Users::format_date( $user->first_login_at ) ); ?></li>
							<li><strong><?php esc_html_e( 'Last login', 'radioudaan-app-api' ); ?>:</strong> <?php echo esc_html( RadioUdaan_Admin_App_Users::format_date( $user->last_login_at ) ); ?></li>
							<li><strong><?php esc_html_e( 'Created', 'radioudaan-app-api' ); ?>:</strong> <?php echo esc_html( RadioUdaan_Admin_App_Users::format_date( $user->created_at ) ); ?></li>
							<li><strong><?php esc_html_e( 'Updated', 'radioudaan-app-api' ); ?>:</strong> <?php echo esc_html( RadioUdaan_Admin_App_Users::format_date( $user->updated_at ) ); ?></li>
							<li><strong><?php esc_html_e( 'User ID', 'radioudaan-app-api' ); ?>:</strong> <code><?php echo (int) $user->id; ?></code></li>
						</ul>
					</div>
				</div>

				<div class="ru-admin__panel">
					<div class="ru-admin__panel-head">
						<h2><?php esc_html_e( 'Push devices', 'radioudaan-app-api' ); ?></h2>
						<span class="ru-admin__result-count"><?php echo count( $devices ); ?></span>
					</div>
					<div class="ru-admin__panel-body" style="padding:0;">
						<?php if ( empty( $devices ) ) : ?>
							<div class="ru-admin__empty">
								<p><?php esc_html_e( 'No registered devices.', 'radioudaan-app-api' ); ?></p>
							</div>
						<?php else : ?>
							<table class="ru-admin__table">
								<thead>
									<tr>
										<th><?php esc_html_e( 'Platform', 'radioudaan-app-api' ); ?></th>
										<th><?php esc_html_e( 'Token', 'radioudaan-app-api' ); ?></th>
										<th><?php esc_html_e( 'Last seen', 'radioudaan-app-api' ); ?></th>
										<th><?php esc_html_e( 'Registered', 'radioudaan-app-api' ); ?></th>
									</tr>
								</thead>
								<tbody>
								<?php foreach ( $devices as $device ) : ?>
									<tr>
										<td><?php echo esc_html( ucfirst( (string) $device['platform'] ) ); ?></td>
										<td><code><?php echo esc_html( self::mask_token( (string) $device['fcm_token'] ) ); ?></code></td>
										<td><?php echo esc_html( RadioUdaan_Admin_App_Users::format_date( $device['last_seen_at'] ) ); ?></td>
										<td><?php echo esc_html( RadioUdaan_Admin_App_Users::format_date( $device['created_at'] ) ); ?></td>
									</tr>
								<?php endforeach; ?>
								</tbody>
							</table>
						<?php endif; ?>
					</div>
				</div>

				<div class="ru-admin__panel">
					<div class="ru-admin__panel-head">
						<h2><?php esc_html_e( 'Event form entries', 'radioudaan-app-api' ); ?></h2>
					</div>
					<div class="ru-admin__panel-body" style="padding:0;">
						<?php if ( empty( $entries ) ) : ?>
							<div class="ru-admin__empty">
								<p><?php esc_html_e( 'No event registrations linked to this phone.', 'radioudaan-app-api' ); ?></p>
							</div>
						<?php else : ?>
							<table class="ru-admin__table">
								<thead>
									<tr>
										<th><?php esc_html_e( 'Date', 'radioudaan-app-api' ); ?></th>
										<th><?php esc_html_e( 'Event', 'radioudaan-app-api' ); ?></th>
										<th><?php esc_html_e( 'Source', 'radioudaan-app-api' ); ?></th>
										<th><?php esc_html_e( 'Entry', 'radioudaan-app-api' ); ?></th>
									</tr>
								</thead>
								<tbody>
								<?php foreach ( $entries as $entry ) : ?>
									<tr>
										<td><?php echo esc_html( RadioUdaan_Admin_App_Users::format_date( $entry['date'] ) ); ?></td>
										<td><?php echo esc_html( $entry['event_title'] ); ?></td>
										<td><?php echo esc_html( $entry['source_label'] ); ?></td>
										<td>
											<?php if ( ! empty( $entry['view_url'] ) ) : ?>
												<a href="<?php echo esc_url( $entry['view_url'] ); ?>"><?php esc_html_e( 'View', 'radioudaan-app-api' ); ?></a>
											<?php else : ?>
												—
											<?php endif; ?>
										</td>
									</tr>
								<?php endforeach; ?>
								</tbody>
							</table>
						<?php endif; ?>
					</div>
				</div>
			</div>

			<aside class="ru-admin__grid-side">
				<div class="ru-admin__panel">
					<div class="ru-admin__panel-head">
						<h2>
							<?php
							printf(
								/* translators: 1: total notifications, 2: unread count */
								esc_html__( 'In-app notifications (%1$d total, %2$d unread)', 'radioudaan-app-api' ),
								(int) $notifications['total'],
								(int) $notifications['unread_count']
							);
							?>
						</h2>
					</div>
					<div class="ru-admin__panel-body">
						<?php if ( empty( $notifications['items'] ) ) : ?>
							<p class="description"><?php esc_html_e( 'No notifications yet.', 'radioudaan-app-api' ); ?></p>
						<?php else : ?>
							<ul class="ru-admin__notif-list">
								<?php foreach ( $notifications['items'] as $notif ) : ?>
									<li class="ru-admin__notif-item<?php echo empty( $notif['read_at'] ) ? ' is-unread' : ''; ?>">
										<strong><?php echo esc_html( $notif['title'] ); ?></strong>
										<span class="ru-admin__notif-meta">
											<?php echo esc_html( RadioUdaan_Admin_App_Users::format_date( $notif['created_at'] ) ); ?>
											· <?php echo esc_html( $notif['type'] ); ?>
										</span>
										<p><?php echo esc_html( wp_trim_words( $notif['body'], 18 ) ); ?></p>
									</li>
								<?php endforeach; ?>
							</ul>
							<?php if ( (int) $notifications['total'] > count( $notifications['items'] ) ) : ?>
								<p class="description">
									<?php
									printf(
										/* translators: %d: total notification count */
										esc_html__( 'Showing latest 10 of %d.', 'radioudaan-app-api' ),
										(int) $notifications['total']
									);
									?>
								</p>
							<?php endif; ?>
						<?php endif; ?>
					</div>
				</div>
			</aside>
		</div>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * @param int $user_id User id.
	 * @return string
	 */
	public static function view_url( $user_id ) {
		return add_query_arg(
			array(
				'page'    => RadioUdaan_Admin_App_Hub::VIEW_USER_SLUG,
				'user_id' => (int) $user_id,
			),
			admin_url( 'admin.php' )
		);
	}

	/**
	 * @param object $user     User row.
	 * @param string $list_url Back link.
	 */
	private static function render_action_bar( $user, $list_url ) {
		$user_id = (int) $user->id;
		$status  = (string) $user->status;
		?>
		<div class="ru-admin__action-bar">
			<a href="<?php echo esc_url( $list_url ); ?>" class="button">&larr; <?php esc_html_e( 'Back to app users', 'radioudaan-app-api' ); ?></a>
			<div class="ru-admin__action-bar-actions">
				<?php if ( RadioUdaan_App_Users::STATUS_ACTIVE === $status ) : ?>
					<form method="post" action="<?php echo esc_url( RadioUdaan_Admin_App_User_Actions::action_url( RadioUdaan_Admin_App_User_Actions::ACTION_PAUSE, $user_id ) ); ?>" class="ru-inline-action-form ru-danger-action-form" data-ru-confirm-word="PAUSE">
						<?php wp_nonce_field( RadioUdaan_Admin_App_User_Actions::nonce_field_name( $user_id ) ); ?>
						<button type="submit" class="button"><?php esc_html_e( 'Pause user', 'radioudaan-app-api' ); ?></button>
					</form>
				<?php elseif ( RadioUdaan_App_Users::STATUS_PAUSED === $status ) : ?>
					<form method="post" action="<?php echo esc_url( RadioUdaan_Admin_App_User_Actions::action_url( RadioUdaan_Admin_App_User_Actions::ACTION_RESUME, $user_id ) ); ?>" class="ru-inline-action-form">
						<?php wp_nonce_field( RadioUdaan_Admin_App_User_Actions::nonce_field_name( $user_id ) ); ?>
						<button type="submit" class="button button-primary"><?php esc_html_e( 'Resume user', 'radioudaan-app-api' ); ?></button>
					</form>
				<?php endif; ?>
				<a href="<?php echo esc_url( RadioUdaan_Admin_Notifications::notify_user_url( $user_id ) ); ?>" class="button"><?php esc_html_e( 'Send notification', 'radioudaan-app-api' ); ?></a>
				<?php if ( RadioUdaan_App_Users::STATUS_DELETED !== $status ) : ?>
					<form method="post" action="<?php echo esc_url( RadioUdaan_Admin_App_User_Actions::action_url( RadioUdaan_Admin_App_User_Actions::ACTION_DELETE, $user_id ) ); ?>" class="ru-inline-action-form ru-danger-action-form" data-ru-confirm-word="DELETE">
						<?php wp_nonce_field( RadioUdaan_Admin_App_User_Actions::nonce_field_name( $user_id ) ); ?>
						<button type="submit" class="button ru-btn-danger"><?php esc_html_e( 'Delete user', 'radioudaan-app-api' ); ?></button>
					</form>
				<?php endif; ?>
			</div>
		</div>
		<?php
	}

	/**
	 * @param int $user_id User id.
	 * @return array<int,array<string,mixed>>
	 */
	private static function list_devices( $user_id ) {
		RadioUdaan_App_Notifications::maybe_create_tables();

		global $wpdb;

		$table = RadioUdaan_App_Notifications::devices_table();

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT id, platform, fcm_token, created_at, last_seen_at FROM {$table} WHERE user_id = %d ORDER BY last_seen_at DESC",
				(int) $user_id
			),
			ARRAY_A
		);

		return is_array( $rows ) ? $rows : array();
	}

	/**
	 * @param string $token FCM token.
	 * @return string
	 */
	private static function mask_token( $token ) {
		$token = (string) $token;
		if ( strlen( $token ) < 8 ) {
			return '****';
		}
		return '…' . substr( $token, -6 );
	}
}

<?php
/**
 * Admin list: app users (OTP login), not event form entries.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * App users admin page.
 */
class RadioUdaan_Admin_App_Users {

	const PER_PAGE = 25;

	/**
	 * Render page.
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$status = isset( $_GET['status'] ) ? sanitize_key( wp_unslash( $_GET['status'] ) ) : '';
		$search = isset( $_GET['s'] ) ? trim( sanitize_text_field( wp_unslash( $_GET['s'] ) ) ) : '';
		$page   = isset( $_GET['paged'] ) ? max( 1, (int) $_GET['paged'] ) : 1;

		$allowed_statuses = array(
			RadioUdaan_App_Users::STATUS_ACTIVE,
			RadioUdaan_App_Users::STATUS_PENDING,
			RadioUdaan_App_Users::STATUS_PAUSED,
		);
		if ( '' !== $status && ! in_array( $status, $allowed_statuses, true ) ) {
			$status = '';
		}

		$result = RadioUdaan_App_Users::list_users_paginated(
			array(
				'page'     => $page,
				'per_page' => self::PER_PAGE,
				'status'   => $status,
				'search'   => $search,
			)
		);

		$stats = array(
			'active'  => RadioUdaan_App_Users::count_by_status( RadioUdaan_App_Users::STATUS_ACTIVE ),
			'pending' => RadioUdaan_App_Users::count_by_status( RadioUdaan_App_Users::STATUS_PENDING ),
			'paused'  => RadioUdaan_App_Users::count_by_status( RadioUdaan_App_Users::STATUS_PAUSED ),
			'total'   => RadioUdaan_App_Users::count_users(),
		);

		$base_url = admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::APP_USERS_SLUG );

		RadioUdaan_Admin_Layout::render_open( 'registrations', __( 'App users', 'radioudaan-app-api' ) );

		RadioUdaan_Admin_Components::render_breadcrumb(
			array(
				array(
					'label' => __( 'Dashboard', 'radioudaan-app-api' ),
					'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::MENU_SLUG ),
				),
				array(
					'label' => __( 'App users', 'radioudaan-app-api' ),
				),
			)
		);

		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'App login', 'radioudaan-app-api' ) . '</strong> — ' .
			esc_html__( 'Mobile app accounts (password + OTP). This is not the same as event form entries.', 'radioudaan-app-api' )
		);

		self::render_stats_row( $stats );
		?>
		<form method="get" action="<?php echo esc_url( admin_url( 'admin.php' ) ); ?>" class="ru-admin__toolbar">
			<input type="hidden" name="page" value="<?php echo esc_attr( RadioUdaan_Admin_App_Hub::APP_USERS_SLUG ); ?>" />
			<?php if ( '' !== $status ) : ?>
				<input type="hidden" name="status" value="<?php echo esc_attr( $status ); ?>" />
			<?php endif; ?>
			<label class="screen-reader-text" for="ru-app-users-search"><?php esc_html_e( 'Search app users', 'radioudaan-app-api' ); ?></label>
			<input
				type="search"
				id="ru-app-users-search"
				name="s"
				class="ru-admin__search-input"
				value="<?php echo esc_attr( $search ); ?>"
				placeholder="<?php esc_attr_e( 'Search name, email, or phone…', 'radioudaan-app-api' ); ?>"
			/>
			<button type="submit" class="button"><?php esc_html_e( 'Search', 'radioudaan-app-api' ); ?></button>
			<?php if ( '' !== $search ) : ?>
				<a href="<?php echo esc_url( '' !== $status ? add_query_arg( 'status', $status, $base_url ) : $base_url ); ?>" class="button">
					<?php esc_html_e( 'Clear search', 'radioudaan-app-api' ); ?>
				</a>
			<?php endif; ?>
		</form>

		<?php
		/*
		 * Bulk form must NOT wrap row-action forms — nested <form> is invalid HTML;
		 * browsers ignore inner form tags so Pause/Delete submit the bulk form instead.
		 * Row checkboxes associate via the HTML form="" attribute.
		 */
		?>
		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'App users', 'radioudaan-app-api' ); ?></h2>
				<nav class="ru-filter-tabs" aria-label="<?php esc_attr_e( 'Filter by status', 'radioudaan-app-api' ); ?>">
					<?php
					$tab_statuses = array(
						''        => __( 'All', 'radioudaan-app-api' ),
						'active'  => __( 'Active', 'radioudaan-app-api' ),
						'pending' => __( 'Pending', 'radioudaan-app-api' ),
						'paused'  => __( 'Paused', 'radioudaan-app-api' ),
					);
					foreach ( $tab_statuses as $tab_key => $tab_label ) :
						$tab_args = array();
						if ( '' !== $tab_key ) {
							$tab_args['status'] = $tab_key;
						}
						if ( '' !== $search ) {
							$tab_args['s'] = $search;
						}
						$tab_url = add_query_arg( $tab_args, $base_url );
						?>
						<a href="<?php echo esc_url( $tab_url ); ?>" class="ru-filter-tabs__link <?php echo $status === $tab_key ? 'is-active' : ''; ?>">
							<?php echo esc_html( $tab_label ); ?>
						</a>
					<?php endforeach; ?>
					<a href="<?php echo esc_url( RadioUdaan_Admin_Export::export_app_users_url( $status, $search ) ); ?>" class="ru-filter-tabs__link">
						<?php esc_html_e( 'Export CSV', 'radioudaan-app-api' ); ?>
					</a>
				</nav>
			</div>

			<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" id="ru-app-users-bulk-form" class="ru-admin__bulk-bar">
				<?php wp_nonce_field( 'radioudaan_app_users_bulk' ); ?>
				<input type="hidden" name="action" value="<?php echo esc_attr( RadioUdaan_Admin_App_User_Actions::ACTION_BULK ); ?>" />
				<?php if ( '' !== $search ) : ?>
					<input type="hidden" name="s" value="<?php echo esc_attr( $search ); ?>" />
				<?php endif; ?>
				<?php if ( '' !== $status ) : ?>
					<input type="hidden" name="status" value="<?php echo esc_attr( $status ); ?>" />
				<?php endif; ?>
				<?php if ( $page > 1 ) : ?>
					<input type="hidden" name="paged" value="<?php echo (int) $page; ?>" />
				<?php endif; ?>
				<label class="ru-admin__bulk-select">
					<input type="checkbox" id="ru-app-users-select-all" />
					<?php esc_html_e( 'Select all on page', 'radioudaan-app-api' ); ?>
				</label>
				<select name="bulk_action" id="ru-app-users-bulk-action" class="ru-admin__bulk-select">
					<option value=""><?php esc_html_e( 'Bulk actions', 'radioudaan-app-api' ); ?></option>
					<option value="pause"><?php esc_html_e( 'Pause', 'radioudaan-app-api' ); ?></option>
					<option value="resume"><?php esc_html_e( 'Resume', 'radioudaan-app-api' ); ?></option>
					<option value="delete"><?php esc_html_e( 'Delete', 'radioudaan-app-api' ); ?></option>
				</select>
				<button type="submit" class="button" id="ru-app-users-bulk-submit"><?php esc_html_e( 'Apply', 'radioudaan-app-api' ); ?></button>
				<span class="ru-admin__result-count">
					<?php
					echo esc_html(
						sprintf(
							/* translators: 1: showing count, 2: total count */
							__( '%1$d of %2$d users', 'radioudaan-app-api' ),
							count( $result['items'] ),
							(int) $result['total']
						)
					);
					?>
				</span>
			</form>

			<div class="ru-admin__panel-body" style="padding:0;">
				<?php if ( empty( $result['items'] ) ) : ?>
					<?php
					RadioUdaan_Admin_Components::render_empty_state(
						__( 'No app users match your filters.', 'radioudaan-app-api' ),
						array( 'icon' => 'dashicons-groups' )
					);
					?>
				<?php else : ?>
					<table class="ru-admin__table ru-admin__table--users">
						<thead>
							<tr>
								<th class="ru-admin__col-check"><span class="screen-reader-text"><?php esc_html_e( 'Select', 'radioudaan-app-api' ); ?></span></th>
								<th><?php esc_html_e( 'Name', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Email', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Mobile', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Status', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Last login', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Actions', 'radioudaan-app-api' ); ?></th>
							</tr>
						</thead>
						<tbody>
						<?php foreach ( $result['items'] as $user ) : ?>
							<tr>
								<td class="ru-admin__col-check">
									<input
										type="checkbox"
										form="ru-app-users-bulk-form"
										name="user_ids[]"
										value="<?php echo (int) $user->id; ?>"
										class="ru-app-user-checkbox"
									/>
								</td>
								<td>
									<strong>
										<a href="<?php echo esc_url( RadioUdaan_Admin_App_User_Detail::view_url( (int) $user->id ) ); ?>">
											<?php echo esc_html( $user->display_name ); ?>
										</a>
									</strong>
								</td>
								<td><?php echo esc_html( $user->email ? $user->email : '—' ); ?></td>
								<td><?php echo esc_html( self::mask_phone( $user->phone_e164 ) ); ?></td>
								<td><?php self::render_status_badge( $user->status ); ?></td>
								<td><?php echo esc_html( self::format_date( $user->last_login_at ) ); ?></td>
								<td class="ru-admin__row-actions">
									<?php self::render_row_actions( $user ); ?>
								</td>
							</tr>
						<?php endforeach; ?>
						</tbody>
					</table>
				<?php endif; ?>
			</div>

			<?php if ( (int) $result['total_pages'] > 1 ) : ?>
				<div class="ru-admin__panel-foot ru-admin__pagination">
					<?php
					$link_args = array();
					if ( '' !== $status ) {
						$link_args['status'] = $status;
					}
					if ( '' !== $search ) {
						$link_args['s'] = $search;
					}
					RadioUdaan_Admin_Components::render_pagination(
						$result,
						$base_url,
						$link_args,
						__( 'App users pagination', 'radioudaan-app-api' )
					);
					?>
				</div>
			<?php endif; ?>
		</div>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * @param array<string,int> $stats Stats.
	 */
	private static function render_stats_row( $stats ) {
		?>
		<div class="ru-admin__stats ru-admin__stats--cards">
			<?php
			RadioUdaan_Admin_Components::render_stat_card(
				__( 'Active', 'radioudaan-app-api' ),
				(string) (int) $stats['active'],
				'',
				array( 'accent' => 'success' )
			);
			RadioUdaan_Admin_Components::render_stat_card(
				__( 'Pending', 'radioudaan-app-api' ),
				(string) (int) $stats['pending'],
				'',
				array( 'accent' => 'warning' )
			);
			RadioUdaan_Admin_Components::render_stat_card(
				__( 'Paused', 'radioudaan-app-api' ),
				(string) (int) $stats['paused'],
				'',
				array( 'accent' => 'muted' )
			);
			RadioUdaan_Admin_Components::render_stat_card(
				__( 'Total', 'radioudaan-app-api' ),
				(string) (int) $stats['total'],
				'',
				array( 'accent' => 'brand' )
			);
			?>
		</div>
		<?php
	}

	/**
	 * @param object $user User row.
	 */
	private static function render_row_actions( $user ) {
		$user_id = (int) $user->id;
		$status  = (string) $user->status;
		?>
		<a href="<?php echo esc_url( RadioUdaan_Admin_App_User_Detail::view_url( $user_id ) ); ?>"><?php esc_html_e( 'View', 'radioudaan-app-api' ); ?></a>
		<?php if ( RadioUdaan_App_Users::STATUS_ACTIVE === $status ) : ?>
			<form method="post" action="<?php echo esc_url( RadioUdaan_Admin_App_User_Actions::action_url( RadioUdaan_Admin_App_User_Actions::ACTION_PAUSE, $user_id ) ); ?>" class="ru-inline-action-form ru-danger-action-form" data-ru-confirm-word="PAUSE">
				<?php wp_nonce_field( RadioUdaan_Admin_App_User_Actions::nonce_field_name( $user_id ) ); ?>
				<button type="submit" class="ru-link-button"><?php esc_html_e( 'Pause', 'radioudaan-app-api' ); ?></button>
			</form>
		<?php elseif ( RadioUdaan_App_Users::STATUS_PAUSED === $status ) : ?>
			<form method="post" action="<?php echo esc_url( RadioUdaan_Admin_App_User_Actions::action_url( RadioUdaan_Admin_App_User_Actions::ACTION_RESUME, $user_id ) ); ?>" class="ru-inline-action-form">
				<?php wp_nonce_field( RadioUdaan_Admin_App_User_Actions::nonce_field_name( $user_id ) ); ?>
				<button type="submit" class="ru-link-button"><?php esc_html_e( 'Resume', 'radioudaan-app-api' ); ?></button>
			</form>
		<?php endif; ?>
		<form method="post" action="<?php echo esc_url( RadioUdaan_Admin_App_User_Actions::action_url( RadioUdaan_Admin_App_User_Actions::ACTION_DELETE, $user_id ) ); ?>" class="ru-inline-action-form ru-danger-action-form" data-ru-confirm-word="DELETE">
			<?php wp_nonce_field( RadioUdaan_Admin_App_User_Actions::nonce_field_name( $user_id ) ); ?>
			<button type="submit" class="ru-link-button ru-link-button--danger"><?php esc_html_e( 'Delete', 'radioudaan-app-api' ); ?></button>
		</form>
		<a href="<?php echo esc_url( RadioUdaan_Admin_Notifications::notify_user_url( $user_id ) ); ?>"><?php esc_html_e( 'Notify', 'radioudaan-app-api' ); ?></a>
		<?php
	}

	/**
	 * @param string $status Status slug.
	 */
	public static function render_status_badge( $status ) {
		$status = sanitize_key( (string) $status );
		$map    = array(
			RadioUdaan_App_Users::STATUS_ACTIVE  => array( 'user-active', __( 'Active', 'radioudaan-app-api' ) ),
			RadioUdaan_App_Users::STATUS_PENDING => array( 'user-pending', __( 'Pending', 'radioudaan-app-api' ) ),
			RadioUdaan_App_Users::STATUS_PAUSED  => array( 'user-paused', __( 'Paused', 'radioudaan-app-api' ) ),
			RadioUdaan_App_Users::STATUS_DELETED => array( 'user-deleted', __( 'Deleted', 'radioudaan-app-api' ) ),
		);

		$meta = isset( $map[ $status ] ) ? $map[ $status ] : array( 'off', $status );
		RadioUdaan_Admin_Components::render_badge( $meta[1], $meta[0] );
	}

	/**
	 * Mask phone — show last 4 digits only.
	 *
	 * @param string $phone E.164 or partial phone.
	 * @return string
	 */
	public static function mask_phone( $phone ) {
		$phone = preg_replace( '/\s+/', '', (string) $phone );
		if ( '' === $phone ) {
			return '—';
		}
		if ( strlen( $phone ) < 4 ) {
			return '****';
		}
		return '****' . substr( $phone, -4 );
	}

	/**
	 * @param string $mysql_datetime GMT datetime.
	 * @return string
	 */
	public static function format_date( $mysql_datetime ) {
		if ( ! $mysql_datetime ) {
			return '—';
		}
		$ts = strtotime( $mysql_datetime );
		if ( ! $ts ) {
			return $mysql_datetime;
		}
		return wp_date( 'j M Y, g:i a', $ts );
	}
}

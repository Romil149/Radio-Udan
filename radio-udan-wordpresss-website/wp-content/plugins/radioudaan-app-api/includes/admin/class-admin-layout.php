<?php
/**
 * Admin layout shell (header, nav, notices).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Shared UI chrome for the mobile app admin dashboard.
 */
class RadioUdaan_Admin_Layout {

	/**
	 * @param string $active Active nav slug.
	 * @param string $title  Page title (optional override).
	 */
	public static function render_open( $active, $title = '' ) {
		$nav = self::get_nav_items();
		?>
		<div class="ru-admin ru-admin--branded<?php echo 'settings' === $active ? ' ru-admin--settings' : ''; ?>">
			<header class="ru-admin__header">
				<div class="ru-admin__header-top">
					<div class="ru-admin__brand">
						<div class="ru-admin__logo" aria-hidden="true">
							<span class="dashicons dashicons-smartphone"></span>
						</div>
						<div>
							<h1 class="ru-admin__title"><?php esc_html_e( 'Radio Udaan Mobile App', 'radioudaan-app-api' ); ?></h1>
							<p class="ru-admin__subtitle"><?php esc_html_e( 'Manage events, app users, donations, and login settings', 'radioudaan-app-api' ); ?></p>
						</div>
					</div>
					<div class="ru-admin__header-actions">
						<form method="get" action="<?php echo esc_url( admin_url( 'admin.php' ) ); ?>" class="ru-admin__global-search" role="search">
							<input type="hidden" name="page" value="<?php echo esc_attr( isset( $_GET['page'] ) ? sanitize_key( wp_unslash( $_GET['page'] ) ) : RadioUdaan_Admin_App_Hub::MENU_SLUG ); ?>" />
							<label class="screen-reader-text" for="ru-global-search"><?php esc_html_e( 'Search app users and events', 'radioudaan-app-api' ); ?></label>
							<input
								type="search"
								name="ru_global_search"
								id="ru-global-search"
								class="ru-admin__search-input"
								value=""
								placeholder="<?php esc_attr_e( 'Search users or events…', 'radioudaan-app-api' ); ?>"
								autocomplete="off"
							/>
							<button type="submit" class="button"><?php esc_html_e( 'Search', 'radioudaan-app-api' ); ?></button>
						</form>
						<a href="<?php echo esc_url( RadioUdaan_Admin_Event_Editor::edit_url( 0 ) ); ?>" class="button ru-btn-large">
							<span class="dashicons dashicons-plus-alt2" style="margin-top:3px;"></span>
							<?php esc_html_e( 'Add new event', 'radioudaan-app-api' ); ?>
						</a>
					</div>
				</div>
				<nav class="ru-admin__nav" aria-label="<?php esc_attr_e( 'App admin sections', 'radioudaan-app-api' ); ?>">
					<?php foreach ( $nav as $slug => $item ) : ?>
						<a href="<?php echo esc_url( $item['url'] ); ?>" class="<?php echo $active === $slug ? 'is-active' : ''; ?>">
							<span class="dashicons <?php echo esc_attr( $item['icon'] ); ?>"></span>
							<?php echo esc_html( $item['label'] ); ?>
						</a>
					<?php endforeach; ?>
				</nav>
			</header>
		<?php
		self::render_notices();

		if ( $title ) {
			echo '<h2 class="screen-reader-text">' . esc_html( $title ) . '</h2>';
		}
	}

	/**
	 * Close layout wrapper.
	 */
	public static function render_close() {
		echo '</div>';
	}

	/**
	 * Admin notices from query args.
	 */
	public static function render_notices() {
		$notice = isset( $_GET['radioudaan_notice'] ) ? sanitize_text_field( wp_unslash( $_GET['radioudaan_notice'] ) ) : '';
		$detail = isset( $_GET['radioudaan_detail'] ) ? sanitize_text_field( wp_unslash( $_GET['radioudaan_detail'] ) ) : '';

		if ( isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'] ) {
			$notice = 'success';
			$detail = __( 'Settings saved successfully.', 'radioudaan-app-api' );
		}

		if ( ! $notice || ! $detail ) {
			return;
		}

		$detail = rawurldecode( $detail );
		if ( 'error' === $notice ) {
			$class = 'notice-error';
		} elseif ( 'warning' === $notice ) {
			$class = 'notice-warning';
		} else {
			$class = 'notice-success';
		}
		?>
		<div class="ru-admin__notice notice <?php echo esc_attr( $class ); ?> is-dismissible" role="status" aria-live="polite">
			<p class="ru-notice-text"><?php echo esc_html( $detail ); ?></p>
		</div>
		<?php
	}

	/**
	 * @return array<string,array{label:string,url:string,icon:string}>
	 */
	public static function get_nav_items() {
		return array(
			'dashboard'      => array(
				'label' => __( 'Dashboard', 'radioudaan-app-api' ),
				'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::MENU_SLUG ),
				'icon'  => 'dashicons-dashboard',
			),
			'events'         => array(
				'label' => __( 'Events', 'radioudaan-app-api' ),
				'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENTS_SLUG ),
				'icon'  => 'dashicons-calendar-alt',
			),
			'registrations'  => array(
				'label' => __( 'App users', 'radioudaan-app-api' ),
				'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::APP_USERS_SLUG ),
				'icon'  => 'dashicons-groups',
			),
			'event-entries'  => array(
				'label' => __( 'Event entries', 'radioudaan-app-api' ),
				'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENT_ENTRIES_SLUG ),
				'icon'  => 'dashicons-id-alt',
			),
			'notifications'  => array(
				'label' => __( 'Send notification', 'radioudaan-app-api' ),
				'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::NOTIFICATIONS_SLUG ),
				'icon'  => 'dashicons-bell',
			),
			'donations'      => array(
				'label' => __( 'Donations', 'radioudaan-app-api' ),
				'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::DONATIONS_SLUG ),
				'icon'  => 'dashicons-money-alt',
			),
			'settings'       => array(
				'label' => __( 'Settings', 'radioudaan-app-api' ),
				'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::SETTINGS_SLUG ),
				'icon'  => 'dashicons-admin-settings',
			),
			'help'           => array(
				'label' => __( 'Help', 'radioudaan-app-api' ),
				'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::HELP_SLUG ),
				'icon'  => 'dashicons-editor-help',
			),
			'tools'          => array(
				'label' => __( 'Advanced', 'radioudaan-app-api' ),
				'url'   => admin_url( 'admin.php?page=radioudaan-form-migration' ),
				'icon'  => 'dashicons-admin-tools',
			),
			'api'            => array(
				'label' => __( 'API', 'radioudaan-app-api' ),
				'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::API_SLUG ),
				'icon'  => 'dashicons-rest-api',
			),
		);
	}

	/**
	 * Optional intro banner below the header nav.
	 *
	 * @param string $html    Sanitized HTML message.
	 * @param string $variant info|warning.
	 */
	public static function render_page_intro( $html, $variant = 'info' ) {
		$class = 'ru-page-intro';
		if ( 'warning' === $variant ) {
			$class .= ' ru-page-intro--warning';
		}
		echo '<div class="' . esc_attr( $class ) . '">' . wp_kses_post( $html ) . '</div>';
	}
}

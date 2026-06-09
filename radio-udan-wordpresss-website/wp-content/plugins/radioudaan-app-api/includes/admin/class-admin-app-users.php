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

	/**
	 * Render page.
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$users = RadioUdaan_App_Users::list_users( 200 );

		RadioUdaan_Admin_Layout::render_open( 'registrations', __( 'Registrations', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'App login', 'radioudaan-app-api' ) . '</strong> — ' .
			esc_html__( 'App accounts (password + OTP). This is not the same as event form entries.', 'radioudaan-app-api' )
		);
		?>
		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'People registered on the app', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body" style="padding:0;">
				<?php if ( empty( $users ) ) : ?>
					<div class="ru-admin__empty">
						<p><?php esc_html_e( 'No app users yet. They appear here after registration or login on the mobile app.', 'radioudaan-app-api' ); ?></p>
					</div>
				<?php else : ?>
					<table class="ru-admin__table">
						<thead>
							<tr>
								<th><?php esc_html_e( 'Name', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Email', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Mobile', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Status', 'radioudaan-app-api' ); ?></th>
								<th><?php esc_html_e( 'Last login', 'radioudaan-app-api' ); ?></th>
							</tr>
						</thead>
						<tbody>
						<?php foreach ( $users as $user ) : ?>
							<tr>
								<td><strong><?php echo esc_html( $user->display_name ); ?></strong></td>
								<td><?php echo esc_html( $user->email ); ?></td>
								<td><?php echo esc_html( $user->phone_e164 ); ?></td>
								<td><?php echo esc_html( $user->status ); ?></td>
								<td><?php echo esc_html( self::format_date( $user->last_login_at ) ); ?></td>
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
	 * @param string $mysql_datetime GMT datetime.
	 * @return string
	 */
	private static function format_date( $mysql_datetime ) {
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

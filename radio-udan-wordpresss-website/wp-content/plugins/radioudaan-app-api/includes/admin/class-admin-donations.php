<?php
/**
 * Admin list for online donations.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Donations admin screen.
 */
class RadioUdaan_Admin_Donations {

	const PAGE_SLUG = 'radioudaan-app-donations';

	/**
	 * @return void
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'You do not have permission to view donations.', 'radioudaan-app-api' ) );
		}

		if ( isset( $_GET['resend_receipt'], $_GET['donation_id'] ) && check_admin_referer( 'radioudaan_resend_receipt_' . (int) $_GET['donation_id'] ) ) {
			$donation = RadioUdaan_App_Donations_Db::get_by_id( (int) $_GET['donation_id'] );
			if ( $donation ) {
				global $wpdb;
				$wpdb->update(
					RadioUdaan_App_Donations_Db::table(),
					array( 'receipt_sent_at' => null ),
					array( 'id' => (int) $donation->id ),
					array( '%s' ),
					array( '%d' )
				);
				$donation = RadioUdaan_App_Donations_Db::get_by_id( (int) $donation->id );
				if ( RadioUdaan_App_Donations_80g_Pdf::send_receipt_email( $donation ) ) {
					RadioUdaan_App_Donations_Db::mark_receipt_sent( (int) $donation->id );
				}
				echo '<div class="notice notice-success is-dismissible"><p>' . esc_html__( 'Receipt email sent.', 'radioudaan-app-api' ) . '</p></div>';
			}
		}

		$rows = RadioUdaan_App_Donations_Db::list_recent( 100 );

		if ( isset( $_GET['export'] ) && 'csv' === $_GET['export'] && check_admin_referer( 'radioudaan_export_donations' ) ) {
			self::export_csv( $rows );
			return;
		}

		?>
		<div class="wrap">
			<h1><?php esc_html_e( 'Donations', 'radioudaan-app-api' ); ?></h1>
			<p class="description"><?php esc_html_e( 'Online donations via Razorpay from the mobile app.', 'radioudaan-app-api' ); ?></p>
			<p>
				<a class="button" href="<?php echo esc_url( wp_nonce_url( admin_url( 'admin.php?page=' . self::PAGE_SLUG . '&export=csv' ), 'radioudaan_export_donations' ) ); ?>">
					<?php esc_html_e( 'Export CSV', 'radioudaan-app-api' ); ?>
				</a>
			</p>
			<table class="widefat striped">
				<thead>
					<tr>
						<th><?php esc_html_e( 'Date', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'Donor', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'Amount', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'Status', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( '80G', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'PAN', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'Payment ID', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'Actions', 'radioudaan-app-api' ); ?></th>
					</tr>
				</thead>
				<tbody>
				<?php if ( empty( $rows ) ) : ?>
					<tr><td colspan="8"><?php esc_html_e( 'No donations yet.', 'radioudaan-app-api' ); ?></td></tr>
				<?php else : ?>
					<?php foreach ( $rows as $row ) : ?>
						<tr>
							<td><?php echo esc_html( mysql2date( 'Y-m-d H:i', (string) $row->created_at ) ); ?></td>
							<td>
								<?php echo esc_html( (string) ( $row->donor_name ?? '' ) ); ?><br />
								<small><?php echo esc_html( (string) ( $row->email ?? '' ) ); ?></small>
							</td>
							<td>₹<?php echo esc_html( number_format_i18n( ( (int) $row->amount_paise ) / 100, 2 ) ); ?></td>
							<td><?php echo esc_html( (string) $row->status ); ?></td>
							<td><?php echo ! empty( $row->want_80g ) ? esc_html__( 'Yes', 'radioudaan-app-api' ) : '—'; ?></td>
							<td>
								<?php
								if ( ! empty( $row->want_80g ) && ! empty( $row->pan_encrypted ) ) {
									$pan = RadioUdaan_App_Donations_Settings::decrypt_pan( (string) $row->pan_encrypted );
									echo esc_html( RadioUdaan_App_Donations_Settings::mask_pan( $pan ) );
								} else {
									echo '—';
								}
								?>
							</td>
							<td><code><?php echo esc_html( (string) ( $row->razorpay_payment_id ?? '' ) ); ?></code></td>
							<td>
								<?php if ( ! empty( $row->want_80g ) && ! empty( $row->email ) ) : ?>
									<a href="<?php echo esc_url( wp_nonce_url( admin_url( 'admin.php?page=' . self::PAGE_SLUG . '&resend_receipt=1&donation_id=' . (int) $row->id ), 'radioudaan_resend_receipt_' . (int) $row->id ) ); ?>">
										<?php esc_html_e( 'Resend receipt', 'radioudaan-app-api' ); ?>
									</a>
								<?php else : ?>
									—
								<?php endif; ?>
							</td>
						</tr>
					<?php endforeach; ?>
				<?php endif; ?>
				</tbody>
			</table>
		</div>
		<?php
	}

	/**
	 * @param array<int,object> $rows Donation rows.
	 * @return void
	 */
	private static function export_csv( array $rows ) {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'You do not have permission to export donations.', 'radioudaan-app-api' ) );
		}

		$filename = 'radio-udaan-donations-' . gmdate( 'Y-m-d' ) . '.csv';
		header( 'Content-Type: text/csv; charset=utf-8' );
		header( 'Content-Disposition: attachment; filename=' . $filename );
		$out = fopen( 'php://output', 'w' );
		if ( false === $out ) {
			return;
		}
		fputcsv(
			$out,
			array( 'Date', 'Donor', 'Email', 'Phone', 'Amount INR', 'Status', '80G', 'PAN masked', 'Order ID', 'Payment ID' )
		);
		foreach ( $rows as $row ) {
			$pan_masked = '';
			if ( ! empty( $row->want_80g ) && ! empty( $row->pan_encrypted ) ) {
				$pan_masked = RadioUdaan_App_Donations_Settings::mask_pan(
					RadioUdaan_App_Donations_Settings::decrypt_pan( (string) $row->pan_encrypted )
				);
			}
			fputcsv(
				$out,
				array(
					(string) $row->created_at,
					(string) ( $row->donor_name ?? '' ),
					(string) ( $row->email ?? '' ),
					(string) ( $row->phone ?? '' ),
					number_format( ( (int) $row->amount_paise ) / 100, 2, '.', '' ),
					(string) $row->status,
					! empty( $row->want_80g ) ? 'yes' : 'no',
					$pan_masked,
					(string) ( $row->razorpay_order_id ?? '' ),
					(string) ( $row->razorpay_payment_id ?? '' ),
				)
			);
		}
		fclose( $out );
		exit;
	}
}

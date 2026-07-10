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
	const PER_PAGE  = 25;

	/**
	 * @return void
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'You do not have permission to view donations.', 'radioudaan-app-api' ) );
		}

		if ( isset( $_GET['resend_receipt'], $_GET['donation_id'] ) && check_admin_referer( 'radioudaan_resend_receipt_' . (int) $_GET['donation_id'] ) ) {
			self::handle_resend_receipt( (int) $_GET['donation_id'] );
			return;
		}

		$status = isset( $_GET['status'] ) ? sanitize_key( wp_unslash( $_GET['status'] ) ) : '';
		$search = isset( $_GET['s'] ) ? trim( sanitize_text_field( wp_unslash( $_GET['s'] ) ) ) : '';
		$page   = isset( $_GET['paged'] ) ? max( 1, (int) $_GET['paged'] ) : 1;

		$allowed_statuses = array(
			RadioUdaan_App_Donations_Db::STATUS_CREATED,
			RadioUdaan_App_Donations_Db::STATUS_CAPTURED,
			RadioUdaan_App_Donations_Db::STATUS_FAILED,
		);
		if ( '' !== $status && ! in_array( $status, $allowed_statuses, true ) ) {
			$status = '';
		}

		$result = RadioUdaan_App_Donations_Db::list_paginated(
			array(
				'page'     => $page,
				'per_page' => self::PER_PAGE,
				'status'   => $status,
				'search'   => $search,
			)
		);

		if ( isset( $_GET['export'] ) && 'csv' === $_GET['export'] && check_admin_referer( 'radioudaan_export_donations' ) ) {
			$export_rows = RadioUdaan_App_Donations_Db::list_paginated(
				array(
					'page'     => 1,
					'per_page' => 500,
					'status'   => $status,
					'search'   => $search,
				)
			)['items'];
			self::export_csv( $export_rows );
			return;
		}

		$stats    = RadioUdaan_App_Donations_Db::get_admin_stats();
		$base_url = admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::DONATIONS_SLUG );

		RadioUdaan_Admin_Layout::render_open( 'donations', __( 'Donations', 'radioudaan-app-api' ) );

		RadioUdaan_Admin_Components::render_breadcrumb(
			array(
				array(
					'label' => __( 'Dashboard', 'radioudaan-app-api' ),
					'url'   => admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::MENU_SLUG ),
				),
				array(
					'label' => __( 'Donations', 'radioudaan-app-api' ),
				),
			)
		);

		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'Online donations', 'radioudaan-app-api' ) . '</strong> — ' .
			esc_html__( 'Razorpay payments from the mobile app. Donors link to an app user when the phone number matches.', 'radioudaan-app-api' )
		);

		self::render_stats_row( $stats );
		?>
		<form method="get" action="<?php echo esc_url( admin_url( 'admin.php' ) ); ?>" class="ru-admin__toolbar">
			<input type="hidden" name="page" value="<?php echo esc_attr( RadioUdaan_Admin_App_Hub::DONATIONS_SLUG ); ?>" />
			<?php if ( '' !== $status ) : ?>
				<input type="hidden" name="status" value="<?php echo esc_attr( $status ); ?>" />
			<?php endif; ?>
			<label class="screen-reader-text" for="ru-donations-search"><?php esc_html_e( 'Search donations', 'radioudaan-app-api' ); ?></label>
			<input type="search" id="ru-donations-search" name="s" class="ru-admin__search-input" value="<?php echo esc_attr( $search ); ?>" placeholder="<?php esc_attr_e( 'Search donor, email, phone, payment ID…', 'radioudaan-app-api' ); ?>" />
			<button type="submit" class="button"><?php esc_html_e( 'Search', 'radioudaan-app-api' ); ?></button>
			<?php if ( '' !== $search ) : ?>
				<a href="<?php echo esc_url( '' !== $status ? add_query_arg( 'status', $status, $base_url ) : $base_url ); ?>" class="button"><?php esc_html_e( 'Clear', 'radioudaan-app-api' ); ?></a>
			<?php endif; ?>
		</form>

		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Donations', 'radioudaan-app-api' ); ?></h2>
				<nav class="ru-filter-tabs" aria-label="<?php esc_attr_e( 'Filter by status', 'radioudaan-app-api' ); ?>">
					<?php
					$tabs = array(
						''        => __( 'All', 'radioudaan-app-api' ),
						'captured' => __( 'Captured', 'radioudaan-app-api' ),
						'created' => __( 'Pending', 'radioudaan-app-api' ),
						'failed'  => __( 'Failed', 'radioudaan-app-api' ),
					);
					foreach ( $tabs as $tab_key => $tab_label ) :
						$tab_args = array();
						if ( '' !== $tab_key ) {
							$tab_args['status'] = $tab_key;
						}
						if ( '' !== $search ) {
							$tab_args['s'] = $search;
						}
						?>
						<a href="<?php echo esc_url( add_query_arg( $tab_args, $base_url ) ); ?>" class="ru-filter-tabs__link <?php echo $status === $tab_key ? 'is-active' : ''; ?>">
							<?php echo esc_html( $tab_label ); ?>
						</a>
					<?php endforeach; ?>
					<a href="<?php echo esc_url( wp_nonce_url( add_query_arg( array_filter( array( 'export' => 'csv', 'status' => $status, 's' => $search ) ), $base_url ), 'radioudaan_export_donations' ) ); ?>" class="ru-filter-tabs__link">
						<?php esc_html_e( 'Export CSV', 'radioudaan-app-api' ); ?>
					</a>
				</nav>
			</div>
			<div class="ru-admin__bulk-bar">
				<span class="ru-admin__result-count">
					<?php
					echo esc_html(
						sprintf(
							/* translators: 1: showing count, 2: total count */
							__( '%1$d of %2$d donations', 'radioudaan-app-api' ),
							count( $result['items'] ),
							(int) $result['total']
						)
					);
					?>
				</span>
			</div>
			<div class="ru-admin__panel-body" style="padding:0;">
				<?php self::render_table( $result['items'], $base_url ); ?>
			</div>
			<?php if ( $result['total_pages'] > 1 ) : ?>
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
						__( 'Donations pagination', 'radioudaan-app-api' )
					);
					?>
				</div>
			<?php endif; ?>
		</div>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * @param array<string,int|float> $stats Stats.
	 */
	private static function render_stats_row( $stats ) {
		$settings_url = admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::SETTINGS_SLUG . '&tab=donate' );
		?>
		<div class="ru-admin__stats ru-admin__stats--cards">
			<?php
			RadioUdaan_Admin_Components::render_stat_card(
				__( 'Captured', 'radioudaan-app-api' ),
				(string) (int) $stats['captured'],
				'₹' . number_format_i18n( (float) $stats['captured_amount_inr'], 2 ),
				array( 'accent' => 'success' )
			);
			RadioUdaan_Admin_Components::render_stat_card(
				__( 'Pending', 'radioudaan-app-api' ),
				(string) (int) $stats['pending'],
				__( 'Awaiting payment', 'radioudaan-app-api' ),
				array( 'accent' => 'warning' )
			);
			RadioUdaan_Admin_Components::render_stat_card(
				__( 'Failed', 'radioudaan-app-api' ),
				(string) (int) $stats['failed'],
				'',
				array( 'accent' => 'danger' )
			);
			RadioUdaan_Admin_Components::render_stat_card(
				__( '80G receipts', 'radioudaan-app-api' ),
				(string) (int) $stats['with_80g'],
				'<a href="' . esc_url( $settings_url ) . '">' . esc_html__( 'Donation settings', 'radioudaan-app-api' ) . '</a>',
				array( 'accent' => 'brand' )
			);
			?>
		</div>
		<?php
	}

	/**
	 * @param array<int,object> $rows     Rows.
	 * @param string          $base_url List base URL.
	 */
	private static function render_table( array $rows, $base_url ) {
		if ( empty( $rows ) ) {
			RadioUdaan_Admin_Components::render_empty_state(
				__( 'No donations match your filters.', 'radioudaan-app-api' ),
				array( 'icon' => 'dashicons-money-alt' )
			);
			return;
		}
		?>
		<table class="ru-admin__table">
			<thead>
				<tr>
					<th><?php esc_html_e( 'Date', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( 'Donor', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( 'App user', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( 'Amount', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( 'Status', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( '80G', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( 'PAN', 'radioudaan-app-api' ); ?></th>
					<th><?php esc_html_e( 'Actions', 'radioudaan-app-api' ); ?></th>
				</tr>
			</thead>
			<tbody>
			<?php foreach ( $rows as $row ) : ?>
				<?php $app_user = self::resolve_app_user( $row ); ?>
				<tr>
					<td><?php echo esc_html( mysql2date( 'Y-m-d H:i', (string) $row->created_at ) ); ?></td>
					<td>
						<strong><?php echo esc_html( (string) ( $row->donor_name ?? '' ) ); ?></strong><br />
						<small><?php echo esc_html( (string) ( $row->email ?? '' ) ); ?></small>
						<?php if ( ! empty( $row->phone ) ) : ?>
							<br /><small><?php echo esc_html( (string) $row->phone ); ?></small>
						<?php endif; ?>
					</td>
					<td>
						<?php if ( $app_user ) : ?>
							<a href="<?php echo esc_url( RadioUdaan_Admin_App_User_Detail::view_url( (int) $app_user->id ) ); ?>">
								<?php echo esc_html( $app_user->display_name ); ?>
							</a>
						<?php else : ?>
							—
						<?php endif; ?>
					</td>
					<td>₹<?php echo esc_html( number_format_i18n( ( (int) $row->amount_paise ) / 100, 2 ) ); ?></td>
					<td><?php self::render_status_badge( (string) $row->status ); ?></td>
					<td>
						<?php
						if ( ! empty( $row->want_80g ) ) {
							RadioUdaan_Admin_Components::render_badge( __( 'Yes', 'radioudaan-app-api' ), 'open' );
						} else {
							echo '—';
						}
						?>
					</td>
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
					<td>
						<?php if ( ! empty( $row->want_80g ) && ! empty( $row->email ) && RadioUdaan_App_Donations_Db::STATUS_CAPTURED === (string) $row->status ) : ?>
							<a class="button button-small" href="<?php echo esc_url( wp_nonce_url( add_query_arg( array( 'resend_receipt' => 1, 'donation_id' => (int) $row->id ), $base_url ), 'radioudaan_resend_receipt_' . (int) $row->id ) ); ?>">
								<?php esc_html_e( 'Resend receipt', 'radioudaan-app-api' ); ?>
							</a>
						<?php else : ?>
							—
						<?php endif; ?>
					</td>
				</tr>
			<?php endforeach; ?>
			</tbody>
		</table>
		<?php
	}

	/**
	 * @param object $row Donation row.
	 * @return object|null
	 */
	private static function resolve_app_user( $row ) {
		if ( ! empty( $row->user_id ) ) {
			$user = RadioUdaan_App_Users::get_by_id( (int) $row->user_id );
			if ( $user && RadioUdaan_App_Users::STATUS_DELETED !== $user->status ) {
				return $user;
			}
		}

		$phone = isset( $row->phone ) ? trim( (string) $row->phone ) : '';
		if ( '' === $phone ) {
			return null;
		}

		$user = RadioUdaan_App_Users::find_by_phone( $phone );
		if ( $user ) {
			return $user;
		}

		if ( preg_match( '/^\d{10}$/', $phone ) ) {
			return RadioUdaan_App_Users::find_by_phone( '+91' . $phone );
		}

		return null;
	}

	/**
	 * @param string $status Donation status.
	 */
	private static function render_status_badge( $status ) {
		$map = array(
			RadioUdaan_App_Donations_Db::STATUS_CAPTURED => array( 'open', __( 'Captured', 'radioudaan-app-api' ) ),
			RadioUdaan_App_Donations_Db::STATUS_FAILED   => array( 'closed', __( 'Failed', 'radioudaan-app-api' ) ),
			RadioUdaan_App_Donations_Db::STATUS_CREATED  => array( 'draft', __( 'Pending', 'radioudaan-app-api' ) ),
		);

		$meta = isset( $map[ $status ] ) ? $map[ $status ] : array( 'off', $status );
		RadioUdaan_Admin_Components::render_badge( $meta[1], $meta[0] );
	}

	/**
	 * @param int $donation_id Donation id.
	 * @return void
	 */
	private static function handle_resend_receipt( $donation_id ) {
		$donation = RadioUdaan_App_Donations_Db::get_by_id( $donation_id );

		if ( $donation && RadioUdaan_App_Donations_Db::STATUS_CAPTURED === (string) $donation->status ) {
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
			$notice = 'success';
			$detail = __( 'Receipt email sent.', 'radioudaan-app-api' );
		} elseif ( $donation ) {
			$notice = 'error';
			$detail = __( 'Receipt can only be resent for captured donations.', 'radioudaan-app-api' );
		} else {
			$notice = 'error';
			$detail = __( 'Donation not found.', 'radioudaan-app-api' );
		}

		wp_safe_redirect(
			add_query_arg(
				array(
					'page'              => RadioUdaan_Admin_App_Hub::DONATIONS_SLUG,
					'radioudaan_notice' => $notice,
					'radioudaan_detail' => rawurlencode( $detail ),
				),
				admin_url( 'admin.php' )
			)
		);
		exit;
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
			array( 'Date', 'Donor', 'Email', 'Phone', 'App user ID', 'Amount INR', 'Status', '80G', 'PAN masked', 'Order ID', 'Payment ID' )
		);
		foreach ( $rows as $row ) {
			$pan_masked = '';
			if ( ! empty( $row->want_80g ) && ! empty( $row->pan_encrypted ) ) {
				$pan_masked = RadioUdaan_App_Donations_Settings::mask_pan(
					RadioUdaan_App_Donations_Settings::decrypt_pan( (string) $row->pan_encrypted )
				);
			}
			$app_user = self::resolve_app_user( $row );
			fputcsv(
				$out,
				array(
					(string) $row->created_at,
					(string) ( $row->donor_name ?? '' ),
					(string) ( $row->email ?? '' ),
					(string) ( $row->phone ?? '' ),
					$app_user ? (int) $app_user->id : '',
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

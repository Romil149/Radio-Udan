<?php
/**
 * Per-tab settings test actions (FCM, MSG91 placeholder, API health).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Admin-post handlers for settings diagnostics.
 */
class RadioUdaan_Admin_Settings_Tests {

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'admin_post_radioudaan_test_fcm', array( __CLASS__, 'handle_test_fcm' ) );
		add_action( 'admin_post_radioudaan_test_msg91', array( __CLASS__, 'handle_test_msg91' ) );
	}

	/**
	 * Verify Firebase service account OAuth from Settings → Notifications.
	 */
	public static function handle_test_fcm() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( 'radioudaan_test_fcm' );

		$tab     = isset( $_POST['radioudaan_active_tab'] ) ? sanitize_key( wp_unslash( $_POST['radioudaan_active_tab'] ) ) : 'notifications';
		$notice  = 'error';
		$detail  = __( 'FCM is not configured. Paste the Firebase service account JSON first.', 'radioudaan-app-api' );

		if ( RadioUdaan_App_Fcm_Sender::is_configured() ) {
			$oauth = RadioUdaan_App_Fcm_Sender::verify_oauth_connection();
			if ( is_wp_error( $oauth ) ) {
				$detail = sprintf(
					/* translators: %s: error message */
					__( 'FCM OAuth failed: %s', 'radioudaan-app-api' ),
					$oauth->get_error_message()
				);
			} else {
				$notice = 'success';
				$detail = __( 'FCM HTTP v1 credentials are valid. OAuth token acquired successfully.', 'radioudaan-app-api' );
			}
		}

		wp_safe_redirect(
			add_query_arg(
				array(
					'page'              => RadioUdaan_Admin_App_Hub::SETTINGS_SLUG,
					'tab'               => $tab,
					'radioudaan_notice' => $notice,
					'radioudaan_detail' => rawurlencode( $detail ),
				),
				admin_url( 'admin.php' )
			)
		);
		exit;
	}

	/**
	 * Placeholder — MSG91 test SMS is not sent from wp-admin.
	 */
	public static function handle_test_msg91() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( 'radioudaan_test_msg91' );

		$tab = isset( $_POST['radioudaan_active_tab'] ) ? sanitize_key( wp_unslash( $_POST['radioudaan_active_tab'] ) ) : 'sms';

		if ( RadioUdaan_App_Settings::is_dev_otp_enabled() ) {
			$detail = __( 'Development OTP is on — the app uses fixed code 123456 instead of MSG91.', 'radioudaan-app-api' );
			$notice = 'warning';
		} elseif ( defined( 'RADIOUDAAN_MSG91_AUTH_KEY' ) || '' !== trim( (string) get_option( 'radioudaan_msg91_auth_key', '' ) ) ) {
			$detail = __( 'MSG91 credentials are saved. Test SMS from wp-admin is not available yet — trigger OTP from the mobile app or use staging dev OTP.', 'radioudaan-app-api' );
			$notice = 'success';
		} else {
			$detail = __( 'MSG91 auth key is empty. Add credentials under SMS (MSG91) before production.', 'radioudaan-app-api' );
			$notice = 'error';
		}

		wp_safe_redirect(
			add_query_arg(
				array(
					'page'              => RadioUdaan_Admin_App_Hub::SETTINGS_SLUG,
					'tab'               => $tab,
					'radioudaan_notice' => $notice,
					'radioudaan_detail' => rawurlencode( $detail ),
				),
				admin_url( 'admin.php' )
			)
		);
		exit;
	}

	/**
	 * Render a test button that posts to admin-post.php.
	 *
	 * @param string $action Nonce action slug.
	 * @param string $label  Button label.
	 * @param string $tab    Settings tab slug.
	 */
	public static function render_test_button( $action, $label, $tab ) {
		?>
		<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" class="ru-settings-test-form" style="margin-top:12px;">
			<?php wp_nonce_field( $action ); ?>
			<input type="hidden" name="action" value="<?php echo esc_attr( $action ); ?>" />
			<input type="hidden" name="radioudaan_active_tab" value="<?php echo esc_attr( $tab ); ?>" />
			<button type="submit" class="button button-secondary"><?php echo esc_html( $label ); ?></button>
		</form>
		<?php
	}
}

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
	 * Deferred standalone test forms (must not nest inside the main settings form).
	 *
	 * @var array<int,array{action:string,label:string,tab:string,form_id:string}>
	 */
	private static $deferred_forms = array();

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
	 * Render a test submit control associated with a deferred standalone form.
	 *
	 * Nested <form> inside the main settings form is invalid HTML: browsers ignore the
	 * inner start tag then treat </form> as closing the outer form, which orphans the
	 * Save button (appears to do nothing).
	 *
	 * @param string $action Nonce action slug.
	 * @param string $label  Button label.
	 * @param string $tab    Settings tab slug.
	 */
	public static function render_test_button( $action, $label, $tab ) {
		$form_id = 'ru-settings-test-' . sanitize_html_class( $action );
		self::$deferred_forms[] = array(
			'action'  => (string) $action,
			'label'   => (string) $label,
			'tab'     => (string) $tab,
			'form_id' => $form_id,
		);
		?>
		<p class="ru-settings-test-actions" style="margin-top:12px;">
			<button type="submit" class="button button-secondary" form="<?php echo esc_attr( $form_id ); ?>">
				<?php echo esc_html( $label ); ?>
			</button>
		</p>
		<?php
	}

	/**
	 * Print standalone test forms after the main settings </form>.
	 */
	public static function render_deferred_forms() {
		if ( empty( self::$deferred_forms ) ) {
			return;
		}

		foreach ( self::$deferred_forms as $item ) {
			?>
			<form
				method="post"
				action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>"
				id="<?php echo esc_attr( $item['form_id'] ); ?>"
				class="ru-settings-test-form"
				hidden
			>
				<?php wp_nonce_field( $item['action'] ); ?>
				<input type="hidden" name="action" value="<?php echo esc_attr( $item['action'] ); ?>" />
				<input type="hidden" name="radioudaan_active_tab" value="<?php echo esc_attr( $item['tab'] ); ?>" />
			</form>
			<?php
		}

		self::$deferred_forms = array();
	}
}

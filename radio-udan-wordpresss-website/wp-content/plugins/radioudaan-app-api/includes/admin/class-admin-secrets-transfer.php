<?php
/**
 * Export / import app API keys & connection options between sites.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Admin tool to move secrets from staging → production without retyping.
 */
class RadioUdaan_Admin_Secrets_Transfer {

	const PAGE_SLUG          = 'radioudaan-app-secrets-transfer';
	const FORMAT             = 'radioudaan_app_secrets';
	const FORMAT_VERSION     = 1;
	const ACTION_EXPORT      = 'radioudaan_export_secrets';
	const ACTION_IMPORT      = 'radioudaan_import_secrets';
	const NONCE_EXPORT       = 'radioudaan_export_secrets';
	const NONCE_IMPORT       = 'radioudaan_import_secrets';
	const REDACTED_PLACEHOLDER = '[REDACTED]';

	const STAGING_BASE = 'https://nexusfleck.com/radioudaan';
	const PROD_BASE    = 'https://radioudaan.com';

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'admin_post_' . self::ACTION_EXPORT, array( __CLASS__, 'handle_export' ) );
		add_action( 'admin_post_' . self::ACTION_IMPORT, array( __CLASS__, 'handle_import' ) );
	}

	/**
	 * Option keys that hold raw secrets (redacted when "Include secret values" is off).
	 *
	 * @return string[]
	 */
	public static function secret_option_keys() {
		return array(
			'radioudaan_msg91_auth_key',
			RadioUdaan_App_Settings::OPTION_FCM_SERVICE_ACCOUNT,
			RadioUdaan_App_Donations_Settings::OPTION_RAZORPAY_KEY_SECRET,
			RadioUdaan_App_Donations_Settings::OPTION_RAZORPAY_WEBHOOK_SECRET,
			RadioUdaan_App_Youtube_Library::OPTION_API_KEY,
		);
	}

	/**
	 * Credential / API keys (always listed when present).
	 *
	 * @return string[]
	 */
	public static function secrets_group_keys() {
		return array(
			'radioudaan_msg91_auth_key',
			'radioudaan_msg91_sender_id',
			'radioudaan_msg91_template_id',
			RadioUdaan_App_Settings::OPTION_FCM_SERVICE_ACCOUNT,
			RadioUdaan_App_Settings::OPTION_FCM_PROJECT_ID,
			RadioUdaan_App_Donations_Settings::OPTION_RAZORPAY_KEY_ID,
			RadioUdaan_App_Donations_Settings::OPTION_RAZORPAY_KEY_SECRET,
			RadioUdaan_App_Donations_Settings::OPTION_RAZORPAY_WEBHOOK_SECRET,
			RadioUdaan_App_Youtube_Library::OPTION_API_KEY,
			RadioUdaan_App_Youtube_Library::OPTION_CHANNEL,
		);
	}

	/**
	 * Connection / legal URLs and support contacts.
	 *
	 * @return string[]
	 */
	public static function connection_group_keys() {
		return array(
			RadioUdaan_App_Settings::OPTION_API_BASE_URL,
			RadioUdaan_App_Settings::OPTION_STREAM_URL,
			RadioUdaan_App_Settings::OPTION_PRIVACY_POLICY_URL,
			RadioUdaan_App_Settings::OPTION_TERMS_URL,
			RadioUdaan_App_Settings::OPTION_ABOUT_URL,
			RadioUdaan_App_Settings::OPTION_CONTACT_URL,
			RadioUdaan_App_Settings::OPTION_APP_STORE_URL,
			RadioUdaan_App_Settings::OPTION_PLAY_STORE_URL,
			RadioUdaan_App_Settings::OPTION_SUPPORT_HELPLINE_PHONE,
			RadioUdaan_App_Settings::OPTION_SUPPORT_EMAIL,
		);
	}

	/**
	 * Donate settings excluding attachment IDs.
	 *
	 * @return string[]
	 */
	public static function donate_group_keys() {
		return array(
			RadioUdaan_App_Donations_Settings::OPTION_RAZORPAY_ENABLED,
			RadioUdaan_App_Donations_Settings::OPTION_RAZORPAY_CHECKOUT_NAME,
			RadioUdaan_App_Donations_Settings::OPTION_RAZORPAY_PRESET_AMOUNTS,
			RadioUdaan_App_Donations_Settings::OPTION_IOS_SAFARI_PAYMENT_URL,
			RadioUdaan_App_Donations_Settings::OPTION_80G_ENABLED,
			RadioUdaan_App_Donations_Settings::OPTION_80G_PDF_EMAIL,
			RadioUdaan_App_Donations_Settings::OPTION_80G_REG_NUMBER,
			RadioUdaan_App_Donations_Settings::OPTION_80G_LEGAL_TEXT,
			RadioUdaan_App_Donations_Settings::OPTION_80G_TRUST_PAN,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_BADGE,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_HEADLINE,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_INTRO,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_ACCESSIBILITY_NOTE,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_UPI_ID,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_ACCOUNT_NAME,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_ACCOUNT_NUMBER,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_BANK_NAME,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_BRANCH_NAME,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_IFSC,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_MICR,
			RadioUdaan_App_Info_Hub::OPTION_DONATE_BANK_ADDRESS,
		);
	}

	/**
	 * Push notification preference defaults.
	 *
	 * @return string[]
	 */
	public static function push_group_keys() {
		return array(
			RadioUdaan_App_Settings::OPTION_NOTIF_EVENTS_DEFAULT,
			RadioUdaan_App_Settings::OPTION_NOTIF_LIBRARY_DEFAULT,
			RadioUdaan_App_Settings::OPTION_NOTIF_PROMOTIONS_DEFAULT,
		);
	}

	/**
	 * Render Transfer secrets page.
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		RadioUdaan_Admin_Layout::render_open( 'secrets-transfer', __( 'Transfer secrets', 'radioudaan-app-api' ) );

		RadioUdaan_Admin_Layout::render_page_intro(
			'<p><strong>' . esc_html__( 'This file contains secrets.', 'radioudaan-app-api' ) . '</strong> '
			. esc_html__( 'Do not commit to git or email. Delete after import.', 'radioudaan-app-api' ) . '</p>',
			'warning'
		);
		?>
		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Export', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
				<p class="description">
					<?php esc_html_e( 'Download a JSON file of keys and connection settings from this site (typically staging).', 'radioudaan-app-api' ); ?>
				</p>
				<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
					<input type="hidden" name="action" value="<?php echo esc_attr( self::ACTION_EXPORT ); ?>" />
					<?php wp_nonce_field( self::NONCE_EXPORT ); ?>
					<div class="ru-admin__field">
						<label>
							<input type="checkbox" name="include_secrets" value="1" checked />
							<?php esc_html_e( 'Include secret values', 'radioudaan-app-api' ); ?>
						</label>
						<p class="description">
							<?php esc_html_e( 'When unchecked, secret fields are listed as [REDACTED] so you can still checklist which keys exist.', 'radioudaan-app-api' ); ?>
						</p>
					</div>
					<div class="ru-admin__field">
						<label>
							<input type="checkbox" name="include_copy_overrides" value="1" />
							<?php esc_html_e( 'Include copy overrides', 'radioudaan-app-api' ); ?>
						</label>
					</div>
					<p>
						<button type="submit" class="button button-primary">
							<?php esc_html_e( 'Download secrets JSON', 'radioudaan-app-api' ); ?>
						</button>
					</p>
				</form>
			</div>
		</div>

		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Import', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
				<p class="description">
					<?php esc_html_e( 'Upload a secrets JSON file on the destination site (typically production). Empty and [REDACTED] values are skipped.', 'radioudaan-app-api' ); ?>
				</p>
				<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" enctype="multipart/form-data">
					<input type="hidden" name="action" value="<?php echo esc_attr( self::ACTION_IMPORT ); ?>" />
					<?php wp_nonce_field( self::NONCE_IMPORT ); ?>
					<div class="ru-admin__field">
						<label for="radioudaan_secrets_file">
							<strong><?php esc_html_e( 'Secrets JSON file', 'radioudaan-app-api' ); ?></strong>
						</label>
						<input type="file" name="secrets_file" id="radioudaan_secrets_file" accept=".json,application/json" required />
					</div>
					<div class="ru-admin__field">
						<label>
							<input type="checkbox" name="import_secrets" value="1" checked />
							<?php esc_html_e( 'Import secrets', 'radioudaan-app-api' ); ?>
						</label>
					</div>
					<div class="ru-admin__field">
						<label>
							<input type="checkbox" name="import_connection" value="1" checked />
							<?php esc_html_e( 'Import connection / URLs', 'radioudaan-app-api' ); ?>
						</label>
					</div>
					<div class="ru-admin__field">
						<label>
							<input type="checkbox" name="import_donate" value="1" checked />
							<?php esc_html_e( 'Import donate settings', 'radioudaan-app-api' ); ?>
						</label>
					</div>
					<div class="ru-admin__field">
						<label>
							<input type="checkbox" name="import_push" value="1" checked />
							<?php esc_html_e( 'Import push defaults', 'radioudaan-app-api' ); ?>
						</label>
					</div>
					<div class="ru-admin__field">
						<label>
							<input type="checkbox" name="import_copy_overrides" value="1" />
							<?php esc_html_e( 'Import copy overrides', 'radioudaan-app-api' ); ?>
						</label>
					</div>
					<div class="ru-admin__field">
						<label>
							<input type="checkbox" name="rewrite_staging_urls" value="1" checked />
							<?php esc_html_e( 'Rewrite staging URLs → production', 'radioudaan-app-api' ); ?>
						</label>
						<p class="description">
							<?php
							echo esc_html(
								sprintf(
									/* translators: 1: staging base URL, 2: production base URL */
									__( 'Replaces %1$s with %2$s in imported string values (including the API base URL).', 'radioudaan-app-api' ),
									self::STAGING_BASE,
									self::PROD_BASE
								)
							);
							?>
						</p>
					</div>
					<p>
						<button type="submit" class="button button-primary">
							<?php esc_html_e( 'Import secrets', 'radioudaan-app-api' ); ?>
						</button>
					</p>
				</form>
			</div>
		</div>

		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Also do manually', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
				<ul class="ru-admin__meta-list">
					<li><?php esc_html_e( 'Firebase app files (google-services.json / GoogleService-Info.plist) stay in the Flutter app — not in this export.', 'radioudaan-app-api' ); ?></li>
					<li><?php esc_html_e( 'APNs Auth Key in Firebase Console.', 'radioudaan-app-api' ); ?></li>
					<li><?php esc_html_e( 'GitHub Actions signing secrets.', 'radioudaan-app-api' ); ?></li>
					<li><?php esc_html_e( 'Re-upload logo / donate QR media on production (attachment IDs are site-specific).', 'radioudaan-app-api' ); ?></li>
					<li>
						<?php
						esc_html_e(
							'Set API base URL to https://radioudaan.com/wp-json/radioudaan/v1 (or use the rewrite checkbox on import).',
							'radioudaan-app-api'
						);
						?>
					</li>
				</ul>
			</div>
		</div>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * Stream secrets JSON download.
	 */
	public static function handle_export() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( self::NONCE_EXPORT );

		$include_secrets = ! empty( $_POST['include_secrets'] );
		$include_copy    = ! empty( $_POST['include_copy_overrides'] );

		$keys = array_merge(
			self::secrets_group_keys(),
			self::connection_group_keys(),
			self::donate_group_keys(),
			self::push_group_keys()
		);

		if ( $include_copy ) {
			$keys[] = RadioUdaan_App_Copy_Catalog::OPTION_OVERRIDES;
		}

		$keys    = array_values( array_unique( $keys ) );
		$options = self::collect_options( $keys, $include_secrets );

		$payload = array(
			'format'           => self::FORMAT,
			'format_version'   => self::FORMAT_VERSION,
			'exported_at'      => gmdate( 'c' ),
			'source_site'      => home_url( '/' ),
			'includes_secrets' => (bool) $include_secrets,
			'options'          => $options,
			'meta'             => array(
				'notes' => $include_secrets
					? 'Contains live secret values. Delete after import. Do not commit or email.'
					: 'Secret values redacted. Re-export with Include secret values to transfer credentials.',
			),
		);

		$json = wp_json_encode( $payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES );
		if ( false === $json ) {
			wp_die( esc_html__( 'Could not encode secrets export.', 'radioudaan-app-api' ) );
		}

		$filename = 'radioudaan-app-secrets-' . gmdate( 'Y-m-d' ) . '.json';

		nocache_headers();
		header( 'Content-Type: application/json; charset=utf-8' );
		header( 'Content-Disposition: attachment; filename=' . $filename );
		header( 'X-Content-Type-Options: nosniff' );

		// phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped -- raw JSON download body.
		echo $json;
		exit;
	}

	/**
	 * Import secrets JSON upload.
	 */
	public static function handle_import() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( self::NONCE_IMPORT );

		if ( empty( $_FILES['secrets_file'] ) || ! is_array( $_FILES['secrets_file'] ) ) {
			self::redirect_notice( 'error', __( 'No file uploaded.', 'radioudaan-app-api' ) );
		}

		$file = $_FILES['secrets_file'];
		if ( ! empty( $file['error'] ) || empty( $file['tmp_name'] ) || ! is_uploaded_file( $file['tmp_name'] ) ) {
			self::redirect_notice( 'error', __( 'Upload failed. Try again.', 'radioudaan-app-api' ) );
		}

		// phpcs:ignore WordPress.WP.AlternativeFunctions.file_get_contents_file_get_contents -- reading uploaded temp file once.
		$raw = file_get_contents( $file['tmp_name'] );
		if ( false === $raw || '' === $raw ) {
			self::redirect_notice( 'error', __( 'Uploaded file is empty.', 'radioudaan-app-api' ) );
		}

		$data = json_decode( $raw, true );
		if ( ! is_array( $data ) ) {
			self::redirect_notice( 'error', __( 'Invalid JSON file.', 'radioudaan-app-api' ) );
		}

		if ( empty( $data['format'] ) || self::FORMAT !== $data['format'] ) {
			self::redirect_notice( 'error', __( 'Wrong file format. Use a Radio Udaan secrets export.', 'radioudaan-app-api' ) );
		}

		$version = isset( $data['format_version'] ) ? (int) $data['format_version'] : 0;
		if ( $version < 1 || $version > self::FORMAT_VERSION ) {
			self::redirect_notice( 'error', __( 'Unsupported secrets format version.', 'radioudaan-app-api' ) );
		}

		if ( empty( $data['options'] ) || ! is_array( $data['options'] ) ) {
			self::redirect_notice( 'error', __( 'Export has no options to import.', 'radioudaan-app-api' ) );
		}

		$import_secrets  = ! empty( $_POST['import_secrets'] );
		$import_conn     = ! empty( $_POST['import_connection'] );
		$import_donate   = ! empty( $_POST['import_donate'] );
		$import_push     = ! empty( $_POST['import_push'] );
		$import_copy     = ! empty( $_POST['import_copy_overrides'] );
		$rewrite_urls    = ! empty( $_POST['rewrite_staging_urls'] );

		$allowed = array();
		if ( $import_secrets ) {
			$allowed = array_merge( $allowed, self::secrets_group_keys() );
		}
		if ( $import_conn ) {
			$allowed = array_merge( $allowed, self::connection_group_keys() );
		}
		if ( $import_donate ) {
			$allowed = array_merge( $allowed, self::donate_group_keys() );
		}
		if ( $import_push ) {
			$allowed = array_merge( $allowed, self::push_group_keys() );
		}
		if ( $import_copy ) {
			$allowed[] = RadioUdaan_App_Copy_Catalog::OPTION_OVERRIDES;
		}
		$allowed = array_fill_keys( array_unique( $allowed ), true );

		$secret_keys = array_fill_keys( self::secret_option_keys(), true );
		$updated     = 0;
		$skipped     = 0;

		foreach ( $data['options'] as $option_name => $value ) {
			$option_name = sanitize_key( (string) $option_name );
			if ( '' === $option_name || empty( $allowed[ $option_name ] ) ) {
				continue;
			}

			if ( self::should_skip_import_value( $value, isset( $secret_keys[ $option_name ] ) ) ) {
				++$skipped;
				continue;
			}

			if ( $rewrite_urls ) {
				$value = self::rewrite_staging_to_production( $value );
			}

			update_option( $option_name, $value, false );
			++$updated;
		}

		if ( class_exists( 'RadioUdaan_App_Config' ) && method_exists( 'RadioUdaan_App_Config', 'invalidate_cache' ) ) {
			RadioUdaan_App_Config::invalidate_cache();
		}

		$detail = sprintf(
			/* translators: 1: options updated count, 2: skipped count */
			__( 'Import finished. Updated %1$d options (%2$d skipped as empty or redacted).', 'radioudaan-app-api' ),
			$updated,
			$skipped
		);

		self::redirect_notice( $updated > 0 ? 'success' : 'warning', $detail );
	}

	/**
	 * Collect present options; optionally redact secret values.
	 *
	 * @param string[] $keys            Option names.
	 * @param bool     $include_secrets Whether to include raw secret values.
	 * @return array<string,mixed>
	 */
	private static function collect_options( array $keys, $include_secrets ) {
		$secret_keys = array_fill_keys( self::secret_option_keys(), true );
		$out         = array();
		$missing     = new stdClass();

		foreach ( $keys as $key ) {
			$value = get_option( $key, $missing );
			if ( $value === $missing ) {
				continue;
			}

			if ( ! $include_secrets && isset( $secret_keys[ $key ] ) ) {
				$out[ $key ] = self::REDACTED_PLACEHOLDER;
				continue;
			}

			$out[ $key ] = $value;
		}

		return $out;
	}

	/**
	 * Whether an import value should be skipped.
	 *
	 * @param mixed $value     Option value.
	 * @param bool  $is_secret Whether this key is a secret field.
	 * @return bool
	 */
	private static function should_skip_import_value( $value, $is_secret ) {
		if ( is_string( $value ) ) {
			$trimmed = trim( $value );
			if ( self::REDACTED_PLACEHOLDER === $trimmed ) {
				return true;
			}
			if ( $is_secret && '' === $trimmed ) {
				return true;
			}
			if ( '' === $trimmed ) {
				return true;
			}
		}

		if ( null === $value ) {
			return true;
		}

		if ( is_array( $value ) && array() === $value ) {
			return true;
		}

		return false;
	}

	/**
	 * Replace staging site base with production in string (or nested string) values.
	 *
	 * @param mixed $value Option value.
	 * @return mixed
	 */
	private static function rewrite_staging_to_production( $value ) {
		if ( is_string( $value ) ) {
			return str_replace( self::STAGING_BASE, self::PROD_BASE, $value );
		}

		if ( is_array( $value ) ) {
			foreach ( $value as $k => $v ) {
				$value[ $k ] = self::rewrite_staging_to_production( $v );
			}
		}

		return $value;
	}

	/**
	 * Redirect back to the transfer page with a notice (no secret values in message).
	 *
	 * @param string $notice success|error|warning.
	 * @param string $detail Human-readable detail (counts only; never secrets).
	 */
	private static function redirect_notice( $notice, $detail ) {
		wp_safe_redirect(
			add_query_arg(
				array(
					'page'              => self::PAGE_SLUG,
					'radioudaan_notice' => $notice,
					'radioudaan_detail' => rawurlencode( $detail ),
				),
				admin_url( 'admin.php' )
			)
		);
		exit;
	}
}

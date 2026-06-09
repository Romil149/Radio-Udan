<?php
/**
 * CF7 → Forminator migration helpers (admin only).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Admin UI to migrate registration forms from CF7 to Forminator.
 */
class RadioUdaan_Admin_Form_Migration {

	const PAGE_SLUG = 'radioudaan-form-migration';

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'admin_post_radioudaan_migrate_form', array( __CLASS__, 'handle_migrate_form' ) );
	}

	/**
	 * Registration events to migrate (live DB page + CF7 IDs).
	 *
	 * @return array<string,array{label:string,cf7_id:int,page_id:int,whatsapp_url?:string}>
	 */
	public static function get_migrations() {
		return RadioUdaan_Event_Registry::get_definitions();
	}

	/**
	 * Admin page.
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$notice = isset( $_GET['radioudaan_notice'] ) ? sanitize_text_field( wp_unslash( $_GET['radioudaan_notice'] ) ) : '';
		$detail = isset( $_GET['radioudaan_detail'] ) ? sanitize_text_field( wp_unslash( $_GET['radioudaan_detail'] ) ) : '';
		if ( $detail ) {
			$detail = rawurldecode( $detail );
		}

		RadioUdaan_Admin_Layout::render_open( 'tools', __( 'Advanced tools', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html__( 'Advanced only', 'radioudaan-app-api' ) . '</strong> — ' .
			esc_html__( 'Migrate legacy Contact Form 7 pages to Forminator and sync app events. Use Events for day-to-day work.', 'radioudaan-app-api' ),
			'warning'
		);
		?>
		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Form migration (CF7 → Forminator)', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
			<p class="description"><?php esc_html_e( 'Reads and writes the live WordPress database. Imports CF7 forms into Forminator and updates Elementor registration pages.', 'radioudaan-app-api' ); ?></p>
			<table class="ru-admin__table widefat striped">
				<thead>
					<tr>
						<th><?php esc_html_e( 'Event', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'Page', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'CF7', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'Forminator (option)', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'Live embed (DB)', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'State', 'radioudaan-app-api' ); ?></th>
						<th><?php esc_html_e( 'Action', 'radioudaan-app-api' ); ?></th>
					</tr>
				</thead>
				<tbody>
				<?php
				foreach ( self::get_migrations() as $event_code => $migration ) :
					$stored_id   = (int) get_option( 'radioudaan_forminator_' . $event_code, 0 );
					$live_status = self::get_elementor_page_form_status( (int) $migration['page_id'] );
					$permalink   = get_permalink( (int) $migration['page_id'] );
					?>
					<tr>
						<td><strong><?php echo esc_html( $migration['label'] ); ?></strong><br /><code><?php echo esc_html( $event_code ); ?></code></td>
						<td><?php echo (int) $migration['page_id']; ?><?php if ( $permalink ) : ?><br /><a href="<?php echo esc_url( $permalink ); ?>" target="_blank" rel="noopener"><?php esc_html_e( 'View page', 'radioudaan-app-api' ); ?></a><?php endif; ?></td>
						<td><?php echo (int) $migration['cf7_id']; ?></td>
						<td><?php echo $stored_id ? (int) $stored_id : '—'; ?></td>
						<td><code style="font-size:11px"><?php echo esc_html( $live_status['shortcode'] ? $live_status['shortcode'] : '—' ); ?></code></td>
						<td><strong><?php echo esc_html( $live_status['state'] ); ?></strong><br /><span class="description"><?php echo esc_html( $live_status['redirect'] ); ?></span></td>
						<td>
							<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
								<?php wp_nonce_field( 'radioudaan_migrate_' . $event_code ); ?>
								<input type="hidden" name="action" value="radioudaan_migrate_form" />
								<input type="hidden" name="migration_key" value="<?php echo esc_attr( $event_code ); ?>" />
								<?php
								$btn_attrs = array();
								if ( self::is_page_migrated( $live_status ) ) {
									$btn_attrs['disabled'] = 'disabled';
								}
								submit_button(
									__( 'Migrate', 'radioudaan-app-api' ),
									'secondary',
									'submit',
									false,
									$btn_attrs
								);
								?>
							</form>
						</td>
					</tr>
				<?php endforeach; ?>
				</tbody>
			</table>
			</div>
		</div>

		<div class="ru-admin__panel" style="margin-top:20px;">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'RJ profiles (CPT → users)', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
				<p class="description">
					<?php esc_html_e( 'Migrates legacy rj-profiles posts into WordPress users with the RJ role, preserves each CPT post slug as user_nicename (public URL /rj-profiles/{nicename}/), rewires radio-shows program_host, and trashes old posts. After migration, delete the rj-profiles post type in CPT UI and save Settings → Permalinks.', 'radioudaan-app-api' ); ?>
				</p>
				<?php
				$legacy_count = class_exists( 'RadioUdaan_Rj_Profile_Migration' )
					? RadioUdaan_Rj_Profile_Migration::count_legacy_posts()
					: array( 'posts' => 0 );
				$rj_users     = count( get_users( array( 'role' => 'rj', 'fields' => 'ID' ) ) );
				$migrated     = class_exists( 'RadioUdaan_Rj_Profile_Migration' ) && RadioUdaan_Rj_Profile_Migration::is_done();
				?>
				<ul>
					<li><?php echo esc_html( sprintf( __( 'Legacy rj-profiles posts: %d', 'radioudaan-app-api' ), (int) $legacy_count['posts'] ) ); ?></li>
					<li><?php echo esc_html( sprintf( __( 'RJ users: %d', 'radioudaan-app-api' ), $rj_users ) ); ?></li>
					<li><?php echo $migrated ? esc_html__( 'Migration flag: completed', 'radioudaan-app-api' ) : esc_html__( 'Migration flag: not run', 'radioudaan-app-api' ); ?></li>
				</ul>
				<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
					<?php wp_nonce_field( 'radioudaan_migrate_rj_profiles' ); ?>
					<input type="hidden" name="action" value="radioudaan_migrate_rj_profiles" />
					<label>
						<input type="checkbox" name="trash_legacy" value="1" checked="checked" />
						<?php esc_html_e( 'Trash legacy rj-profiles posts after migration', 'radioudaan-app-api' ); ?>
					</label>
					<p style="margin-top:12px;">
						<?php submit_button( __( 'Migrate RJ profiles to users', 'radioudaan-app-api' ), 'secondary', 'submit', false ); ?>
					</p>
				</form>
			</div>
		</div>

		<div class="ru-admin__panel" style="margin-top:20px;">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Sync app events', 'radioudaan-app-api' ); ?></h2>
			</div>
			<div class="ru-admin__panel-body">
				<p><?php esc_html_e( 'Creates or updates App Event posts from the built-in registry.', 'radioudaan-app-api' ); ?></p>
				<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
					<?php wp_nonce_field( 'radioudaan_sync_ru_events' ); ?>
					<input type="hidden" name="action" value="radioudaan_sync_ru_events" />
					<?php submit_button( __( 'Sync app events', 'radioudaan-app-api' ), 'primary ru-btn-large', 'submit', false ); ?>
				</form>
				<p><a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENTS_SLUG ) ); ?>"><?php esc_html_e( 'Go to Events', 'radioudaan-app-api' ); ?></a></p>
			</div>
		</div>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * @param array{shortcode:string,redirect:string,state:string} $live_status Status row.
	 */
	private static function is_page_migrated( $live_status ) {
		return false !== strpos( $live_status['shortcode'], 'forminator_form' );
	}

	/**
	 * Run migration for one event.
	 */
	public static function handle_migrate_form() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$key         = isset( $_POST['migration_key'] ) ? sanitize_key( wp_unslash( $_POST['migration_key'] ) ) : '';
		$migrations  = self::get_migrations();
		if ( ! isset( $migrations[ $key ] ) ) {
			wp_die( esc_html__( 'Unknown migration.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( 'radioudaan_migrate_' . $key );

		$migration = $migrations[ $key ];
		$whatsapp  = isset( $migration['whatsapp_url'] ) ? $migration['whatsapp_url'] : '';

		$result = self::migrate_cf7_to_forminator_on_page(
			(int) $migration['cf7_id'],
			(int) $migration['page_id'],
			'EVENT: ' . $key,
			$whatsapp
		);

		$args = array(
			'page'              => self::PAGE_SLUG,
			'radioudaan_notice' => $result['success'] ? 'success' : 'error',
			'radioudaan_detail' => rawurlencode( $result['message'] ),
		);

		if ( $result['success'] && ! empty( $result['forminator_id'] ) ) {
			update_option( 'radioudaan_forminator_' . $key, (int) $result['forminator_id'] );
		}

		wp_safe_redirect( add_query_arg( $args, admin_url( 'admin.php' ) ) );
		exit;
	}

	/**
	 * Import CF7 form, rename, patch Elementor page shortcode + optional WhatsApp redirect script.
	 *
	 * @param int    $cf7_id       CF7 post ID.
	 * @param int    $page_id      WordPress page ID (Elementor).
	 * @param string $form_name    Forminator display name.
	 * @param string $whatsapp_url Optional post-submit redirect URL.
	 * @return array{success:bool,message:string,forminator_id?:int}
	 */
	public static function migrate_cf7_to_forminator_on_page( $cf7_id, $page_id, $form_name, $whatsapp_url = '' ) {
		$live = self::get_elementor_page_form_status( (int) $page_id );
		if ( self::is_page_migrated( $live ) && preg_match( '/id="(\d+)"/', $live['shortcode'], $matches ) ) {
			$existing_id = (int) $matches[1];
			return array(
				'success'       => true,
				'message'       => sprintf(
					'Page %1$d already uses Forminator form %2$d. No re-import. Verify: %3$s',
					$page_id,
					$existing_id,
					get_permalink( $page_id ) ? get_permalink( $page_id ) : ''
				),
				'forminator_id' => $existing_id,
			);
		}

		if ( ! class_exists( 'WPCF7_ContactForm' ) ) {
			return array(
				'success' => false,
				'message' => 'Contact Form 7 is not active.',
			);
		}

		if ( ! class_exists( 'Forminator' ) ) {
			return array(
				'success' => false,
				'message' => 'Forminator is not active.',
			);
		}

		if ( ! function_exists( 'forminator_plugin_dir' ) ) {
			return array(
				'success' => false,
				'message' => 'Forminator plugin path unavailable.',
			);
		}

		require_once forminator_plugin_dir() . 'admin/classes/thirdparty-importers/class-importer-cf7.php';

		if ( ! class_exists( 'Forminator_Admin_Import_CF7' ) ) {
			return array(
				'success' => false,
				'message' => 'Forminator CF7 importer class not found.',
			);
		}

		$cf7 = wpcf7_contact_form( (int) $cf7_id );
		if ( ! $cf7 ) {
			return array(
				'success' => false,
				'message' => sprintf( 'CF7 form %d not found.', (int) $cf7_id ),
			);
		}

		$importer = Forminator_Admin_Import_CF7::get_instance();
		$import   = $importer->import_form( (int) $cf7_id );

		if ( empty( $import['id'] ) || ( isset( $import['type'] ) && 'fail' === $import['type'] ) ) {
			$msg = isset( $import['message'] ) ? $import['message'] : 'Forminator import failed.';
			return array(
				'success' => false,
				'message' => $msg,
			);
		}

		$forminator_id = (int) $import['id'];

		if ( class_exists( 'Forminator_Form_Model' ) ) {
			$model = Forminator_Form_Model::model()->load( $forminator_id );
			if ( $model ) {
				$model->name = $form_name;
				$model->save();
			}
		}

		$patch = self::patch_elementor_page_form( $page_id, $forminator_id, $whatsapp_url );
		if ( ! $patch['success'] ) {
			return array(
				'success'       => false,
				'message'       => sprintf(
					'Form imported (ID %1$d) but page update failed: %2$s',
					$forminator_id,
					$patch['message']
				),
				'forminator_id' => $forminator_id,
			);
		}

		if ( class_exists( '\Elementor\Plugin' ) ) {
			\Elementor\Plugin::$instance->files_manager->clear_cache();
		}

		$verify_url = get_permalink( $page_id );
		return array(
			'success'       => true,
			'message'       => sprintf(
				'Migration complete. Forminator form ID %1$d is live on page %2$d. Verify: %3$s',
				$forminator_id,
				$page_id,
				$verify_url ? $verify_url : ''
			),
			'forminator_id' => $forminator_id,
		);
	}

	/**
	 * Inspect Elementor _elementor_data on a page (live DB).
	 *
	 * @param int $page_id Page ID.
	 * @return array{shortcode:string,redirect:string,state:string}
	 */
	public static function get_elementor_page_form_status( $page_id ) {
		$empty = array(
			'shortcode' => '',
			'redirect'  => __( 'Not found', 'radioudaan-app-api' ),
			'state'     => __( 'Unknown', 'radioudaan-app-api' ),
		);

		$raw = get_post_meta( (int) $page_id, '_elementor_data', true );
		if ( empty( $raw ) ) {
			$empty['state'] = __( 'No Elementor data on page', 'radioudaan-app-api' );
			return $empty;
		}

		$data = json_decode( $raw, true );
		if ( ! is_array( $data ) ) {
			$empty['state'] = __( 'Invalid Elementor JSON', 'radioudaan-app-api' );
			return $empty;
		}

		$shortcode = '';
		$redirect  = __( 'Not found', 'radioudaan-app-api' );

		$walk = function ( $elements ) use ( &$walk, &$shortcode, &$redirect ) {
			foreach ( $elements as $el ) {
				if ( isset( $el['widgetType'] ) && 'shortcode' === $el['widgetType'] && ! empty( $el['settings']['shortcode'] ) ) {
					$sc = $el['settings']['shortcode'];
					if ( false !== strpos( $sc, 'contact-form-7' ) || false !== strpos( $sc, 'forminator_form' ) ) {
						$shortcode = $sc;
					}
				}
				if ( isset( $el['widgetType'] ) && 'html' === $el['widgetType'] && ! empty( $el['settings']['html'] ) ) {
					$html = $el['settings']['html'];
					if ( false !== strpos( $html, 'wpcf7mailsent' ) ) {
						$redirect = 'CF7 (wpcf7mailsent)';
					} elseif ( false !== strpos( $html, 'forminator:form:submit:success' ) ) {
						$redirect = 'Forminator (submit:success → WhatsApp)';
					}
				}
				if ( ! empty( $el['elements'] ) && is_array( $el['elements'] ) ) {
					$walk( $el['elements'] );
				}
			}
		};

		$walk( $data );

		$state = __( 'Unknown', 'radioudaan-app-api' );
		if ( false !== strpos( $shortcode, 'forminator_form' ) ) {
			$state = false !== strpos( $redirect, 'Forminator' )
				? __( 'Migrated (Forminator + redirect)', 'radioudaan-app-api' )
				: __( 'Migrated (Forminator on page)', 'radioudaan-app-api' );
		} elseif ( false !== strpos( $shortcode, 'contact-form-7' ) ) {
			$state = __( 'Still CF7 — run migration', 'radioudaan-app-api' );
		} elseif ( $shortcode ) {
			$state = __( 'Custom shortcode — review manually', 'radioudaan-app-api' );
		}

		return array(
			'shortcode' => $shortcode,
			'redirect'  => $redirect,
			'state'     => $state,
		);
	}

	/**
	 * Replace CF7 shortcode widget with Forminator; update post-submit redirect script when present.
	 *
	 * @param int    $page_id       Page ID.
	 * @param int    $forminator_id Forminator form ID.
	 * @param string $whatsapp_url  Optional WhatsApp redirect after submit.
	 * @return array{success:bool,message:string}
	 */
	public static function patch_elementor_page_form( $page_id, $forminator_id, $whatsapp_url = '' ) {
		$raw = get_post_meta( (int) $page_id, '_elementor_data', true );
		if ( empty( $raw ) ) {
			return array(
				'success' => false,
				'message' => '_elementor_data meta missing on page.',
			);
		}

		$data = json_decode( $raw, true );
		if ( ! is_array( $data ) ) {
			return array(
				'success' => false,
				'message' => 'Invalid Elementor JSON on page.',
			);
		}

		$shortcode    = '[forminator_form id="' . (int) $forminator_id . '"]';
		$found_form   = false;
		$found_script = false;
		$new_script   = '';

		if ( $whatsapp_url ) {
			$new_script = '<script>document.addEventListener(\'forminator:form:submit:success\',function(){window.location.href=\'' . esc_url_raw( $whatsapp_url ) . '\';},false);</script>';
		}

		$walk = function ( &$elements ) use ( &$walk, $shortcode, $new_script, &$found_form, &$found_script ) {
			foreach ( $elements as &$el ) {
				if ( isset( $el['widgetType'] ) && 'shortcode' === $el['widgetType'] ) {
					if ( ! empty( $el['settings']['shortcode'] ) && false !== strpos( $el['settings']['shortcode'], 'contact-form-7' ) ) {
						$el['settings']['shortcode'] = $shortcode;
						$found_form                  = true;
					}
				}
				if ( $new_script && isset( $el['widgetType'] ) && 'html' === $el['widgetType'] ) {
					if ( ! empty( $el['settings']['html'] ) && false !== strpos( $el['settings']['html'], 'wpcf7mailsent' ) ) {
						$el['settings']['html'] = $new_script;
						$found_script           = true;
					}
				}
				if ( ! empty( $el['elements'] ) && is_array( $el['elements'] ) ) {
					$walk( $el['elements'] );
				}
			}
		};

		$walk( $data );

		if ( ! $found_form ) {
			return array(
				'success' => false,
				'message' => 'CF7 shortcode widget not found in Elementor data.',
			);
		}

		$encoded = wp_slash( wp_json_encode( $data ) );
		update_post_meta( (int) $page_id, '_elementor_data', $encoded );

		return array(
			'success' => true,
			'message' => $found_script
				? 'Replaced CF7 shortcode and WhatsApp redirect script.'
				: 'Replaced CF7 shortcode (no WhatsApp script on page).',
		);
	}
}

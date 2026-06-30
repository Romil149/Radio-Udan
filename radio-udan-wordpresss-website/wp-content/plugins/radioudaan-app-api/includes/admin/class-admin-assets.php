<?php
/**
 * Admin CSS/JS assets.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Enqueue branded admin assets on plugin screens.
 */
class RadioUdaan_Admin_Assets {

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'admin_enqueue_scripts', array( __CLASS__, 'enqueue' ) );
		add_filter( 'admin_body_class', array( __CLASS__, 'body_class' ) );
		add_action( 'edit_form_top', array( __CLASS__, 'render_cpt_banner' ) );
	}

	/**
	 * @param string $hook Hook suffix.
	 */
	public static function enqueue( $hook ) {
		if ( ! self::is_plugin_screen( $hook ) ) {
			return;
		}

		wp_enqueue_style(
			'radioudaan-app-admin',
			RADIOUDAAN_APP_API_URL . 'assets/css/admin.css',
			array(),
			RADIOUDAAN_APP_API_VERSION
		);

		$admin_deps = array( 'jquery' );
		if ( false !== strpos( (string) $hook, RadioUdaan_Admin_App_Hub::EVENTS_SLUG ) ) {
			wp_enqueue_script( 'jquery-ui-sortable' );
			$admin_deps[] = 'jquery-ui-sortable';
		}

		wp_enqueue_script(
			'radioudaan-app-admin',
			RADIOUDAAN_APP_API_URL . 'assets/js/admin.js',
			$admin_deps,
			RADIOUDAAN_APP_API_VERSION,
			true
		);

		if ( false !== strpos( (string) $hook, RadioUdaan_Admin_App_Hub::EVENTS_SLUG ) ) {
			wp_localize_script(
				'radioudaan-app-admin',
				'radioudaanEventsAdmin',
				array(
					'ajaxUrl' => admin_url( 'admin-ajax.php' ),
					'nonce'   => wp_create_nonce( 'radioudaan_events_order' ),
					'i18n'    => array(
						'saving' => __( 'Saving order…', 'radioudaan-app-api' ),
						'saved'  => __( 'Event order saved for the mobile app.', 'radioudaan-app-api' ),
						'error'  => __( 'Could not save event order. Try again.', 'radioudaan-app-api' ),
					),
				)
			);
		}

		if ( false !== strpos( (string) $hook, RadioUdaan_Admin_App_Hub::EDIT_EVENT_SLUG ) ) {
			wp_enqueue_media();
			wp_enqueue_script(
				'radioudaan-app-editor',
				RADIOUDAAN_APP_API_URL . 'assets/js/admin-editor.js',
				array( 'jquery' ),
				RADIOUDAAN_APP_API_VERSION,
				true
			);
		}

		if ( false !== strpos( (string) $hook, RadioUdaan_Admin_App_Hub::SETTINGS_SLUG ) ) {
			wp_enqueue_style(
				'radioudaan-app-settings',
				RADIOUDAAN_APP_API_URL . 'assets/css/admin-settings.css',
				array( 'radioudaan-app-admin' ),
				RADIOUDAAN_APP_API_VERSION
			);
			wp_enqueue_media();
			$settings_js_path = RADIOUDAAN_APP_API_PATH . 'assets/js/admin-settings.js';
			wp_enqueue_script(
				'radioudaan-app-settings',
				RADIOUDAAN_APP_API_URL . 'assets/js/admin-settings.js',
				array( 'jquery', 'media-editor', 'media-views' ),
				is_readable( $settings_js_path ) ? (string) filemtime( $settings_js_path ) : RADIOUDAAN_APP_API_VERSION,
				true
			);
		}
	}

	/**
	 * @param string $classes Body classes.
	 * @return string
	 */
	public static function body_class( $classes ) {
		$screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
		if ( ! $screen ) {
			return $classes;
		}

		if ( self::is_plugin_screen( $screen->id ) || RadioUdaan_Cpt_Ru_Event::POST_TYPE === $screen->post_type ) {
			$classes .= ' ru-app-admin ru-a11y-large';
		}

		return $classes;
	}

	/**
	 * @param string $hook Hook or screen id.
	 * @return bool
	 */
	public static function is_plugin_screen( $hook ) {
		if ( false !== strpos( (string) $hook, 'radioudaan' ) ) {
			return true;
		}

		if ( false !== strpos( (string) $hook, 'radioudaan-app-edit-event' )
			|| false !== strpos( (string) $hook, 'radioudaan-app-view-entry' )
			|| false !== strpos( (string) $hook, 'radioudaan-app-users' ) ) {
			return true;
		}

		$screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
		if ( $screen && RadioUdaan_Cpt_Ru_Event::POST_TYPE === $screen->post_type ) {
			return true;
		}

		return false;
	}

	/**
	 * Help banner on App Event editor.
	 *
	 * @param WP_Post $post Post.
	 */
	public static function render_cpt_banner( $post ) {
		if ( ! $post || RadioUdaan_Cpt_Ru_Event::POST_TYPE !== $post->post_type ) {
			return;
		}

		$dashboard = admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::MENU_SLUG );
		?>
		<div class="ru-admin-cpt-banner notice notice-info inline">
			<p>
				<?php
				printf(
					/* translators: %s: dashboard URL */
					wp_kses_post( __( 'This event powers the <strong>mobile app</strong>. Return to the <a href="%s">App Dashboard</a> to manage all events.', 'radioudaan-app-api' ) ),
					esc_url( $dashboard )
				);
				?>
			</p>
		</div>
		<?php
	}
}

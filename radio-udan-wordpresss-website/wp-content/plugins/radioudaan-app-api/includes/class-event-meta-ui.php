<?php
/**
 * App Event meta box UI helpers (dropdowns).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Choices for ru_event editor dropdowns.
 */
class RadioUdaan_Event_Meta_Ui {

	/**
	 * Register admin scripts for event editor.
	 */
	public static function init() {
		add_action( 'admin_enqueue_scripts', array( __CLASS__, 'enqueue_scripts' ) );
	}

	/**
	 * @param string $hook Hook.
	 */
	public static function enqueue_scripts( $hook ) {
		if ( ! in_array( $hook, array( 'post.php', 'post-new.php' ), true ) ) {
			return;
		}

		$screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
		if ( ! $screen || RadioUdaan_Cpt_Ru_Event::POST_TYPE !== $screen->post_type ) {
			return;
		}

		wp_enqueue_style(
			'radioudaan-app-admin',
			RADIOUDAAN_APP_API_URL . 'assets/css/admin.css',
			array(),
			RADIOUDAAN_APP_API_VERSION
		);

		wp_enqueue_script(
			'radioudaan-event-meta',
			RADIOUDAAN_APP_API_URL . 'assets/js/event-meta.js',
			array( 'jquery' ),
			RADIOUDAAN_APP_API_VERSION,
			true
		);
	}

	/**
	 * @return array<int,string> id => label
	 */
	public static function get_page_choices() {
		$pages = get_posts(
			array(
				'post_type'      => 'page',
				'post_status'    => array( 'publish', 'draft', 'private' ),
				'posts_per_page' => 200,
				'orderby'        => 'title',
				'order'          => 'ASC',
			)
		);

		$choices = array( 0 => __( '— No linked page —', 'radioudaan-app-api' ) );
		foreach ( $pages as $page ) {
			$choices[ (int) $page->ID ] = sprintf(
				'%s (ID %d)',
				$page->post_title ? $page->post_title : __( '(no title)', 'radioudaan-app-api' ),
				$page->ID
			);
		}

		return $choices;
	}

	/**
	 * @return array<int,string> form_id => label
	 */
	public static function get_forminator_choices() {
		$choices = array( 0 => __( '— Select a form —', 'radioudaan-app-api' ) );

		if ( class_exists( 'Forminator_API' ) ) {
			Forminator_API::initialize();
			$forms = Forminator_API::get_forms( null, 1, 500, 'publish' );
			if ( is_array( $forms ) ) {
				foreach ( $forms as $form ) {
					if ( is_object( $form ) && ! empty( $form->id ) ) {
						$name = ! empty( $form->name ) ? $form->name : sprintf( __( 'Form #%d', 'radioudaan-app-api' ), $form->id );
						$choices[ (int) $form->id ] = sprintf( '%s (ID %d)', $name, (int) $form->id );
					}
				}
			}
		}

		if ( count( $choices ) <= 1 ) {
			$posts = get_posts(
				array(
					'post_type'      => 'forminator_forms',
					'post_status'    => 'publish',
					'posts_per_page' => 200,
					'orderby'        => 'title',
					'order'          => 'ASC',
				)
			);
			foreach ( $posts as $post ) {
				$choices[ (int) $post->ID ] = sprintf(
					'%s (ID %d)',
					$post->post_title ? $post->post_title : __( '(no title)', 'radioudaan-app-api' ),
					$post->ID
				);
			}
		}

		return $choices;
	}

	/**
	 * @return array<string,string> code => label
	 */
	public static function get_event_code_choices() {
		$choices = array(
			'' => __( '— Select or enter custom —', 'radioudaan-app-api' ),
		);

		foreach ( RadioUdaan_Event_Registry::get_definitions() as $code => $def ) {
			$choices[ $code ] = sprintf( '%s — %s', $code, $def['label'] );
		}

		$choices['__custom__'] = __( 'Custom code…', 'radioudaan-app-api' );

		return $choices;
	}

	/**
	 * @return array<string,string> key => message
	 */
	public static function get_success_message_presets() {
		return array(
			''       => __( '— Choose a template (optional) —', 'radioudaan-app-api' ),
			'default'=> __( 'Thank you. Your registration was received.', 'radioudaan-app-api' ),
			'contact'=> __( 'Thank you! We will contact you soon.', 'radioudaan-app-api' ),
			'review' => __( 'Thank you! Your submission is under review.', 'radioudaan-app-api' ),
		);
	}

	/**
	 * Render a styled dropdown.
	 *
	 * @param string $id       Field id.
	 * @param string $name     Field name.
	 * @param array  $options  value => label.
	 * @param string $selected Selected value.
	 * @param array  $attrs    Extra attributes.
	 */
	public static function render_select( $id, $name, $options, $selected, $attrs = array() ) {
		$attr_html = '';
		foreach ( $attrs as $key => $val ) {
			$attr_html .= sprintf( ' %s="%s"', esc_attr( $key ), esc_attr( $val ) );
		}
		?>
		<select name="<?php echo esc_attr( $name ); ?>" id="<?php echo esc_attr( $id ); ?>" class="ru-event-select widefat"<?php echo $attr_html; // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped ?>>
			<?php foreach ( $options as $value => $label ) : ?>
				<option value="<?php echo esc_attr( (string) $value ); ?>" <?php selected( (string) $selected, (string) $value ); ?>>
					<?php echo esc_html( $label ); ?>
				</option>
			<?php endforeach; ?>
		</select>
		<?php
	}
}

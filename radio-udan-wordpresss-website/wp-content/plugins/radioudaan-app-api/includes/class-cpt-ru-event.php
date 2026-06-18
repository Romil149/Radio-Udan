<?php
/**
 * ru_event custom post type for app-visible events.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Registers ru_event CPT and post meta used by the App API.
 */
class RadioUdaan_Cpt_Ru_Event {

	const POST_TYPE = 'ru_event';

	const META_EVENT_CODE            = 'ru_event_code';
	const META_REGISTRATION_PAGE_ID  = 'ru_registration_page_id';
	const META_FORMINATOR_FORM_ID    = 'ru_forminator_form_id';
	const META_EVENT_STATUS          = 'ru_event_status';
	const META_SUCCESS_MESSAGE       = 'ru_success_message';
	const META_EVENT_TYPE            = 'ru_event_type';
	const META_EVENT_START_AT                = 'ru_event_start_at';
	const META_ALLOW_MULTIPLE_REGISTRATIONS  = 'ru_allow_multiple_registrations';

	/**
	 * Register CPT and meta.
	 */
	public static function init() {
		add_action( 'init', array( __CLASS__, 'register_post_type' ) );
		add_action( 'init', array( __CLASS__, 'register_meta' ) );
		add_action( 'add_meta_boxes', array( __CLASS__, 'add_meta_boxes' ) );
		add_action( 'save_post_' . self::POST_TYPE, array( __CLASS__, 'save_meta_box' ), 10, 2 );
	}

	/**
	 * Register ru_event post type.
	 */
	public static function register_post_type() {
		register_post_type(
			self::POST_TYPE,
			array(
				'labels'              => array(
					'name'          => __( 'App Events', 'radioudaan-app-api' ),
					'singular_name' => __( 'App Event', 'radioudaan-app-api' ),
					'add_new_item'  => __( 'Add App Event', 'radioudaan-app-api' ),
					'edit_item'     => __( 'Edit App Event', 'radioudaan-app-api' ),
				),
				'public'              => false,
				'show_ui'             => true,
				'show_in_menu'        => false,
				'show_in_rest'        => true,
				'menu_position'       => 25,
				'capability_type'     => 'post',
				'map_meta_cap'        => true,
				'hierarchical'        => false,
				'supports'            => array( 'title', 'editor', 'thumbnail', 'revisions' ),
				'has_archive'         => false,
				'rewrite'             => false,
			)
		);
	}

	/**
	 * Register post meta for REST and queries.
	 */
	public static function register_meta() {
		$metas = array(
			self::META_EVENT_CODE           => 'string',
			self::META_REGISTRATION_PAGE_ID => 'integer',
			self::META_FORMINATOR_FORM_ID   => 'integer',
			self::META_EVENT_STATUS         => 'string',
			self::META_SUCCESS_MESSAGE      => 'string',
			self::META_EVENT_TYPE           => 'string',
			self::META_EVENT_START_AT       => 'string',
		);

		foreach ( $metas as $key => $type ) {
			register_post_meta(
				self::POST_TYPE,
				$key,
				array(
					'type'              => $type,
					'single'            => true,
					'show_in_rest'      => true,
					'sanitize_callback' => 'sanitize_text_field',
					'auth_callback'     => static function () {
						return current_user_can( 'edit_posts' );
					},
				)
			);
		}

		register_post_meta(
			self::POST_TYPE,
			self::META_ALLOW_MULTIPLE_REGISTRATIONS,
			array(
				'type'              => 'boolean',
				'single'            => true,
				'show_in_rest'      => true,
				'default'           => false,
				'sanitize_callback' => 'rest_sanitize_boolean',
				'auth_callback'     => static function () {
					return current_user_can( 'edit_posts' );
				},
			)
		);
	}

	/**
	 * Admin meta box.
	 */
	public static function add_meta_boxes() {
		add_meta_box(
			'radioudaan-ru-event-settings',
			__( 'Mobile app settings', 'radioudaan-app-api' ),
			array( __CLASS__, 'render_meta_box' ),
			self::POST_TYPE,
			'normal',
			'high'
		);
	}

	/**
	 * @param WP_Post $post Post.
	 */
	public static function render_meta_box( $post ) {
		wp_nonce_field( 'radioudaan_ru_event_meta', 'radioudaan_ru_event_nonce' );

		$code    = get_post_meta( $post->ID, self::META_EVENT_CODE, true );
		$page_id = (int) get_post_meta( $post->ID, self::META_REGISTRATION_PAGE_ID, true );
		$form_id = (int) get_post_meta( $post->ID, self::META_FORMINATOR_FORM_ID, true );
		$status  = get_post_meta( $post->ID, self::META_EVENT_STATUS, true );
		$success         = get_post_meta( $post->ID, self::META_SUCCESS_MESSAGE, true );
		$allow_multiple  = (bool) get_post_meta( $post->ID, self::META_ALLOW_MULTIPLE_REGISTRATIONS, true );

		if ( ! $status ) {
			$status = 'open';
		}

		$registry_codes = array_keys( RadioUdaan_Event_Registry::get_definitions() );
		$code_pick        = ( $code && in_array( $code, $registry_codes, true ) ) ? $code : ( $code ? '__custom__' : '' );
		$code_custom      = ( '__custom__' === $code_pick ) ? $code : '';

		$entries_url = $form_id ? RadioUdaan_Admin_Data::forminator_entries_url( $form_id ) : '';
		$form_url    = $form_id ? RadioUdaan_Admin_Data::forminator_form_url( $form_id ) : '';

		$status_options = array(
			'open'   => __( 'Open — users can register in the app', 'radioudaan-app-api' ),
			'closed' => __( 'Closed — registration disabled', 'radioudaan-app-api' ),
			'draft'  => __( 'Draft — hidden from the app', 'radioudaan-app-api' ),
		);
		?>
		<div class="ru-event-settings">
			<?php if ( $form_url || $entries_url ) : ?>
				<div class="ru-event-actions">
					<?php if ( $form_url ) : ?>
						<a href="<?php echo esc_url( $form_url ); ?>" class="button button-small"><?php esc_html_e( 'Edit form fields', 'radioudaan-app-api' ); ?></a>
					<?php endif; ?>
					<?php if ( $entries_url ) : ?>
						<a href="<?php echo esc_url( $entries_url ); ?>" class="button button-small"><?php esc_html_e( 'View entries', 'radioudaan-app-api' ); ?></a>
					<?php endif; ?>
				</div>
			<?php endif; ?>

			<div class="ru-event-grid">
				<div class="ru-event-field">
					<label for="ru_event_status"><?php esc_html_e( 'App status', 'radioudaan-app-api' ); ?></label>
					<?php RadioUdaan_Event_Meta_Ui::render_select( 'ru_event_status', 'ru_event_status', $status_options, $status ); ?>
				</div>

				<div class="ru-event-field">
					<label for="ru_forminator_form_id"><?php esc_html_e( 'Registration form', 'radioudaan-app-api' ); ?></label>
					<?php
					RadioUdaan_Event_Meta_Ui::render_select(
						'ru_forminator_form_id',
						'ru_forminator_form_id',
						RadioUdaan_Event_Meta_Ui::get_forminator_choices(),
						$form_id,
						array( 'required' => 'required' )
					);
					?>
					<p class="description"><?php esc_html_e( 'Forminator form used for web and mobile registrations.', 'radioudaan-app-api' ); ?></p>
				</div>

				<div class="ru-event-field">
					<label for="ru_registration_page_id"><?php esc_html_e( 'Website registration page', 'radioudaan-app-api' ); ?></label>
					<select name="ru_registration_page_id" id="ru_registration_page_id" class="ru-event-select widefat">
						<?php foreach ( RadioUdaan_Event_Meta_Ui::get_page_choices() as $id => $label ) : ?>
							<?php
							$slug = '';
							if ( $id > 0 ) {
								$p = get_post( $id );
								$slug = $p ? $p->post_name : '';
							}
							?>
							<option value="<?php echo (int) $id; ?>" data-slug="<?php echo esc_attr( $slug ); ?>" <?php selected( $page_id, $id ); ?>>
								<?php echo esc_html( $label ); ?>
							</option>
						<?php endforeach; ?>
					</select>
					<p class="description"><?php esc_html_e( 'Optional public page with the same form (for web sign-ups).', 'radioudaan-app-api' ); ?></p>
				</div>

				<div class="ru-event-field">
					<label for="ru_event_code_pick"><?php esc_html_e( 'Event code', 'radioudaan-app-api' ); ?></label>
					<?php RadioUdaan_Event_Meta_Ui::render_select( 'ru_event_code_pick', 'ru_event_code_pick', RadioUdaan_Event_Meta_Ui::get_event_code_choices(), $code_pick ); ?>
					<input type="text" id="ru_event_code_custom" class="widefat" value="<?php echo esc_attr( $code_custom ); ?>" placeholder="<?php esc_attr_e( 'e.g. registration-udaan-idol', 'radioudaan-app-api' ); ?>" style="<?php echo '__custom__' === $code_pick ? '' : 'display:none;'; ?>" />
					<input type="hidden" name="ru_event_code" id="ru_event_code" value="<?php echo esc_attr( $code ); ?>" />
					<p class="description"><?php esc_html_e( 'Stable ID for the API. Pick a preset or enter a custom slug.', 'radioudaan-app-api' ); ?></p>
				</div>
			</div>

			<div class="ru-event-field" style="margin-top:8px;">
				<label>
					<input type="checkbox" name="ru_allow_multiple_registrations" id="ru_allow_multiple_registrations" value="1" <?php checked( $allow_multiple ); ?> />
					<?php esc_html_e( 'Allow multiple registrations per email', 'radioudaan-app-api' ); ?>
				</label>
				<p class="description"><?php esc_html_e( 'When unchecked, each account email may register only once for this event (if duplicate prevention is enabled globally).', 'radioudaan-app-api' ); ?></p>
			</div>

			<div class="ru-event-field" style="margin-top:8px;">
				<label for="ru_success_message"><?php esc_html_e( 'Success message (app)', 'radioudaan-app-api' ); ?></label>
				<?php RadioUdaan_Event_Meta_Ui::render_select( 'ru_success_preset', 'ru_success_preset', RadioUdaan_Event_Meta_Ui::get_success_message_presets(), '' ); ?>
				<textarea name="ru_success_message" id="ru_success_message" class="widefat" rows="3" placeholder="<?php esc_attr_e( 'Shown after a successful registration in the mobile app.', 'radioudaan-app-api' ); ?>"><?php echo esc_textarea( $success ); ?></textarea>
			</div>
		</div>
		<?php
	}

	/**
	 * @param int     $post_id Post ID.
	 * @param WP_Post $post    Post.
	 */
	public static function save_meta_box( $post_id, $post ) {
		unset( $post );

		if ( ! isset( $_POST['radioudaan_ru_event_nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['radioudaan_ru_event_nonce'] ) ), 'radioudaan_ru_event_meta' ) ) {
			return;
		}

		if ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) {
			return;
		}

		if ( ! current_user_can( 'edit_post', $post_id ) ) {
			return;
		}

		if ( isset( $_POST['ru_event_code'] ) ) {
			update_post_meta( $post_id, self::META_EVENT_CODE, sanitize_key( wp_unslash( $_POST['ru_event_code'] ) ) );
		}
		if ( isset( $_POST['ru_registration_page_id'] ) ) {
			update_post_meta( $post_id, self::META_REGISTRATION_PAGE_ID, (int) $_POST['ru_registration_page_id'] );
		}
		if ( isset( $_POST['ru_forminator_form_id'] ) ) {
			update_post_meta( $post_id, self::META_FORMINATOR_FORM_ID, (int) $_POST['ru_forminator_form_id'] );
		}
		if ( isset( $_POST['ru_event_status'] ) ) {
			$status = sanitize_key( wp_unslash( $_POST['ru_event_status'] ) );
			if ( in_array( $status, array( 'open', 'closed', 'draft' ), true ) ) {
				update_post_meta( $post_id, self::META_EVENT_STATUS, $status );
			}
		}
		if ( isset( $_POST['ru_success_message'] ) ) {
			update_post_meta( $post_id, self::META_SUCCESS_MESSAGE, sanitize_textarea_field( wp_unslash( $_POST['ru_success_message'] ) ) );
		}
		update_post_meta( $post_id, self::META_ALLOW_MULTIPLE_REGISTRATIONS, ! empty( $_POST['ru_allow_multiple_registrations'] ) );
	}
}

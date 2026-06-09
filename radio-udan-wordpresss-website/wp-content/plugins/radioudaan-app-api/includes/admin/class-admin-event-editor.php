<?php
/**
 * Simple in-plugin event editor (no WordPress post screen).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Client-friendly event create/edit inside the app dashboard.
 */
class RadioUdaan_Admin_Event_Editor {

	/**
	 * @return string
	 */
	public static function edit_url( $event_id = 0 ) {
		$args = array( 'page' => RadioUdaan_Admin_App_Hub::EDIT_EVENT_SLUG );
		if ( $event_id > 0 ) {
			$args['event_id'] = (int) $event_id;
		}
		return add_query_arg( $args, admin_url( 'admin.php' ) );
	}

	/**
	 * Render editor page.
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$event_id = isset( $_GET['event_id'] ) ? (int) $_GET['event_id'] : 0;
		$post     = $event_id ? get_post( $event_id ) : null;

		if ( $event_id && ( ! $post || RadioUdaan_Cpt_Ru_Event::POST_TYPE !== $post->post_type ) ) {
			wp_die( esc_html__( 'Event not found.', 'radioudaan-app-api' ) );
		}

		$is_new = ! $event_id;

		wp_enqueue_media();

		RadioUdaan_Admin_Layout::render_open( 'events', $is_new ? __( 'Add event', 'radioudaan-app-api' ) : __( 'Edit event', 'radioudaan-app-api' ) );

		$title   = $post ? $post->post_title : '';
		$content = $post ? $post->post_content : '';
		$thumb   = $post ? get_post_thumbnail_id( $post->ID ) : 0;
		$thumb_url = $thumb ? wp_get_attachment_image_url( $thumb, 'medium' ) : '';

		RadioUdaan_Admin_Layout::render_page_intro(
			$is_new
				? '<strong>' . esc_html__( 'New event', 'radioudaan-app-api' ) . '</strong> — ' . esc_html__( 'Choose a Forminator form, set Open/Closed/Hidden, then save.', 'radioudaan-app-api' )
				: '<strong>' . esc_html__( 'Edit event', 'radioudaan-app-api' ) . '</strong> — ' . esc_html__( 'Changes appear in the mobile app after save.', 'radioudaan-app-api' )
		);

		self::render_event_fields( $post, $title, $content, $thumb, $thumb_url, $is_new );

		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * @param WP_Post|null $post       Post.
	 * @param string       $title      Title.
	 * @param string       $content    Content.
	 * @param int          $thumb      Attachment ID.
	 * @param string       $thumb_url  Thumb URL.
	 * @param bool         $is_new     New event.
	 */
	private static function render_event_fields( $post, $title, $content, $thumb, $thumb_url, $is_new ) {
		$post_id = $post ? (int) $post->ID : 0;
		$code    = $post ? get_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_CODE, true ) : '';
		$page_id = $post ? (int) get_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_REGISTRATION_PAGE_ID, true ) : 0;
		$form_id = $post ? (int) get_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_FORMINATOR_FORM_ID, true ) : 0;
		$status  = $post ? get_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_STATUS, true ) : 'open';
		$success   = $post ? get_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_SUCCESS_MESSAGE, true ) : '';
		$event_type = $post ? RadioUdaan_Event_Registry::normalize_event_type(
			get_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_TYPE, true )
		) : 'other';
		$start_at_raw = $post ? get_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_START_AT, true ) : '';
		$start_at_local = '';
		if ( $start_at_raw ) {
			$ts = strtotime( (string) $start_at_raw );
			if ( $ts ) {
				$start_at_local = wp_date( 'Y-m-d\TH:i', $ts );
			}
		}

		if ( ! $status ) {
			$status = 'open';
		}

		$event_type_options = array(
			'live_stream' => __( 'Live stream', 'radioudaan-app-api' ),
			'workshop'    => __( 'Workshop', 'radioudaan-app-api' ),
			'other'       => __( 'General event (no badge)', 'radioudaan-app-api' ),
		);

		$registry_codes = array_keys( RadioUdaan_Event_Registry::get_definitions() );
		$code_pick      = ( $code && in_array( $code, $registry_codes, true ) ) ? $code : ( $code ? '__custom__' : '' );
		$code_custom    = ( '__custom__' === $code_pick ) ? $code : '';

		$status_options = array(
			'open'   => __( 'Open — people can register', 'radioudaan-app-api' ),
			'closed' => __( 'Closed — registration stopped', 'radioudaan-app-api' ),
			'draft'  => __( 'Hidden — not shown in the app', 'radioudaan-app-api' ),
		);
		?>
		<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" class="ru-event-settings ru-event-editor-form">
			<?php wp_nonce_field( 'radioudaan_save_event' ); ?>
			<input type="hidden" name="action" value="radioudaan_save_event" />
			<input type="hidden" name="event_id" value="<?php echo (int) $post_id; ?>" />
			<input type="hidden" name="featured_image_id" id="ru_featured_image_id" value="<?php echo (int) $thumb; ?>" />

			<div class="ru-admin__panel">
				<div class="ru-admin__panel-head">
					<h2><?php echo $is_new ? esc_html__( 'New event', 'radioudaan-app-api' ) : esc_html__( 'Edit event', 'radioudaan-app-api' ); ?></h2>
					<a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENTS_SLUG ) ); ?>" class="button ru-btn-large"><?php esc_html_e( 'Back to events', 'radioudaan-app-api' ); ?></a>
				</div>
				<div class="ru-admin__panel-body">
					<div class="ru-event-field">
						<label for="event_title"><?php esc_html_e( 'Event name', 'radioudaan-app-api' ); ?></label>
						<input type="text" name="event_title" id="event_title" class="widefat ru-input-large" required value="<?php echo esc_attr( $title ); ?>" />
						<p class="description"><?php esc_html_e( 'Shown in the mobile app events list.', 'radioudaan-app-api' ); ?></p>
					</div>

					<div class="ru-event-field">
						<label for="event_content"><?php esc_html_e( 'Description', 'radioudaan-app-api' ); ?></label>
						<textarea name="event_content" id="event_content" class="widefat" rows="5"><?php echo esc_textarea( $content ); ?></textarea>
					</div>

					<div class="ru-event-field">
						<label><?php esc_html_e( 'Banner image', 'radioudaan-app-api' ); ?></label>
						<div id="ru-thumb-preview" class="ru-thumb-preview">
							<?php if ( $thumb_url ) : ?>
								<img src="<?php echo esc_url( $thumb_url ); ?>" alt="" />
							<?php endif; ?>
						</div>
						<p>
							<button type="button" class="button ru-btn-large" id="ru-pick-image"><?php esc_html_e( 'Choose image', 'radioudaan-app-api' ); ?></button>
							<button type="button" class="button ru-btn-large" id="ru-remove-image" <?php echo $thumb ? '' : 'style="display:none"'; ?>><?php esc_html_e( 'Remove image', 'radioudaan-app-api' ); ?></button>
						</p>
					</div>

					<div class="ru-event-grid">
						<div class="ru-event-field">
							<label for="ru_event_type"><?php esc_html_e( 'Event type badge', 'radioudaan-app-api' ); ?></label>
							<?php RadioUdaan_Event_Meta_Ui::render_select( 'ru_event_type', 'ru_event_type', $event_type_options, $event_type ); ?>
							<p class="description"><?php esc_html_e( 'Shown on the event card in the mobile app (e.g. LIVE STREAM, WORKSHOP).', 'radioudaan-app-api' ); ?></p>
						</div>
						<div class="ru-event-field">
							<label for="ru_event_start_at"><?php esc_html_e( 'Event date & time', 'radioudaan-app-api' ); ?></label>
							<input type="datetime-local" name="ru_event_start_at" id="ru_event_start_at" class="widefat"
								value="<?php echo esc_attr( $start_at_local ); ?>" />
							<p class="description"><?php esc_html_e( 'Displayed in the app (IST). Leave empty to hide the date line.', 'radioudaan-app-api' ); ?></p>
						</div>
						<div class="ru-event-field">
							<label for="ru_event_status"><?php esc_html_e( 'Registration status', 'radioudaan-app-api' ); ?></label>
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
						</div>
						<div class="ru-event-field">
							<label for="ru_registration_page_id"><?php esc_html_e( 'Website page (optional)', 'radioudaan-app-api' ); ?></label>
							<select name="ru_registration_page_id" id="ru_registration_page_id" class="ru-event-select widefat">
								<?php foreach ( RadioUdaan_Event_Meta_Ui::get_page_choices() as $id => $label ) : ?>
									<option value="<?php echo (int) $id; ?>" <?php selected( $page_id, $id ); ?>><?php echo esc_html( $label ); ?></option>
								<?php endforeach; ?>
							</select>
						</div>
						<div class="ru-event-field">
							<label for="ru_event_code_pick"><?php esc_html_e( 'Internal event code', 'radioudaan-app-api' ); ?></label>
							<?php RadioUdaan_Event_Meta_Ui::render_select( 'ru_event_code_pick', 'ru_event_code_pick', RadioUdaan_Event_Meta_Ui::get_event_code_choices(), $code_pick ); ?>
							<input type="text" id="ru_event_code_custom" class="widefat" value="<?php echo esc_attr( $code_custom ); ?>" style="<?php echo '__custom__' === $code_pick ? '' : 'display:none;'; ?>" />
							<input type="hidden" name="ru_event_code" id="ru_event_code" value="<?php echo esc_attr( $code ); ?>" />
						</div>
					</div>

					<div class="ru-event-field">
						<label for="ru_success_message"><?php esc_html_e( 'Thank-you message in the app', 'radioudaan-app-api' ); ?></label>
						<?php RadioUdaan_Event_Meta_Ui::render_select( 'ru_success_preset', 'ru_success_preset', RadioUdaan_Event_Meta_Ui::get_success_message_presets(), '' ); ?>
						<textarea name="ru_success_message" id="ru_success_message" class="widefat" rows="3"><?php echo esc_textarea( $success ); ?></textarea>
					</div>

					<?php if ( $form_id ) : ?>
						<p class="description">
							<?php esc_html_e( 'To change form questions (name, uploads, etc.), use the advanced link on the Events page after saving.', 'radioudaan-app-api' ); ?>
						</p>
					<?php endif; ?>
				</div>
			</div>

			<div class="ru-form-sticky-footer">
				<p class="ru-form-sticky-footer__hint"><?php esc_html_e( 'Save to update the mobile app events list.', 'radioudaan-app-api' ); ?></p>
				<button type="submit" class="button button-primary ru-btn-large"><?php esc_html_e( 'Save event', 'radioudaan-app-api' ); ?></button>
			</div>
		</form>
		<?php
	}

	/**
	 * Save event from dashboard form.
	 */
	public static function handle_save() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		check_admin_referer( 'radioudaan_save_event' );

		$event_id = isset( $_POST['event_id'] ) ? (int) $_POST['event_id'] : 0;
		$title    = isset( $_POST['event_title'] ) ? sanitize_text_field( wp_unslash( $_POST['event_title'] ) ) : '';
		$content  = isset( $_POST['event_content'] ) ? wp_kses_post( wp_unslash( $_POST['event_content'] ) ) : '';

		if ( ! $title ) {
			wp_die( esc_html__( 'Event name is required.', 'radioudaan-app-api' ) );
		}

		$postarr = array(
			'post_type'    => RadioUdaan_Cpt_Ru_Event::POST_TYPE,
			'post_title'   => $title,
			'post_content' => $content,
			'post_status'  => 'publish',
		);

		if ( $event_id ) {
			$postarr['ID'] = $event_id;
			$result        = wp_update_post( $postarr, true );
		} else {
			$postarr['menu_order'] = RadioUdaan_Admin_Data::get_next_event_menu_order();
			$result                = wp_insert_post( $postarr, true );
		}

		if ( is_wp_error( $result ) || ! $result ) {
			wp_die( esc_html__( 'Could not save event.', 'radioudaan-app-api' ) );
		}

		$event_id = (int) $result;

		if ( isset( $_POST['ru_event_code'] ) ) {
			$code = sanitize_key( wp_unslash( $_POST['ru_event_code'] ) );
			if ( $code ) {
				update_post_meta( $event_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_CODE, $code );
			}
		}
		if ( isset( $_POST['ru_registration_page_id'] ) ) {
			update_post_meta( $event_id, RadioUdaan_Cpt_Ru_Event::META_REGISTRATION_PAGE_ID, (int) $_POST['ru_registration_page_id'] );
		}
		if ( isset( $_POST['ru_forminator_form_id'] ) ) {
			update_post_meta( $event_id, RadioUdaan_Cpt_Ru_Event::META_FORMINATOR_FORM_ID, (int) $_POST['ru_forminator_form_id'] );
		}
		if ( isset( $_POST['ru_event_status'] ) ) {
			$status = sanitize_key( wp_unslash( $_POST['ru_event_status'] ) );
			if ( in_array( $status, array( 'open', 'closed', 'draft' ), true ) ) {
				update_post_meta( $event_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_STATUS, $status );
			}
		}
		if ( isset( $_POST['ru_success_message'] ) ) {
			update_post_meta( $event_id, RadioUdaan_Cpt_Ru_Event::META_SUCCESS_MESSAGE, sanitize_textarea_field( wp_unslash( $_POST['ru_success_message'] ) ) );
		}
		if ( isset( $_POST['ru_event_type'] ) ) {
			update_post_meta(
				$event_id,
				RadioUdaan_Cpt_Ru_Event::META_EVENT_TYPE,
				RadioUdaan_Event_Registry::normalize_event_type( wp_unslash( $_POST['ru_event_type'] ) )
			);
		}
		if ( isset( $_POST['ru_event_start_at'] ) ) {
			$start_raw = sanitize_text_field( wp_unslash( $_POST['ru_event_start_at'] ) );
			if ( $start_raw === '' ) {
				delete_post_meta( $event_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_START_AT );
			} else {
				$ts = strtotime( $start_raw );
				update_post_meta(
					$event_id,
					RadioUdaan_Cpt_Ru_Event::META_EVENT_START_AT,
					$ts ? gmdate( 'c', $ts ) : ''
				);
			}
		}

		$thumb_id = isset( $_POST['featured_image_id'] ) ? (int) $_POST['featured_image_id'] : 0;
		if ( $thumb_id ) {
			set_post_thumbnail( $event_id, $thumb_id );
		} else {
			delete_post_thumbnail( $event_id );
		}

		wp_safe_redirect(
			add_query_arg(
				array(
					'page'              => RadioUdaan_Admin_App_Hub::EVENTS_SLUG,
					'radioudaan_notice' => 'success',
					'radioudaan_detail' => rawurlencode(
						sprintf(
							/* translators: %s: event title */
							__( 'Saved: %s', 'radioudaan-app-api' ),
							$title
						)
					),
				),
				admin_url( 'admin.php' )
			)
		);
		exit;
	}
}

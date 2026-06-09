<?php
/**
 * View a single registration inside the app dashboard.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Client-friendly registration detail (no Forminator UI required).
 */
class RadioUdaan_Admin_Entry_Viewer {

	/**
	 * @param int $entry_id Entry ID.
	 * @param int $form_id  Form ID.
	 * @return string
	 */
	public static function view_url( $entry_id, $form_id ) {
		return add_query_arg(
			array(
				'page'     => RadioUdaan_Admin_App_Hub::VIEW_ENTRY_SLUG,
				'entry_id' => (int) $entry_id,
				'form_id'  => (int) $form_id,
			),
			admin_url( 'admin.php' )
		);
	}

	/**
	 * Render detail page.
	 */
	public static function render_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}

		$entry_id = isset( $_GET['entry_id'] ) ? (int) $_GET['entry_id'] : 0;
		$form_id  = isset( $_GET['form_id'] ) ? (int) $_GET['form_id'] : 0;

		if ( ! $entry_id || ! $form_id ) {
			wp_die( esc_html__( 'Invalid registration.', 'radioudaan-app-api' ) );
		}

		$detail = self::get_entry_detail( $entry_id, $form_id );
		if ( is_wp_error( $detail ) ) {
			wp_die( esc_html( $detail->get_error_message() ) );
		}

		RadioUdaan_Admin_Layout::render_open( 'event-entries', __( 'Event entry details', 'radioudaan-app-api' ) );
		RadioUdaan_Admin_Layout::render_page_intro(
			'<strong>' . esc_html( $detail['event_title'] ) . '</strong> — ' .
			esc_html( $detail['date'] ) . ' · ' . esc_html( $detail['source_label'] )
		);
		?>
		<div class="ru-admin__panel">
			<div class="ru-admin__panel-head">
				<h2><?php esc_html_e( 'Event entry details', 'radioudaan-app-api' ); ?></h2>
				<a href="<?php echo esc_url( admin_url( 'admin.php?page=' . RadioUdaan_Admin_App_Hub::EVENT_ENTRIES_SLUG ) ); ?>" class="button ru-btn-large"><?php esc_html_e( 'Back to event entries', 'radioudaan-app-api' ); ?></a>
			</div>
			<div class="ru-admin__panel-body" style="padding:0;">
				<table class="ru-admin__table ru-detail-table">
					<tbody>
					<tr>
						<th scope="row"><?php esc_html_e( 'Submitted', 'radioudaan-app-api' ); ?></th>
						<td><?php echo esc_html( $detail['date'] ); ?></td>
					</tr>
					<tr>
						<th scope="row"><?php esc_html_e( 'Source', 'radioudaan-app-api' ); ?></th>
						<td><strong><?php echo esc_html( $detail['source_label'] ); ?></strong></td>
					</tr>
					<tr>
						<th scope="row"><?php esc_html_e( 'Event', 'radioudaan-app-api' ); ?></th>
						<td><?php echo esc_html( $detail['event_title'] ); ?></td>
					</tr>
					<tr>
						<th scope="row"><?php esc_html_e( 'Phone', 'radioudaan-app-api' ); ?></th>
						<td><?php echo esc_html( $detail['phone'] ); ?></td>
					</tr>
					<?php foreach ( $detail['fields'] as $row ) : ?>
						<tr>
							<th scope="row"><?php echo esc_html( $row['label'] ); ?></th>
							<td><?php echo wp_kses_post( $row['value'] ); ?></td>
						</tr>
					<?php endforeach; ?>
					</tbody>
				</table>
			</div>
		</div>
		<p class="description">
			<a href="<?php echo esc_url( RadioUdaan_Admin_Data::forminator_entries_url( $form_id ) ); ?>" class="button"><?php esc_html_e( 'Open in advanced form tool (optional)', 'radioudaan-app-api' ); ?></a>
		</p>
		<?php
		RadioUdaan_Admin_Layout::render_close();
	}

	/**
	 * @param int $entry_id Entry ID.
	 * @param int $form_id  Form ID.
	 * @return array|WP_Error
	 */
	public static function get_entry_detail( $entry_id, $form_id ) {
		if ( ! class_exists( 'Forminator_Form_Entry_Model' ) ) {
			return new WP_Error( 'no_forminator', __( 'Forminator is not available.', 'radioudaan-app-api' ) );
		}

		$entry = new Forminator_Form_Entry_Model( $entry_id );
		if ( empty( $entry->entry_id ) ) {
			return new WP_Error( 'not_found', __( 'Registration not found.', 'radioudaan-app-api' ) );
		}

		$entry->load_meta();

		$labels = self::get_field_labels( $form_id );
		$fields = array();

		foreach ( $entry->meta_data as $key => $meta ) {
			if ( 0 === strpos( $key, '_' ) ) {
				continue;
			}
			$value = isset( $meta['value'] ) ? $meta['value'] : '';
			$fields[] = array(
				'label' => isset( $labels[ $key ] ) ? $labels[ $key ] : $key,
				'value' => self::format_value( $value ),
			);
		}

		$source = $entry->get_meta( RadioUdaan_Entry_Source::META_KEY, '' );
		$code   = $entry->get_meta( '_radioudaan_event_code', '' );
		$phone  = $entry->get_meta( '_radioudaan_phone_e164', '' );

		$event_title = __( 'Event', 'radioudaan-app-api' );
		foreach ( RadioUdaan_Admin_Data::get_managed_events() as $ev ) {
			if ( ! empty( $ev['event_code'] ) && $ev['event_code'] === $code ) {
				$event_title = $ev['title'];
				break;
			}
		}

		return array(
			'date'         => $entry->date_created,
			'source_label' => RadioUdaan_Entry_Source::label_for( $source ),
			'event_title'  => $event_title,
			'phone'        => $phone ? $phone : '—',
			'fields'       => $fields,
		);
	}

	/**
	 * @param int $form_id Form ID.
	 * @return array<string,string>
	 */
	private static function get_field_labels( $form_id ) {
		$labels = array();
		if ( ! class_exists( 'Forminator_API' ) ) {
			return $labels;
		}
		Forminator_API::initialize();
		$form = Forminator_API::get_form( $form_id );
		if ( is_wp_error( $form ) || ! is_object( $form ) || ! method_exists( $form, 'get_fields_as_array' ) ) {
			return $labels;
		}
		foreach ( $form->get_fields_as_array() as $field ) {
			if ( ! empty( $field['element_id'] ) ) {
				$labels[ $field['element_id'] ] = ! empty( $field['field_label'] ) ? $field['field_label'] : $field['element_id'];
			}
		}
		return $labels;
	}

	/**
	 * @param mixed $value Raw value.
	 * @return string
	 */
	private static function format_value( $value ) {
		if ( is_array( $value ) ) {
			if ( isset( $value['file_url'] ) ) {
				return '<a href="' . esc_url( $value['file_url'] ) . '" target="_blank" rel="noopener">' . esc_html__( 'Download file', 'radioudaan-app-api' ) . '</a>';
			}
			if ( isset( $value['file']['file_url'] ) ) {
				return '<a href="' . esc_url( $value['file']['file_url'] ) . '" target="_blank" rel="noopener">' . esc_html__( 'Download file', 'radioudaan-app-api' ) . '</a>';
			}
			return esc_html( wp_json_encode( $value ) );
		}
		return esc_html( (string) $value );
	}
}

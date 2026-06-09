<?php
/**
 * Tag Forminator entries with source=app|web for reporting.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Entry source metadata on Forminator submissions.
 */
class RadioUdaan_Entry_Source {

	const META_KEY = '_radioudaan_source';

	const SOURCE_APP = 'app';
	const SOURCE_WEB = 'web';

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'forminator_after_handle_form', array( __CLASS__, 'tag_web_submission' ), 10, 1 );
	}

	/**
	 * After a browser Forminator submit, tag as web if this form belongs to an app event.
	 *
	 * @param Forminator_Form_Entry_Model $entry Entry model.
	 */
	public static function tag_web_submission( $entry ) {
		if ( ! $entry instanceof Forminator_Form_Entry_Model || empty( $entry->entry_id ) ) {
			return;
		}

		if ( 'custom-forms' !== $entry->entry_type ) {
			return;
		}

		$existing = self::get_entry_source( (int) $entry->entry_id );
		if ( $existing ) {
			return;
		}

		$form_id = (int) $entry->form_id;
		$event   = self::get_event_by_form_id( $form_id );
		if ( ! $event ) {
			return;
		}

		$meta = array(
			array(
				'name'  => self::META_KEY,
				'value' => self::SOURCE_WEB,
			),
			array(
				'name'  => '_radioudaan_event_id',
				'value' => (int) $event['event_id'],
			),
			array(
				'name'  => '_radioudaan_event_code',
				'value' => $event['event_code'],
			),
		);

		$entry->set_fields( $meta );
	}

	/**
	 * @param int $entry_id Entry ID.
	 * @return string app|web|''
	 */
	public static function get_entry_source( $entry_id ) {
		global $wpdb;

		$meta_table = $wpdb->prefix . 'frmt_form_entry_meta';

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching
		$value = $wpdb->get_var(
			$wpdb->prepare(
				"SELECT meta_value FROM {$meta_table} WHERE entry_id = %d AND meta_key = %s LIMIT 1",
				(int) $entry_id,
				self::META_KEY
			)
		);

		return is_string( $value ) ? $value : '';
	}

	/**
	 * @param int $form_id Forminator form ID.
	 * @return array{event_id:int,event_code:string}|null
	 */
	public static function get_event_by_form_id( $form_id ) {
		$form_id = (int) $form_id;
		if ( $form_id <= 0 ) {
			return null;
		}

		$posts = get_posts(
			array(
				'post_type'      => RadioUdaan_Cpt_Ru_Event::POST_TYPE,
				'post_status'    => 'any',
				'posts_per_page' => 1,
				'meta_key'       => RadioUdaan_Cpt_Ru_Event::META_FORMINATOR_FORM_ID,
				'meta_value'     => $form_id,
				'fields'         => 'ids',
			)
		);

		if ( ! empty( $posts[0] ) ) {
			$post_id = (int) $posts[0];
			return array(
				'event_id'   => $post_id,
				'event_code' => (string) get_post_meta( $post_id, RadioUdaan_Cpt_Ru_Event::META_EVENT_CODE, true ),
			);
		}

		foreach ( RadioUdaan_Event_Registry::get_definitions() as $code => $def ) {
			if ( RadioUdaan_Event_Registry::get_forminator_id( $code ) === $form_id ) {
				return array(
					'event_id'   => (int) $def['page_id'],
					'event_code' => $code,
				);
			}
		}

		return null;
	}

	/**
	 * Human label for admin UI.
	 *
	 * @param string $source Raw source.
	 * @return string
	 */
	public static function label_for( $source ) {
		if ( self::SOURCE_APP === $source ) {
			return __( 'Mobile app', 'radioudaan-app-api' );
		}
		if ( self::SOURCE_WEB === $source ) {
			return __( 'Website', 'radioudaan-app-api' );
		}
		return __( 'Unknown', 'radioudaan-app-api' );
	}
}

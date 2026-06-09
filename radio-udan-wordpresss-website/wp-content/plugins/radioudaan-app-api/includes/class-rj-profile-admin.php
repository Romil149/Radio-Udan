<?php
/**
 * RJ profile fields on WordPress Users → Profile.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Admin UI for RJ user meta.
 */
class RadioUdaan_Rj_Profile_Admin {

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'show_user_profile', array( __CLASS__, 'render_fields' ) );
		add_action( 'edit_user_profile', array( __CLASS__, 'render_fields' ) );
		add_action( 'personal_options_update', array( __CLASS__, 'save_fields' ) );
		add_action( 'edit_user_profile_update', array( __CLASS__, 'save_fields' ) );
		add_action( 'admin_enqueue_scripts', array( __CLASS__, 'enqueue_media' ) );
	}

	/**
	 * @param string $hook Admin hook.
	 */
	public static function enqueue_media( $hook ) {
		if ( ! in_array( $hook, array( 'profile.php', 'user-edit.php' ), true ) ) {
			return;
		}
		wp_enqueue_media();
		wp_enqueue_script(
			'radioudaan-rj-profile-admin',
			RADIOUDAAN_APP_API_URL . 'assets/js/rj-profile-admin.js',
			array( 'jquery' ),
			RADIOUDAAN_APP_API_VERSION,
			true
		);
	}

	/**
	 * @param WP_User $user User being edited.
	 */
	public static function render_fields( $user ) {
		if ( ! self::can_edit_rj_fields( $user ) ) {
			return;
		}

		$profile   = RadioUdaan_Rj_Profile::get_profile( $user->ID );
		$is_admin  = current_user_can( 'manage_options' );
		$photo_id  = (int) $profile['photo_id'];
		$photo_url = $profile['photo_url'];
		?>
		<h2><?php esc_html_e( 'Radio Udaan RJ profile', 'radioudaan-app-api' ); ?></h2>
		<p class="description">
			<?php esc_html_e( 'Public information shown on Meet Our RJs and linked from radio show schedules.', 'radioudaan-app-api' ); ?>
		</p>
		<table class="form-table" role="presentation">
			<tr>
				<th><label for="radioudaan_rj_display_name"><?php esc_html_e( 'RJ display name', 'radioudaan-app-api' ); ?></label></th>
				<td>
					<input type="text" name="radioudaan_rj_display_name" id="radioudaan_rj_display_name" class="regular-text"
						value="<?php echo esc_attr( $profile['display_name'] ); ?>" />
				</td>
			</tr>
			<tr>
				<th><label for="radioudaan_rj_bio"><?php esc_html_e( 'Bio', 'radioudaan-app-api' ); ?></label></th>
				<td>
					<textarea name="radioudaan_rj_bio" id="radioudaan_rj_bio" rows="6" class="large-text"><?php echo esc_textarea( $profile['bio_plain'] ); ?></textarea>
				</td>
			</tr>
			<tr>
				<th><label for="radioudaan_rj_show_name"><?php esc_html_e( 'Show / tagline', 'radioudaan-app-api' ); ?></label></th>
				<td>
					<input type="text" name="radioudaan_rj_show_name" id="radioudaan_rj_show_name" class="regular-text"
						value="<?php echo esc_attr( $profile['show_name'] ); ?>" />
				</td>
			</tr>
			<tr>
				<th><label for="radioudaan_rj_experience"><?php esc_html_e( 'Experience', 'radioudaan-app-api' ); ?></label></th>
				<td>
					<input type="text" name="radioudaan_rj_experience" id="radioudaan_rj_experience" class="regular-text"
						value="<?php echo esc_attr( $profile['experience'] ); ?>" />
				</td>
			</tr>
			<tr>
				<th><?php esc_html_e( 'Profile photo', 'radioudaan-app-api' ); ?></th>
				<td>
					<input type="hidden" name="radioudaan_rj_photo_id" id="radioudaan_rj_photo_id" value="<?php echo (int) $photo_id; ?>" />
					<div id="radioudaan-rj-photo-preview" style="margin-bottom:10px;">
						<?php if ( $photo_url ) : ?>
							<img src="<?php echo esc_url( $photo_url ); ?>" alt="" style="max-width:220px;border-radius:12px;" />
						<?php endif; ?>
					</div>
					<button type="button" class="button" id="radioudaan-rj-pick-photo"><?php esc_html_e( 'Choose photo', 'radioudaan-app-api' ); ?></button>
					<button type="button" class="button" id="radioudaan-rj-remove-photo" <?php echo $photo_id ? '' : 'style="display:none;"'; ?>>
						<?php esc_html_e( 'Remove', 'radioudaan-app-api' ); ?>
					</button>
				</td>
			</tr>
			<tr>
				<th><label for="radioudaan_rj_facebook"><?php esc_html_e( 'Facebook URL', 'radioudaan-app-api' ); ?></label></th>
				<td><input type="url" name="radioudaan_rj_facebook" id="radioudaan_rj_facebook" class="regular-text" value="<?php echo esc_attr( $profile['facebook_url'] ); ?>" /></td>
			</tr>
			<tr>
				<th><label for="radioudaan_rj_instagram"><?php esc_html_e( 'Instagram URL', 'radioudaan-app-api' ); ?></label></th>
				<td><input type="url" name="radioudaan_rj_instagram" id="radioudaan_rj_instagram" class="regular-text" value="<?php echo esc_attr( $profile['instagram_url'] ); ?>" /></td>
			</tr>
			<tr>
				<th><label for="radioudaan_rj_youtube"><?php esc_html_e( 'YouTube URL', 'radioudaan-app-api' ); ?></label></th>
				<td><input type="url" name="radioudaan_rj_youtube" id="radioudaan_rj_youtube" class="regular-text" value="<?php echo esc_attr( $profile['youtube_url'] ); ?>" /></td>
			</tr>
			<tr>
				<th><?php esc_html_e( 'Public profile', 'radioudaan-app-api' ); ?></th>
				<td>
					<label>
						<input type="checkbox" name="radioudaan_rj_is_public" value="1" <?php checked( $profile['is_public'] ); ?> />
						<?php esc_html_e( 'Show on Meet Our RJs', 'radioudaan-app-api' ); ?>
					</label>
					<?php if ( $profile['profile_url'] ) : ?>
						<p class="description">
							<a href="<?php echo esc_url( $profile['profile_url'] ); ?>" target="_blank" rel="noopener noreferrer">
								<?php esc_html_e( 'View public profile', 'radioudaan-app-api' ); ?>
							</a>
						</p>
					<?php endif; ?>
				</td>
			</tr>
			<?php if ( $is_admin ) : ?>
			<tr>
				<th><label for="radioudaan_rj_public_phone"><?php esc_html_e( 'Public phone (E.164)', 'radioudaan-app-api' ); ?></label></th>
				<td>
					<input type="text" name="radioudaan_rj_public_phone" id="radioudaan_rj_public_phone" class="regular-text"
						value="<?php echo esc_attr( $profile['public_phone_e164'] ); ?>" placeholder="+919876543210" />
					<p class="description"><?php esc_html_e( 'Reserved for future app linking; not shown on the website yet.', 'radioudaan-app-api' ); ?></p>
				</td>
			</tr>
			<tr>
				<th><label for="radioudaan_rj_linked_app_user"><?php esc_html_e( 'Linked app user ID', 'radioudaan-app-api' ); ?></label></th>
				<td>
					<input type="number" min="0" name="radioudaan_rj_linked_app_user" id="radioudaan_rj_linked_app_user" class="small-text"
						value="<?php echo (int) $profile['linked_app_user_id']; ?>" />
					<p class="description"><?php esc_html_e( 'Optional link to wp_ru_app_users.id for a future unified login.', 'radioudaan-app-api' ); ?></p>
				</td>
			</tr>
			<?php endif; ?>
		</table>
		<?php
	}

	/**
	 * @param int $user_id User ID.
	 */
	public static function save_fields( $user_id ) {
		$user = get_user_by( 'id', (int) $user_id );
		if ( ! $user || ! self::can_edit_rj_fields( $user ) ) {
			return;
		}

		if ( ! current_user_can( 'edit_user', $user_id ) ) {
			return;
		}

		$data = array(
			'display_name' => isset( $_POST['radioudaan_rj_display_name'] )
				? sanitize_text_field( wp_unslash( $_POST['radioudaan_rj_display_name'] ) )
				: $user->display_name,
			'bio'          => isset( $_POST['radioudaan_rj_bio'] )
				? wp_kses_post( wp_unslash( $_POST['radioudaan_rj_bio'] ) )
				: '',
			'show_name'    => isset( $_POST['radioudaan_rj_show_name'] )
				? sanitize_text_field( wp_unslash( $_POST['radioudaan_rj_show_name'] ) )
				: '',
			'experience'   => isset( $_POST['radioudaan_rj_experience'] )
				? sanitize_text_field( wp_unslash( $_POST['radioudaan_rj_experience'] ) )
				: '',
			'photo_id'     => isset( $_POST['radioudaan_rj_photo_id'] ) ? (int) $_POST['radioudaan_rj_photo_id'] : 0,
			'facebook_url' => isset( $_POST['radioudaan_rj_facebook'] ) ? esc_url_raw( wp_unslash( $_POST['radioudaan_rj_facebook'] ) ) : '',
			'instagram_url'=> isset( $_POST['radioudaan_rj_instagram'] ) ? esc_url_raw( wp_unslash( $_POST['radioudaan_rj_instagram'] ) ) : '',
			'youtube_url'  => isset( $_POST['radioudaan_rj_youtube'] ) ? esc_url_raw( wp_unslash( $_POST['radioudaan_rj_youtube'] ) ) : '',
			'is_public'    => ! empty( $_POST['radioudaan_rj_is_public'] ),
		);

		if ( current_user_can( 'manage_options' ) ) {
			$data['public_phone_e164']  = isset( $_POST['radioudaan_rj_public_phone'] )
				? sanitize_text_field( wp_unslash( $_POST['radioudaan_rj_public_phone'] ) )
				: '';
			$data['linked_app_user_id'] = isset( $_POST['radioudaan_rj_linked_app_user'] )
				? (int) $_POST['radioudaan_rj_linked_app_user']
				: 0;
		}

		RadioUdaan_Rj_Profile::save_profile( $user_id, $data );
	}

	/**
	 * @param WP_User $user Profile user.
	 * @return bool
	 */
	private static function can_edit_rj_fields( $user ) {
		if ( ! RadioUdaan_Rj_Profile::is_rj( $user ) ) {
			return false;
		}
		if ( current_user_can( 'manage_options' ) ) {
			return true;
		}
		return get_current_user_id() === (int) $user->ID;
	}
}

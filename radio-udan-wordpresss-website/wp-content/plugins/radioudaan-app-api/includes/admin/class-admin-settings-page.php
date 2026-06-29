<?php
/**
 * Tabbed Settings page UI (branding, copy, connection, etc.).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Renders admin.php?page=radioudaan-app-settings.
 */
class RadioUdaan_Admin_Settings_Page {

	/**
	 * @param array<string,mixed> $c Context from RadioUdaan_Admin_Pages::render_settings().
	 */
	public static function render( array $c ) {
		$brand_colors  = $c['brand_colors'];
		$copy_defaults = $c['copy_defaults'];
		$copy_groups   = RadioUdaan_App_Copy_Catalog::groups();

		$tabs = array(
			'branding'   => array( __( 'Branding', 'radioudaan-app-api' ), 'dashicons-art' ),
			'copy'       => array( __( 'App copy', 'radioudaan-app-api' ), 'dashicons-edit' ),
			'connection' => array( __( 'Connection', 'radioudaan-app-api' ), 'dashicons-admin-links' ),
			'live_radio'      => array( __( 'Live radio', 'radioudaan-app-api' ), 'dashicons-controls-play' ),
			'youtube_library' => array( __( 'YouTube library', 'radioudaan-app-api' ), 'dashicons-video-alt3' ),
			'auth'       => array( __( 'App accounts', 'radioudaan-app-api' ), 'dashicons-groups' ),
			'legal'      => array( __( 'Legal URLs', 'radioudaan-app-api' ), 'dashicons-shield' ),
			'about_tab'  => array( __( 'About tab', 'radioudaan-app-api' ), 'dashicons-info-outline' ),
			'uploads'    => array( __( 'Uploads', 'radioudaan-app-api' ), 'dashicons-upload' ),
			'security'   => array( __( 'OTP & limits', 'radioudaan-app-api' ), 'dashicons-lock' ),
			'sms'           => array( __( 'SMS (MSG91)', 'radioudaan-app-api' ), 'dashicons-email-alt' ),
			'notifications' => array( __( 'Notifications', 'radioudaan-app-api' ), 'dashicons-bell' ),
		);
		?>
		<p class="ru-settings-intro">
			<strong><?php esc_html_e( 'Mobile app control centre', 'radioudaan-app-api' ); ?></strong> —
			<?php esc_html_e( 'Branding, text, and limits are sent to the app via GET /config. Save once, then reopen the app to see changes.', 'radioudaan-app-api' ); ?>
		</p>

		<nav class="ru-settings-tabs" role="tablist" aria-label="<?php esc_attr_e( 'Settings sections', 'radioudaan-app-api' ); ?>">
			<?php
			$first = true;
			foreach ( $tabs as $slug => $meta ) :
				?>
				<button type="button" class="ru-settings-tabs__btn<?php echo $first ? ' is-active' : ''; ?>"
					role="tab" aria-selected="<?php echo $first ? 'true' : 'false'; ?>"
					data-tab="<?php echo esc_attr( $slug ); ?>" id="ru-tab-<?php echo esc_attr( $slug ); ?>">
					<span class="dashicons <?php echo esc_attr( $meta[1] ); ?>"></span>
					<?php echo esc_html( $meta[0] ); ?>
				</button>
				<?php
				$first = false;
			endforeach;
			?>
		</nav>

		<!-- Branding -->
		<section class="ru-settings-panel is-active" data-panel="branding" role="tabpanel" aria-labelledby="ru-tab-branding">
			<div class="ru-settings-branding-layout">
				<div class="ru-settings-branding-form">
					<div class="ru-settings-panel__card">
						<h3><?php esc_html_e( 'Identity', 'radioudaan-app-api' ); ?></h3>
						<p class="description"><?php esc_html_e( 'App name and tagline appear on splash, sign-in, and More.', 'radioudaan-app-api' ); ?></p>
						<div class="ru-admin__field">
							<label for="branding_app_name"><?php esc_html_e( 'App name', 'radioudaan-app-api' ); ?></label>
							<input type="text" name="branding_app_name" id="branding_app_name" class="large-text"
								value="<?php echo esc_attr( $c['brand_name'] ); ?>"
								placeholder="<?php echo esc_attr( RadioUdaan_App_Branding::get_app_name() ); ?>" />
						</div>
						<div class="ru-admin__field">
							<label for="branding_tagline"><?php esc_html_e( 'Tagline', 'radioudaan-app-api' ); ?></label>
							<input type="text" name="branding_tagline" id="branding_tagline" class="large-text"
								value="<?php echo esc_attr( $c['brand_tag'] ); ?>"
								placeholder="<?php echo esc_attr( RadioUdaan_App_Branding::get_tagline() ); ?>" />
						</div>
						<div class="ru-admin__field">
							<label><?php esc_html_e( 'App logo', 'radioudaan-app-api' ); ?></label>
							<input type="hidden" name="branding_logo_id" id="branding_logo_id" value="<?php echo (int) $c['brand_logo']; ?>" />
							<div id="ru-brand-logo-preview" class="ru-admin__logo-preview">
								<?php if ( ! empty( $c['brand_logo_u'] ) ) : ?>
									<img src="<?php echo esc_url( $c['brand_logo_u'] ); ?>" alt="" />
								<?php endif; ?>
							</div>
							<p>
								<button type="button" class="button button-secondary" id="ru-pick-brand-logo"><?php esc_html_e( 'Choose logo', 'radioudaan-app-api' ); ?></button>
								<button type="button" class="button" id="ru-remove-brand-logo" <?php echo $c['brand_logo'] ? '' : 'style="display:none;"'; ?>><?php esc_html_e( 'Remove', 'radioudaan-app-api' ); ?></button>
							</p>
							<p class="description"><?php esc_html_e( 'PNG with transparent background recommended.', 'radioudaan-app-api' ); ?></p>
						</div>
					</div>
					<div class="ru-settings-panel__card">
						<h3><?php esc_html_e( 'Colors', 'radioudaan-app-api' ); ?></h3>
						<p class="description"><?php esc_html_e( 'Defaults match radio-udaan.com (orange #ff6b00).', 'radioudaan-app-api' ); ?></p>
						<div class="ru-admin__field ru-admin__color-grid">
							<?php
							$color_labels = RadioUdaan_App_Branding::color_labels();
							foreach ( $color_labels as $key => $label ) :
								$field_id   = 'branding_color_' . $key;
								$hex_value  = $brand_colors[ $key ] ?? '#000000';
								$is_scrim   = ( 'scrim' === $key );
								$picker_hex = $is_scrim && strlen( $hex_value ) >= 7
									? '#' . substr( ltrim( $hex_value, '#' ), -6 )
									: $hex_value;
								?>
								<div class="ru-admin__color-field">
									<label for="<?php echo esc_attr( $field_id ); ?>"><?php echo esc_html( $label ); ?></label>
									<?php if ( ! $is_scrim ) : ?>
									<input type="color" name="<?php echo esc_attr( $field_id ); ?>" id="<?php echo esc_attr( $field_id ); ?>"
										value="<?php echo esc_attr( $picker_hex ); ?>" />
									<?php else : ?>
									<input type="hidden" name="<?php echo esc_attr( $field_id ); ?>" id="<?php echo esc_attr( $field_id ); ?>"
										value="<?php echo esc_attr( $hex_value ); ?>" />
									<?php endif; ?>
									<input type="text" class="ru-color-hex" data-for="<?php echo esc_attr( $field_id ); ?>"
										value="<?php echo esc_attr( $hex_value ); ?>" maxlength="<?php echo $is_scrim ? 9 : 7; ?>" aria-label="<?php echo esc_attr( $label ); ?> hex" />
								</div>
							<?php endforeach; ?>
						</div>
					</div>
				</div>
				<aside class="ru-phone-preview" aria-hidden="false">
					<p class="ru-phone-preview__label"><?php esc_html_e( 'Live preview', 'radioudaan-app-api' ); ?></p>
					<div class="ru-phone-preview__device">
						<div class="ru-phone-preview__screen">
							<div class="ru-phone-preview__header" id="ru-preview-header" style="background:<?php echo esc_attr( $brand_colors['surface_dark'] ); ?>;">
								<div id="ru-preview-logo">
									<?php if ( ! empty( $c['brand_logo_u'] ) ) : ?>
										<img src="<?php echo esc_url( $c['brand_logo_u'] ); ?>" alt="" />
									<?php endif; ?>
								</div>
								<p class="ru-phone-preview__app-name" id="ru-preview-app-name"><?php echo esc_html( RadioUdaan_App_Branding::get_app_name() ); ?></p>
								<p class="ru-phone-preview__tagline" id="ru-preview-tagline"><?php echo esc_html( RadioUdaan_App_Branding::get_tagline() ); ?></p>
							</div>
							<div class="ru-phone-preview__body">
								<button type="button" class="ru-phone-preview__btn" id="ru-preview-btn" disabled>
									<?php esc_html_e( 'Play live radio', 'radioudaan-app-api' ); ?>
								</button>
							</div>
							<div class="ru-phone-preview__tabs" id="ru-preview-tabs">
								<span class="is-active" data-preview-tab="radio"><?php esc_html_e( 'Live Radio', 'radioudaan-app-api' ); ?></span>
								<span><?php esc_html_e( 'Library', 'radioudaan-app-api' ); ?></span>
								<span><?php esc_html_e( 'Events', 'radioudaan-app-api' ); ?></span>
								<span><?php esc_html_e( 'More', 'radioudaan-app-api' ); ?></span>
							</div>
						</div>
					</div>
				</aside>
			</div>
		</section>

		<!-- Copy -->
		<section class="ru-settings-panel" data-panel="copy" role="tabpanel">
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'In-app text', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'Short, plain-language strings. Leave blank to use defaults.', 'radioudaan-app-api' ); ?></p>
				<div class="ru-copy-groups">
					<?php foreach ( $copy_groups as $group_title => $catalog_keys ) : ?>
						<details class="ru-copy-group" open>
							<summary><?php echo esc_html( $group_title ); ?></summary>
							<div class="ru-copy-group__body">
								<?php foreach ( $catalog_keys as $catalog_key ) : ?>
									<?php
									$input_name = 'copy_' . $catalog_key;
									$stored     = trim( (string) get_option( RadioUdaan_App_Copy_Catalog::option_name( $catalog_key ), '' ) );
									$default    = isset( $copy_defaults[ $catalog_key ] ) ? $copy_defaults[ $catalog_key ] : '';
									$label      = RadioUdaan_App_Copy_Catalog::field_label( $catalog_key );
									$is_long    = RadioUdaan_App_Copy_Catalog::is_long_text( $catalog_key );
									?>
									<div class="ru-admin__field">
										<label for="<?php echo esc_attr( $input_name ); ?>"><?php echo esc_html( $label ); ?></label>
										<?php if ( $is_long ) : ?>
											<textarea name="<?php echo esc_attr( $input_name ); ?>" id="<?php echo esc_attr( $input_name ); ?>"
												class="large-text" rows="3"
												placeholder="<?php echo esc_attr( $default ); ?>"><?php echo esc_textarea( $stored ); ?></textarea>
										<?php else : ?>
											<input type="text" name="<?php echo esc_attr( $input_name ); ?>" id="<?php echo esc_attr( $input_name ); ?>"
												class="large-text" value="<?php echo esc_attr( $stored ); ?>"
												placeholder="<?php echo esc_attr( $default ); ?>" />
										<?php endif; ?>
									</div>
								<?php endforeach; ?>
							</div>
						</details>
					<?php endforeach; ?>
				</div>
			</div>
		</section>

		<!-- Connection -->
		<section class="ru-settings-panel" data-panel="connection" role="tabpanel">
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'API & stream', 'radioudaan-app-api' ); ?></h3>
				<div class="ru-admin__field">
					<label for="api_base_url"><?php esc_html_e( 'App API base URL', 'radioudaan-app-api' ); ?></label>
					<input type="url" name="api_base_url" id="api_base_url" class="large-text"
						value="<?php echo esc_attr( $c['api_override'] ? $c['api_override'] : $c['api_base'] ); ?>"
						placeholder="<?php echo esc_attr( $c['api_base'] ); ?>" />
					<p class="description">
						<?php
						printf(
							esc_html__( 'Auto-detected: %s. Returned in GET /config.', 'radioudaan-app-api' ),
							esc_html( $c['api_base'] )
						);
						?>
					</p>
				</div>
				<div class="ru-admin__field">
					<label for="stream_url"><?php esc_html_e( 'Live radio stream URL', 'radioudaan-app-api' ); ?></label>
					<input type="url" name="stream_url" id="stream_url" class="large-text" value="<?php echo esc_attr( $c['stream_url'] ); ?>" />
				</div>
			</div>
		</section>

		<!-- Live radio home screen -->
		<section class="ru-settings-panel" data-panel="live_radio" role="tabpanel">
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Live tab (home after sign-in)', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'Show title, hero image, and buttons on the app Live screen. Sent via GET /config → live_radio.', 'radioudaan-app-api' ); ?></p>
				<div class="ru-admin__field">
					<label for="live_show_title"><?php esc_html_e( 'Show title', 'radioudaan-app-api' ); ?></label>
					<input type="text" name="live_show_title" id="live_show_title" class="large-text"
						value="<?php echo esc_attr( $c['live_show_title'] ); ?>"
						placeholder="<?php echo esc_attr( $c['live_defaults']['show_title'] ); ?>" />
				</div>
				<div class="ru-admin__field">
					<label for="live_show_subtitle"><?php esc_html_e( 'Hosts / subtitle', 'radioudaan-app-api' ); ?></label>
					<input type="text" name="live_show_subtitle" id="live_show_subtitle" class="large-text"
						value="<?php echo esc_attr( $c['live_show_subtitle'] ); ?>"
						placeholder="<?php echo esc_attr( $c['live_defaults']['show_subtitle'] ); ?>" />
				</div>
				<div class="ru-admin__field">
					<label><?php esc_html_e( 'Hero image', 'radioudaan-app-api' ); ?></label>
					<input type="hidden" name="live_hero_id" id="live_hero_id" value="<?php echo (int) $c['live_hero_id']; ?>" />
					<div id="ru-live-hero-preview" class="ru-admin__logo-preview">
						<?php if ( ! empty( $c['live_hero_url'] ) ) : ?>
							<img src="<?php echo esc_url( $c['live_hero_url'] ); ?>" alt="" style="max-width:100%;border-radius:8px;" />
						<?php endif; ?>
					</div>
					<p>
						<button type="button" class="button button-secondary" id="ru-pick-live-hero"><?php esc_html_e( 'Choose image', 'radioudaan-app-api' ); ?></button>
						<button type="button" class="button" id="ru-remove-live-hero" <?php echo $c['live_hero_id'] ? '' : 'style="display:none;"'; ?>><?php esc_html_e( 'Remove', 'radioudaan-app-api' ); ?></button>
					</p>
				</div>
			</div>
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Action buttons', 'radioudaan-app-api' ); ?></h3>
				<div class="ru-admin__toggle">
					<input type="checkbox" name="live_show_share" id="live_show_share" value="1" <?php checked( $c['live_show_share'] ); ?> />
					<div>
						<label for="live_show_share"><strong><?php esc_html_e( 'Share button', 'radioudaan-app-api' ); ?></strong></label>
						<div class="ru-admin__field">
							<label for="live_share_label"><?php esc_html_e( 'Button label', 'radioudaan-app-api' ); ?></label>
							<input type="text" name="live_share_label" id="live_share_label" class="large-text"
								value="<?php echo esc_attr( $c['live_share_label'] ); ?>" />
						</div>
						<div class="ru-admin__field">
							<label for="live_share_text"><?php esc_html_e( 'Share message', 'radioudaan-app-api' ); ?></label>
							<textarea name="live_share_text" id="live_share_text" rows="2" class="large-text"><?php echo esc_textarea( $c['live_share_text'] ); ?></textarea>
						</div>
					</div>
				</div>
				<div class="ru-admin__toggle">
					<input type="checkbox" name="live_show_volume" id="live_show_volume" value="1" <?php checked( $c['live_show_volume'] ); ?> />
					<div>
						<label for="live_show_volume"><strong><?php esc_html_e( 'Volume slider', 'radioudaan-app-api' ); ?></strong></label>
					</div>
				</div>
			</div>
		</section>

		<!-- YouTube library -->
		<section class="ru-settings-panel" data-panel="youtube_library" role="tabpanel">
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'YouTube Data API', 'radioudaan-app-api' ); ?></h3>
				<p class="description">
					<?php esc_html_e( 'Powers the app Library tab from the @radioudaan channel. API key stays on the server only.', 'radioudaan-app-api' ); ?>
				</p>
				<div class="ru-admin__field">
					<label for="youtube_api_key"><?php esc_html_e( 'Google API key', 'radioudaan-app-api' ); ?></label>
					<input type="password" name="youtube_api_key" id="youtube_api_key" class="large-text"
						value="<?php echo esc_attr( $c['youtube_api_key'] ); ?>" autocomplete="off" />
					<p class="description">
						<?php
						printf(
							/* translators: %s: Google Cloud Console URL */
							wp_kses_post( __( 'Create a key in <a href="%s" target="_blank" rel="noopener noreferrer">Google Cloud Console</a>, enable <strong>YouTube Data API v3</strong>, and restrict the key to that API.', 'radioudaan-app-api' ) ),
							esc_url( 'https://console.cloud.google.com/apis/credentials' )
						);
						?>
					</p>
				</div>
				<div class="ru-admin__field">
					<label for="youtube_channel"><?php esc_html_e( 'Channel handle or ID', 'radioudaan-app-api' ); ?></label>
					<input type="text" name="youtube_channel" id="youtube_channel" class="large-text"
						value="<?php echo esc_attr( $c['youtube_channel'] ); ?>"
						placeholder="<?php echo esc_attr( RadioUdaan_App_Youtube_Library::DEFAULT_CHANNEL_HANDLE ); ?>" />
					<p class="description">
						<?php
						printf(
							/* translators: 1: default handle, 2: default channel ID */
							esc_html__( 'Example: %1$s or %2$s', 'radioudaan-app-api' ),
							esc_html( RadioUdaan_App_Youtube_Library::DEFAULT_CHANNEL_HANDLE ),
							esc_html( RadioUdaan_App_Youtube_Library::DEFAULT_CHANNEL_ID )
						);
						?>
					</p>
				</div>
			</div>
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Featured playlists', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'Shown in the app via GET /library/youtube/playlists/featured. Load playlists after saving API key and channel.', 'radioudaan-app-api' ); ?></p>
				<div class="ru-youtube-playlist-toolbar">
					<button type="button" class="button button-secondary" id="ru-youtube-load-playlists">
						<?php esc_html_e( 'Load playlists from channel', 'radioudaan-app-api' ); ?>
					</button>
					<span id="ru-youtube-load-status" class="ru-youtube-playlist-toolbar__status" aria-live="polite"></span>
				</div>
				<div class="ru-youtube-playlist-tools" id="ru-youtube-playlist-tools" hidden>
					<input type="search" id="ru-youtube-playlist-search" class="regular-text"
						placeholder="<?php esc_attr_e( 'Search playlists…', 'radioudaan-app-api' ); ?>"
						aria-label="<?php esc_attr_e( 'Search playlists', 'radioudaan-app-api' ); ?>" />
					<span id="ru-youtube-playlist-selected" class="description" aria-live="polite"></span>
				</div>
				<p id="ru-youtube-playlist-drag-hint" class="description ru-youtube-playlist-drag-hint" hidden>
					<?php esc_html_e( 'Drag selected playlists to set the order shown in the app.', 'radioudaan-app-api' ); ?>
				</p>
				<div id="ru-youtube-playlist-picker" class="ru-youtube-playlist-picker">
					<?php
					$featured_items = isset( $c['youtube_featured_playlist_items'] ) && is_array( $c['youtube_featured_playlist_items'] )
						? $c['youtube_featured_playlist_items']
						: array();
					if ( ! empty( $featured_items ) ) :
						?>
						<p class="description ru-youtube-playlist-picker__hint">
							<?php esc_html_e( 'Saved featured playlists. Load from channel to add more or refresh thumbnails.', 'radioudaan-app-api' ); ?>
						</p>
						<?php
						foreach ( $featured_items as $playlist ) :
							self::render_youtube_playlist_item( $playlist, true );
						endforeach;
					else :
						?>
						<p class="description ru-youtube-playlist-picker__empty">
							<?php esc_html_e( 'No featured playlists selected yet. Load playlists from your channel to choose which appear in the app.', 'radioudaan-app-api' ); ?>
						</p>
					<?php endif; ?>
				</div>
			</div>
		</section>

		<!-- Auth -->
		<section class="ru-settings-panel" data-panel="auth" role="tabpanel">
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Registration & login', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'Exposed to the app via GET /config → auth_policy.', 'radioudaan-app-api' ); ?></p>
				<div class="ru-admin__field">
					<label for="password_min_length"><?php esc_html_e( 'Minimum password length', 'radioudaan-app-api' ); ?></label>
					<input type="number" name="password_min_length" id="password_min_length" min="8" max="128"
						value="<?php echo (int) $c['password_min']; ?>" class="small-text" />
				</div>
				<div class="ru-admin__toggle">
					<input type="checkbox" name="require_unique_email" id="require_unique_email" value="1"
						<?php checked( $c['require_unique_email'] ); ?> />
					<div>
						<label for="require_unique_email"><strong><?php esc_html_e( 'Require unique email', 'radioudaan-app-api' ); ?></strong></label>
						<p class="description"><?php esc_html_e( 'Mobile number is always unique. Uncheck only if duplicate emails are acceptable.', 'radioudaan-app-api' ); ?></p>
					</div>
				</div>
				<div class="ru-admin__toggle">
					<input type="checkbox" name="require_email_verification" id="require_email_verification" value="1"
						<?php checked( $c['require_email_verification'] ); ?> />
					<div>
						<label for="require_email_verification"><strong><?php esc_html_e( 'Require email verification to log in', 'radioudaan-app-api' ); ?></strong></label>
						<p class="description"><?php esc_html_e( 'When enabled, users must verify email after phone OTP (optional profile verify when off).', 'radioudaan-app-api' ); ?></p>
					</div>
				</div>
			</div>
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Email templates', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'Placeholders: {{name}}, {{email}}, {{code}}, {{link}}, {{app_name}}', 'radioudaan-app-api' ); ?></p>
				<div class="ru-admin__field">
					<label for="email_verify_subject"><?php esc_html_e( 'Verification subject', 'radioudaan-app-api' ); ?></label>
					<input type="text" name="email_verify_subject" id="email_verify_subject" class="large-text"
						value="<?php echo esc_attr( $c['email_verify_subject'] ); ?>"
						placeholder="<?php echo esc_attr( RadioUdaan_App_Settings::get_email_verify_subject() ); ?>" />
				</div>
				<div class="ru-admin__field">
					<label for="email_verify_body"><?php esc_html_e( 'Verification body', 'radioudaan-app-api' ); ?></label>
					<textarea name="email_verify_body" id="email_verify_body" rows="4" class="large-text"
						placeholder="<?php echo esc_attr( RadioUdaan_App_Settings::get_email_verify_body() ); ?>"><?php echo esc_textarea( $c['email_verify_body'] ); ?></textarea>
				</div>
				<div class="ru-admin__field">
					<label for="email_reset_subject"><?php esc_html_e( 'Password reset subject', 'radioudaan-app-api' ); ?></label>
					<input type="text" name="email_reset_subject" id="email_reset_subject" class="large-text"
						value="<?php echo esc_attr( $c['email_reset_subject'] ); ?>"
						placeholder="<?php echo esc_attr( RadioUdaan_App_Settings::get_email_reset_subject() ); ?>" />
				</div>
				<div class="ru-admin__field">
					<label for="email_reset_body"><?php esc_html_e( 'Password reset body', 'radioudaan-app-api' ); ?></label>
					<textarea name="email_reset_body" id="email_reset_body" rows="5" class="large-text"
						placeholder="<?php echo esc_attr( RadioUdaan_App_Settings::get_email_reset_body() ); ?>"><?php echo esc_textarea( $c['email_reset_body'] ); ?></textarea>
				</div>
			</div>
		</section>

		<!-- Legal -->
		<section class="ru-settings-panel" data-panel="legal" role="tabpanel">
			<?php
			RadioUdaan_Admin_Layout::render_page_intro(
				'<strong>' . esc_html__( 'Store requirement', 'radioudaan-app-api' ) . '</strong> — ' .
				esc_html__( 'App Store and Google Play require a public HTTPS Privacy Policy in store listings and in the app (More tab, via GET /config).', 'radioudaan-app-api' )
			);
			$privacy_effective = RadioUdaan_App_Settings::get_privacy_policy_url();
			$privacy_warn        = '';
			if ( '' === $c['privacy_ov'] ) {
				$privacy_warn = __( 'Privacy policy URL is empty. Set an HTTPS link before release.', 'radioudaan-app-api' );
			} elseif ( $privacy_effective && 0 !== strpos( strtolower( $privacy_effective ), 'https://' ) ) {
				$privacy_warn = __( 'Privacy policy URL must use HTTPS (App Store and Google Play).', 'radioudaan-app-api' );
			}
			if ( $privacy_warn ) {
				RadioUdaan_Admin_Layout::render_page_intro(
					'<strong>' . esc_html__( 'Action needed', 'radioudaan-app-api' ) . '</strong> — ' . esc_html( $privacy_warn ),
					'warning'
				);
			}
			?>
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'In-app legal content', 'radioudaan-app-api' ); ?></h3>
				<p class="description">
					<?php esc_html_e( 'Choose WordPress pages (Elementor or classic). The app shows page body only — no site header or footer. Edit text in Pages or Elementor as usual.', 'radioudaan-app-api' ); ?>
				</p>
				<?php
				$legal_pages = array(
					'legal_privacy_page_id' => array( __( 'Privacy policy page', 'radioudaan-app-api' ), (int) $c['legal_privacy_page_id'] ),
					'legal_terms_page_id'   => array( __( 'Terms page', 'radioudaan-app-api' ), (int) $c['legal_terms_page_id'] ),
					'legal_about_page_id'   => array( __( 'About page', 'radioudaan-app-api' ), (int) $c['legal_about_page_id'] ),
				);
				$page_choices = isset( $c['page_choices'] ) && is_array( $c['page_choices'] ) ? $c['page_choices'] : array();
				foreach ( $legal_pages as $name => $meta ) :
					?>
					<div class="ru-admin__field">
						<label for="<?php echo esc_attr( $name ); ?>"><?php echo esc_html( $meta[0] ); ?></label>
						<select name="<?php echo esc_attr( $name ); ?>" id="<?php echo esc_attr( $name ); ?>" class="widefat">
							<?php foreach ( $page_choices as $id => $label ) : ?>
								<option value="<?php echo (int) $id; ?>" <?php selected( $meta[1], $id ); ?>><?php echo esc_html( $label ); ?></option>
							<?php endforeach; ?>
						</select>
					</div>
				<?php endforeach; ?>
			</div>
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Public URLs (stores & web)', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'HTTPS links for App Store / Play listings and in-app Share (iOS → App Store, Android → Play).', 'radioudaan-app-api' ); ?></p>
				<?php
				$legal = array(
					'privacy_policy_url' => array( __( 'Privacy policy', 'radioudaan-app-api' ), $c['privacy_ov'], $c['privacy_url'] ),
					'terms_url'          => array( __( 'Terms', 'radioudaan-app-api' ), $c['terms_ov'], $c['terms_url'] ),
					'about_url'          => array( __( 'About', 'radioudaan-app-api' ), $c['about_ov'], $c['about_url'] ),
					'contact_url'        => array( __( 'Contact', 'radioudaan-app-api' ), $c['contact_ov'], $c['contact_url'] ),
					'app_store_url'      => array( __( 'App Store (iOS)', 'radioudaan-app-api' ), $c['app_store_ov'], $c['app_store_url'] ),
					'play_store_url'     => array( __( 'Google Play (Android)', 'radioudaan-app-api' ), $c['play_store_ov'], $c['play_store_url'] ),
				);
				foreach ( $legal as $name => $meta ) :
					?>
					<div class="ru-admin__field">
						<label for="<?php echo esc_attr( $name ); ?>"><?php echo esc_html( $meta[0] ); ?></label>
						<input type="url" name="<?php echo esc_attr( $name ); ?>" id="<?php echo esc_attr( $name ); ?>"
							class="large-text" value="<?php echo esc_attr( $meta[1] ); ?>"
							placeholder="<?php echo esc_attr( $meta[2] ); ?>" />
					</div>
				<?php endforeach; ?>
				<div class="ru-admin__field">
					<label for="support_helpline_phone"><?php esc_html_e( 'Support helpline (E.164)', 'radioudaan-app-api' ); ?></label>
					<input type="text" name="support_helpline_phone" id="support_helpline_phone" class="regular-text"
						value="<?php echo esc_attr( $c['support_helpline'] ); ?>"
						placeholder="+919876543210" />
					<p class="description"><?php esc_html_e( 'Exposed in GET /config → support.helpline_phone for in-app call links.', 'radioudaan-app-api' ); ?></p>
				</div>
				<div class="ru-admin__field">
					<label for="support_email"><?php esc_html_e( 'Support email', 'radioudaan-app-api' ); ?></label>
					<input type="email" name="support_email" id="support_email" class="regular-text"
						value="<?php echo esc_attr( $c['support_email'] ); ?>"
						placeholder="<?php echo esc_attr( get_option( 'admin_email' ) ); ?>" />
					<p class="description"><?php esc_html_e( 'In-app contact form messages are sent here (falls back to WP admin email).', 'radioudaan-app-api' ); ?></p>
				</div>
			</div>
		</section>

		<!-- About tab (app) -->
		<section class="ru-settings-panel" data-panel="about_tab" role="tabpanel" aria-labelledby="ru-tab-about_tab">
			<p class="description" style="margin-top:0;">
				<?php esc_html_e( 'Content for the mobile app About tab: Donate Us screen and social icons at the bottom. Sent via GET /config → info_hub.', 'radioudaan-app-api' ); ?>
			</p>
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Donate', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'Shown when users open About → Donate Us. Choose a UPI QR image from your Media Library uploads.', 'radioudaan-app-api' ); ?></p>
				<?php
				$donate_fields_before_qr = array(
					'donate_badge'              => array( __( 'Badge label', 'radioudaan-app-api' ), 'text', $c['donate_badge'] ?? '' ),
					'donate_headline'           => array( __( 'Headline', 'radioudaan-app-api' ), 'text', $c['donate_headline'] ?? '' ),
					'donate_intro'              => array( __( 'Introduction', 'radioudaan-app-api' ), 'textarea', $c['donate_intro'] ?? '' ),
					'donate_accessibility_note' => array( __( 'Accessibility note', 'radioudaan-app-api' ), 'textarea', $c['donate_accessibility_note'] ?? '' ),
					'donate_upi_id'             => array( __( 'UPI ID', 'radioudaan-app-api' ), 'text', $c['donate_upi_id'] ?? '' ),
				);
				$donate_fields_after_qr = array(
					'donate_account_name'   => array( __( 'Bank account name', 'radioudaan-app-api' ), 'text', $c['donate_account_name'] ?? '' ),
					'donate_account_number' => array( __( 'Account number', 'radioudaan-app-api' ), 'text', $c['donate_account_number'] ?? '' ),
					'donate_bank_name'      => array( __( 'Bank name', 'radioudaan-app-api' ), 'text', $c['donate_bank_name'] ?? '' ),
					'donate_branch_name'    => array( __( 'Branch', 'radioudaan-app-api' ), 'text', $c['donate_branch_name'] ?? '' ),
					'donate_ifsc'           => array( __( 'IFSC', 'radioudaan-app-api' ), 'text', $c['donate_ifsc'] ?? '' ),
					'donate_micr'           => array( __( 'MICR', 'radioudaan-app-api' ), 'text', $c['donate_micr'] ?? '' ),
					'donate_bank_address'   => array( __( 'Bank address', 'radioudaan-app-api' ), 'textarea', $c['donate_bank_address'] ?? '' ),
				);
				$donate_qr_id = (int) ( $c['donate_qr_attachment_id'] ?? 0 );
				foreach ( array( $donate_fields_before_qr, $donate_fields_after_qr ) as $donate_field_group ) :
					foreach ( $donate_field_group as $name => $meta ) :
						if ( 'donate_upi_id' === $name ) :
							?>
							<div class="ru-admin__field">
								<label for="<?php echo esc_attr( $name ); ?>"><?php echo esc_html( $meta[0] ); ?></label>
								<input type="text" name="<?php echo esc_attr( $name ); ?>" id="<?php echo esc_attr( $name ); ?>" class="large-text" value="<?php echo esc_attr( (string) $meta[2] ); ?>" />
							</div>
							<div class="ru-admin__field">
								<label><?php esc_html_e( 'UPI QR image', 'radioudaan-app-api' ); ?></label>
								<input type="hidden" name="donate_qr_attachment_id" id="donate_qr_attachment_id" value="<?php echo $donate_qr_id; ?>" />
								<div id="ru-donate-qr-preview" class="ru-admin__logo-preview">
									<?php if ( ! empty( $c['donate_qr_url'] ) ) : ?>
										<img src="<?php echo esc_url( $c['donate_qr_url'] ); ?>" alt="" style="max-width:220px;border-radius:8px;" />
									<?php endif; ?>
								</div>
								<p>
									<button type="button" class="button button-secondary" id="ru-pick-donate-qr"><?php esc_html_e( 'Choose from uploads', 'radioudaan-app-api' ); ?></button>
									<button type="button" class="button" id="ru-remove-donate-qr" <?php echo $donate_qr_id ? '' : 'style="display:none;"'; ?>><?php esc_html_e( 'Remove', 'radioudaan-app-api' ); ?></button>
								</p>
								<p class="description"><?php esc_html_e( 'Square PNG or JPG recommended. Shown in the app Donate screen for UPI scan-to-pay.', 'radioudaan-app-api' ); ?></p>
							</div>
							<?php
							continue;
						endif;
						?>
					<div class="ru-admin__field">
						<label for="<?php echo esc_attr( $name ); ?>"><?php echo esc_html( $meta[0] ); ?></label>
						<?php if ( 'textarea' === $meta[1] ) : ?>
							<textarea name="<?php echo esc_attr( $name ); ?>" id="<?php echo esc_attr( $name ); ?>" class="large-text" rows="3"><?php echo esc_textarea( (string) $meta[2] ); ?></textarea>
						<?php else : ?>
							<input type="text" name="<?php echo esc_attr( $name ); ?>" id="<?php echo esc_attr( $name ); ?>" class="large-text" value="<?php echo esc_attr( (string) $meta[2] ); ?>" />
						<?php endif; ?>
					</div>
					<?php
					endforeach;
				endforeach;
				?>
			</div>
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Join WhatsApp', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'Shown in the app About tab. Opens your WhatsApp community or channel link.', 'radioudaan-app-api' ); ?></p>
				<div class="ru-admin__toggle">
					<input type="checkbox" name="live_show_whatsapp" id="live_show_whatsapp" value="1" <?php checked( $c['live_show_whatsapp'] ); ?> />
					<div>
						<label for="live_show_whatsapp"><strong><?php esc_html_e( 'Show Join WhatsApp on About tab', 'radioudaan-app-api' ); ?></strong></label>
						<div class="ru-admin__field">
							<label for="live_whatsapp_label"><?php esc_html_e( 'Menu label', 'radioudaan-app-api' ); ?></label>
							<input type="text" name="live_whatsapp_label" id="live_whatsapp_label" class="large-text"
								value="<?php echo esc_attr( $c['live_whatsapp_label'] ); ?>" />
						</div>
						<div class="ru-admin__field">
							<label for="live_whatsapp_url"><?php esc_html_e( 'WhatsApp URL', 'radioudaan-app-api' ); ?></label>
							<input type="url" name="live_whatsapp_url" id="live_whatsapp_url" class="large-text"
								value="<?php echo esc_attr( $c['live_whatsapp_url'] ); ?>" />
						</div>
					</div>
				</div>
			</div>
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Social links', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'Icons at the bottom of the About tab. Leave blank to hide.', 'radioudaan-app-api' ); ?></p>
				<?php
				$social_admin = array(
					'social_facebook_url'  => array( __( 'Facebook URL', 'radioudaan-app-api' ), $c['social_facebook_url'] ?? '' ),
					'social_instagram_url' => array( __( 'Instagram URL', 'radioudaan-app-api' ), $c['social_instagram_url'] ?? '' ),
					'social_x_url'         => array( __( 'X (Twitter) URL', 'radioudaan-app-api' ), $c['social_x_url'] ?? '' ),
					'social_youtube_url'   => array( __( 'YouTube URL', 'radioudaan-app-api' ), $c['social_youtube_url'] ?? '' ),
					'social_website_url'   => array( __( 'Website URL', 'radioudaan-app-api' ), $c['social_website_url'] ?? '' ),
				);
				foreach ( $social_admin as $name => $meta ) :
					?>
					<div class="ru-admin__field">
						<label for="<?php echo esc_attr( $name ); ?>"><?php echo esc_html( $meta[0] ); ?></label>
						<input type="url" name="<?php echo esc_attr( $name ); ?>" id="<?php echo esc_attr( $name ); ?>" class="large-text" value="<?php echo esc_attr( (string) $meta[1] ); ?>" />
					</div>
				<?php endforeach; ?>
			</div>
		</section>

		<!-- Notifications -->
		<section class="ru-settings-panel" data-panel="notifications" role="tabpanel">
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Firebase Cloud Messaging (HTTP v1)', 'radioudaan-app-api' ); ?></h3>
				<p class="description">
					<?php esc_html_e( 'Server-side only — never sent to the mobile app. Uses Firebase service account JSON and the FCM HTTP v1 API.', 'radioudaan-app-api' ); ?>
				</p>
				<div class="ru-admin__field">
					<label for="fcm_project_id"><?php esc_html_e( 'FCM project ID', 'radioudaan-app-api' ); ?></label>
					<input type="text" name="fcm_project_id" id="fcm_project_id" class="regular-text"
						value="<?php echo esc_attr( $c['fcm_project_id'] ); ?>" />
					<p class="description"><?php esc_html_e( 'Optional if your service account JSON already includes project_id.', 'radioudaan-app-api' ); ?></p>
				</div>
				<div class="ru-admin__field">
					<label for="fcm_service_account_json"><?php esc_html_e( 'Firebase service account JSON', 'radioudaan-app-api' ); ?></label>
					<textarea name="fcm_service_account_json" id="fcm_service_account_json" class="large-text code" rows="6" autocomplete="off"
						placeholder="<?php echo $c['fcm_account_set'] ? esc_attr__( 'Saved — paste new JSON only to replace', 'radioudaan-app-api' ) : esc_attr__( 'Paste the full service account JSON from Firebase Console', 'radioudaan-app-api' ); ?>"></textarea>
					<?php if ( ! empty( $c['fcm_account_set'] ) ) : ?>
						<p class="description"><?php esc_html_e( 'Service account is saved. Leave blank to keep the current credentials.', 'radioudaan-app-api' ); ?></p>
					<?php endif; ?>
				</div>
			</div>
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Default notification preferences', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'Returned in GET /config → notification_preferences for new users.', 'radioudaan-app-api' ); ?></p>
				<div class="ru-admin__toggle">
					<input type="checkbox" name="notif_events_default" id="notif_events_default" value="1" <?php checked( $c['notif_events'] ); ?> />
					<div>
						<label for="notif_events_default"><strong><?php esc_html_e( 'Events', 'radioudaan-app-api' ); ?></strong></label>
					</div>
				</div>
				<div class="ru-admin__toggle">
					<input type="checkbox" name="notif_library_default" id="notif_library_default" value="1" <?php checked( $c['notif_library'] ); ?> />
					<div>
						<label for="notif_library_default"><strong><?php esc_html_e( 'Library updates', 'radioudaan-app-api' ); ?></strong></label>
					</div>
				</div>
				<div class="ru-admin__toggle">
					<input type="checkbox" name="notif_promotions_default" id="notif_promotions_default" value="1" <?php checked( $c['notif_promotions'] ); ?> />
					<div>
						<label for="notif_promotions_default"><strong><?php esc_html_e( 'Promotions', 'radioudaan-app-api' ); ?></strong></label>
					</div>
				</div>
			</div>
		</section>

		<!-- Uploads -->
		<section class="ru-settings-panel" data-panel="uploads" role="tabpanel">
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'File uploads', 'radioudaan-app-api' ); ?></h3>
				<div class="ru-settings-grid-2">
					<div class="ru-admin__field">
						<label for="max_upload_mb"><?php esc_html_e( 'Max file size (MB)', 'radioudaan-app-api' ); ?></label>
						<input type="number" name="max_upload_mb" id="max_upload_mb" min="1" max="200" value="<?php echo (int) $c['max_mb']; ?>" class="small-text" />
					</div>
					<div class="ru-admin__field">
						<label for="max_files_per_field"><?php esc_html_e( 'Max files per field', 'radioudaan-app-api' ); ?></label>
						<input type="number" name="max_files_per_field" id="max_files_per_field" min="1" max="10" value="<?php echo (int) $c['max_files']; ?>" class="small-text" />
					</div>
					<div class="ru-admin__field">
						<label for="upload_retention_days"><?php esc_html_e( 'Cleanup (days)', 'radioudaan-app-api' ); ?></label>
						<input type="number" name="upload_retention_days" id="upload_retention_days" min="1" max="90" value="<?php echo (int) $c['retention']; ?>" class="small-text" />
					</div>
				</div>
				<div class="ru-admin__field">
					<label for="allowed_mime"><?php esc_html_e( 'Allowed MIME types', 'radioudaan-app-api' ); ?></label>
					<textarea name="allowed_mime" id="allowed_mime" rows="3" class="large-text"><?php echo esc_textarea( $c['allowed_mime'] ); ?></textarea>
				</div>
				<div class="ru-admin__toggle">
					<input type="checkbox" name="private_uploads" id="private_uploads" value="1" <?php checked( $c['private_up'] ); ?> />
					<div>
						<label for="private_uploads"><strong><?php esc_html_e( 'Private upload storage', 'radioudaan-app-api' ); ?></strong></label>
						<p class="description"><?php esc_html_e( 'Recommended for UDID and media files.', 'radioudaan-app-api' ); ?></p>
					</div>
				</div>
			</div>
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'Registration limits', 'radioudaan-app-api' ); ?></h3>
				<div class="ru-settings-grid-2">
					<div class="ru-admin__field">
						<label for="reg_limit_phone"><?php esc_html_e( 'Per phone / hour', 'radioudaan-app-api' ); ?></label>
						<input type="number" name="reg_limit_phone" id="reg_limit_phone" min="1" max="100" value="<?php echo (int) $c['reg_phone']; ?>" class="small-text" />
					</div>
					<div class="ru-admin__field">
						<label for="reg_limit_ip"><?php esc_html_e( 'Per IP / hour', 'radioudaan-app-api' ); ?></label>
						<input type="number" name="reg_limit_ip" id="reg_limit_ip" min="1" max="500" value="<?php echo (int) $c['reg_ip']; ?>" class="small-text" />
					</div>
				</div>
				<div class="ru-admin__toggle">
					<input type="checkbox" name="prevent_duplicate" id="prevent_duplicate" value="1" <?php checked( $c['prevent_dup'] ); ?> />
					<div>
						<label for="prevent_duplicate"><strong><?php esc_html_e( 'One registration per email per event', 'radioudaan-app-api' ); ?></strong></label>
						<p class="description"><?php esc_html_e( 'Per-event override: allow multiple registrations per email on individual App Events.', 'radioudaan-app-api' ); ?></p>
					</div>
				</div>
			</div>
		</section>

		<!-- Security / OTP -->
		<section class="ru-settings-panel" data-panel="security" role="tabpanel">
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'OTP rate limits', 'radioudaan-app-api' ); ?></h3>
				<div class="ru-settings-grid-2">
					<div class="ru-admin__field">
						<label for="otp_limit_hour"><?php esc_html_e( 'Requests / hour', 'radioudaan-app-api' ); ?></label>
						<input type="number" name="otp_limit_hour" id="otp_limit_hour" min="1" max="50" value="<?php echo (int) $c['otp_limit']; ?>" class="small-text" />
					</div>
					<div class="ru-admin__field">
						<label for="otp_verify_max"><?php esc_html_e( 'Max wrong attempts', 'radioudaan-app-api' ); ?></label>
						<input type="number" name="otp_verify_max" id="otp_verify_max" min="1" max="20" value="<?php echo (int) $c['otp_verify']; ?>" class="small-text" />
					</div>
					<div class="ru-admin__field">
						<label for="otp_resend_delay"><?php esc_html_e( 'Resend delay (sec)', 'radioudaan-app-api' ); ?></label>
						<input type="number" name="otp_resend_delay" id="otp_resend_delay" min="30" max="600" value="<?php echo (int) $c['otp_resend']; ?>" class="small-text" />
					</div>
				</div>
			</div>
			<div class="ru-settings-panel__card ru-settings-danger-card">
				<h3><?php esc_html_e( 'Development only', 'radioudaan-app-api' ); ?></h3>
				<?php if ( $c['otp_const'] ) : ?>
					<p class="description">
						<strong><?php esc_html_e( 'Fixed OTP is controlled by wp-config.php', 'radioudaan-app-api' ); ?></strong>
						<?php
						echo ' — ';
						esc_html_e(
							'Remove or change RADIOUDAAN_APP_API_DEV_OTP in wp-config.php to use this checkbox instead.',
							'radioudaan-app-api'
						);
						?>
					</p>
				<?php elseif ( ! empty( $c['dev_bypass_locked'] ) ) : ?>
					<p class="description">
						<strong><?php esc_html_e( 'Blocked on this production host', 'radioudaan-app-api' ); ?></strong>
						<?php
						echo ' — ';
						esc_html_e( 'Fixed OTP is only available on staging and local sites.', 'radioudaan-app-api' );
						?>
					</p>
				<?php endif; ?>
				<div class="ru-admin__toggle">
					<?php if ( ! $c['otp_const'] && empty( $c['dev_bypass_locked'] ) ) : ?>
						<input type="hidden" name="dev_otp" value="0" />
					<?php endif; ?>
					<input type="checkbox" name="dev_otp" id="dev_otp" value="1"
						<?php checked( $c['otp_const'] ? (bool) RADIOUDAAN_APP_API_DEV_OTP : $c['dev_otp'] ); ?>
						<?php disabled( $c['otp_const'] || ! empty( $c['dev_bypass_locked'] ) ); ?> />
					<div>
						<label for="dev_otp"><strong><?php esc_html_e( 'Fixed OTP 123456', 'radioudaan-app-api' ); ?></strong></label>
						<p class="description">
							<?php esc_html_e( 'Local/staging only. Disable before production.', 'radioudaan-app-api' ); ?>
							<?php if ( ! empty( $c['dev_otp_effective'] ) ) : ?>
								<strong><?php esc_html_e( 'Currently active — OTP requests return 123456.', 'radioudaan-app-api' ); ?></strong>
							<?php endif; ?>
						</p>
					</div>
				</div>
				<?php if ( $c['auth_const'] ) : ?>
					<p class="description">
						<strong><?php esc_html_e( 'Dev auth is controlled by wp-config.php', 'radioudaan-app-api' ); ?></strong>
						<?php
						echo ' — ';
						esc_html_e(
							'Remove or change RADIOUDAAN_APP_API_DEV_AUTH in wp-config.php to use this checkbox instead.',
							'radioudaan-app-api'
						);
						?>
					</p>
				<?php endif; ?>
				<div class="ru-admin__toggle">
					<?php if ( ! $c['auth_const'] && empty( $c['dev_bypass_locked'] ) ) : ?>
						<input type="hidden" name="dev_auth" value="0" />
					<?php endif; ?>
					<input type="checkbox" name="dev_auth" id="dev_auth" value="1"
						<?php checked( $c['auth_const'] ? ( defined( 'RADIOUDAAN_APP_API_DEV_AUTH' ) && RADIOUDAAN_APP_API_DEV_AUTH ) : $c['dev_auth'] ); ?>
						<?php disabled( $c['auth_const'] || ! empty( $c['dev_bypass_locked'] ) ); ?> />
					<div>
						<label for="dev_auth"><strong><?php esc_html_e( 'Skip bearer token check', 'radioudaan-app-api' ); ?></strong></label>
						<p class="description"><?php esc_html_e( 'Never enable on production.', 'radioudaan-app-api' ); ?></p>
					</div>
				</div>
			</div>
		</section>

		<!-- SMS -->
		<section class="ru-settings-panel" data-panel="sms" role="tabpanel">
			<div class="ru-settings-panel__card">
				<h3><?php esc_html_e( 'MSG91 (production SMS)', 'radioudaan-app-api' ); ?></h3>
				<p class="description"><?php esc_html_e( 'Used when development OTP is off.', 'radioudaan-app-api' ); ?></p>
				<div class="ru-admin__field">
					<label for="msg91_auth_key"><?php esc_html_e( 'Auth key', 'radioudaan-app-api' ); ?></label>
					<input type="password" name="msg91_auth_key" id="msg91_auth_key" class="large-text"
						value="<?php echo esc_attr( $c['msg91_key'] ); ?>" autocomplete="off" <?php disabled( $c['msg91_const'] ); ?> />
				</div>
				<div class="ru-settings-grid-2">
					<div class="ru-admin__field">
						<label for="msg91_sender_id"><?php esc_html_e( 'Sender ID', 'radioudaan-app-api' ); ?></label>
						<input type="text" name="msg91_sender_id" id="msg91_sender_id" class="regular-text" value="<?php echo esc_attr( $c['msg91_snd'] ); ?>" />
					</div>
					<div class="ru-admin__field">
						<label for="msg91_template_id"><?php esc_html_e( 'DLT template ID', 'radioudaan-app-api' ); ?></label>
						<input type="text" name="msg91_template_id" id="msg91_template_id" class="regular-text" value="<?php echo esc_attr( $c['msg91_tpl'] ); ?>" />
					</div>
				</div>
			</div>
		</section>

		<div class="ru-settings-sticky-footer ru-form-sticky-footer">
			<p class="ru-form-sticky-footer__hint"><?php esc_html_e( 'Changes apply to the mobile app after save (config cache refreshes within 5 minutes).', 'radioudaan-app-api' ); ?></p>
			<?php submit_button( __( 'Save all settings', 'radioudaan-app-api' ), 'primary', 'submit', false, array( 'class' => 'ru-btn-large' ) ); ?>
		</div>
		<?php
	}

	/**
	 * One featured-playlist row for the YouTube admin picker.
	 *
	 * @param array<string,mixed> $playlist Playlist payload.
	 * @param bool                $checked  Whether checkbox is checked.
	 */
	public static function render_youtube_playlist_item( array $playlist, $checked = false ) {
		$id    = isset( $playlist['id'] ) ? sanitize_text_field( (string) $playlist['id'] ) : '';
		$title = isset( $playlist['title'] ) ? sanitize_text_field( (string) $playlist['title'] ) : '';
		$thumb = isset( $playlist['thumbnail_url'] ) ? esc_url( (string) $playlist['thumbnail_url'] ) : '';
		$count = isset( $playlist['video_count'] ) ? (int) $playlist['video_count'] : 0;

		if ( $id === '' ) {
			return;
		}

		if ( $title === '' ) {
			$title = $id;
		}

		$is_stub = ( $title === $id && $thumb === '' );
		$classes = 'ru-youtube-playlist-item';
		if ( $checked ) {
			$classes .= ' is-selected';
		}
		if ( $is_stub ) {
			$classes .= ' is-stub';
		}
		?>
		<label class="<?php echo esc_attr( $classes ); ?>" data-title="<?php echo esc_attr( strtolower( $title ) ); ?>">
			<input type="checkbox" name="youtube_featured_playlists[]" value="<?php echo esc_attr( $id ); ?>"
				<?php checked( $checked ); ?> />
			<span class="ru-youtube-playlist-item__drag dashicons dashicons-menu"
				role="button" tabindex="0"
				aria-label="<?php esc_attr_e( 'Drag to reorder', 'radioudaan-app-api' ); ?>"
				title="<?php esc_attr_e( 'Drag to reorder', 'radioudaan-app-api' ); ?>"></span>
			<span class="ru-youtube-playlist-item__thumb" aria-hidden="true">
				<?php if ( $thumb !== '' ) : ?>
					<img src="<?php echo esc_url( $thumb ); ?>" alt="" loading="lazy" decoding="async" />
				<?php else : ?>
					<span class="ru-youtube-playlist-item__thumb-placeholder dashicons dashicons-playlist-video"></span>
				<?php endif; ?>
			</span>
			<span class="ru-youtube-playlist-item__body">
				<strong class="ru-youtube-playlist-item__title"><?php echo esc_html( $title ); ?></strong>
				<?php if ( $count > 0 ) : ?>
					<span class="ru-youtube-playlist-item__meta">
						<?php
						printf(
							/* translators: %d: number of videos */
							esc_html( _n( '%d video', '%d videos', $count, 'radioudaan-app-api' ) ),
							(int) $count
						);
						?>
					</span>
				<?php elseif ( $is_stub ) : ?>
					<span class="ru-youtube-playlist-item__meta ru-youtube-playlist-item__meta--warn">
						<?php esc_html_e( 'Reload playlists to refresh title and thumbnail', 'radioudaan-app-api' ); ?>
					</span>
				<?php endif; ?>
				<code class="ru-youtube-playlist-item__id"><?php echo esc_html( $id ); ?></code>
			</span>
		</label>
		<?php
	}
}

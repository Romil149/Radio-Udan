<?php
/**
 * Shared admin UI components (badges, empty states, breadcrumbs, modals, stat cards).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Reusable render helpers for the ru-admin design system.
 */
class RadioUdaan_Admin_Components {

	/**
	 * Status or label pill.
	 *
	 * @param string $label   Visible text.
	 * @param string $variant CSS modifier (open, closed, ok, user-active, etc.).
	 */
	public static function render_badge( $label, $variant = 'default' ) {
		$variant = sanitize_html_class( (string) $variant );
		if ( 'default' === $variant ) {
			$variant = 'off';
		}
		printf(
			'<span class="ru-admin__badge ru-admin__badge--%1$s">%2$s</span>',
			esc_attr( $variant ),
			esc_html( $label )
		);
	}

	/**
	 * Centered empty list placeholder.
	 *
	 * @param string               $message Primary message.
	 * @param array<string,mixed>  $args    icon, action_label, action_url.
	 */
	public static function render_empty_state( $message, array $args = array() ) {
		$icon         = isset( $args['icon'] ) ? sanitize_html_class( (string) $args['icon'] ) : 'dashicons-info-outline';
		$action_label = isset( $args['action_label'] ) ? (string) $args['action_label'] : '';
		$action_url   = isset( $args['action_url'] ) ? (string) $args['action_url'] : '';
		?>
		<div class="ru-admin__empty ru-empty-state">
			<span class="dashicons <?php echo esc_attr( $icon ); ?>" aria-hidden="true"></span>
			<p><?php echo esc_html( $message ); ?></p>
			<?php if ( $action_label && $action_url ) : ?>
				<p><a href="<?php echo esc_url( $action_url ); ?>" class="button button-primary ru-btn-large"><?php echo esc_html( $action_label ); ?></a></p>
			<?php endif; ?>
		</div>
		<?php
	}

	/**
	 * Breadcrumb trail below the header nav.
	 *
	 * @param array<int,array{label:string,url?:string}> $crumbs Ordered crumbs; omit url on last item.
	 */
	public static function render_breadcrumb( array $crumbs ) {
		if ( empty( $crumbs ) ) {
			return;
		}

		echo '<nav class="ru-breadcrumb" aria-label="' . esc_attr__( 'Breadcrumb', 'radioudaan-app-api' ) . '">';
		echo '<ol class="ru-breadcrumb__list">';

		$last_index = count( $crumbs ) - 1;
		foreach ( $crumbs as $index => $crumb ) {
			$label = isset( $crumb['label'] ) ? (string) $crumb['label'] : '';
			if ( '' === $label ) {
				continue;
			}

			$url      = isset( $crumb['url'] ) ? (string) $crumb['url'] : '';
			$is_last  = $index === $last_index;
			$item_cls = 'ru-breadcrumb__item' . ( $is_last ? ' is-current' : '' );

			echo '<li class="' . esc_attr( $item_cls ) . '">';
			if ( ! $is_last && '' !== $url ) {
				echo '<a href="' . esc_url( $url ) . '">' . esc_html( $label ) . '</a>';
			} else {
				echo '<span aria-current="page">' . esc_html( $label ) . '</span>';
			}
			echo '</li>';
		}

		echo '</ol></nav>';
	}

	/**
	 * Accessible modal shell (toggle visibility via JS / details element).
	 *
	 * @param string               $id      Unique DOM id.
	 * @param string               $title   Modal title.
	 * @param string               $content Sanitized HTML body.
	 * @param array<string,mixed>  $args    open, footer_html.
	 */
	public static function render_modal_shell( $id, $title, $content, array $args = array() ) {
		$open        = ! empty( $args['open'] );
		$footer_html = isset( $args['footer_html'] ) ? (string) $args['footer_html'] : '';
		$modal_id    = sanitize_html_class( (string) $id );
		?>
		<div
			id="<?php echo esc_attr( $modal_id ); ?>"
			class="ru-modal<?php echo $open ? ' is-open' : ''; ?>"
			role="dialog"
			aria-modal="true"
			aria-labelledby="<?php echo esc_attr( $modal_id ); ?>-title"
			<?php echo $open ? '' : 'hidden'; ?>
		>
			<div class="ru-modal__backdrop" data-ru-modal-close="<?php echo esc_attr( $modal_id ); ?>"></div>
			<div class="ru-modal__panel">
				<header class="ru-modal__head">
					<h2 id="<?php echo esc_attr( $modal_id ); ?>-title" class="ru-modal__title"><?php echo esc_html( $title ); ?></h2>
					<button type="button" class="ru-modal__close" data-ru-modal-close="<?php echo esc_attr( $modal_id ); ?>" aria-label="<?php esc_attr_e( 'Close', 'radioudaan-app-api' ); ?>">
						<span class="dashicons dashicons-no" aria-hidden="true"></span>
					</button>
				</header>
				<div class="ru-modal__body">
					<?php echo wp_kses_post( $content ); ?>
				</div>
				<?php if ( '' !== $footer_html ) : ?>
					<footer class="ru-modal__foot">
						<?php echo wp_kses_post( $footer_html ); ?>
					</footer>
				<?php endif; ?>
			</div>
		</div>
		<?php
	}

	/**
	 * Dashboard stat tile.
	 *
	 * @param string               $label Stat label.
	 * @param string               $value Primary value (may include HTML entities via esc_html).
	 * @param string               $hint  Optional secondary line.
	 * @param array<string,mixed>  $args  accent (css color token suffix), size (compact|default).
	 */
	public static function render_stat_card( $label, $value, $hint = '', array $args = array() ) {
		$accent = isset( $args['accent'] ) ? sanitize_html_class( (string) $args['accent'] ) : '';
		$size   = isset( $args['size'] ) && 'compact' === $args['size'] ? 'compact' : 'default';

		$classes = 'ru-stat-card';
		if ( $accent ) {
			$classes .= ' ru-stat-card--' . $accent;
		}
		if ( 'compact' === $size ) {
			$classes .= ' ru-stat-card--compact';
		}
		?>
		<div class="<?php echo esc_attr( $classes ); ?>">
			<div class="ru-stat-card__label"><?php echo esc_html( $label ); ?></div>
			<div class="ru-stat-card__value"><?php echo esc_html( (string) $value ); ?></div>
			<?php if ( '' !== $hint ) : ?>
				<div class="ru-stat-card__hint"><?php echo wp_kses_post( $hint ); ?></div>
			<?php endif; ?>
		</div>
		<?php
	}

	/**
	 * Shared prev/next pagination bar.
	 *
	 * @param array<string,mixed> $result    page, total_pages keys.
	 * @param string              $base_url  List URL without paged.
	 * @param array<string,mixed> $link_args Extra query args.
	 * @param string              $aria      Accessible nav label.
	 */
	public static function render_pagination( $result, $base_url, array $link_args = array(), $aria = '' ) {
		$current = (int) ( $result['page'] ?? 1 );
		$total   = (int) ( $result['total_pages'] ?? 0 );

		if ( $total <= 1 ) {
			return;
		}

		if ( '' === $aria ) {
			$aria = __( 'Pagination', 'radioudaan-app-api' );
		}

		echo '<nav class="ru-pagination" aria-label="' . esc_attr( $aria ) . '">';

		if ( $current > 1 ) {
			$prev_args = array_merge( $link_args, array( 'paged' => $current - 1 ) );
			echo '<a class="button" href="' . esc_url( add_query_arg( $prev_args, $base_url ) ) . '">' . esc_html__( 'Previous', 'radioudaan-app-api' ) . '</a> ';
		}

		echo '<span class="ru-pagination__status">';
		printf(
			/* translators: 1: current page, 2: total pages */
			esc_html__( 'Page %1$d of %2$d', 'radioudaan-app-api' ),
			$current,
			$total
		);
		echo '</span>';

		if ( $current < $total ) {
			$next_args = array_merge( $link_args, array( 'paged' => $current + 1 ) );
			echo ' <a class="button" href="' . esc_url( add_query_arg( $next_args, $base_url ) ) . '">' . esc_html__( 'Next', 'radioudaan-app-api' ) . '</a>';
		}

		echo '</nav>';
	}
}

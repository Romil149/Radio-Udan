<?php
/**
 * RJ profiles — WordPress users with role `rj` (replaces rj-profiles CPT).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * User-meta schema for on-air hosts / public RJ directory.
 */
class RadioUdaan_Rj_Profile {

	const ROLE = 'rj';

	const META_PHOTO_ID          = 'radioudaan_rj_photo_id';
	const META_SHOW_NAME         = 'radioudaan_rj_show_name';
	const META_EXPERIENCE        = 'radioudaan_rj_experience';
	const META_FACEBOOK          = 'radioudaan_rj_facebook';
	const META_INSTAGRAM         = 'radioudaan_rj_instagram';
	const META_YOUTUBE           = 'radioudaan_rj_youtube';
	const META_LEGACY_POST_ID    = 'radioudaan_rj_legacy_post_id';
	const META_LINKED_APP_USER   = 'radioudaan_rj_linked_app_user_id';
	const META_PUBLIC_PHONE      = 'radioudaan_rj_public_phone_e164';
	const META_IS_PUBLIC         = 'radioudaan_rj_is_public';

	const QUERY_VAR_ARCHIVE  = 'ru_rj_archive';
	const QUERY_VAR_NICENAME = 'ru_rj_nicename';

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'init', array( __CLASS__, 'ensure_role' ), 9 );
		RadioUdaan_Rj_Profile_Public::init();
		if ( is_admin() ) {
			RadioUdaan_Rj_Profile_Admin::init();
			RadioUdaan_Rj_Profile_Migration::init();
		}
	}

	/**
	 * Ensure the RJ role exists with media upload capability.
	 */
	public static function ensure_role() {
		$role = get_role( self::ROLE );
		if ( ! $role ) {
			add_role(
				self::ROLE,
				__( 'RJ', 'radioudaan-app-api' ),
				array(
					'read'         => true,
					'upload_files' => true,
				)
			);
			return;
		}

		if ( ! $role->has_cap( 'upload_files' ) ) {
			$role->add_cap( 'upload_files' );
		}
		if ( ! $role->has_cap( 'read' ) ) {
			$role->add_cap( 'read' );
		}
	}

	/**
	 * @param int|WP_User|null $user User or ID.
	 * @return bool
	 */
	public static function is_rj( $user ) {
		$user = self::normalize_user( $user );
		if ( ! $user ) {
			return false;
		}
		return in_array( self::ROLE, (array) $user->roles, true );
	}

	/**
	 * @param int|WP_User|null $user User or ID.
	 * @return bool
	 */
	public static function is_public_rj( $user ) {
		if ( ! self::is_rj( $user ) ) {
			return false;
		}
		$user = self::normalize_user( $user );
		if ( ! $user ) {
			return false;
		}
		$flag = get_user_meta( $user->ID, self::META_IS_PUBLIC, true );
		if ( $flag === '' || $flag === null ) {
			return true;
		}
		return (bool) (int) $flag;
	}

	/**
	 * @return WP_User[]
	 */
	public static function list_public_rjs() {
		$users = get_users(
			array(
				'role'    => self::ROLE,
				'orderby' => 'display_name',
				'order'   => 'ASC',
				'number'  => 500,
			)
		);

		$public = array();
		foreach ( $users as $user ) {
			if ( self::is_public_rj( $user ) ) {
				$public[] = $user;
			}
		}

		return $public;
	}

	/**
	 * @param int $user_id User ID.
	 * @return array<string,mixed>
	 */
	public static function get_profile( $user_id ) {
		$user = self::normalize_user( $user_id );
		if ( ! $user ) {
			return array();
		}

		$photo_id = (int) get_user_meta( $user->ID, self::META_PHOTO_ID, true );

		return array(
			'user_id'              => (int) $user->ID,
			'nicename'             => $user->user_nicename,
			'display_name'         => self::get_display_name( $user ),
			'bio_html'             => wpautop( wp_kses_post( $user->description ) ),
			'bio_plain'            => wp_strip_all_tags( $user->description ),
			'show_name'            => (string) get_user_meta( $user->ID, self::META_SHOW_NAME, true ),
			'experience'           => (string) get_user_meta( $user->ID, self::META_EXPERIENCE, true ),
			'photo_id'             => $photo_id,
			'photo_url'            => self::get_photo_url( $user->ID ),
			'facebook_url'         => esc_url_raw( (string) get_user_meta( $user->ID, self::META_FACEBOOK, true ) ),
			'instagram_url'        => esc_url_raw( (string) get_user_meta( $user->ID, self::META_INSTAGRAM, true ) ),
			'youtube_url'          => esc_url_raw( (string) get_user_meta( $user->ID, self::META_YOUTUBE, true ) ),
			'public_phone_e164'    => (string) get_user_meta( $user->ID, self::META_PUBLIC_PHONE, true ),
			'linked_app_user_id'   => (int) get_user_meta( $user->ID, self::META_LINKED_APP_USER, true ),
			'legacy_post_id'       => (int) get_user_meta( $user->ID, self::META_LEGACY_POST_ID, true ),
			'is_public'            => self::is_public_rj( $user ),
			'profile_url'          => self::get_public_url( $user->ID ),
			'hosted_shows'         => self::get_hosted_shows( $user->ID ),
		);
	}

	/**
	 * Future REST / app payload (stable contract).
	 *
	 * @param int $user_id User ID.
	 * @return array<string,mixed>
	 */
	public static function get_public_api_shape( $user_id ) {
		$p = self::get_profile( $user_id );
		if ( empty( $p ) ) {
			return array();
		}

		$shows = array();
		foreach ( $p['hosted_shows'] as $show ) {
			$shows[] = array(
				'id'    => (int) $show->ID,
				'title' => get_the_title( $show ),
				'url'   => get_permalink( $show ),
			);
		}

		return array(
			'id'           => $p['user_id'],
			'slug'         => $p['nicename'],
			'name'         => $p['display_name'],
			'show_name'    => $p['show_name'],
			'experience'   => $p['experience'],
			'bio'          => $p['bio_plain'],
			'photo_url'    => $p['photo_url'],
			'social'       => array(
				'facebook'  => $p['facebook_url'],
				'instagram' => $p['instagram_url'],
				'youtube'   => $p['youtube_url'],
			),
			'shows'        => $shows,
			'profile_url'  => $p['profile_url'],
			'app_user_id'  => $p['linked_app_user_id'] ? $p['linked_app_user_id'] : null,
		);
	}

	/**
	 * @param int|WP_User|null $user User or ID.
	 * @return string
	 */
	public static function get_display_name( $user ) {
		$user = self::normalize_user( $user );
		if ( ! $user ) {
			return '';
		}
		$name = trim( $user->display_name );
		return $name !== '' ? $name : $user->user_login;
	}

	/**
	 * @param int $user_id User ID.
	 * @return string
	 */
	public static function get_photo_url( $user_id ) {
		$photo_id = (int) get_user_meta( $user_id, self::META_PHOTO_ID, true );
		if ( $photo_id > 0 ) {
			$url = wp_get_attachment_image_url( $photo_id, 'large' );
			if ( $url ) {
				return esc_url_raw( $url );
			}
		}
		return '';
	}

	/**
	 * @param int $user_id User ID.
	 * @return string
	 */
	public static function get_public_url( $user_id ) {
		$user = self::normalize_user( $user_id );
		if ( ! $user ) {
			return '';
		}
		return home_url( '/rj-profiles/' . $user->user_nicename . '/' );
	}

	/**
	 * @param string $nicename User nicename / legacy CPT slug.
	 * @return WP_User|null
	 */
	public static function resolve_public_user_by_nicename( $nicename ) {
		$nicename = sanitize_title( (string) $nicename );
		if ( $nicename === '' || in_array( $nicename, array( 'feed' ), true ) ) {
			return null;
		}

		$user = get_user_by( 'slug', $nicename );
		if ( ! $user || ! self::is_public_rj( $user ) ) {
			return null;
		}

		return $user;
	}

	/**
	 * Shows where this RJ is assigned on program_host (single source of truth).
	 *
	 * @param int $user_id User ID.
	 * @return WP_Post[]
	 */
	public static function get_hosted_shows( $user_id ) {
		$user_id = (int) $user_id;
		if ( $user_id <= 0 ) {
			return array();
		}

		$shows = get_posts(
			array(
				'post_type'      => 'radio-shows',
				'post_status'    => 'publish',
				'posts_per_page' => -1,
				'orderby'        => 'title',
				'order'          => 'ASC',
			)
		);

		$matched = array();
		foreach ( $shows as $show ) {
			$host_ids = self::get_program_host_user_ids_for_show( $show->ID );
			if ( in_array( $user_id, $host_ids, true ) ) {
				$matched[] = $show;
			}
		}

		return $matched;
	}

	/**
	 * @param int $show_post_id radio-shows post ID.
	 * @return int[]
	 */
	public static function get_program_host_user_ids_for_show( $show_post_id ) {
		if ( ! function_exists( 'get_field' ) ) {
			return array();
		}
		$raw = get_field( 'program_host', (int) $show_post_id );
		return self::extract_user_ids_from_hosts( $raw );
	}

	/**
	 * Comma-separated host line for schedule / live radio.
	 *
	 * @param mixed $hosts_raw ACF program_host value.
	 * @return string
	 */
	public static function resolve_program_host_names( $hosts_raw ) {
		if ( ! $hosts_raw ) {
			return '';
		}
		if ( is_string( $hosts_raw ) ) {
			return self::resolve_program_host_string( $hosts_raw );
		}
		if ( ! is_array( $hosts_raw ) ) {
			return '';
		}

		$names = array();
		foreach ( $hosts_raw as $host ) {
			$name = self::resolve_single_host_name( $host );
			if ( $name !== '' ) {
				$names[] = $name;
			}
		}

		return implode( ', ', array_unique( $names ) );
	}

	/**
	 * Resolve plain-text program_host, including comma-separated user IDs.
	 *
	 * @param string $raw Host line from ACF.
	 * @return string
	 */
	private static function resolve_program_host_string( $raw ) {
		$raw = trim( (string) $raw );
		if ( $raw === '' ) {
			return '';
		}

		if ( strpos( $raw, ',' ) !== false ) {
			$parts = array_map( 'trim', explode( ',', $raw ) );
			$names = array();
			foreach ( $parts as $part ) {
				if ( $part === '' ) {
					continue;
				}
				$name = self::resolve_single_host_name( $part );
				$names[] = $name !== '' ? $name : $part;
			}
			return implode( ', ', array_unique( $names ) );
		}

		return self::resolve_single_host_name( $raw );
	}

	/**
	 * @param mixed $host Single host entry.
	 * @return string
	 */
	private static function resolve_single_host_name( $host ) {
		if ( is_string( $host ) ) {
			$trimmed = trim( $host );
			if ( $trimmed === '' ) {
				return '';
			}
			if ( ctype_digit( $trimmed ) ) {
				$user = get_user_by( 'id', (int) $trimmed );
				return $user ? self::get_display_name( $user ) : $trimmed;
			}
			$user = get_user_by( 'slug', sanitize_title( $trimmed ) );
			if ( $user && self::is_rj( $user ) ) {
				return self::get_display_name( $user );
			}
			return $trimmed;
		}
		if ( $host instanceof WP_User ) {
			return self::get_display_name( $host );
		}
		if ( is_numeric( $host ) ) {
			$user = get_user_by( 'id', (int) $host );
			return $user ? self::get_display_name( $user ) : '';
		}
		if ( is_object( $host ) && isset( $host->ID, $host->post_type ) ) {
			if ( 'rj-profiles' === $host->post_type ) {
				$mapped = self::find_user_by_legacy_post_id( (int) $host->ID );
				if ( $mapped ) {
					return self::get_display_name( $mapped );
				}
				return trim( (string) $host->post_title );
			}
			if ( isset( $host->user_login ) ) {
				return self::get_display_name( $host );
			}
			if ( isset( $host->post_title ) ) {
				return trim( (string) $host->post_title );
			}
		}
		if ( is_array( $host ) ) {
			if ( ! empty( $host['ID'] ) && ! empty( $host['post_type'] ) && 'rj-profiles' === $host['post_type'] ) {
				$mapped = self::find_user_by_legacy_post_id( (int) $host['ID'] );
				if ( $mapped ) {
					return self::get_display_name( $mapped );
				}
			}
			if ( ! empty( $host['display_name'] ) ) {
			 return trim( (string) $host['display_name'] );
			}
			if ( ! empty( $host['post_title'] ) ) {
				return trim( (string) $host['post_title'] );
			}
		}
		return '';
	}

	/**
	 * @param mixed $hosts_raw ACF value.
	 * @return int[]
	 */
	public static function extract_user_ids_from_hosts( $hosts_raw ) {
		if ( ! $hosts_raw ) {
			return array();
		}

		$list = is_array( $hosts_raw ) ? $hosts_raw : array( $hosts_raw );
		$ids  = array();

		foreach ( $list as $host ) {
			$id = self::extract_single_user_id( $host );
			if ( $id > 0 ) {
				$ids[] = $id;
			}
		}

		return array_values( array_unique( $ids ) );
	}

	/**
	 * @param mixed $host Host entry.
	 * @return int
	 */
	private static function extract_single_user_id( $host ) {
		if ( $host instanceof WP_User ) {
			return (int) $host->ID;
		}
		if ( is_string( $host ) && ctype_digit( trim( $host ) ) ) {
			$user = get_user_by( 'id', (int) trim( $host ) );
			return $user ? (int) $user->ID : 0;
		}
		if ( is_numeric( $host ) ) {
			$user = get_user_by( 'id', (int) $host );
			return $user ? (int) $user->ID : 0;
		}
		if ( is_object( $host ) && isset( $host->ID, $host->post_type ) && 'rj-profiles' === $host->post_type ) {
			$mapped = self::find_user_by_legacy_post_id( (int) $host->ID );
			return $mapped ? (int) $mapped->ID : 0;
		}
		if ( is_object( $host ) && isset( $host->ID ) && isset( $host->user_login ) ) {
			return (int) $host->ID;
		}
		if ( is_array( $host ) ) {
			if ( ! empty( $host['ID'] ) && ! empty( $host['roles'] ) ) {
				return (int) $host['ID'];
			}
			if ( ! empty( $host['ID'] ) && ! empty( $host['post_type'] ) && 'rj-profiles' === $host['post_type'] ) {
				$mapped = self::find_user_by_legacy_post_id( (int) $host['ID'] );
				return $mapped ? (int) $mapped->ID : 0;
			}
		}
		return 0;
	}

	/**
	 * @param int $legacy_post_id Old rj-profiles post ID.
	 * @return WP_User|null
	 */
	public static function find_user_by_legacy_post_id( $legacy_post_id ) {
		$users = get_users(
			array(
				'meta_key'   => self::META_LEGACY_POST_ID,
				'meta_value' => (int) $legacy_post_id,
				'number'     => 1,
			)
		);
		return ! empty( $users[0] ) ? $users[0] : null;
	}

	/**
	 * @param int   $show_post_id Show post ID.
	 * @param int[] $user_ids     RJ user IDs.
	 * @return bool
	 */
	public static function set_program_host_user_ids( $show_post_id, array $user_ids ) {
		$user_ids = array_values(
			array_filter(
				array_map( 'intval', $user_ids ),
				static function ( $id ) {
					return $id > 0;
				}
			)
		);

		if ( function_exists( 'update_field' ) ) {
			$value = count( $user_ids ) === 1 ? $user_ids[0] : $user_ids;
			return (bool) update_field( 'program_host', $value, (int) $show_post_id );
		}

		return false;
	}

	/**
	 * Merge RJ user IDs into program_host, preserving plain-text hosts when present.
	 *
	 * @param int   $show_post_id Show post ID.
	 * @param int[] $user_ids     RJ user IDs to add.
	 * @return bool
	 */
	public static function merge_program_host_users( $show_post_id, array $user_ids ) {
		$existing = self::get_program_host_user_ids_for_show( $show_post_id );
		return self::set_program_host_user_ids( $show_post_id, array_merge( $existing, $user_ids ) );
	}

	/**
	 * @param int               $user_id Target user.
	 * @param array<string,mixed> $data  Profile fields.
	 * @return bool|WP_Error
	 */
	public static function save_profile( $user_id, array $data ) {
		$user = self::normalize_user( $user_id );
		if ( ! $user ) {
			return new WP_Error( 'invalid_user', __( 'Invalid user.', 'radioudaan-app-api' ) );
		}

		if ( isset( $data['display_name'] ) ) {
			wp_update_user(
				array(
					'ID'           => $user->ID,
					'display_name' => sanitize_text_field( (string) $data['display_name'] ),
				)
			);
		}

		if ( array_key_exists( 'bio', $data ) ) {
			wp_update_user(
				array(
					'ID'          => $user->ID,
					'description' => wp_kses_post( (string) $data['bio'] ),
				)
			);
		}

		$meta_map = array(
			'photo_id'           => self::META_PHOTO_ID,
			'show_name'          => self::META_SHOW_NAME,
			'experience'         => self::META_EXPERIENCE,
			'facebook_url'       => self::META_FACEBOOK,
			'instagram_url'      => self::META_INSTAGRAM,
			'youtube_url'        => self::META_YOUTUBE,
			'public_phone_e164'  => self::META_PUBLIC_PHONE,
			'linked_app_user_id' => self::META_LINKED_APP_USER,
			'is_public'          => self::META_IS_PUBLIC,
		);

		foreach ( $meta_map as $key => $meta_key ) {
			if ( ! array_key_exists( $key, $data ) ) {
				continue;
			}
			$value = $data[ $key ];
			if ( in_array( $key, array( 'photo_id', 'linked_app_user_id' ), true ) ) {
				update_user_meta( $user->ID, $meta_key, (int) $value );
			} elseif ( 'is_public' === $key ) {
				update_user_meta( $user->ID, $meta_key, ! empty( $value ) ? 1 : 0 );
			} elseif ( in_array( $key, array( 'facebook_url', 'instagram_url', 'youtube_url' ), true ) ) {
				update_user_meta( $user->ID, $meta_key, esc_url_raw( (string) $value ) );
			} else {
				update_user_meta( $user->ID, $meta_key, sanitize_text_field( (string) $value ) );
			}
		}

		return true;
	}

	/**
	 * @param int|WP_User|null $user User or ID.
	 * @return WP_User|null
	 */
	private static function normalize_user( $user ) {
		if ( $user instanceof WP_User ) {
			return $user;
		}
		if ( is_numeric( $user ) ) {
			$found = get_user_by( 'id', (int) $user );
			return $found ? $found : null;
		}
		return null;
	}
}

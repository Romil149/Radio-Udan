<?php
/**
 * Migrate legacy rj-profiles CPT posts → WordPress users (role rj).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * One-time admin migration + program_host rewiring on radio-shows.
 */
class RadioUdaan_Rj_Profile_Migration {

	const OPTION_DONE = 'radioudaan_rj_profiles_migrated_v1';

	/**
	 * Register hooks.
	 */
	public static function init() {
		add_action( 'admin_post_radioudaan_migrate_rj_profiles', array( __CLASS__, 'handle_migrate' ) );
		add_action( 'admin_post_radioudaan_repair_rj_profiles', array( __CLASS__, 'handle_repair' ) );
	}

	/**
	 * @return bool
	 */
	public static function is_done() {
		return (bool) get_option( self::OPTION_DONE, false );
	}

	/**
	 * @return array{posts:int,users:int,shows:int,trashed:int}
	 */
	public static function count_legacy_posts() {
		$posts = get_posts(
			array(
				'post_type'      => 'rj-profiles',
				'post_status'    => array( 'publish', 'draft', 'private' ),
				'posts_per_page' => -1,
				'fields'         => 'ids',
			)
		);
		$trashed = get_posts(
			array(
				'post_type'      => 'rj-profiles',
				'post_status'    => 'trash',
				'posts_per_page' => -1,
				'fields'         => 'ids',
			)
		);
		return array(
			'posts'   => count( $posts ),
			'trashed' => count( $trashed ),
		);
	}

	/**
	 * Run full migration.
	 *
	 * @param bool $trash_cpt Trash legacy posts after success.
	 * @return array{success:bool,message:string,stats?:array<string,int>}
	 */
	public static function migrate_all( $trash_cpt = true ) {
		if ( ! post_type_exists( 'rj-profiles' ) ) {
			$existing = get_users( array( 'role' => RadioUdaan_Rj_Profile::ROLE, 'number' => 1 ) );
			if ( ! empty( $existing ) ) {
				update_option( self::OPTION_DONE, 1 );
				flush_rewrite_rules();
				return array(
					'success' => true,
					'message' => __( 'rj-profiles CPT is already removed. RJ users are active.', 'radioudaan-app-api' ),
				);
			}
		}

		RadioUdaan_Rj_Profile::ensure_role();

		$posts = get_posts(
			array(
				'post_type'      => 'rj-profiles',
				'post_status'    => array( 'publish', 'draft', 'private' ),
				'posts_per_page' => -1,
				'orderby'        => 'ID',
				'order'          => 'ASC',
			)
		);

		if ( empty( $posts ) ) {
			$repaired = self::repair_archive();
			if ( $repaired['public_rjs'] > 0 ) {
				update_option( self::OPTION_DONE, 1 );
				flush_rewrite_rules();
				return array(
					'success' => true,
					'message' => $repaired['message'],
					'stats'   => $repaired['stats'],
				);
			}

			update_option( self::OPTION_DONE, 1 );
			flush_rewrite_rules();
			return array(
				'success' => true,
				'message' => __( 'No active rj-profiles posts found. Use “Repair RJ archive” if profiles are missing after migration.', 'radioudaan-app-api' ),
				'stats'   => array(
					'users_created' => 0,
					'users_updated' => 0,
					'shows_updated' => 0,
					'posts_trashed' => 0,
				),
			);
		}

		$map             = array();
		$users_created   = 0;
		$users_updated   = 0;
		$shows_updated   = 0;
		$posts_trashed   = 0;
		$errors          = array();

		foreach ( $posts as $post ) {
			$result = self::migrate_post_to_user( $post );
			if ( is_wp_error( $result ) ) {
				$errors[] = sprintf( 'Post %d: %s', $post->ID, $result->get_error_message() );
				continue;
			}
			$map[ (int) $post->ID ] = (int) $result['user_id'];
			if ( ! empty( $result['created'] ) ) {
				++$users_created;
			} else {
				++$users_updated;
			}
		}

		$shows_updated += self::rewire_radio_shows_program_host( $map );
		$shows_updated += self::apply_legacy_hosted_shows( $posts, $map );

		if ( $trash_cpt ) {
			foreach ( $posts as $post ) {
				if ( wp_trash_post( $post->ID ) ) {
					++$posts_trashed;
				}
			}
		}

		if ( ! empty( $errors ) && empty( $map ) ) {
			return array(
				'success' => false,
				'message' => implode( ' ', $errors ),
			);
		}

		update_option( self::OPTION_DONE, 1 );
		flush_rewrite_rules();

		$message = sprintf(
			/* translators: 1: users created 2: users updated 3: shows updated 4: posts trashed */
			__( 'Migration complete. Created %1$d users, updated %2$d, rewired %3$d shows, trashed %4$d legacy posts. Delete the rj-profiles post type in CPT UI, then save Permalinks → Settings once.', 'radioudaan-app-api' ),
			$users_created,
			$users_updated,
			$shows_updated,
			$posts_trashed
		);

		if ( ! empty( $errors ) ) {
			$message .= ' ' . __( 'Some rows had errors:', 'radioudaan-app-api' ) . ' ' . implode( '; ', $errors );
		}

		return array(
			'success' => true,
			'message' => $message,
			'stats'   => array(
				'users_created' => $users_created,
				'users_updated' => $users_updated,
				'shows_updated' => $shows_updated,
				'posts_trashed' => $posts_trashed,
			),
		);
	}

	/**
	 * @param WP_Post $post Legacy CPT post.
	 * @return array{user_id:int,created:bool}|WP_Error
	 */
	private static function migrate_post_to_user( WP_Post $post ) {
		$nicename = self::resolve_nicename_from_post( $post );

		$existing = RadioUdaan_Rj_Profile::find_user_by_legacy_post_id( $post->ID );
		if ( $existing ) {
			self::copy_acf_to_user( $post, $existing->ID );
			$existing->add_role( RadioUdaan_Rj_Profile::ROLE );
			self::apply_nicename( (int) $existing->ID, $nicename );
			return array(
				'user_id' => (int) $existing->ID,
				'created' => false,
			);
		}

		$name = self::acf_text( 'rj_name', $post->ID );
		if ( $name === '' ) {
			$name = $post->post_title;
		}

		$login = sanitize_user( $post->post_name, true );
		if ( $login === '' || username_exists( $login ) ) {
			$login = sanitize_user( 'rj-' . $post->ID, true );
		}
		if ( username_exists( $login ) ) {
			$login = sanitize_user( 'rj-' . $post->ID . '-' . wp_generate_password( 4, false ), true );
		}

		$email = self::acf_text( 'rj_email', $post->ID );
		if ( ! is_email( $email ) ) {
			$email = 'rj.' . $post->ID . '@profiles.radioudaan.internal';
		}
		if ( email_exists( $email ) ) {
			$email = 'rj.' . $post->ID . '.' . wp_generate_password( 6, false ) . '@profiles.radioudaan.internal';
		}

		$user_id = wp_insert_user(
			array(
				'user_login'    => $login,
				'user_nicename' => $nicename,
				'user_email'    => $email,
				'user_pass'     => wp_generate_password( 24, true, true ),
				'display_name'  => $name,
				'nickname'      => $name,
				'description'   => wp_strip_all_tags( self::acf_html( 'rj_bio', $post->ID ) ),
				'role'          => RadioUdaan_Rj_Profile::ROLE,
			)
		);

		if ( is_wp_error( $user_id ) ) {
			return $user_id;
		}

		update_user_meta( $user_id, RadioUdaan_Rj_Profile::META_LEGACY_POST_ID, (int) $post->ID );
		update_user_meta( $user_id, RadioUdaan_Rj_Profile::META_IS_PUBLIC, 1 );

		self::copy_acf_to_user( $post, $user_id );

		return array(
			'user_id' => (int) $user_id,
			'created' => true,
		);
	}

	/**
	 * Public profile URL slug: /rj-profiles/{user_nicename}/ — preserved from CPT post_name.
	 *
	 * @param WP_Post $post Legacy rj-profiles post.
	 * @return string
	 */
	private static function resolve_nicename_from_post( WP_Post $post ) {
		$base = sanitize_title( $post->post_name );
		if ( $base === '' ) {
			$base = sanitize_title( self::acf_text( 'rj_name', $post->ID ) );
		}
		if ( $base === '' ) {
			$base = sanitize_title( $post->post_title );
		}
		if ( $base === '' ) {
			$base = 'rj-' . (int) $post->ID;
		}

		return self::unique_nicename( $base, (int) $post->ID );
	}

	/**
	 * @param string $base     Preferred slug.
	 * @param int    $post_id  Legacy post ID (for collision suffix + skip self).
	 * @return string
	 */
	private static function unique_nicename( $base, $post_id = 0 ) {
		$base = sanitize_title( $base );
		if ( $base === '' ) {
			$base = 'rj-' . max( 1, $post_id );
		}

		$candidate = $base;
		$attempt   = 0;
		while ( self::nicename_taken( $candidate, $post_id ) ) {
			++$attempt;
			$candidate = $base . '-' . ( $post_id > 0 ? $post_id : $attempt );
			if ( $attempt > 20 ) {
				$candidate = $base . '-' . wp_generate_password( 6, false );
				break;
			}
		}

		return $candidate;
	}

	/**
	 * @param string $nicename  Candidate slug.
	 * @param int    $post_id   Legacy post ID to allow re-migration of same user.
	 * @return bool
	 */
	private static function nicename_taken( $nicename, $post_id = 0 ) {
		$user = get_user_by( 'slug', $nicename );
		if ( ! $user ) {
			return false;
		}
		if ( $post_id > 0 ) {
			$legacy = (int) get_user_meta( $user->ID, RadioUdaan_Rj_Profile::META_LEGACY_POST_ID, true );
			if ( $legacy === $post_id ) {
				return false;
			}
		}
		return true;
	}

	/**
	 * @param int    $user_id  User ID.
	 * @param string $nicename Public slug.
	 */
	private static function apply_nicename( $user_id, $nicename ) {
		$nicename = sanitize_title( $nicename );
		if ( $nicename === '' ) {
			return;
		}
		wp_update_user(
			array(
				'ID'            => $user_id,
				'user_nicename' => $nicename,
			)
		);
	}

	/**
	 * Whether a migrated legacy post should appear on Meet Our RJs.
	 *
	 * @param WP_Post $post Legacy CPT post.
	 * @return bool
	 */
	private static function should_show_on_archive( WP_Post $post ) {
		// Only explicit drafts stay hidden; private/publish/trash (post-migration) are public.
		return 'draft' !== $post->post_status;
	}

	/**
	 * @param WP_Post $post    Legacy post.
	 * @param int     $user_id WP user ID.
	 */
	private static function copy_acf_to_user( WP_Post $post, $user_id ) {
		$photo = function_exists( 'get_field' ) ? get_field( 'rj_photo', $post->ID ) : null;
		$photo_id = 0;
		if ( is_array( $photo ) && ! empty( $photo['ID'] ) ) {
			$photo_id = (int) $photo['ID'];
		} elseif ( is_numeric( $photo ) ) {
			$photo_id = (int) $photo;
		}

		$data = array(
			'display_name'  => self::acf_text( 'rj_name', $post->ID ) ?: $post->post_title,
			'bio'           => self::acf_html( 'rj_bio', $post->ID ),
			'show_name'     => self::acf_text( 'rj_show_name', $post->ID ),
			'experience'    => self::acf_text( 'rj_experience', $post->ID ),
			'photo_id'      => $photo_id,
			'facebook_url'  => self::acf_text( 'facebook_link', $post->ID ),
			'instagram_url' => self::acf_text( 'instagram_link', $post->ID ),
			'youtube_url'   => self::acf_text( 'youtube_link', $post->ID ),
			'is_public'     => self::should_show_on_archive( $post ),
		);

		RadioUdaan_Rj_Profile::save_profile( $user_id, $data );
	}

	/**
	 * Replace legacy CPT references in program_host with user IDs.
	 *
	 * @param array<int,int> $map legacy post ID => user ID.
	 * @return int Number of shows updated.
	 */
	private static function rewire_radio_shows_program_host( array $map ) {
		if ( empty( $map ) ) {
			return 0;
		}

		$shows   = get_posts(
			array(
				'post_type'      => 'radio-shows',
				'post_status'    => array( 'publish', 'draft', 'private' ),
				'posts_per_page' => -1,
				'fields'         => 'ids',
			)
		);
		$updated = 0;

		foreach ( $shows as $show_id ) {
			if ( ! function_exists( 'get_field' ) ) {
				break;
			}
			$raw = get_field( 'program_host', $show_id );
			if ( ! $raw ) {
				continue;
			}

			$list    = is_array( $raw ) ? $raw : array( $raw );
			$user_ids = array();
			$changed  = false;

			foreach ( $list as $host ) {
				$post_id = 0;
				if ( is_object( $host ) && isset( $host->ID, $host->post_type ) && 'rj-profiles' === $host->post_type ) {
					$post_id = (int) $host->ID;
				} elseif ( is_array( $host ) && ! empty( $host['post_type'] ) && 'rj-profiles' === $host['post_type'] && ! empty( $host['ID'] ) ) {
					$post_id = (int) $host['ID'];
				} elseif ( is_numeric( $host ) && get_post_type( (int) $host ) === 'rj-profiles' ) {
					$post_id = (int) $host;
				}

				if ( $post_id && isset( $map[ $post_id ] ) ) {
					$user_ids[] = $map[ $post_id ];
					$changed    = true;
					continue;
				}

				$uid = RadioUdaan_Rj_Profile::extract_user_ids_from_hosts( array( $host ) );
				if ( ! empty( $uid ) ) {
					$user_ids = array_merge( $user_ids, $uid );
				}
			}

			if ( ! $changed || empty( $user_ids ) ) {
				continue;
			}

			$user_ids = array_values( array_unique( $user_ids ) );
			if ( RadioUdaan_Rj_Profile::set_program_host_user_ids( $show_id, $user_ids ) ) {
				++$updated;
			}
		}

		return $updated;
	}

	/**
	 * Ensure hosted_shows from legacy profiles are reflected on program_host.
	 *
	 * @param WP_Post[]      $posts Legacy posts.
	 * @param array<int,int> $map   Post ID => user ID.
	 * @return int
	 */
	private static function apply_legacy_hosted_shows( array $posts, array $map ) {
		$updated = 0;
		foreach ( $posts as $post ) {
			if ( empty( $map[ $post->ID ] ) ) {
				continue;
			}
			$user_id = $map[ $post->ID ];
			$hosted  = function_exists( 'get_field' ) ? get_field( 'hosted_shows', $post->ID ) : array();
			if ( ! is_array( $hosted ) ) {
				continue;
			}
			foreach ( $hosted as $show_item ) {
				$show_id = is_object( $show_item ) ? (int) $show_item->ID : (int) $show_item;
				if ( $show_id <= 0 ) {
					continue;
				}
				if ( RadioUdaan_Rj_Profile::merge_program_host_users( $show_id, array( $user_id ) ) ) {
					++$updated;
				}
			}
		}
		return $updated;
	}

	/**
	 * @param string $field   ACF field.
	 * @param int    $post_id Post ID.
	 * @return string
	 */
	private static function acf_text( $field, $post_id ) {
		if ( ! function_exists( 'get_field' ) ) {
			return '';
		}
		$val = get_field( $field, $post_id );
		if ( is_array( $val ) || is_object( $val ) ) {
			return '';
		}
		return trim( wp_strip_all_tags( (string) $val ) );
	}

	/**
	 * @param string $field   ACF field.
	 * @param int    $post_id Post ID.
	 * @return string
	 */
	private static function acf_html( $field, $post_id ) {
		if ( ! function_exists( 'get_field' ) ) {
			return '';
		}
		$val = get_field( $field, $post_id );
		return trim( (string) $val );
	}

	/**
	 * Fix blank /rj-profiles/ after migration: restore RJ role, public flag, and sync from trashed CPT rows.
	 *
	 * @return array{success:bool,message:string,public_rjs:int,stats:array<string,int>}
	 */
	public static function repair_archive() {
		RadioUdaan_Rj_Profile::ensure_role();

		$roles_fixed   = 0;
		$public_fixed  = 0;
		$resynced      = 0;
		$created       = 0;
		$shows_updated = 0;

		$legacy_users = get_users(
			array(
				'meta_key'     => RadioUdaan_Rj_Profile::META_LEGACY_POST_ID,
				'meta_compare' => 'EXISTS',
				'number'       => 500,
			)
		);

		foreach ( $legacy_users as $user ) {
			if ( ! RadioUdaan_Rj_Profile::is_rj( $user ) ) {
				$user->add_role( RadioUdaan_Rj_Profile::ROLE );
				++$roles_fixed;
			}
			if ( ! RadioUdaan_Rj_Profile::is_public_rj( $user ) ) {
				update_user_meta( $user->ID, RadioUdaan_Rj_Profile::META_IS_PUBLIC, 1 );
				++$public_fixed;
			}
		}

		$trashed_posts = get_posts(
			array(
				'post_type'      => 'rj-profiles',
				'post_status'    => 'trash',
				'posts_per_page' => -1,
				'orderby'        => 'ID',
				'order'          => 'ASC',
			)
		);

		$map = array();
		foreach ( $trashed_posts as $post ) {
			$existing = RadioUdaan_Rj_Profile::find_user_by_legacy_post_id( $post->ID );
			if ( $existing ) {
				self::copy_acf_to_user( $post, $existing->ID );
				$existing->add_role( RadioUdaan_Rj_Profile::ROLE );
				update_user_meta( $existing->ID, RadioUdaan_Rj_Profile::META_IS_PUBLIC, 1 );
				$map[ (int) $post->ID ] = (int) $existing->ID;
				++$resynced;
				continue;
			}

			$result = self::migrate_post_to_user( $post );
			if ( is_wp_error( $result ) ) {
				continue;
			}
			update_user_meta( $result['user_id'], RadioUdaan_Rj_Profile::META_IS_PUBLIC, 1 );
			$map[ (int) $post->ID ] = (int) $result['user_id'];
			if ( ! empty( $result['created'] ) ) {
				++$created;
			} else {
				++$resynced;
			}
		}

		if ( ! empty( $map ) ) {
			$shows_updated += self::rewire_radio_shows_program_host( $map );
			$shows_updated += self::apply_legacy_hosted_shows( $trashed_posts, $map );
		}

		// Any RJ user without legacy meta still missing public flag.
		$rj_users = get_users(
			array(
				'role'   => RadioUdaan_Rj_Profile::ROLE,
				'number' => 500,
			)
		);
		foreach ( $rj_users as $user ) {
			if ( ! RadioUdaan_Rj_Profile::is_public_rj( $user ) ) {
				update_user_meta( $user->ID, RadioUdaan_Rj_Profile::META_IS_PUBLIC, 1 );
				++$public_fixed;
			}
		}

		flush_rewrite_rules( false );

		$public_rjs = count( RadioUdaan_Rj_Profile::list_public_rjs() );
		$message    = sprintf(
			/* translators: 1: public count 2: roles fixed 3: public fixed 4: resynced 5: created 6: shows updated */
			__( 'RJ archive repair complete. %1$d profiles now public. Roles restored: %2$d. Public flags fixed: %3$d. Re-synced from trash: %4$d. Created from trash: %5$d. Shows rewired: %6$d.', 'radioudaan-app-api' ),
			$public_rjs,
			$roles_fixed,
			$public_fixed,
			$resynced,
			$created,
			$shows_updated
		);

		return array(
			'success'    => true,
			'message'    => $message,
			'public_rjs' => $public_rjs,
			'stats'      => array(
				'public_rjs'    => $public_rjs,
				'roles_fixed'   => $roles_fixed,
				'public_fixed'  => $public_fixed,
				'resynced'      => $resynced,
				'created'       => $created,
				'shows_updated' => $shows_updated,
			),
		);
	}

	/**
	 * Admin POST handler.
	 */
	public static function handle_migrate() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}
		check_admin_referer( 'radioudaan_migrate_rj_profiles' );

		$result = self::migrate_all( ! empty( $_POST['trash_legacy'] ) );

		wp_safe_redirect(
			add_query_arg(
				array(
					'page'              => RadioUdaan_Admin_Form_Migration::PAGE_SLUG,
					'radioudaan_notice' => $result['success'] ? 'success' : 'error',
					'radioudaan_detail'   => rawurlencode( $result['message'] ),
				),
				admin_url( 'admin.php' )
			)
		);
		exit;
	}

	/**
	 * Admin POST handler — repair blank Meet Our RJs archive.
	 */
	public static function handle_repair() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}
		check_admin_referer( 'radioudaan_repair_rj_profiles' );

		$result = self::repair_archive();

		wp_safe_redirect(
			add_query_arg(
				array(
					'page'                => RadioUdaan_Admin_Form_Migration::PAGE_SLUG,
					'radioudaan_notice'   => $result['success'] ? 'success' : 'error',
					'radioudaan_detail'   => rawurlencode( $result['message'] ),
				),
				admin_url( 'admin.php' )
			)
		);
		exit;
	}
}

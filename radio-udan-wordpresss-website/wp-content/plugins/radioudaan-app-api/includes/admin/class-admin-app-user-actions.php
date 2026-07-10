<?php
/**
 * Admin POST handlers for app user pause, resume, delete, and bulk actions.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * App user management actions (nonces, audit, token revoke, cleanup).
 */
class RadioUdaan_Admin_App_User_Actions {

	const ACTION_PAUSE  = 'radioudaan_app_user_pause';
	const ACTION_RESUME = 'radioudaan_app_user_resume';
	const ACTION_DELETE = 'radioudaan_app_user_delete';
	const ACTION_BULK   = 'radioudaan_app_users_bulk';

	/**
	 * Register admin_post handlers.
	 */
	public static function init() {
		add_action( 'admin_post_' . self::ACTION_PAUSE, array( __CLASS__, 'handle_pause' ) );
		add_action( 'admin_post_' . self::ACTION_RESUME, array( __CLASS__, 'handle_resume' ) );
		add_action( 'admin_post_' . self::ACTION_DELETE, array( __CLASS__, 'handle_delete' ) );
		add_action( 'admin_post_' . self::ACTION_BULK, array( __CLASS__, 'handle_bulk' ) );
	}

	/**
	 * Pause a single user.
	 */
	public static function handle_pause() {
		self::assert_cap();
		$user_id = self::require_user_id();
		check_admin_referer( 'radioudaan_app_user_action_' . $user_id );

		$user = RadioUdaan_App_Users::get_by_id( $user_id );
		if ( ! $user || RadioUdaan_App_Users::STATUS_ACTIVE !== $user->status ) {
			self::redirect_with_notice( 'error', __( 'User cannot be paused.', 'radioudaan-app-api' ), $user_id );
		}

		$ok = RadioUdaan_App_Users::pause( $user_id );
		if ( $ok ) {
			RadioUdaan_App_Admin_Audit::log(
				RadioUdaan_App_Admin_Audit::ACTION_USER_PAUSED,
				get_current_user_id(),
				$user_id,
				array( 'user_id' => $user_id )
			);
		}

		self::redirect_with_notice(
			$ok ? 'success' : 'error',
			$ok
				? __( 'User paused. Active sessions were revoked.', 'radioudaan-app-api' )
				: __( 'Could not pause user.', 'radioudaan-app-api' ),
			$user_id
		);
	}

	/**
	 * Resume a paused user.
	 */
	public static function handle_resume() {
		self::assert_cap();
		$user_id = self::require_user_id();
		check_admin_referer( 'radioudaan_app_user_action_' . $user_id );

		$ok = RadioUdaan_App_Users::resume( $user_id );
		if ( $ok ) {
			RadioUdaan_App_Admin_Audit::log(
				RadioUdaan_App_Admin_Audit::ACTION_USER_RESUMED,
				get_current_user_id(),
				$user_id,
				array( 'user_id' => $user_id )
			);
		}

		self::redirect_with_notice(
			$ok ? 'success' : 'error',
			$ok
				? __( 'User resumed.', 'radioudaan-app-api' )
				: __( 'Could not resume user.', 'radioudaan-app-api' ),
			$user_id
		);
	}

	/**
	 * Soft-delete user with device and notification cleanup.
	 */
	public static function handle_delete() {
		self::assert_cap();
		$user_id = self::require_user_id();
		check_admin_referer( 'radioudaan_app_user_action_' . $user_id );

		$user = RadioUdaan_App_Users::get_by_id( $user_id );
		if ( ! $user || RadioUdaan_App_Users::STATUS_DELETED === $user->status ) {
			self::redirect_with_notice( 'error', __( 'User not found or already deleted.', 'radioudaan-app-api' ) );
		}

		$ok = self::delete_user_fully( $user_id );
		if ( $ok ) {
			RadioUdaan_App_Admin_Audit::log(
				RadioUdaan_App_Admin_Audit::ACTION_USER_DELETED,
				get_current_user_id(),
				$user_id,
				array( 'user_id' => $user_id )
			);
		}

		self::redirect_with_notice(
			$ok ? 'success' : 'error',
			$ok
				? __( 'User deleted. Phone and email are available for re-registration.', 'radioudaan-app-api' )
				: __( 'Could not delete user.', 'radioudaan-app-api' )
		);
	}

	/**
	 * Bulk pause, resume, or delete.
	 */
	public static function handle_bulk() {
		self::assert_cap();
		check_admin_referer( 'radioudaan_app_users_bulk' );

		$bulk_action = isset( $_POST['bulk_action'] ) ? sanitize_key( wp_unslash( $_POST['bulk_action'] ) ) : '';
		$user_ids    = isset( $_POST['user_ids'] ) ? array_map( 'intval', (array) wp_unslash( $_POST['user_ids'] ) ) : array();
		$user_ids    = array_values( array_filter( array_unique( $user_ids ) ) );

		if ( empty( $user_ids ) || ! in_array( $bulk_action, array( 'pause', 'resume', 'delete' ), true ) ) {
			self::redirect_with_notice( 'error', __( 'Select users and a bulk action.', 'radioudaan-app-api' ) );
		}

		$success = 0;
		$failed  = 0;

		foreach ( $user_ids as $user_id ) {
			if ( $user_id < 1 ) {
				continue;
			}

			$ok = false;
			if ( 'pause' === $bulk_action ) {
				$user = RadioUdaan_App_Users::get_by_id( $user_id );
				if ( $user && RadioUdaan_App_Users::STATUS_ACTIVE === $user->status ) {
					$ok = RadioUdaan_App_Users::pause( $user_id );
				}
			} elseif ( 'resume' === $bulk_action ) {
				$ok = RadioUdaan_App_Users::resume( $user_id );
			} elseif ( 'delete' === $bulk_action ) {
				$user = RadioUdaan_App_Users::get_by_id( $user_id );
				if ( $user && RadioUdaan_App_Users::STATUS_DELETED !== $user->status ) {
					$ok = self::delete_user_fully( $user_id );
				}
			}

			if ( $ok ) {
				++$success;
			} else {
				++$failed;
			}
		}

		if ( $success > 0 ) {
			$audit_action = 'pause' === $bulk_action
				? RadioUdaan_App_Admin_Audit::ACTION_BULK_PAUSED
				: ( 'resume' === $bulk_action
					? RadioUdaan_App_Admin_Audit::ACTION_BULK_RESUMED
					: RadioUdaan_App_Admin_Audit::ACTION_BULK_DELETED );

			RadioUdaan_App_Admin_Audit::log(
				$audit_action,
				get_current_user_id(),
				null,
				array(
					'count'   => $success,
					'failed'  => $failed,
					'user_ids' => $user_ids,
				)
			);
		}

		$message = sprintf(
			/* translators: 1: success count, 2: failed count */
			__( 'Bulk action complete: %1$d succeeded, %2$d skipped or failed.', 'radioudaan-app-api' ),
			$success,
			$failed
		);

		self::redirect_with_notice( $success > 0 ? 'success' : 'error', $message );
	}

	/**
	 * Full account deletion (matches API account-delete cleanup).
	 *
	 * @param int $user_id User id.
	 * @return bool
	 */
	public static function delete_user_fully( $user_id ) {
		$user_id = (int) $user_id;
		if ( $user_id < 1 ) {
			return false;
		}

		RadioUdaan_App_Notifications::delete_devices_for_user( $user_id );
		RadioUdaan_App_Notifications::anonymize_notifications_for_user( $user_id );
		RadioUdaan_App_Favorites::delete_for_user( $user_id );
		$removed = RadioUdaan_App_Users::soft_delete( $user_id );
		RadioUdaan_App_Auth::revoke_all_tokens_for_user_id( $user_id );

		return (bool) $removed;
	}

	/**
	 * @param string $action Action slug.
	 * @param int    $user_id User id.
	 * @return string
	 */
	public static function action_url( $action, $user_id ) {
		return add_query_arg(
			array(
				'action'  => $action,
				'user_id' => (int) $user_id,
			),
			admin_url( 'admin-post.php' )
		);
	}

	/**
	 * @param int $user_id User id.
	 * @return string
	 */
	public static function nonce_field_name( $user_id ) {
		return 'radioudaan_app_user_action_' . (int) $user_id;
	}

	/**
	 * Assert manage_options.
	 */
	private static function assert_cap() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Insufficient permissions.', 'radioudaan-app-api' ) );
		}
	}

	/**
	 * @return int
	 */
	private static function require_user_id() {
		$user_id = isset( $_REQUEST['user_id'] ) ? (int) $_REQUEST['user_id'] : 0;
		if ( $user_id < 1 ) {
			wp_die( esc_html__( 'Invalid user.', 'radioudaan-app-api' ) );
		}
		return $user_id;
	}

	/**
	 * @param string   $notice  success|error.
	 * @param string   $detail  Message.
	 * @param int|null $user_id Redirect to detail when set.
	 */
	private static function redirect_with_notice( $notice, $detail, $user_id = null ) {
		$page = RadioUdaan_Admin_App_Hub::APP_USERS_SLUG;
		if ( null !== $user_id && $user_id > 0 ) {
			$page = RadioUdaan_Admin_App_Hub::VIEW_USER_SLUG;
		}

		$args = array(
			'page'              => $page,
			'radioudaan_notice' => $notice,
			'radioudaan_detail' => rawurlencode( $detail ),
		);

		if ( null !== $user_id && $user_id > 0 ) {
			$args['user_id'] = (int) $user_id;
		}

		// Preserve list filters when returning to the list.
		if ( RadioUdaan_Admin_App_Hub::APP_USERS_SLUG === $page ) {
			foreach ( array( 'status', 's', 'paged' ) as $key ) {
				if ( ! empty( $_REQUEST[ $key ] ) ) {
					$args[ $key ] = sanitize_text_field( wp_unslash( $_REQUEST[ $key ] ) );
				}
			}
		}

		wp_safe_redirect( add_query_arg( $args, admin_url( 'admin.php' ) ) );
		exit;
	}
}

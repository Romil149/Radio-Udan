<?php
/**
 * Cron cleanup for staged / abandoned app uploads.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Daily cleanup of old private app upload attachments.
 */
class RadioUdaan_Upload_Cleanup {

	const CRON_HOOK = 'radioudaan_cleanup_uploads';

	/**
	 * Register cron.
	 */
	public static function init() {
		add_action( self::CRON_HOOK, array( __CLASS__, 'run' ) );
		add_action( 'init', array( __CLASS__, 'schedule' ) );
	}

	/**
	 * Schedule daily event.
	 */
	public static function schedule() {
		if ( ! wp_next_scheduled( self::CRON_HOOK ) ) {
			wp_schedule_event( time() + HOUR_IN_SECONDS, 'daily', self::CRON_HOOK );
		}
	}

	/**
	 * Delete orphaned private attachments in app upload folder older than retention.
	 */
	public static function run() {
		$days = RadioUdaan_App_Settings::get_upload_retention_days();
		$cut  = time() - ( $days * DAY_IN_SECONDS );

		$upload_dir = wp_upload_dir();
		$base       = trailingslashit( $upload_dir['basedir'] ) . 'radioudaan-app-private';

		if ( ! is_dir( $base ) ) {
			return;
		}

		$iterator = new RecursiveIteratorIterator(
			new RecursiveDirectoryIterator( $base, FilesystemIterator::SKIP_DOTS )
		);

		foreach ( $iterator as $file ) {
			if ( ! $file->isFile() ) {
				continue;
			}
			if ( '.htaccess' === $file->getFilename() || 'index.php' === $file->getFilename() ) {
				continue;
			}
			if ( $file->getMTime() < $cut ) {
				wp_delete_file( $file->getPathname() );
			}
		}

		RadioUdaan_App_Logger::log(
			'upload_cleanup',
			array(
				'retention_days' => $days,
			)
		);
	}
}

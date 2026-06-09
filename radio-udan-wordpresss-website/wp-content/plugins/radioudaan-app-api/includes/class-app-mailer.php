<?php
/**
 * Transactional email for app password auth.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Sends verification and password-reset messages via wp_mail.
 */
class RadioUdaan_App_Mailer {

	/**
	 * @param object $user Row from wp_ru_app_users.
	 * @param string $code Plain 6-digit code (not stored in logs).
	 * @return bool
	 */
	public static function send_verification( $user, $code ) {
		$subject = RadioUdaan_App_Settings::get_email_verify_subject();
		$body    = RadioUdaan_App_Settings::get_email_verify_body();

		$body = self::replace_placeholders(
			$body,
			array(
				'name'     => $user->display_name,
				'email'    => $user->email,
				'code'     => $code,
				'app_name' => RadioUdaan_App_Branding::get_app_name(),
			)
		);

		return self::send( $user->email, $subject, $body );
	}

	/**
	 * @param object $user  User row.
	 * @param string $code  Plain 6-digit reset code.
	 * @param string $token Opaque reset token for web link.
	 * @return bool
	 */
	public static function send_password_reset( $user, $code, $token ) {
		$subject = RadioUdaan_App_Settings::get_email_reset_subject();
		$body    = RadioUdaan_App_Settings::get_email_reset_body();

		$link = add_query_arg(
			array(
				'ru_reset' => '1',
				'token'    => rawurlencode( $token ),
				'email'    => rawurlencode( $user->email ),
			),
			home_url( '/' )
		);

		$body = self::replace_placeholders(
			$body,
			array(
				'name'     => $user->display_name,
				'email'    => $user->email,
				'code'     => $code,
				'link'     => $link,
				'app_name' => RadioUdaan_App_Branding::get_app_name(),
			)
		);

		return self::send( $user->email, $subject, $body );
	}

	/**
	 * @param string               $to      Recipient.
	 * @param string               $subject Subject line.
	 * @param string               $body    Plain-text body.
	 * @return bool
	 */
	private static function send( $to, $subject, $body ) {
		$headers = array( 'Content-Type: text/plain; charset=UTF-8' );

		$sent = wp_mail( $to, $subject, $body, $headers );

		if ( ! $sent ) {
			RadioUdaan_App_Logger::log( 'mail_failed', array( 'type' => 'app_auth' ) );
		}

		return (bool) $sent;
	}

	/**
	 * @param string              $template Template with {{placeholders}}.
	 * @param array<string,string> $vars    Replacement values.
	 * @return string
	 */
	private static function replace_placeholders( $template, array $vars ) {
		$search  = array();
		$replace = array();
		foreach ( $vars as $key => $value ) {
			$search[]  = '{{' . $key . '}}';
			$replace[] = (string) $value;
		}

		return str_replace( $search, $replace, $template );
	}
}

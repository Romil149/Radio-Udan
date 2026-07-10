<?php
/**
 * 80G donation receipt email (HTML + simple PDF attachment).
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Sends donor receipt when admin toggles allow.
 */
class RadioUdaan_App_Donations_80g_Pdf {

	/**
	 * Send receipt email after captured donation.
	 *
	 * @param object $donation DB row.
	 * @return bool
	 */
	public static function maybe_send_receipt( $donation ) {
		if ( ! $donation || empty( $donation->email ) ) {
			return false;
		}
		if ( ! RadioUdaan_App_Donations_Settings::is_80g_pdf_email_enabled() ) {
			return false;
		}
		if ( empty( $donation->want_80g ) ) {
			return false;
		}
		if ( ! empty( $donation->receipt_sent_at ) ) {
			return false;
		}

		$sent = self::send_receipt_email( $donation );
		if ( $sent ) {
			RadioUdaan_App_Donations_Db::mark_receipt_sent( (int) $donation->id );
		}
		return $sent;
	}

	/**
	 * @param object $donation DB row.
	 * @return bool
	 */
	public static function send_receipt_email( $donation ) {
		$email = sanitize_email( (string) $donation->email );
		if ( '' === $email ) {
			return false;
		}

		$html     = self::build_html_receipt( $donation );
		$pdf      = self::build_simple_pdf( $donation );
		$subject  = sprintf(
			/* translators: %s: trust name */
			__( 'Donation receipt — %s', 'radioudaan-app-api' ),
			RadioUdaan_App_Donations_Settings::get_checkout_name()
		);
		$headers  = array( 'Content-Type: text/html; charset=UTF-8' );
		$boundary = wp_generate_password( 24, false, false );

		$body  = "--{$boundary}\r\n";
		$body .= "Content-Type: text/html; charset=UTF-8\r\n\r\n";
		$body .= $html . "\r\n";
		if ( '' !== $pdf ) {
			$body .= "--{$boundary}\r\n";
			$body .= "Content-Type: application/pdf; name=\"donation-receipt.pdf\"\r\n";
			$body .= "Content-Transfer-Encoding: base64\r\n";
			$body .= "Content-Disposition: attachment; filename=\"donation-receipt.pdf\"\r\n\r\n";
			$body .= chunk_split( base64_encode( $pdf ) ) . "\r\n";
		}
		$body .= "--{$boundary}--";

		$headers[] = 'MIME-Version: 1.0';
		$headers[] = 'Content-Type: multipart/mixed; boundary="' . $boundary . '"';

		return (bool) wp_mail( $email, $subject, $body, $headers );
	}

	/**
	 * @param object $donation DB row.
	 * @return string
	 */
	public static function build_html_receipt( $donation ) {
		$trust     = esc_html( RadioUdaan_App_Donations_Settings::get_checkout_name() );
		$address   = esc_html( trim( (string) get_option( RadioUdaan_App_Info_Hub::OPTION_DONATE_BANK_ADDRESS, '' ) ) );
		$trust_pan = esc_html( RadioUdaan_App_Donations_Settings::get_80g_trust_pan() );
		$reg_no    = esc_html( RadioUdaan_App_Donations_Settings::get_80g_reg_number() );
		$legal     = nl2br( esc_html( RadioUdaan_App_Donations_Settings::get_80g_legal_text() ) );
		$donor     = esc_html( (string) ( $donation->donor_name ?? '' ) );
		$pan_mask  = '';
		if ( ! empty( $donation->pan_encrypted ) ) {
			$pan      = RadioUdaan_App_Donations_Settings::decrypt_pan( $donation->pan_encrypted );
			$pan_mask = esc_html( RadioUdaan_App_Donations_Settings::mask_pan( $pan ) );
		}
		$amount_inr = number_format_i18n( ( (int) $donation->amount_paise ) / 100, 2 );
		$date       = esc_html( mysql2date( 'd M Y', (string) $donation->created_at ) );
		$payment_id = esc_html( (string) ( $donation->razorpay_payment_id ?? '' ) );

		ob_start();
		?>
		<html><body style="font-family: sans-serif; line-height: 1.5; color: #111;">
		<h1><?php echo esc_html__( 'Donation Receipt', 'radioudaan-app-api' ); ?></h1>
		<p><strong><?php echo esc_html__( 'Trust', 'radioudaan-app-api' ); ?>:</strong> <?php echo $trust; ?></p>
		<?php if ( $address ) : ?><p><strong><?php echo esc_html__( 'Address', 'radioudaan-app-api' ); ?>:</strong> <?php echo $address; ?></p><?php endif; ?>
		<?php if ( $trust_pan ) : ?><p><strong><?php echo esc_html__( 'Trust PAN', 'radioudaan-app-api' ); ?>:</strong> <?php echo $trust_pan; ?></p><?php endif; ?>
		<?php if ( $reg_no ) : ?><p><strong><?php echo esc_html__( '80G Registration', 'radioudaan-app-api' ); ?>:</strong> <?php echo $reg_no; ?></p><?php endif; ?>
		<hr>
		<p><strong><?php echo esc_html__( 'Donor', 'radioudaan-app-api' ); ?>:</strong> <?php echo $donor; ?></p>
		<?php if ( $pan_mask ) : ?><p><strong><?php echo esc_html__( 'Donor PAN', 'radioudaan-app-api' ); ?>:</strong> <?php echo $pan_mask; ?></p><?php endif; ?>
		<p><strong><?php echo esc_html__( 'Amount', 'radioudaan-app-api' ); ?>:</strong> ₹<?php echo esc_html( $amount_inr ); ?></p>
		<p><strong><?php echo esc_html__( 'Date', 'radioudaan-app-api' ); ?>:</strong> <?php echo $date; ?></p>
		<p><strong><?php echo esc_html__( 'Payment reference', 'radioudaan-app-api' ); ?>:</strong> <?php echo $payment_id; ?></p>
		<?php if ( $legal ) : ?><p><?php echo $legal; ?></p><?php endif; ?>
		<?php
		$signatory_url = RadioUdaan_App_Donations_Settings::get_80g_signatory_url();
		if ( $signatory_url ) :
			?>
			<p><img src="<?php echo esc_url( $signatory_url ); ?>" alt="<?php echo esc_attr__( 'Authorized signatory', 'radioudaan-app-api' ); ?>" style="max-width:220px;height:auto;" /></p>
		<?php endif; ?>
		<p style="font-size: 14px; color: #444;"><?php echo esc_html__( 'Form 10BE for income tax filing will be issued by the trust as per Income Tax rules.', 'radioudaan-app-api' ); ?></p>
		</body></html>
		<?php
		return (string) ob_get_clean();
	}

	/**
	 * Minimal text PDF for attachment (no external library).
	 *
	 * @param object $donation DB row.
	 * @return string Binary PDF or empty.
	 */
	public static function build_simple_pdf( $donation ) {
		$lines = array(
			'Donation Receipt',
			'Trust: ' . RadioUdaan_App_Donations_Settings::get_checkout_name(),
			'Donor: ' . (string) ( $donation->donor_name ?? '' ),
			'Amount: INR ' . number_format( ( (int) $donation->amount_paise ) / 100, 2 ),
			'Date: ' . mysql2date( 'd M Y', (string) $donation->created_at ),
			'Payment: ' . (string) ( $donation->razorpay_payment_id ?? '' ),
		);
		if ( ! empty( $donation->pan_encrypted ) ) {
			$pan     = RadioUdaan_App_Donations_Settings::decrypt_pan( $donation->pan_encrypted );
			$lines[] = 'Donor PAN: ' . RadioUdaan_App_Donations_Settings::mask_pan( $pan );
		}
		$reg = RadioUdaan_App_Donations_Settings::get_80g_reg_number();
		if ( $reg ) {
			$lines[] = '80G Reg: ' . $reg;
		}
		$text = implode( "\n", $lines );
		$signatory_jpeg = self::get_signatory_jpeg_bytes();
		return self::text_to_pdf( $text, $signatory_jpeg );
	}

	/**
	 * Load configured signatory attachment as JPEG bytes for PDF embedding.
	 *
	 * @return string Binary JPEG or empty.
	 */
	private static function get_signatory_jpeg_bytes() {
		$attachment_id = (int) get_option( RadioUdaan_App_Donations_Settings::OPTION_80G_SIGNATORY_ATTACHMENT_ID, 0 );
		if ( $attachment_id < 1 ) {
			return '';
		}

		$path = get_attached_file( $attachment_id );
		if ( ! $path || ! is_readable( $path ) ) {
			return '';
		}

		$bytes = file_get_contents( $path );
		if ( false === $bytes || '' === $bytes ) {
			return '';
		}

		if ( function_exists( 'imagecreatefromstring' ) && function_exists( 'imagejpeg' ) ) {
			$image = imagecreatefromstring( $bytes );
			if ( $image ) {
				ob_start();
				imagejpeg( $image, null, 88 );
				$jpeg = (string) ob_get_clean();
				imagedestroy( $image );
				if ( '' !== $jpeg ) {
					return $jpeg;
				}
			}
		}

		$mime = wp_check_filetype( $path );
		if ( isset( $mime['type'] ) && 'image/jpeg' === $mime['type'] ) {
			return $bytes;
		}

		return '';
	}

	/**
	 * @param string $text Plain text.
	 * @param string $jpeg_bytes Optional signatory JPEG.
	 * @return string
	 */
	private static function text_to_pdf( $text, $jpeg_bytes = '' ) {
		$text   = preg_replace( '/[^\x09\x0A\x0D\x20-\x7E]/', '', (string) $text );
		$lines  = explode( "\n", $text );
		$stream = "BT\n/F1 12 Tf\n50 750 Td\n";
		$first  = true;
		foreach ( $lines as $line ) {
			$line = str_replace( array( '\\', '(', ')' ), array( '\\\\', '\\(', '\\)' ), $line );
			if ( $first ) {
				$stream .= '(' . $line . ") Tj\n";
				$first   = false;
			} else {
				$stream .= "0 -16 Td\n(" . $line . ") Tj\n";
			}
		}
		$stream .= "ET\n";

		$image_info = ( '' !== $jpeg_bytes ) ? self::jpeg_dimensions( $jpeg_bytes ) : null;
		if ( $image_info ) {
			$img_w  = (float) $image_info['width'];
			$img_h  = (float) $image_info['height'];
			$draw_w = 180.0;
			$draw_h = max( 40.0, ( $img_h / $img_w ) * $draw_w );
			$y      = max( 80.0, 750.0 - ( count( $lines ) * 16.0 ) - $draw_h - 24.0 );
			$stream .= 'q ' . $draw_w . ' 0 0 ' . $draw_h . ' 50 ' . $y . " cm /Im1 Do Q\n";
		}

		$objects   = array();
		$objects[] = '<< /Type /Catalog /Pages 2 0 R >>';
		$objects[] = '<< /Type /Pages /Kids [3 0 R] /Count 1 >>';

		if ( $image_info ) {
			$objects[] = '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> /XObject << /Im1 6 0 R >> >> >>';
		} else {
			$objects[] = '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>';
		}

		$objects[] = '<< /Length ' . strlen( $stream ) . " >>\nstream\n" . $stream . "\nendstream";
		$objects[] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>';

		if ( $image_info ) {
			$objects[] = '<< /Type /XObject /Subtype /Image /Width ' . (int) $image_info['width'] . ' /Height ' . (int) $image_info['height'] . ' /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ' . strlen( $jpeg_bytes ) . " >>\nstream\n" . $jpeg_bytes . "\nendstream";
		}

		$pdf = "%PDF-1.4\n";
		$offsets = array( 0 );
		for ( $i = 0; $i < count( $objects ); $i++ ) {
			$offsets[] = strlen( $pdf );
			$pdf      .= ( $i + 1 ) . " 0 obj\n" . $objects[ $i ] . "\nendobj\n";
		}
		$xref = strlen( $pdf );
		$pdf .= "xref\n0 " . ( count( $objects ) + 1 ) . "\n";
		$pdf .= "0000000000 65535 f \n";
		for ( $i = 1; $i <= count( $objects ); $i++ ) {
			$pdf .= sprintf( "%010d 00000 n \n", $offsets[ $i ] );
		}
		$pdf .= "trailer\n<< /Size " . ( count( $objects ) + 1 ) . " /Root 1 0 R >>\n";
		$pdf .= "startxref\n{$xref}\n%%EOF";
		return $pdf;
	}

	/**
	 * @param string $jpeg_bytes JPEG binary.
	 * @return array{width:int,height:int}|null
	 */
	private static function jpeg_dimensions( $jpeg_bytes ) {
		if ( ! function_exists( 'imagecreatefromstring' ) ) {
			return null;
		}
		$image = imagecreatefromstring( $jpeg_bytes );
		if ( ! $image ) {
			return null;
		}
		$width  = imagesx( $image );
		$height = imagesy( $image );
		imagedestroy( $image );
		if ( $width < 1 || $height < 1 ) {
			return null;
		}
		return array(
			'width'  => $width,
			'height' => $height,
		);
	}
}

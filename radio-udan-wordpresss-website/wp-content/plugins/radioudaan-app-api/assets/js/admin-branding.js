/**
 * Settings: app logo picker + color hex sync.
 */
(function ($) {
	'use strict';

	$(function () {
		var frame;

		$('#ru-pick-brand-logo').on('click', function (e) {
			e.preventDefault();
			if (frame) {
				frame.open();
				return;
			}
			frame = wp.media({
				title: 'Choose app logo',
				button: { text: 'Use this logo' },
				multiple: false
			});
			frame.on('select', function () {
				var attachment = frame.state().get('selection').first().toJSON();
				$('#branding_logo_id').val(attachment.id);
				$('#ru-brand-logo-preview').html(
					'<img src="' + attachment.url + '" alt="" style="max-height:80px;width:auto;" />'
				);
				$('#ru-remove-brand-logo').show();
			});
			frame.open();
		});

		$('#ru-remove-brand-logo').on('click', function (e) {
			e.preventDefault();
			$('#branding_logo_id').val('0');
			$('#ru-brand-logo-preview').empty();
			$(this).hide();
		});

		$('.ru-color-hex').each(function () {
			var $hex = $(this);
			var $color = $('#' + $hex.data('for'));
			$color.on('input', function () {
				$hex.val($color.val());
			});
			$hex.on('change blur', function () {
				var v = $hex.val();
				if (/^#[0-9a-fA-F]{6}$/.test(v)) {
					$color.val(v);
				}
			});
		});
	});
})(jQuery);

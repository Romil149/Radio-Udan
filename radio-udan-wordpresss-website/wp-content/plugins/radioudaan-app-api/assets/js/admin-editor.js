/**
 * Event editor: image picker + event code sync.
 */
(function ($) {
	'use strict';

	function syncEventCode() {
		var $pick = $('#ru_event_code_pick');
		var $custom = $('#ru_event_code_custom');
		var $hidden = $('#ru_event_code');
		if (!$pick.length || !$hidden.length) {
			return;
		}
		if ($pick.val() === '__custom__') {
			$custom.show().prop('required', true);
			$hidden.val($custom.val());
		} else if ($pick.val()) {
			$custom.hide().prop('required', false);
			$hidden.val($pick.val());
		} else {
			$custom.hide().prop('required', false);
			$hidden.val($custom.val() || '');
		}
	}

	var presetMessages = {
		default: 'Thank you. Your registration was received.',
		contact: 'Thank you! We will contact you soon.',
		review: 'Thank you! Your submission is under review.'
	};

	$(function () {
		$('#ru_event_code_pick').on('change', syncEventCode);
		$('#ru_event_code_custom').on('input', syncEventCode);
		$('#ru_success_preset').on('change', function () {
			var val = $(this).val();
			if (val && presetMessages[val]) {
				$('#ru_success_message').val(presetMessages[val]);
			}
		});

		var frame;
		$('#ru-pick-image').on('click', function (e) {
			e.preventDefault();
			if (frame) {
				frame.open();
				return;
			}
			frame = wp.media({
				title: 'Choose banner image',
				button: { text: 'Use this image' },
				multiple: false
			});
			frame.on('select', function () {
				var attachment = frame.state().get('selection').first().toJSON();
				$('#ru_featured_image_id').val(attachment.id);
				$('#ru-thumb-preview').html('<img src="' + attachment.url + '" alt="" />');
				$('#ru-remove-image').show();
			});
			frame.open();
		});

		$('#ru-remove-image').on('click', function (e) {
			e.preventDefault();
			$('#ru_featured_image_id').val('');
			$('#ru-thumb-preview').empty();
			$(this).hide();
		});

		$('.ru-event-editor-form').on('submit', syncEventCode);
		syncEventCode();
	});
})(jQuery);

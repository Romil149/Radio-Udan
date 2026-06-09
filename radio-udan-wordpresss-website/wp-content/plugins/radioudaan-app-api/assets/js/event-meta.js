/**
 * App Event meta box interactions.
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

	function suggestCodeFromPage() {
		var $page = $('#ru_registration_page_id');
		var $pick = $('#ru_event_code_pick');
		var $custom = $('#ru_event_code_custom');
		if (!$page.length) {
			return;
		}
		var slug = $page.find('option:selected').data('slug');
		if (!slug || ($pick.val() && $pick.val() !== '__custom__')) {
			return;
		}
		if ($pick.val() === '__custom__' && !$custom.val()) {
			$custom.val(slug);
			syncEventCode();
		}
	}

	$(function () {
		$('#ru_event_code_pick').on('change', syncEventCode);
		$('#ru_event_code_custom').on('input', syncEventCode);
		$('#ru_registration_page_id').on('change', suggestCodeFromPage);

		var presetMessages = {
			default: 'Thank you. Your registration was received.',
			contact: 'Thank you! We will contact you soon.',
			review: 'Thank you! Your submission is under review.'
		};

		$('#ru_success_preset').on('change', function () {
			var val = $(this).val();
			if (!val) {
				return;
			}
			if (presetMessages[val]) {
				$('#ru_success_message').val(presetMessages[val]);
			}
		});

		$('#post').on('submit', function () {
			syncEventCode();
		});

		syncEventCode();
	});
})(jQuery);

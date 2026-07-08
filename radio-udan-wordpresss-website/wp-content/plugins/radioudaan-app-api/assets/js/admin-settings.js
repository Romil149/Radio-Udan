/**
 * Settings page: tabs, live phone preview, logo picker, color sync.
 */
(function ($) {
	'use strict';

	function activateSettingsTab(tab) {
		var $tabs = $('.ru-settings-tabs__btn');
		var $panels = $('.ru-settings-panel');

		$tabs.removeClass('is-active').attr('aria-selected', 'false');
		$tabs.filter('[data-tab="' + tab + '"]').addClass('is-active').attr('aria-selected', 'true');
		$panels.removeClass('is-active');
		$panels.filter('[data-panel="' + tab + '"]').addClass('is-active');
	}

	function initTabs() {
		$('.ru-settings-tabs__btn').on('click', function () {
			activateSettingsTab($(this).data('tab'));
		});

		var tab = new URLSearchParams(window.location.search).get('tab');
		if (tab && $('.ru-settings-tabs__btn[data-tab="' + tab + '"]').length) {
			activateSettingsTab(tab);
		}
	}

	function initFormSubmit() {
		var $form = $('.ru-settings-form');
		if (!$form.length) {
			return;
		}

		$form.on('submit', function () {
			// Browsers omit controls inside display:none / [hidden] ancestors from POST.
			$form.addClass('is-submitting');
			$('.ru-settings-panel').removeAttr('hidden');

			var activeTab = $('.ru-settings-tabs__btn.is-active').data('tab');
			if (activeTab) {
				$form.find('input[name="radioudaan_active_tab"]').remove();
				$('<input>', {
					type: 'hidden',
					name: 'radioudaan_active_tab',
					value: activeTab
				}).appendTo($form);
			}
		});
	}

	function updatePreview() {
		var primary = $('#branding_color_primary').val() || '#ff6b00';
		var onPrimary = $('#branding_color_on_primary').val() || '#ffffff';
		var dark = $('#branding_color_surface_dark').val() || '#1a1a1a';
		var name =
			$('#branding_app_name').val().trim() ||
			$('#branding_app_name').attr('placeholder') ||
			'Radio Udaan';
		var tagline =
			$('#branding_tagline').val().trim() ||
			$('#branding_tagline').attr('placeholder') ||
			'';

		var $header = $('#ru-preview-header');
		var $btn = $('#ru-preview-btn');
		var $tabs = $('#ru-preview-tabs');

		$header.css('background', dark);
		$('#ru-preview-app-name').text(name).css('color', onPrimary);
		$('#ru-preview-tagline').text(tagline).css('color', onPrimary);
		$btn.css({ background: primary, color: onPrimary });
		$tabs.css('--ru-preview-primary', primary);
		$tabs.find('[data-preview-tab="radio"]').css('color', primary);

		var tabRadio = $('#copy_tab_radio').val() || $('#copy_tab_radio').attr('placeholder');
		if (tabRadio) {
			$tabs.find('[data-preview-tab="radio"]').text(tabRadio);
		}
	}

	function initPreview() {
		$(
			'#branding_app_name, #branding_tagline, #branding_color_primary, #branding_color_on_primary, #branding_color_surface_dark, #copy_tab_radio'
		).on('input change', updatePreview);
		updatePreview();
	}

	function initLogoPicker() {
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
					'<img src="' + attachment.url + '" alt="" />'
				);
				$('#ru-preview-logo').html(
					'<img src="' + attachment.url + '" alt="" />'
				);
				$('#ru-remove-brand-logo').show();
			});
			frame.open();
		});

		$('#ru-remove-brand-logo').on('click', function (e) {
			e.preventDefault();
			$('#branding_logo_id').val('0');
			$('#ru-brand-logo-preview').empty();
			$('#ru-preview-logo').empty();
			$(this).hide();
		});
	}

	function initColorHex() {
		$('.ru-color-hex').each(function () {
			var $hex = $(this);
			var $color = $('#' + $hex.data('for'));
			$color.on('input', function () {
				$hex.val($color.val());
				if ($hex.data('for').indexOf('branding_color_') === 0) {
					updatePreview();
				}
			});
			$hex.on('change blur', function () {
				var v = $hex.val();
				if (/^#[0-9a-fA-F]{6}$/.test(v)) {
					$color.val(v);
					updatePreview();
				}
			});
		});
	}

	function initDonateQrPicker() {
		var frame;

		function openDonateQrFrame() {
			if (typeof wp === 'undefined' || !wp.media) {
				window.alert('Media library is not available. Refresh the page and try again.');
				return;
			}
			if (frame) {
				frame.open();
				return;
			}
			frame = wp.media({
				title: 'Choose UPI QR image',
				button: { text: 'Use this image' },
				multiple: false
			});
			frame.on('select', function () {
				var attachment = frame.state().get('selection').first().toJSON();
				$('#donate_qr_attachment_id').val(attachment.id);
				$('#ru-donate-qr-preview').html(
					'<img src="' + attachment.url + '" alt="" style="max-width:220px;border-radius:8px;" />'
				);
				$('#ru-remove-donate-qr').show();
			});
			frame.open();
		}

		$(document).on('click', '#ru-pick-donate-qr', function (e) {
			e.preventDefault();
			openDonateQrFrame();
		});

		$(document).on('click', '#ru-remove-donate-qr', function (e) {
			e.preventDefault();
			$('#donate_qr_attachment_id').val('0');
			$('#ru-donate-qr-preview').empty();
			$(this).hide();
		});

		$(document).on('click', '#ru-pick-donate-signatory', function (e) {
			e.preventDefault();
			var signFrame = wp.media({
				title: 'Choose signatory image',
				button: { text: 'Use this image' },
				multiple: false
			});
			signFrame.on('select', function () {
				var attachment = signFrame.state().get('selection').first().toJSON();
				$('#donate_80g_signatory_attachment_id').val(attachment.id);
				$('#ru-donate-signatory-preview').html(
					'<img src="' + attachment.url + '" alt="" style="max-width:220px;border-radius:8px;" />'
				);
				$('#ru-remove-donate-signatory').show();
			});
			signFrame.open();
		});

		$(document).on('click', '#ru-remove-donate-signatory', function (e) {
			e.preventDefault();
			$('#donate_80g_signatory_attachment_id').val('0');
			$('#ru-donate-signatory-preview').empty();
			$(this).hide();
		});
	}

	function initLiveHeroPicker() {
		var frame;
		$('#ru-pick-live-hero').on('click', function (e) {
			e.preventDefault();
			if (frame) {
				frame.open();
				return;
			}
			frame = wp.media({
				title: 'Choose live radio hero image',
				button: { text: 'Use this image' },
				multiple: false
			});
			frame.on('select', function () {
				var attachment = frame.state().get('selection').first().toJSON();
				$('#live_hero_id').val(attachment.id);
				$('#ru-live-hero-preview').html(
					'<img src="' + attachment.url + '" alt="" style="max-width:100%;border-radius:8px;" />'
				);
				$('#ru-remove-live-hero').show();
			});
			frame.open();
		});

		$('#ru-remove-live-hero').on('click', function (e) {
			e.preventDefault();
			$('#live_hero_id').val('0');
			$('#ru-live-hero-preview').empty();
			$(this).hide();
		});
	}

	$(function () {
		if (!$('.ru-admin--settings').length) {
			return;
		}
		initTabs();
		initFormSubmit();
		initPreview();
		initLogoPicker();
		initDonateQrPicker();
		initLiveHeroPicker();
		initColorHex();
	});
})(jQuery);

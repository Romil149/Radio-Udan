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

	function escapeHtml(text) {
		return $('<div>').text(text || '').html();
	}

	function formatVideoCount(count) {
		var n = parseInt(count, 10) || 0;
		if (n <= 0) {
			return '';
		}
		if (radioudaanYoutubeAdmin.i18n.videoCount) {
			return radioudaanYoutubeAdmin.i18n.videoCount.replace('%d', String(n));
		}
		return n === 1 ? '1 video' : n + ' videos';
	}

	function buildPlaylistItemHtml(pl, checked) {
		var id = pl.id || '';
		var title = pl.title || id;
		var thumb = pl.thumbnail_url || '';
		var countLabel = formatVideoCount(pl.video_count);
		var isStub = title === id && !thumb;
		var classes = 'ru-youtube-playlist-item';
		if (checked) {
			classes += ' is-selected';
		}
		if (isStub) {
			classes += ' is-stub';
		}

		var thumbHtml = thumb
			? '<img src="' + escapeHtml(thumb) + '" alt="" loading="lazy" decoding="async" />'
			: '<span class="ru-youtube-playlist-item__thumb-placeholder dashicons dashicons-playlist-video"></span>';

		var metaHtml = '';
		if (countLabel) {
			metaHtml =
				'<span class="ru-youtube-playlist-item__meta">' + escapeHtml(countLabel) + '</span>';
		} else if (isStub) {
			metaHtml =
				'<span class="ru-youtube-playlist-item__meta ru-youtube-playlist-item__meta--warn">' +
				escapeHtml(radioudaanYoutubeAdmin.i18n.stubNote) +
				'</span>';
		}

		return (
			'<label class="' +
			classes +
			'" data-title="' +
			escapeHtml(title.toLowerCase()) +
			'">' +
			'<input type="checkbox" name="youtube_featured_playlists[]" value="' +
			escapeHtml(id) +
			'"' +
			(checked ? ' checked' : '') +
			' />' +
			'<span class="ru-youtube-playlist-item__drag dashicons dashicons-menu" role="button" tabindex="0" aria-label="' +
			escapeHtml(radioudaanYoutubeAdmin.i18n.dragHandle) +
			'" title="' +
			escapeHtml(radioudaanYoutubeAdmin.i18n.dragHandle) +
			'"></span>' +
			'<span class="ru-youtube-playlist-item__thumb" aria-hidden="true">' +
			thumbHtml +
			'</span>' +
			'<span class="ru-youtube-playlist-item__body">' +
			'<strong class="ru-youtube-playlist-item__title">' +
			escapeHtml(title) +
			'</strong>' +
			metaHtml +
			'<code class="ru-youtube-playlist-item__id">' +
			escapeHtml(id) +
			'</code>' +
			'</span>' +
			'</label>'
		);
	}

	function updatePlaylistSelectedCount($picker) {
		var $selected = $('#ru-youtube-playlist-selected');
		if (!$selected.length) {
			return;
		}
		var count = $picker.find('input[type="checkbox"]:checked').length;
		$selected.text(
			radioudaanYoutubeAdmin.i18n.selected.replace('%d', String(count))
		);
	}

	function getSelectedOrderFromPicker($picker) {
		var order = [];
		$picker.find('.ru-youtube-playlist-item input[type="checkbox"]:checked').each(function () {
			order.push($(this).val());
		});
		return order;
	}

	function sortItemsPreservingOrder(items, selectedOrder) {
		return items.slice().sort(function (a, b) {
			var aIdx = selectedOrder.indexOf(a.id);
			var bIdx = selectedOrder.indexOf(b.id);
			if (aIdx !== -1 && bIdx !== -1) {
				return aIdx - bIdx;
			}
			if (aIdx !== -1) {
				return -1;
			}
			if (bIdx !== -1) {
				return 1;
			}
			return (a.title || a.id).localeCompare(b.title || b.id);
		});
	}

	function initPlaylistSortable($picker) {
		if (!$picker.length || !$.fn.sortable) {
			return;
		}

		if ($picker.hasClass('ui-sortable')) {
			$picker.sortable('destroy');
		}

		$picker.sortable({
			items: '.ru-youtube-playlist-item:not(.is-hidden)',
			handle: '.ru-youtube-playlist-item__drag',
			axis: 'y',
			cursor: 'grabbing',
			placeholder: 'ru-youtube-playlist-item ui-sortable-placeholder',
			forcePlaceholderSize: true,
			tolerance: 'pointer',
			start: function (_event, ui) {
				ui.item.addClass('is-dragging');
			},
			stop: function (_event, ui) {
				ui.item.removeClass('is-dragging');
			}
		});

		$picker.off('mousedown.ruYoutubeDrag').on('mousedown.ruYoutubeDrag', '.ru-youtube-playlist-item__drag', function (e) {
			e.preventDefault();
		});
	}

	function togglePlaylistDragUi($picker) {
		var hasItems = $picker.find('.ru-youtube-playlist-item').length > 0;
		$('#ru-youtube-playlist-drag-hint').toggle(hasItems);
		if (hasItems) {
			initPlaylistSortable($picker);
		} else if ($picker.hasClass('ui-sortable')) {
			$picker.sortable('destroy');
			$('#ru-youtube-playlist-drag-hint').attr('hidden', true);
		}
	}

	function bindPlaylistPickerEvents($picker) {
		$picker.off('change.ruYoutube').on('change.ruYoutube', 'input[type="checkbox"]', function () {
			$(this).closest('.ru-youtube-playlist-item').toggleClass('is-selected', this.checked);
			updatePlaylistSelectedCount($picker);
		});
		updatePlaylistSelectedCount($picker);
		togglePlaylistDragUi($picker);
	}

	function filterPlaylistPicker(query) {
		var q = (query || '').trim().toLowerCase();
		$('#ru-youtube-playlist-picker .ru-youtube-playlist-item').each(function () {
			var title = $(this).data('title') || '';
			var id = $(this).find('.ru-youtube-playlist-item__id').text().toLowerCase();
			var match = !q || title.indexOf(q) !== -1 || id.indexOf(q) !== -1;
			$(this).toggleClass('is-hidden', !match);
		});
	}

	function syncFeaturedPlaylistSubmitOrder($form, $picker) {
		var ordered = [];
		$picker.find('.ru-youtube-playlist-item').each(function () {
			var $cb = $(this).find('input[type="checkbox"]');
			if ($cb.is(':checked')) {
				ordered.push($cb.val());
			}
		});

		$form.find('input.ru-yt-featured-order').remove();
		$picker.find('input[name="youtube_featured_playlists[]"]').removeAttr('name');

		ordered.forEach(function (id) {
			$('<input>', {
				type: 'hidden',
				'class': 'ru-yt-featured-order',
				name: 'youtube_featured_playlists[]',
				value: id
			}).appendTo($form);
		});
	}

	function initYoutubePlaylistLoader() {
		var $btn = $('#ru-youtube-load-playlists');
		var $picker = $('#ru-youtube-playlist-picker');
		var $status = $('#ru-youtube-load-status');
		var $tools = $('#ru-youtube-playlist-tools');
		var $search = $('#ru-youtube-playlist-search');
		var $form = $picker.closest('form');
		if (!$btn.length || typeof radioudaanYoutubeAdmin === 'undefined') {
			return;
		}

		if ($form.length) {
			$form.on('submit.ruYoutube', function () {
				if ($picker.find('.ru-youtube-playlist-item').length) {
					syncFeaturedPlaylistSubmitOrder($form, $picker);
				}
			});
		}

		if ($picker.find('.ru-youtube-playlist-item').length) {
			$tools.removeAttr('hidden');
			$('#ru-youtube-playlist-drag-hint').removeAttr('hidden');
			bindPlaylistPickerEvents($picker);
		}

		$search.on('input', function () {
			filterPlaylistPicker($(this).val());
		});

		$btn.on('click', function () {
			var selected = {};
			var selectedOrder = getSelectedOrderFromPicker($picker);
			$picker.find('input[type="checkbox"]:checked').each(function () {
				selected[$(this).val()] = true;
			});

			$btn.prop('disabled', true);
			$status.text(radioudaanYoutubeAdmin.i18n.loading);

			$.post(radioudaanYoutubeAdmin.ajaxUrl, {
				action: 'radioudaan_youtube_load_playlists',
				nonce: radioudaanYoutubeAdmin.nonce
			})
				.done(function (res) {
					if (!res || !res.success || !res.data || !res.data.items) {
						$status.text(radioudaanYoutubeAdmin.i18n.error);
						return;
					}
					var items = res.data.items;
					if (!items.length) {
						$picker.html(
							'<p class="description ru-youtube-playlist-picker__empty">' +
								radioudaanYoutubeAdmin.i18n.empty +
								'</p>'
						);
						$tools.attr('hidden', true);
						$status.text('');
						return;
					}

					items = sortItemsPreservingOrder(items, selectedOrder);

					var html = '';
					items.forEach(function (pl) {
						html += buildPlaylistItemHtml(pl, !!selected[pl.id]);
					});
					$picker.html(html);
					$tools.removeAttr('hidden');
					bindPlaylistPickerEvents($picker);
					filterPlaylistPicker($search.val());
					$status.text(
						radioudaanYoutubeAdmin.i18n.loaded.replace('%d', String(items.length))
					);
				})
				.fail(function () {
					$status.text(radioudaanYoutubeAdmin.i18n.error);
				})
				.always(function () {
					$btn.prop('disabled', false);
				});
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
		initYoutubePlaylistLoader();
	});
})(jQuery);

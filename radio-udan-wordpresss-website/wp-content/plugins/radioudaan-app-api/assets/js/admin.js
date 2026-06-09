/**
 * Radio Udaan App admin dashboard scripts.
 */
(function () {
	'use strict';

	function copyText(text, button) {
		if (!text) {
			return;
		}
		var done = function () {
			if (!button) {
				return;
			}
			var original = button.textContent;
			button.textContent = button.getAttribute('data-copied-label') || 'Copied!';
			setTimeout(function () {
				button.textContent = original;
			}, 2000);
		};

		if (navigator.clipboard && navigator.clipboard.writeText) {
			navigator.clipboard.writeText(text).then(done).catch(function () {
				window.prompt('Copy:', text);
			});
			return;
		}
		window.prompt('Copy:', text);
		done();
	}

	document.addEventListener('click', function (e) {
		var btn = e.target.closest('[data-ru-copy]');
		if (!btn) {
			return;
		}
		e.preventDefault();
		var targetId = btn.getAttribute('data-ru-copy');
		var el = targetId ? document.getElementById(targetId) : null;
		var text = el ? (el.textContent || el.value || '').trim() : btn.getAttribute('data-ru-copy-text');
		copyText(text, btn);
	});

	document.addEventListener('submit', function (e) {
		var form = e.target;
		if (!form || !form.classList.contains('ru-confirm-submit')) {
			return;
		}
		var msg = form.getAttribute('data-confirm');
		if (msg && !window.confirm(msg)) {
			e.preventDefault();
		}
	});

	function initEventsSortable() {
		if (typeof jQuery === 'undefined' || !jQuery.fn.sortable) {
			return;
		}

		var $ = jQuery;
		var $list = $('#ru-events-sortable');
		var $status = $('#ru-events-order-status');
		if (
			!$list.length ||
			typeof radioudaanEventsAdmin === 'undefined' ||
			!$list.find('.ru-admin__event-card--sortable').length
		) {
			return;
		}

		var saveTimer = null;
		var saving = false;

		function collectOrder() {
			var order = [];
			$list.find('.ru-admin__event-card--sortable').each(function () {
				var id = parseInt($(this).attr('data-event-id'), 10);
				if (id > 0) {
					order.push(id);
				}
			});
			return order;
		}

		function saveOrder() {
			if (saving) {
				return;
			}
			saving = true;
			$status.text(radioudaanEventsAdmin.i18n.saving);

			$.post(radioudaanEventsAdmin.ajaxUrl, {
				action: 'radioudaan_save_event_order',
				nonce: radioudaanEventsAdmin.nonce,
				order: collectOrder()
			})
				.done(function (res) {
					if (res && res.success) {
						$status.text(radioudaanEventsAdmin.i18n.saved);
					} else {
						$status.text(radioudaanEventsAdmin.i18n.error);
					}
				})
				.fail(function () {
					$status.text(radioudaanEventsAdmin.i18n.error);
				})
				.always(function () {
					saving = false;
					window.setTimeout(function () {
						if (!$status.text()) {
							return;
						}
						if (
							$status.text() === radioudaanEventsAdmin.i18n.saved ||
							$status.text() === radioudaanEventsAdmin.i18n.error
						) {
							$status.text('');
						}
					}, 3500);
				});
		}

		function queueSave() {
			if (saveTimer) {
				window.clearTimeout(saveTimer);
			}
			saveTimer = window.setTimeout(saveOrder, 350);
		}

		if ($list.hasClass('ui-sortable')) {
			$list.sortable('destroy');
		}

		$list.sortable({
			items: '.ru-admin__event-card--sortable',
			handle: '.ru-admin__event-drag',
			axis: 'y',
			cursor: 'grabbing',
			placeholder: 'ru-admin__event-card ru-admin__event-card--placeholder',
			forcePlaceholderSize: true,
			tolerance: 'pointer',
			start: function (_event, ui) {
				ui.item.addClass('is-dragging');
			},
			stop: function (_event, ui) {
				ui.item.removeClass('is-dragging');
				queueSave();
			}
		});

		$list.on('mousedown', '.ru-admin__event-drag', function (e) {
			e.preventDefault();
		});
	}

	if (typeof jQuery !== 'undefined') {
		jQuery(initEventsSortable);
	}
})();

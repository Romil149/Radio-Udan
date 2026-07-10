/**
 * App users admin — double-confirm for pause/delete and bulk actions.
 */
(function () {
	'use strict';

	var i18n = (typeof radioudaanUsersAdmin !== 'undefined' && radioudaanUsersAdmin.i18n)
		? radioudaanUsersAdmin.i18n
		: {};

	function promptConfirmWord(word, message) {
		var typed = window.prompt(message || ('Type ' + word + ' to confirm:'));
		if (null === typed) {
			return false;
		}
		if (typed.trim().toUpperCase() !== word) {
			window.alert(i18n.typeMismatch || 'Confirmation text did not match. Action cancelled.');
			return false;
		}
		return true;
	}

	document.addEventListener('submit', function (e) {
		var form = e.target;
		if (!form || !form.classList.contains('ru-danger-action-form')) {
			return;
		}

		var word = form.getAttribute('data-ru-confirm-word');
		if (!word) {
			return;
		}

		var message = 'DELETE' === word
			? (i18n.confirmDelete || 'Type DELETE to confirm:')
			: (i18n.confirmPause || 'Type PAUSE to confirm:');

		if (!promptConfirmWord(word, message)) {
			e.preventDefault();
		}
	});

	var bulkForm = document.getElementById('ru-app-users-bulk-form');
	if (bulkForm) {
		bulkForm.addEventListener('submit', function (e) {
			var actionSelect = document.getElementById('ru-app-users-bulk-action');
			var action = actionSelect ? actionSelect.value : '';
			if (!action) {
				e.preventDefault();
				window.alert(i18n.selectAction || 'Choose a bulk action.');
				return;
			}

			var checked = bulkForm.querySelectorAll('.ru-app-user-checkbox:checked');
			if (!checked.length) {
				e.preventDefault();
				window.alert(i18n.selectUsers || 'Select at least one user.');
				return;
			}

			if ('delete' === action) {
				if (!promptConfirmWord('DELETE', i18n.confirmDelete)) {
					e.preventDefault();
				}
				return;
			}

			if ('pause' === action) {
				if (!promptConfirmWord('PAUSE', i18n.confirmPause)) {
					e.preventDefault();
				}
				return;
			}

			if (!window.confirm(i18n.confirmBulk || 'Apply this bulk action to the selected users?')) {
				e.preventDefault();
			}
		});
	}

	var selectAll = document.getElementById('ru-app-users-select-all');
	if (selectAll) {
		selectAll.addEventListener('change', function () {
			var boxes = document.querySelectorAll('.ru-app-user-checkbox');
			for (var i = 0; i < boxes.length; i++) {
				boxes[i].checked = selectAll.checked;
			}
		});
	}
})();

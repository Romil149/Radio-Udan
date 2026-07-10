/**
 * Global admin header search — keyboard focus shortcut.
 */
(function () {
	'use strict';

	document.addEventListener('DOMContentLoaded', function () {
		var input = document.getElementById('ru-global-search');
		if (!input) {
			return;
		}

		document.addEventListener('keydown', function (event) {
			if (
				event.key === '/' &&
				!event.metaKey &&
				!event.ctrlKey &&
				!event.altKey &&
				document.activeElement !== input &&
				!document.activeElement.matches('input, textarea, select, [contenteditable="true"]')
			) {
				event.preventDefault();
				input.focus();
				input.select();
			}
		});
	});
})();

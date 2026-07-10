/**
 * Searchable FAQ and API route lists in the app admin.
 */
(function () {
	'use strict';

	function normalize(text) {
		return String(text || '')
			.toLowerCase()
			.replace(/\s+/g, ' ')
			.trim();
	}

	function filterItems(input, itemSelector, emptySelector) {
		var query = normalize(input.value);
		var items = document.querySelectorAll(itemSelector);
		var visible = 0;

		items.forEach(function (item) {
			var haystack = normalize(item.getAttribute('data-ru-search') || item.textContent);
			var show = !query || haystack.indexOf(query) !== -1;
			item.hidden = !show;
			if (show) {
				visible += 1;
			}
		});

		var empty = document.querySelector(emptySelector);
		if (empty) {
			empty.hidden = visible > 0 || !query;
		}
	}

	function initFaqSearch() {
		var input = document.getElementById('ru-help-faq-search');
		if (!input) {
			return;
		}

		input.addEventListener('input', function () {
			filterItems(input, '.ru-help-faq-item', '.ru-help-faq-empty');
		});
	}

	function initRouteSearch() {
		var input = document.getElementById('ru-api-route-search');
		if (!input) {
			return;
		}

		input.addEventListener('input', function () {
			filterItems(input, '.ru-admin__endpoint[data-ru-search]', '.ru-api-routes-empty');
		});
	}

	document.addEventListener('DOMContentLoaded', function () {
		initFaqSearch();
		initRouteSearch();
	});
})();

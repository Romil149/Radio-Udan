(function ($) {
	'use strict';

	function bindPhotoPicker() {
		var frame;
		var $input = $('#radioudaan_rj_photo_id');
		var $preview = $('#radioudaan-rj-photo-preview');
		var $remove = $('#radioudaan-rj-remove-photo');

		$('#radioudaan-rj-pick-photo').on('click', function (e) {
			e.preventDefault();
			if (frame) {
				frame.open();
				return;
			}
			frame = wp.media({
				title: 'Choose RJ profile photo',
				button: { text: 'Use photo' },
				multiple: false,
				library: { type: 'image' },
			});
			frame.on('select', function () {
				var attachment = frame.state().get('selection').first().toJSON();
				$input.val(attachment.id);
				$preview.html(
					'<img src="' + attachment.url + '" alt="" style="max-width:220px;border-radius:12px;" />'
				);
				$remove.show();
			});
			frame.open();
		});

		$remove.on('click', function (e) {
			e.preventDefault();
			$input.val('');
			$preview.empty();
			$remove.hide();
		});
	}

	$(bindPhotoPicker);
})(jQuery);

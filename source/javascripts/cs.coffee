$ ()->
	songScrapper = "http://valayosai.com"
	$(".valayosai_add_song").click (e)->
		chrome.runtime.sendMessage({message: $.extend({action: "add"}, $(this).data())})
		e.preventDefault()

	$(".valayosai_add_album").click (e) ->
		$.getJSON($(this).data("url"))
			.done (data) ->
				$.each data, (key, value) ->
					chrome.runtime.sendMessage({message: {action: "add", name: value.name, movie: value.movie_name, id: value._id, url: value.url}})
		e.stopPropagation()
		e.preventDefault()

				# purr()
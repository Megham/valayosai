$ ()->
	localStorage["installed"] = "true"
	$('.valayosai_install').hide()
	$('.valayosai_add_song').show()
	$('.valayosai_add_album').show()
	$('.valayosai_add_marked').show()
	$(".valayosai_add_song").click (e)->
		chrome.runtime.sendMessage {message: $.extend({action: "add"}, $(this).data())}, (response) ->
			
		displayPurr("Queued")
		e.preventDefault()

	$(".valayosai_add_album").click (e) ->
		chrome.runtime.sendMessage {message: $.extend({action: "addAlbum"}, $(this).data())} , (response) ->

		displayPurr("Queued up all songs for playing")
		e.stopPropagation()
		e.preventDefault()

	$(".valayosai_add_marked").click (e) ->
		checked_songs = $(".check_mark:checked")
		$.each checked_songs, (i, v) ->
			chrome.runtime.sendMessage {message: $.extend({action: "add"}, $(v).data())}, (response) ->

		displayPurr("Queued up #{checked_songs.length} song(s) for playing")
		e.stopPropagation()
		e.preventDefault()

	displayPurr = (message) ->
		purrContainer = $("<div id='purr'>#{message}</div>")
		$('body').append(purrContainer)
		purrContainer.fadeIn(200).delay(800).fadeOut(200)


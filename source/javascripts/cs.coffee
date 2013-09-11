$ ()->
	$('.valayosai_install').hide()
	$('.valayosai_add_song').show()
	$('.valayosai_add_album').show()
	$(".valayosai_add_song").click (e)->
		chrome.runtime.sendMessage {message: $.extend({action: "add"}, $(this).data())}, (response) ->
			
		purrContainer = $("<div id='purr'>Queued up for playing</div>")
		$('body').append(purrContainer)
		purrContainer.fadeIn(200).delay(800).fadeOut(200)
		e.preventDefault()

	$(".valayosai_add_album").click (e) ->
		chrome.runtime.sendMessage {message: $.extend({action: "addAlbum"}, $(this).data())} , (resposnse) ->

		e.stopPropagation()
		e.preventDefault()

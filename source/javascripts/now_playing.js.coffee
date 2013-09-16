songScrapper = "http://valayosai.com";
# songScrapper = "http://localhost:3000";
valayosai = angular.module('valayosai', [])
playerLength = 250

$ () ->
	chrome.extension.sendMessage {message: {action: "init"}}
	$("#fb_like_iframe")[0].src = "http://www.facebook.com/plugins/like.php?href=https://www.facebook.com/valayosai1&send=false&layout=button_count&width=90&show_faces=false&font&colorscheme=light&action=like&height=21&appId=247333488655259&"
	window._gaq = window._gaq || []
	window._gaq.push(['_setAccount', 'UA-41329375-1'])
	window._gaq.push(['_trackPageview'])

	(() ->
		ga = document.createElement('script')
		ga.type = 'text/javascript'
		ga.async = true
		ga.src = 'https://ssl.google-analytics.com/ga.js'
		s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
	)()

	$('.thanks a').click (e) ->
			url = $(this).attr("href")
			chrome.tabs.create({url: url})
			e.preventDefault()

delay = (() ->
	timer = 0
	(callback, ms) ->
	  	clearTimeout (timer)
	  	timer = setTimeout(callback, ms)
  )()


valayosai.factory 'Result', () ->
	Result = (data) ->
		angular.extend(this, data);
		angular.extend(this, {
			isSong: (event) ->
				(this.type =='song')
			displayName: () ->
				if this.movie? then "#{this.name} - #{this.movie}" else this.name
		})
	Result

valayosai.factory 'Song', () ->
	Song = (data) ->
		angular.extend(this, data);
		angular.extend(this, {
			displayName: () ->
				"#{this.name} - #{this.movie}"
		})
	Song

valayosai.factory 'sendMessage', () ->
	(message) ->
		chrome.extension.sendMessage {message: message}, (response) ->

valayosai.factory 'LocalStorage', () ->
	LocalStorage = {
		,get: (key) ->
			localStorage[key]

		,set: (key, value) ->
			localStorage[key] = value
	}
	LocalStorage

valayosai.factory 'purr', ($rootScope) ->
	(message) ->
		message = "Added" unless message?
		$rootScope.purr = message
		purrContainer = $(".purr")
		purrContainer.fadeIn(200).delay(800).fadeOut(200)


valayosai.factory 'setVolumeState', (LocalStorage, sendMessage) ->
	(value, scope) ->
		value = LocalStorage.get("lastVolumeVal") unless value?
		value = parseInt(value)
		sendMessage({action: "volume", value: parseFloat(value / 10) })
		volState = if value != 0 then "up" else "off";
		LocalStorage.set("volume", volState)
		LocalStorage.set("lastVolumeVal", value) if volState == "up"
		scope.volume = value
		scope.volumeIcon = "icon-volume-#{volState}"

valayosai.factory 'NowPlaying', ($rootScope, purr, sendMessage, Song) ->
	NowPlaying = {
			add: (songJson, doPurr) ->
				songHash = {name: songJson.name, movie: songJson.movie, id: songJson.id, url: songJson.url}
				unless this.find(songJson.id)
					$rootScope.npSongs.push new Song(songHash)
					purr() if doPurr
					sendMessage({action: "add", name: songJson.name, movie: songJson.movie, id: songJson.id, url: songJson.url, state: "new"})

			,addAlbum: (type, id) ->
				sendMessage({action: "addAlbum", type: type, id: id})

			,destroyAll: () ->
				sendMessage({action: "destroyAll"})
				$rootScope.npSongs = []

			,destroy: (id) ->
				# sendMessage({action: "destroy", id: id})
				$rootScope.npSongs = $.grep $rootScope.npSongs, (obj)->
							obj.id != id

			,playSong: (id) ->
				sendMessage({action: "aplaySong", id: id})

			,playNext: () ->
				sendMessage({action: "playNext"})

			,playPrevious: () ->
				sendMessage({action: "playPrevious"})

			,find: (id) ->
				$.grep($rootScope.npSongs, (obj) -> obj.id == id)[0]

			,initialize: (allSongString) ->
				$rootScope.npSongs = []
				$.each JSON.parse(allSongString), (i, v) ->
					$rootScope.npSongs.push(new Song(v))


	}

valayosai.directive 'search', ($http, $q, Result, purr,$window) ->
	{
		link: (scope, elm, attrs, ctrl) ->
			elm.bind 'keyup', () ->
				scope.results = []
				delay(() ->
					s = []
					if elm.val().length > 1
						scope.loadingClass = "loading"
						scope.showResults = false
						scope.showAlbum = false
						scope.$apply()
						searchVal = elm.val()
						$window._gaq.push(['_trackEvent', 'search', 'searched', searchVal]);
						searchURL = songScrapper + "/search?q="+ encodeURIComponent(searchVal)
						$http.get(searchURL, {})
						.success (data, status, headers, config) ->
							$.each data, (index, result) ->
								s.push new Result {type: result._type, name: result.name, movie: result.movie_name, id: result._id, url: result.url}
							scope.results = s
							scope.showResults = true
							scope.showAlbum = true
							scope.loadingClass = ""
							purr("No results found") if s.length == 0
					else
						scope.results = []
						scope.showResults = true
						scope.showAlbum = true
						scope.loadingClass = ""
						scope.$apply()
				, 250)
	}


SearchResultCtrl = ($scope, $rootScope, $http, Result, NowPlaying, purr) ->
	$rootScope.showSearch = false
	$scope.showResults = true
	$scope.showAlbum = true
	$scope.album = {name: "", songs: []}

	$scope.addSong = (id) ->
		result = $.grep $scope.results, (obj) ->
			obj.id == id
		NowPlaying.add(result[0], true)

	$scope.addAllSongs = (result) ->
		NowPlaying.addAlbum(result.type, result.id)
		# getAllSongsUrl = "#{songScrapper}/#{result.type}s/#{result.id}"
		# $http.get(getAllSongsUrl, {})
		# 	.success (data, status, headers, config) ->
		# 		$.each data, (key, value) ->
		# 			NowPlaying.add({name: value.name, movie: value.movie_name, id: value._id, url: value.url})
		# 		purr()

	$scope.displayAlbum = (result) ->
		getAllSongsUrl = "#{songScrapper}/#{result.type}s/#{result.id}"
		$scope.album = {}
		$scope.loadingClass = "loading"
		$scope.showResults = false
		$http.get(getAllSongsUrl, {})
			.success (data, status, headers, config) ->
				songs = []
				$.each data, (key, value) ->
					songs.push {name: value.name, id: value._id, url: value.url, checked: false}
				$scope.album = {name: result.name, songs: songs}
				$scope.loadingClass = ""


	$scope.addAllAlbumSongs = () ->
		$.each $scope.album.songs, (index, value) ->
			NowPlaying.add($.extend(value, {movie: $scope.album.name}))
		purr()

	$scope.addMarkedAlbumSongs = () ->
		checkedSongs = $.grep $scope.album.songs, (obj) ->
			obj.checked == true
		$.each checkedSongs, (index, value) ->
			NowPlaying.add($.extend(value, {movie: $scope.album.name}))
		purr()

NowPlayingCtrl = ($rootScope, $scope, sendMessage, NowPlaying) ->
	$scope.removeSong = (song) ->
		sendMessage({action: "destroy", id: song.id})

	$scope.createPlaylist = () ->
		$rootScope.createPlaylistPopup = if $rootScope.npSongs.length < 15 then "#need_more" else "#create_playlist"

	$scope.destroyAll = () ->
		NowPlaying.destroyAll()

	$scope.playSong = (id) ->
		NowPlaying.playSong(id)

CreatePlaylistCtrl = ($rootScope, $scope, $http, purr) ->
	$scope.playlistName = ""
	$scope.createPlaylist = () ->
		$http.post(songScrapper+"/playlists", {name: $scope.playlistName, songIds: $rootScope.npSongs.map((obj) -> obj.id) })
						.success (data, status, headers, config) ->
							purr("#{$scope.playlistName} playlist created")
							$scope.playlistName = ""
							$("#create_playlist").modal("hide")

VPlayerCtrl = ($scope, $rootScope, NowPlaying, sendMessage, setVolumeState, purr) ->
	$scope.playPause = "pause"
	$scope.playPauseIcon = "icon-play"

	chrome.extension.onMessage.addListener (request, sender, sendResponse) ->
		command = request.message
		if command.action == "initResponse"
			NowPlaying.initialize(command.allSongs || "[]")
			$scope.playingWidth = {width: "#{command.playPercent * playerLength}px"}
			$scope.bufferingWidth = {width: "#{command.bufferPercent * playerLength}px"}
			$scope.currentTime = command.currentTime
			$scope.duration = command.duration
			$scope.volume = command.volume
			$scope.songName = NowPlaying.find(command.id).displayName() if command.id?
			$scope.playing =  !command.paused
			$scope.setPlayPause(!command.paused)
			$scope.loopValue = command.loopValue
			$scope.loopActiveClass = if command.loopValue? then "active" else ""
			$scope.shuffleActiveClass = command.shuffleValue
			setVolumeState(command.volume, $scope)
			$scope.loadSongClass = "audio_loading" if !command.paused && command.readyState == 0 && (command.songSrc? && command.songSrc!= "")


		if(command.action == "timeupdate")
			$scope.playingWidth = {width: "#{command.percent * playerLength}px"}
			$scope.currentTime = command.value

		if(command.action == "loadedmetadata")
			$scope.duration = command.value
			$scope.setPlayPause(true)
			$scope.loadSongClass = ""

		if(command.action == "bufferpercent")
			$scope.bufferingWidth = {width: "#{command.value * playerLength}px"}

		if(command.action == "preparePlayerForNewSong")
			playingSong = NowPlaying.find(command.id)
			playingSong.state = "playing"
			$scope.songName = playingSong.displayName()
			$scope.loadSongClass = "audio_loading"

		if(command.action == "emptyPlayer")
			$scope.songName = ""
			$scope.currentTime = "0.00"
			$scope.duration = "0.00"
			$scope.playingWidth = {width : "0px"}
			$scope.bufferingWidth = {width: "0px"}
			$scope.setPlayPause(false)
			$scope.loadSongClass = ""

		if command.action == "updatePlayed"
			playedSong = NowPlaying.find(command.playedId)
			playedSong.state = "played" if playedSong?

		if command.action == "setLooping"
			if command.loopValue?
				$scope.loopValue = command.loopValue
				$scope.loopActiveClass = "active"
				purr("#{NowPlaying.find(command.loopValue).name} is in loop")
			else
				purr("Loop mode switched OFF")
				$scope.loopValue = null
				$scope.loopActiveClass = ""

		if command.action == "setShuffle"
			$scope.shuffleActiveClass = command.value
			if command.value == "active"
				purr("Shuffle mode ON")
			else
				purr("Shuffle mode OFF")

		if command.action is "albumAdded"
			NowPlaying.initialize(command.allSongString)
			purr()



		if(command.action == "setPlayingNew")
			$scope.setPlayPause(true)

		if(command.action == "updateAllNew")
			$.each $rootScope.npSongs, (i,v) -> v.state = "new"

		if(command.action == "removeSong")
			NowPlaying.destroy(command.id)

		$scope.$apply()

	$scope.doPlayPause = ()->
		action = if $scope.playPause == "play" then "pause" else "play"
		sendMessage({action: action})
		$scope.setPlayPause(!($scope.playPause == "play"))

	$scope.playNext = () ->
		NowPlaying.playNext()
		purr("This song is in loop") if $scope.loopActiveClass == "active"

	$scope.playPrevious = () ->
		NowPlaying.playPrevious()
		purr("This song is in loop") if $scope.loopActiveClass == "active"

	$scope.setPlayPause = (isPlaying) ->
		action = if isPlaying then "play" else "pause"
		revertAction = if isPlaying then "pause" else "play"
		$scope.playPause = action
		$scope.playPauseIcon = "icon-#{revertAction}"

	$scope.seekDuration = (e) ->
		posX = $(e.currentTarget).offset().left
		seekPos = (e.pageX - posX)
		sendMessage({action: "setSeek", value: seekPos/playerLength} )

	$scope.setVolume = (e) ->
		setVolumeState($scope.volume, $scope)
	
	$scope.toggelMuteVolume = () ->
		volumeVal = if ($scope.volume != 0) then 0 else null;
		setVolumeState(volumeVal, $scope)

	$scope.toggleLoopOne = () ->
		sendMessage({action:"loopPlaying"})

	$scope.toggleShuffle = () ->
		sendMessage({action:"shufflePlaylist"})

window.SearchResultCtrl = SearchResultCtrl
window.NowPlayingCtrl = NowPlayingCtrl
window.CreatePlaylistCtrl = CreatePlaylistCtrl
window.VPlayerCtrl = VPlayerCtrl
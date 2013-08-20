songScrapper = "http://song-scrapper.herokuapp.com";
valayosai = angular.module('valayosai', [])
playerLength = 250

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
	# playImmediately = typeof playImmediately !== 'undefined' ? playImmediately : true;
	# var dataID = songJson.id != undefined ? "data-id='" + songJson.id+"'" : '';
	# nowPlaying.append("<li><span><a class='playsong' data-song='"+songJson.song+"' "+ dataID+ " data-movie='"+songJson.movie+"' href >"+ songJson.song +"-" + songJson.movie +"</a></span><a class='remove_song' href='' "+dataID+"><i class='icon-remove-sign'></i></a></li>");
	# if(playImmediately)
	# {
	# 	_gaq.push(['_trackEvent', 'AddSong', 'Added', songJson.song + " - " + songJson.movie]);
	# }
	NowPlaying = {
			add: (songJson, doPurr) ->
				songHash = {name: songJson.name, movie: songJson.movie, id: songJson.id, url: songJson.url}
				unless this.find(songJson.id)
					$rootScope.npSongs.push new Song(songHash)
					purr() if doPurr
					sendMessage({action: "add", name: songJson.name, movie: songJson.movie, id: songJson.id, url: songJson.url, state: "new"})

			,destroyAll: () ->
				sendMessage({action: "destroyAll"})
				$rootScope.npSongs = []

			,destroy: (record) ->
				sendMessage({action: "destroy", id: record.id})
				$rootScope.npSongs = $.grep $rootScope.npSongs, (obj)->
							obj != record

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

valayosai.directive 'search', ($http, $q, Result) ->
	{
		link: (scope, elm, attrs, ctrl) ->
			elm.bind 'keyup', () ->
				scope.results = []
				delay(() ->
					s = []
					if elm.val().length > 1
						searchVal = elm.val()
						searchURL = songScrapper + "/search?q="+ encodeURIComponent(searchVal)
						$http.get(searchURL, {})
						.success (data, status, headers, config) ->
							$.each data, (index, result) ->
								s.push new Result {type: result._type, name: result.name, movie: result.movie_name, id: result._id, url: result.url}

					scope.$apply () ->
						scope.results = s
						scope.showResults = true

				, 250)
	}


SearchResultCtrl = ($scope, $rootScope, $http, Result, NowPlaying, purr) ->
	$rootScope.showSearch = false
	$scope.showResults = true
	$scope.album = {name: "", songs: []}

	$scope.addSong = (id) ->
		result = $.grep $scope.results, (obj) ->
			obj.id == id
		NowPlaying.add(result[0], true)

	$scope.addAllSongs = (result) ->
		getAllSongsUrl = "#{songScrapper}/#{result.type}s/#{result.id}"
		$http.get(getAllSongsUrl, {})
			.success (data, status, headers, config) ->
				$.each data, (key, value) ->
					NowPlaying.add({name: value.name, movie: value.movie_name, id: value._id, url: value.url})
				purr()

	$scope.showAlbum = (result) ->
		getAllSongsUrl = "#{songScrapper}/#{result.type}s/#{result.id}"
		$scope.showResults = false
		$http.get(getAllSongsUrl, {})
			.success (data, status, headers, config) ->
				songs = []
				$.each data, (key, value) ->
					songs.push {name: value.name, id: value._id, url: value.url, checked: false}
				$scope.album = {name: result.name, songs: songs}

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
		NowPlaying.destroy(song)

	$scope.createPlaylist = () ->
		$rootScope.createPlaylistPopup = if $rootScope.npSongs.length < 15 then "#need_more" else "#create_playlist"

	$scope.destroyAll = () ->
		NowPlaying.destroyAll()

	$scope.playSong = (id) ->
		NowPlaying.playSong(id)

CreatePlaylistCtrl = ($rootScope, $scope, $http) ->
	$scope.playlistName = ""
	$scope.createPlaylist = () ->
		$http.post(songScrapper+"/playlists", {name: $scope.playlistName, songIds: $rootScope.npSongs.map((obj) -> obj.id) })
						.success (data, status, headers, config) ->
							$("#create_playlist").modal("hide")


VPlayerCtrl = ($scope, $rootScope, NowPlaying, sendMessage, setVolumeState, purr) ->
	chrome.extension.sendMessage {message: {action: "init"}}, (response) ->		
		NowPlaying.initialize(response.allSongs)
		$scope.playingWidth = {width: "#{response.playPercent * playerLength}px"}
		$scope.bufferingWidth = {width: "#{response.bufferPercent * playerLength}px"}
		$scope.currentTime = response.currentTime
		$scope.duration = response.duration
		$scope.volume = response.volume
		$scope.songName = NowPlaying.find(response.id).displayName() if response.id?
		$scope.playing =  !response.paused
		$scope.setPlayPause(!response.paused)
		$scope.loopValue = response.loopValue
		$scope.loopActiveClass = if response.loopValue? then "active" else ""
		$scope.shuffleActiveClass = response.shuffleValue
		setVolumeState(response.volume, $scope)
		$scope.$apply()


	chrome.extension.onMessage.addListener (request, sender, sendResponse) ->
		command = request.message
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

		if(command.action == "setPlayingNew")
			$scope.setPlayPause(true)

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
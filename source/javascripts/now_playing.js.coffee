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

valayosai.factory 'LocalStorage', () ->
	LocalStorage = {
		add: (songJson) ->
			existingPlaylist = this.all()
			existingPlaylist.push songJson
			localStorage["playlist"] = JSON.stringify existingPlaylist

		,all: () ->
			playlist = localStorage["playlist"]
			playlist = if (playlist? and playlist !=  "") then JSON.parse(playlist) else []

		,destroy: (id) ->
			existingPlaylist = this.all()
			existingPlaylist = $.grep existingPlaylist, (obj) ->
								obj.id != id
			localStorage["playlist"] = JSON.stringify existingPlaylist

		,destroyAll: () ->
			localStorage["playlist"] = "[]"
	}
	LocalStorage

valayosai.factory 'purr', ($rootScope) ->
	(message) ->
		message = "Added" unless message?
		$rootScope.purr = message
		purrContainer = $(".purr")
		purrContainer.fadeIn(200).delay(800).fadeOut(200)


valayosai.factory 'addToNowPlaying', ($rootScope, purr, LocalStorage) ->
	# playImmediately = typeof playImmediately !== 'undefined' ? playImmediately : true;
	# var dataID = songJson.id != undefined ? "data-id='" + songJson.id+"'" : '';
	# nowPlaying.append("<li><span><a class='playsong' data-song='"+songJson.song+"' "+ dataID+ " data-movie='"+songJson.movie+"' href >"+ songJson.song +"-" + songJson.movie +"</a></span><a class='remove_song' href='' "+dataID+"><i class='icon-remove-sign'></i></a></li>");
	# if(playImmediately)
	# {
	# 	_gaq.push(['_trackEvent', 'AddSong', 'Added', songJson.song + " - " + songJson.movie]);
	# }
	(songJson, doPurr) ->
		$rootScope.npSongs.push {name: songJson.name, movie: songJson.movie, id: songJson.id}
		LocalStorage.add {name: songJson.name, movie: songJson.movie, id: songJson.id, url: songJson.url }
		purr() if doPurr
		# sendMessage({action: "playSongIfNotPlaying", id: songJson.id})

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

				, 250)
	}


SearchResultCtrl = ($scope, $rootScope, $http, Result, addToNowPlaying, purr) ->
	$rootScope.showSearch = false
	$scope.showResults = true
	$scope.album = {name: "", songs: []}

	$scope.addSong = (id) ->
		result = $.grep $scope.results, (obj) ->
			obj.id == id
		addToNowPlaying(result[0], true)

	$scope.addAllSongs = (result) ->
		getAllSongsUrl = "#{songScrapper}/#{result.type}s/#{result.id}"
		$http.get(getAllSongsUrl, {})
			.success (data, status, headers, config) ->
				$.each data, (key, value) ->
					addToNowPlaying({name: value.name, movie: value.movie_name, id: value._id, url: value.url})
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
			addToNowPlaying($.extend(value, {movie: $scope.album.name}))
		purr()

	$scope.addMarkedAlbumSongs = () ->
		checkedSongs = $.grep $scope.album.songs, (obj) ->
			obj.checked == true
		$.each checkedSongs, (index, value) ->
			addToNowPlaying($.extend(value, {movie: $scope.album.name}))
		purr()

NowPlayingCtrl = ($rootScope, $scope, LocalStorage) ->	
	$scope.removeSong = (song) ->
		$rootScope.npSongs = $.grep $rootScope.npSongs, (obj)->
							obj != song
		LocalStorage.destroy(song.id)

	$scope.createPlaylist = () ->
		$rootScope.createPlaylistPopup = if $rootScope.npSongs.length < 15 then "#need_more" else "#create_playlist"

	$scope.destroyAll = () ->
		$rootScope.npSongs = []
		LocalStorage.destroyAll()


CreatePlaylistCtrl = ($rootScope, $scope, $http) ->
	$scope.playlistName = ""
	$scope.createPlaylist = () ->
		$http.post(songScrapper+"/playlists", {name: $scope.playlistName, songIds: $rootScope.npSongs.map((obj) -> obj.id) })
						.success (data, status, headers, config) ->
							console.log("success")
							$("#create_playlist").modal("hide")


VPlayerCtrl = ($scope, $rootScope, LocalStorage) ->
	chrome.extension.sendMessage {message: {action: "init"}}, (response) ->
		console.log(response)
		$scope.$apply () ->
			$scope.playingWidth = {width: "#{response.playPercent * playerLength}px"}
			$scope.bufferingWidth = {width: "#{response.bufferPercent * playerLength}px"}

			$scope.currentTime = response.currentTime
			$scope.duration = response.duration
			$scope.volume = response.volume
			$scope.songName = response.songName
			$scope.playing =  !response.paused
			$scope.playPause = if response.paused then "icon-play icon-large" else "icon-pause icon-large"
	$rootScope.npSongs = LocalStorage.all()

	$scope.play = ()->








	# 	playing.width(response.playPercent * playerLength);
	# 	currentTime.html(response.currentTime);
	# 	duration.html(response.duration);
	# 	buffering.width(response.bufferPercent* playerLength);
	# 	setVolumeState(response.volume);
	# 	songName.html(response.songName);
	# 	$(".playsong[data-id='"+ response.currentSongIndex+"'] ").addClass("current");
	# 	if(!response.paused)
	# 		setPlayPause("pause");
	# 	else
	# 		setPlayPause("play");

	# $.each(getSongs(), function(index, entry){
	# 	addToNowPlaying({movie: entry.movie, song: entry.song, id: entry.id }, false);
	# });

	
window.SearchResultCtrl = SearchResultCtrl
window.NowPlayingCtrl = NowPlayingCtrl
window.CreatePlaylistCtrl = CreatePlaylistCtrl
window.VPlayerCtrl = VPlayerCtrl



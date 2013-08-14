songScrapper = "http://song-scrapper.herokuapp.com";
valayosai = angular.module('valayosai', [])

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
valayosai.factory 'purr', ($rootScope) ->
	(message) ->
		message = "Added" unless message?
		$rootScope.purr = message
		purrContainer = $(".purr")
		purrContainer.fadeIn(200).delay(800).fadeOut(200)


valayosai.factory 'addToNowPlaying', ($rootScope, purr) ->
	# playImmediately = typeof playImmediately !== 'undefined' ? playImmediately : true;
	# var dataID = songJson.id != undefined ? "data-id='" + songJson.id+"'" : '';
	# nowPlaying.append("<li><span><a class='playsong' data-song='"+songJson.song+"' "+ dataID+ " data-movie='"+songJson.movie+"' href >"+ songJson.song +"-" + songJson.movie +"</a></span><a class='remove_song' href='' "+dataID+"><i class='icon-remove-sign'></i></a></li>");
	# if(playImmediately)
	# {
	# 	_gaq.push(['_trackEvent', 'AddSong', 'Added', songJson.song + " - " + songJson.movie]);
	# }
	(songJson, doPurr) ->
		$rootScope.npSongs.push {name: songJson.name, movie: songJson.movie, id: songJson.id}
		if doPurr
			purr()
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

NowPlayingCtrl = ($rootScope, $scope) ->
	$rootScope.npSongs = []
	
	$scope.removeSong = (song) ->
		$rootScope.npSongs = $.grep $rootScope.npSongs, (obj)->
							obj != song

	$scope.createPlaylist = () ->
		$rootScope.createPlaylistPopup = if $rootScope.npSongs.length < 15 then "#need_more" else "#create_playlist"

CreatePlaylistCtrl = ($rootScope, $scope, $http) ->
	$scope.playlistName = ""
	$scope.createPlaylist = () ->
		$http.post(songScrapper+"/playlists", {name: $scope.playlistName, songIds: $rootScope.npSongs.map((obj) -> obj.id) })
						.success (data, status, headers, config) ->
							console.log("success")
							$("#create_playlist").modal("hide")



	

window.SearchResultCtrl = SearchResultCtrl
window.NowPlayingCtrl = NowPlayingCtrl
window.CreatePlaylistCtrl = CreatePlaylistCtrl





					# scope.$apply(function() {
					# 	ctrl.$setViewValue(elm.html());
					# 	});
					# });

# // model -> view
# ctrl.$render = function(value) {
# 	elm.html(value);
# 	};

# 	// load init value from DOM
# 	ctrl.$setViewValue(elm.html());
# }
# };


# function TodoCtrl($scope) {
#   $scope.todos = [
#     {text:'learn angular', done:true},
#     {text:'build an angular app', done:false}];

#   $scope.addTodo = function() {
#     $scope.todos.push({text:$scope.todoText, done:false});
#     $scope.todoText = '';
#   };

#   $scope.remaining = function() {
#     var count = 0;
#     angular.forEach($scope.todos, function(todo) {
#       count += todo.done ? 0 : 1;
#     });
#     return count;
#   };

#   $scope.archive = function() {
#     var oldTodos = $scope.todos;
#     $scope.todos = [];
#     angular.forEach(oldTodos, function(todo) {
#       if (!todo.done) $scope.todos.push(todo);
#     });
#   };
# }
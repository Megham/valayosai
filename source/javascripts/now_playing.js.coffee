songScrapper = "http://song-scrapper.herokuapp.com";
resultList = $("#results ul")
album = $("#album")

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

valayosai.factory 'addToNowPlaying', () ->
	# playImmediately = typeof playImmediately !== 'undefined' ? playImmediately : true;
	# var dataID = songJson.id != undefined ? "data-id='" + songJson.id+"'" : '';
	# nowPlaying.append("<li><span><a class='playsong' data-song='"+songJson.song+"' "+ dataID+ " data-movie='"+songJson.movie+"' href >"+ songJson.song +"-" + songJson.movie +"</a></span><a class='remove_song' href='' "+dataID+"><i class='icon-remove-sign'></i></a></li>");
	# if(playImmediately)
	# {
	# 	_gaq.push(['_trackEvent', 'AddSong', 'Added', songJson.song + " - " + songJson.movie]);
	# }
	(songJson, scope) ->
		scope.npSongs.push {name: songJson.name, movie: songJson.movie, id: songJson.id}
		# sendMessage({action: "playSongIfNotPlaying", id: songJson.id})

valayosai.directive 'search', ($http, $q, Result) ->
	{
		link: (scope, elm, attrs, ctrl) ->
			elm.bind 'keyup', () ->
				delay(() ->
					searchVal = elm.val()
					searchURL = songScrapper + "/search?q="+ encodeURIComponent(searchVal)
					$http.get(searchURL, {})
					.success (data, status, headers, config) ->
						s = []
						$.each data, (index, result) ->
							s.push new Result {type: result._type, name: result.name, movie: result.movie_name, id: result._id, url: result.url}
						scope.results = s
				, 250)
	}


SearchResultCtrl = ($scope, $rootScope, $http, Result, addToNowPlaying) ->
	$scope.showResults = true
	$scope.album = {name: "", songs: []}


	$scope.addSong = (id) ->
		result = $.grep $scope.results, (obj) ->
			obj.id == id
		addToNowPlaying(result[0], $rootScope)

	$scope.addAllSongs = (result) ->
		getAllSongsUrl = "#{songScrapper}/#{result.type}s/#{result.id}"
		$http.get(getAllSongsUrl, {})
			.success (data, status, headers, config) ->
				$.each data, (key, value) ->
					addToNowPlaying({name: value.name, movie: value.movie_name, id: value._id, url: value.url}, $rootScope)

	$scope.showAlbum = (result) ->
		getAllSongsUrl = "#{songScrapper}/#{result.type}s/#{result.id}"
		$scope.showResults = false
		$http.get(getAllSongsUrl, {})
			.success (data, status, headers, config) ->
				songs = []
				$.each data, (key, value) ->
					songs.push {name: value.name, id: value._id, url: value.url}
				$scope.album = {name: result.name, songs: songs}

	$scope.displayResults = () ->
		$scope.showResults = true

NowPlayingCtrl = ($rootScope, $scope) ->
	$rootScope.npSongs = []
	$scope.addTo = (song) ->
		$rootScope.npSongs.push song

window.SearchResultCtrl = SearchResultCtrl
window.NowPlayingCtrl = NowPlayingCtrl





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
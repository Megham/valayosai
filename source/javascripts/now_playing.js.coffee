songScrapper = "http://song-scrapper.herokuapp.com";
canceler = null

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

valayosai.directive 'search', ($http, $q, Result) ->
	{
		link: (scope, elm, attrs, ctrl) ->
			elm.bind 'keyup', () ->
				delay(() ->
					if canceler?
						canceler.resolve()
					searchVal = elm.val()
					canceler = $q.defer()
					searchURL = songScrapper + "/search?q="+ encodeURIComponent(searchVal)
					$http.get(searchURL, {timeout: canceler.promise})
					.success (data, status, headers, config) ->
						s = []
						$.each data, (index, result) ->
							s.push new Result {type: result._type, name: result.name, movie: result.movie_name, id: result._id, url: result.url}
						scope.results = s
				, 250)
	}


SearchResultCtrl = ($scope, Result) ->
	$scope.albumSongs = []


	# $scope.addToNowPlaying = (song) ->


NowPlayingCtrl = ($scope) ->
	$scope.npSongs = []
	$scope.addTo = (song) ->
		$scope.npSongs.push song

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
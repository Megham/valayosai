//GA Code
var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-41329375-1']);
_gaq.push(['_trackPageview']);

(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = 'https://ssl.google-analytics.com/ga.js';
  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();
//GA Code ends

$(function(){

var playpause = $('#playpause');
var volume = $('#volume');
var currentTime = $("#currenttime");
var duration = $("#duration");
var buffering = $("#buffering");
var playerTime = $(".player_time");
var playing = $("#playing");
var playerLength = 250;	
var search = $("#search");	
var results = $("#results ul");
var resultsContainer = $("#results");
var nowPlaying = $("#nowplaying ul");	
var links = $(".links");
var previous = $("#previous");
var next = $("#next");
var songName = $("#song_name");
var album = $("#album");
var albumList = $("#album ul");
var albumName = $("#album_name");
var albumnAuthor = $("#albumn_author");
var progress = $("#progress");
var album_back = $("#album_back");
var np_add_all = $("#np_add_all");
var np_add_songs = $("#np_add_songs");
var clear_all = $("#np_clear_all");
var np_link = $("#np_link");
var purr = $(".purr");
var thanksLinks = $('.thanks a');
var volumeIcon = $('.volume_icon');
var createPlaylist = $("#np_create_playlist");
var createPlaylistForm = $("#create_playlist_form");
var createPlaylistModal = $("#create_playlist");
var moreCount = $(".more_count");
var playlistName = $("#playlist_name");
// var songScrapper = "http://localhost:3000";
var songScrapper = "http://song-scrapper.herokuapp.com";

init();
bindPlay();
showNowPlaying();

$(window).load(function(){
	setTimeout(function () {
		$("a:first").focus();
	}, 50);
});

var delay = (function(){
  var timer = 0;
  return function(callback, ms){
    clearTimeout (timer);
    timer = setTimeout(callback, ms);
  };
})();

playpause.click(function(e){
	// var target = $(e.currentTarget);
	// var todo = target.data("action") ;
	// var nextAction = target.data("action") == "play" ? "pause" : "play";
	// setPlayPause(nextAction);
	// sendMessage({action: todo});
	// e.preventDefault();
});

// search.keyup(function(){
// 	delay(function(){
// 		var searchVal = search.val();
// 		results.html("");
// 		resultsContainer.removeClass("loading");
// 		showSearchResult();
// 		if(searchVal.length > 1)
// 		{
// 			resultsContainer.addClass("loading");
// 			_gaq.push(['_trackEvent', 'search', 'searched', searchVal]);
// 			var searchURL = songScrapper + "/search?q="+ encodeURIComponent(searchVal);
// 			$.getJSON(searchURL, null, function(data){
// 				results.html("");
// 				resultsContainer.removeClass("loading");
// 				if(data.length == 0)
// 					results.append("<li><span class='no_results'>No results found</span></li>")

// 				$.each(data, function(index, result){
// 					var addView = "";
// 					if(result._type == "song")
// 					{
// 						addView = "<a href class='addsong' data-movie='"+result.movie_name+"' data-song='"+result.name+"' data-url='"+ result.url  +"' title='Add Song' data-vid='"+ result._id+"'><i class='icon-plus-sign'></i></a>";
// 						results.append("<li><span>"+ result.name + " - " + result.movie_name + '</span>'+  addView + "</li>");
// 					}
// 					else
// 					{
// 						addView = "<a href class='addall' data-by='"+result._id+"' data-name='"+result.name+"' data-type='"+ result._type + "' title='Add all songs in album'><i class='icon-plus-sign'></i></a>"
// 						 			+ "<a href class='viewentries' data-by='"+result._id+"' data-name='"+result.name+"' data-type='"+ result._type + "' title='View album'><i class='icon-list'></i></a>";
// 						results.append("<li><span>"+ result.name +" - "+ result._type +" </span>" + addView + "</li>");
// 					}
// 				});

				
// 			});
// 		}
// 	}, 250);
// });

progress.click(function(e){
	// var posX = $(this).offset().left, posY = $(this).offset().top;
	// var seekPos = (e.pageX - posX);
 //    console.log((e.pageX - posX)+ ' , ' + (e.pageY - posY));
 //    sendMessage({action: "setSeek", value: seekPos/progress.width()} )
 //    e.preventDefault();
 //    e.stopPropagation();

});
links.click(function(e){
	// var target = $(e.currentTarget);
	// var loc = target.attr('href');
	// $(".panel").show();
	// $(loc).hide();
	// $(".nav-pills .active").removeClass("active");
	// target.parent().addClass("active");
	// e.preventDefault();
});

album_back.click(function(e){
	// showSearchResult();
	// e.preventDefault();
});

previous.click(function(e){
	// sendMessage({action: "previous"})
	// e.preventDefault();
});

next.click(function(e){
	// sendMessage({action: "next"})
	// e.preventDefault();
});

np_add_all.click(function(e){
	// var songList = $("#album ul input[type='checkbox']");
	// addSongsFromAlbum(songList);
	// var target = $(e.currentTarget);
	// displayPurr();
	// e.preventDefault();	
});

np_add_songs.click(function(e){
	// var songList = $("#album ul input[type='checkbox']:checked");
	// addSongsFromAlbum(songList);
	// var target = $(e.currentTarget);
	// displayPurr();
	// e.preventDefault();	
});

thanksLinks.click(function(e){
	url = $(this).attr("href")
	chrome.tabs.create({url: url});
	e.preventDefault();
});

volume.change(function(){
	// setVolumeState(this.value)
});

volumeIcon.click(function(e){
	// var volumeState = localStorage["volume"]
	// var volumeVal = (volumeState == "ON" || volumeState == undefined) ? 0 : localStorage["lastVolumeVal"];
	// setVolumeState(volumeVal)
});


function setVolumeState(volumeVal)
{
	volumeVal = parseInt(volumeVal);
	sendMessage({action: "volume", value: parseFloat(volumeVal / 10) })
	volume.val(volumeVal);
	volState = volumeVal != 0 ? "ON" : "OFF";
	localStorage["volume"] = volState;
	if(volState == "ON")
	{
		$("i", volumeIcon).attr("class", "icon-volume-up");
		localStorage["lastVolumeVal"] = volumeVal;
	}
	else{
		$("i", volumeIcon).attr("class", "icon-volume-off");
	}
}

createPlaylist.click(function(e){
	// e.preventDefault();
	// var songs = getSongs();
	// if(songs.length < 15)
	// {
	// 	moreCount.html(15-songs.length);
	// 	createPlaylist.attr("href", "#need_more");
	// }
	// else
	// {
	// 	createPlaylist.attr("href", "#create_playlist");
	// }
});
createPlaylistForm.submit(function(e){
	// e.preventDefault();
	// var name = playlistName.val().trim();
	// var songs = getSongs();

 //    if(name == "") { playlistName.val(""); return;}
	// var songIds = [];
	// $.each(songs, function (index, entry) {
	// 	songIds.push(entry.vId);
	// });
	// $.post(songScrapper +"/playlists", 
	// 	{
	// 		name: name,
	// 		songIds: songIds
	// 	}, function(data){
	// 		console.log("playlist created")
	// 		displayPurr(name + " created");
	// });
	// playlistName.val("");
	// createPlaylistModal.modal("hide");
})


function addSongsFromAlbum(songs)
{
	// $.each(songs, function(key, value){
	// 		value = $(value);
	// 		movie = value.data('movie');
	// 		song = value.data('song');
	// 		code = value.data('url');
	// 		vId = value.data('vid');
	// 		var newID = addToLocalstorage({movie: movie, song: song, constructedUrl: code, vId: vId});
	// 		addToNowPlaying({movie: movie, song: song, id: newID});
	// 	});
}

function showSearchResult()
{
	// results.show();
	// album.hide();
	// albumList.html("")
}

function showNowPlaying(){
	// $("#search_panel").hide();
}

function bindPlay(){
	// results.on('click',".addsong", function(e){
	// 	var target = $(e.currentTarget);
	// 	var movie = target.data("movie");
	// 	var song = target.data("song");
	// 	var url = target.data("url");
	// 	var vId = target.data("vid");
	// 	var newID = addToLocalstorage({movie: movie, song: song, constructedUrl: url, vId: vId});
	// 	addToNowPlaying({movie: movie, song: song, id: newID});
	// 	displayPurr();
	// 	e.preventDefault();
	// });

	results.on('click',".viewentries", function(e){
		// var target = $(e.currentTarget);
		// var movieID = target.data("by");
		// var name = target.data("name");
		// var type = target.data("type");
		// fetchAndAddAllToAlbumSongs(movieID,name, type);
		// results.hide();
		// album.show();
		// e.preventDefault();
	});

	results.on('click', '.addall', function(e){
		// var target = $(e.currentTarget);
		// var movieID = target.data("by");
		// var type = target.data("type");
		// fetchAndAddAllToNowPlayingSongs(movieID, type);
		// displayPurr();
		// e.preventDefault();
	})

	nowPlaying.on("click", ".playsong", function(e){
		// var index = $(e.currentTarget).data("id");
		// sendMessage({action:"playSong", value: index});
		// e.preventDefault();
	});

	nowPlaying.on("click", ".remove_song", function(e){
		// var indexToRemove = $(e.currentTarget).data("id");
		// $("a[data-id='"+indexToRemove+"']", nowPlaying).parent("li").remove();
		// chrome.extension.sendMessage({message: {action: "removeIfPlaying", id: indexToRemove}}, function(res){
		// 	removeFromLocalStorage(indexToRemove);
		// });

		// e.stopPropagation();
		// e.preventDefault();
	});

	clear_all.click(function(e){
		// localStorage["playlist"] = "";
		// sendMessage({action:"next"});
		// setPlayPause("play");
		// nowPlaying.html("");
		// e.preventDefault();
	});

}

function getSongs(){
	var playlist = localStorage["playlist"];
	return (playlist == undefined || playlist == "" || playlist == null) ? [] : JSON.parse(playlist);
}

function fetchAndAddAllToAlbumSongs(movieID, movieName, type){
	// albumName.html(movieName);
	// $.get(songScrapper + "/"+ type +"s/"+movieID, function(data){
	// 	$.each(data, function(key, value){
	// 	 	var addView = "<input type='checkbox' data-movie='"+value.movie_name+"' data-song='"+value.name+"' data-url='"+ value.url  +"' data-vid='"+ value._id+"'/>";
	// 		albumList.append("<li><label>"+ addView + value.name + "<label></li>");
	// 	});
	// });
}

function fetchAndAddAllToNowPlayingSongs(movieID, type){
	// $.get(songScrapper + "/"+type+"s/"+movieID, function(data){
	// 	$.each(data, function(key, value){
	// 		movie = value.movie_name;
	// 		song = value.name;
	// 		vId = value._id
	// 		var newID = addToLocalstorage({movie: movie, song: song, constructedUrl: value.url, vId: vId});
	// 		addToNowPlaying({movie: movie, song: song, id: newID});
	// 	});
	// });
}

function addToLocalstorage(songJson)
{
	// var existingPlaylist = getSongs();
	// var playlistLength = existingPlaylist.length;
	// var newID =  playlistLength == 0 ? 0 : existingPlaylist[playlistLength-1].id + 1;
	// $.extend(songJson, {id: newID})
	// existingPlaylist.push(songJson);
	// localStorage["playlist"] =  JSON.stringify(existingPlaylist);
	// return newID;
}

function removeFromLocalStorage(index){
	// var existingPlaylist = getSongs();
	// var newSongList = [];
	// $.each(existingPlaylist, function(ind, value){
	// 	if(value.id != index)
	// 		newSongList.push(value)
	// });
	// localStorage["playlist"] = JSON.stringify(newSongList);

}
function addToNowPlaying(songJson, playImmediately)
{
	playImmediately = typeof playImmediately !== 'undefined' ? playImmediately : true;
	var dataID = songJson.id != undefined ? "data-id='" + songJson.id+"'" : '';
	nowPlaying.append("<li><span><a class='playsong' data-song='"+songJson.song+"' "+ dataID+ " data-movie='"+songJson.movie+"' href >"+ songJson.song +"-" + songJson.movie +"</a></span><a class='remove_song' href='' "+dataID+"><i class='icon-remove-sign'></i></a></li>");
	if(playImmediately)
	{
		sendMessage({action: "playSongIfNotPlaying", id: songJson.id});
		_gaq.push(['_trackEvent', 'AddSong', 'Added', songJson.song + " - " + songJson.movie]);
	}
}

function setPlayPause(action){
	// removeAction = action == "play" ? "pause" : "play";
	// icon = $("i", playpause)
	// icon.removeClass("icon-" + removeAction);
	// icon.addClass("icon-" + action);
	// playpause.data("action", action);
}

function displayPurr(notification)
{
	// notification = typeof notification !== 'undefined' ? notification : "Added";
	// purr.html(notification);
	// purr.fadeIn(200).delay(800).fadeOut(200);
}

// chrome.extension.onMessage.addListener(
// 	function(request, sender, sendResponse) {
// 		var command = request.message;
// 		if(command.action == "timeupdate")
// 		{
// 			playing.width(command.percent * playerLength);
// 			currentTime.html(command.value);
// 		}
// 		if(command.action == "loadedmetadata")
// 		{
// 			duration.html(command.value);
// 			setPlayPause("pause");
// 			playerTime.removeClass("audio_loading");
// 		}

// 		if(command.action == "bufferpercent")
// 		{
// 			buffering.width(command.value * playerLength);
// 		}
// 		if(command.action == "ended")
// 		{
// 			setPlayPause("play");
// 			currentTime.html("0.0");
// 			playing.width(0);	
// 		}

// 		if(command.action == "displaySongName")
// 		{
// 			songName.html(command.value);
// 			currentTime.html("0.00");
// 			duration.html("0.00");
// 			playing.width("0px");
// 			buffering.width("0px");
// 			var action = command.value == null ? "play" : "pause"
// 			setPlayPause(action);
// 			$(".playsong").removeClass("current");
// 			$(".playsong[data-id='"+ command.songIndex+"'] ").addClass("current");
// 		}
// 		if(command.action == "setPlayingNew")
// 		{
// 			setPlayPause("play");
// 			playerTime.addClass("audio_loading");
// 		}
// 	});


function sendMessage(message)
{
	chrome.extension.sendMessage({message: message}, function(response) {
	});
}

function init()
{
	// chrome.extension.sendMessage({message: {action: "init"}}, function(response) {
		// console.log(response);

		// playing.width(response.playPercent * playerLength);
		// currentTime.html(response.currentTime);
		// duration.html(response.duration);
		// buffering.width(response.bufferPercent* playerLength);
		// setVolumeState(response.volume);
		// songName.html(response.songName);
		// $(".playsong[data-id='"+ response.currentSongIndex+"'] ").addClass("current");
		// if(!response.paused)
		// 	setPlayPause("pause");
		// else
		// 	setPlayPause("play");
	// });

	// $.each(getSongs(), function(index, entry){
	// 	addToNowPlaying({movie: entry.movie, song: entry.song, id: entry.id }, false);
	// });
}
});
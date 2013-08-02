$("body").append("<audio id='main_player' controls><source id='player_src' type='audio/mpeg; codecs=\"mp3\"'></source></audio>");	

var audio = $('#main_player')[0];
var audioSrc = $('#player_src')[0];
var currentSongIndex = null;

chrome.extension.onMessage.addListener(
	function(request, sender, sendResponse) {
		var command = request.message;
		var audio = $('#main_player')[0];
		if(command.action == "pause")
		{
			audio.pause();
		}
		if(command.action == "play")
		{
			audio.play();
		}
		if(command.action == "volume")
			audio.volume = command.value
		if(command.action == "playSongIfNotPlaying")
		{
			if(audioSrc.src == "")
			{
				playSong(command.id);
			}
		}

		if(command.action == "setSeek")
		{
			audio.currentTime = audio.duration * command.value;
		}

		if (command.action == "init")
		{
			var isPlaying = audio.played.length != 0 ;
			var response = {playing: isPlaying};
			var playPercent = audio.currentTime/ audio.duration;
			$.extend(response, {song: audio.src, duration:  getFormattedTime(audio.duration), currentTime: getFormattedTime(audio.currentTime) ,
			 				playPercent: playPercent, bufferPercent: getBufferPercent(),
			  				paused: audio.paused, songName: $(audio).data("song"), volume: parseInt(audio.volume*10), currentSongIndex: currentSongIndex});
			sendResponse(response);
		}

		if (command.action == "previous") {playPrevious()};
		if (command.action == "next") {playNext()};
		if(command.action == "playSong"){playSong(command.value)};
		if(command.action == "removeIfPlaying"){
		 	if(command.id == currentSongIndex) playNext(); 
		 	sendResponse({removed: true});
		};

	});


audio.addEventListener("timeupdate", function() {
    var currentPercent = audio.currentTime /audio.duration;
	sendMessage({action: "timeupdate", value: getFormattedTime(audio.currentTime), percent: currentPercent });
	sendAudioBuffering();
}, false);

audio.addEventListener('loadedmetadata', function(){
   sendMessage({action: "loadedmetadata", value: getFormattedTime(audio.duration) })
}, false);
audio.addEventListener('loadstart', function(){
	sendAudioBuffering();
}, false);
audio.addEventListener('progress', function(){
	sendAudioBuffering();
}, false);

audio.addEventListener('ended', function(){
	sendMessage({action: 'ended'});
	playNext();
}, false);


function getFormattedTime(time)
{
	time = isNaN(time) ? 0 : parseInt(time)
	var seconds = (time % 60) + "";
	var s = seconds.length ==  1 ? "0" + seconds : seconds;
    var m = parseInt((time / 60) % 60);
    return m + '.' + s ;
}

function sendAudioBuffering()
{
    sendMessage({action: "bufferpercent", value: getBufferPercent() });
}
function playNext()
{
	var currentSongArrayIndex = getCurrentSongArrayIndex()
	if(currentSongArrayIndex >= totalSongs() - 1)
	{
		setAudio(null, null, null);
		return;
	}
	playSong(getSongId(currentSongArrayIndex + 1));
}
function playPrevious()
{
	var currentSongArrayIndex = getCurrentSongArrayIndex()
	if(currentSongArrayIndex == 0)
		return;
	playSong(getSongId(currentSongArrayIndex -1));
}

function playSong(songIndex)
{
	var audioPaused = audio.paused;
	setSource(songIndex);
	audio.play();
	sendMessage({action:"setPlayingNew"});

}

function setSource(songIndex){
	var songObj = getSong(songIndex);
    var displayName = songObj.movie + " - " +  songObj.song;
    setAudio(displayName, songObj.constructedUrl, songIndex);
}

function setAudio(displayName, url, songIndex ){
	currentSongIndex = songIndex;
	audioSrc.src = url;
	audio.pause();
	audio.load();
	$(audio).data("song", displayName);
	sendMessage({action:"displaySongName", value: displayName, songIndex: songIndex });
}


function getSong(songIndex)
{
	var songObj =  jQuery.grep(getSongs(), function(element, index){
  		return element.id == songIndex;
	})[0];
	return songObj;
}
function getSongs(){
	var playlist = localStorage["playlist"];
	return (playlist == undefined || playlist == "" || playlist == null) ? [] : JSON.parse(playlist);
}

function getSongId(arrayIndex)
{
	return getSongs()[arrayIndex].id
}

function getCurrentSongArrayIndex()
{
	var currentSongArrayIndex = null;
	var allSongs = getSongs();
	$.each(allSongs, function(ind, value) {
		if(value.id == currentSongIndex)
			currentSongArrayIndex = allSongs.indexOf(value);
	});
	return currentSongArrayIndex;
}

function totalSongs()
{
	return getSongs().length;
}


function getBufferPercent()
{
	if(audio.buffered.length == 0)
		return 0;
	buffered = audio.buffered.length == 0 ? 0 : audio.buffered.length - 1
	var durationLoaded = audio.buffered.end(buffered);
    return durationLoaded / audio.duration;
}

function sendMessage(message)
{
	chrome.extension.sendMessage({message: message});
}

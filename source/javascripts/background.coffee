$("body").append "<audio id='main_player' controls><source id='player_src' type='audio/mpeg; codecs=\"mp3\"'></source></audio>"
audio = $("#main_player")[0]
audioSrc = $("#player_src")[0]
currentSongIndex = null

LocalStorage = 
	add: (songJson) ->
		existingPlaylist = this.all()
		existingPlaylist.push songJson
		this.persist existingPlaylist

	all: () ->
		playlist = localStorage["playlist"]
		playlist = if (playlist? and playlist !=  "") then JSON.parse(playlist) else []

	destroy: (id) ->
		existingPlaylist = this.all()
		existingPlaylist = $.grep existingPlaylist, (obj) ->
							obj.id != id
		this.persist existingPlaylist

	destroyAll: () ->
		this.persist []

	update: (id, values) ->
		existingPlaylist = this.all()
		$.each existingPlaylist, (index, value) ->
			if existingPlaylist[index].id == id
				existingPlaylist[index] = $.extend(existingPlaylist[index], values)
		this.persist existingPlaylist

	updateAllNew: () ->
		existingPlaylist = this.all()
		$.each existingPlaylist, (index, value) ->
			existingPlaylist[index].state = "new"
		this.persist existingPlaylist

	persist: (array) ->
		localStorage["playlist"] = JSON.stringify array

	get: (key) ->
		localStorage[key]

	set: (key, value) ->
		localStorage[key] = value
	remove: (key) ->
		localStorage.removeItem(key)

Playlist =
	add: (songJson) ->
		unless this.find(songJson.id)
			LocalStorage.add songJson
			this.playSong(songJson.id) unless this.playing()?

	destroyAll: () ->
		LocalStorage.remove("loop")
		LocalStorage.destroyAll()
		this.resetPlayer()

	destroy: (id) ->
		if LocalStorage.get("loop")? && LocalStorage.get("loop") == id
			this.toggleLoopPlaying()
		playing = this.playing()
		allSongs = LocalStorage.all()
		if playing.id == id && allSongs.length == 1
			this.resetPlayer()
		if playing.id == id && allSongs.length > 1
			this.playNext()	
		LocalStorage.destroy(id)

	playSong: (id) ->
		this.markPlayingPlayed()
		if id?
			toPlay = this.find(id)
			LocalStorage.update(toPlay.id, {state: "playing"})
			audioSrc.src = toPlay.url
			audio.load()
			$(audio).data "id", id
			audio.play()
			sendMessage	{action: "preparePlayerForNewSong", id: id}
			if LocalStorage.get("loop")? && LocalStorage.get("loop") != id
				this.toggleLoopPlaying()

	playNext: () ->
		allSongs = LocalStorage.all()
		newPlayingIndex = this.indexOfPlaying() + 1
		if newPlayingIndex >= allSongs.length
			newPlayingIndex =  0
			LocalStorage.updateAllNew()
		newSongID = if LocalStorage.get("loop")? then LocalStorage.get("loop") else allSongs[newPlayingIndex].id
		this.playSong(newSongID)

	playPrevious: () ->
		allSongs = LocalStorage.all()
		newPlayingIndex = this.indexOfPlaying() - 1
		newPlayingIndex = allSongs.length - 1 if newPlayingIndex < 0
		newSongID = if LocalStorage.get("loop")? then LocalStorage.get("loop") else allSongs[newPlayingIndex].id
		this.playSong(newSongID)

	playing: () ->
		$.grep(LocalStorage.all(), (obj) -> obj.state == "playing")[0]

	toggleLoopPlaying: () ->
		if LocalStorage.get("loop")?
			LocalStorage.remove("loop")
		else
			LocalStorage.set("loop", this.playing().id)
		sendMessage({action: "setLooping", loopValue: LocalStorage.get("loop")})

	toggleShufflePlaylist: () ->
		currentShuffle = LocalStorage.get("shuffle")
		newShuffle = if currentShuffle == "active" then "" else "active"
		LocalStorage.set("shuffle", newShuffle)
		sendMessage({action: "setShuffle", value: newShuffle})


	indexOfPlaying: () ->
		allSongs = LocalStorage.all()
		indexOfPlaying = -1
		$.each allSongs, (index, value) ->
			if value.state == "playing"
				indexOfPlaying = allSongs.indexOf(value)
				false
		indexOfPlaying

	find: (id) ->
		$.grep(LocalStorage.all(), (obj) -> obj.id == id)[0]

	markPlayingPlayed: () ->
		playing = this.playing()
		this.resetPlayer()
		if playing?
			LocalStorage.update(playing.id, {state: "played"})
			sendMessage({action: "updatePlayed", playedId: playing.id})
		playing

	resetPlayer: () ->
		audio.pause()
		audioSrc.src = ""
		audio.load()
		$(audio).data "id", null
		sendMessage({action: "emptyPlayer"})	


chrome.extension.onMessage.addListener (request, sender, sendResponse) ->
	command = request.message
	audio = $("#main_player")[0]
	if command.action is "pause"
		audio.pause()

	if command.action is "play"
		audio.play()

	if command.action is "volume"
		audio.volume = command.value

	if command.action is "setSeek"
		audio.currentTime = audio.duration * command.value

	if command.action is "playPrevious"
		Playlist.playPrevious()

	if command.action is "playNext"
		Playlist.playNext()

	if command.action is "destroy"
		Playlist.destroy(command.id)
	
	if command.action is "destroyAll"
		Playlist.destroyAll()
	
	if command.action is "add"
		Playlist.add {name: command.name, movie: command.movie, url: command.url, state: command.state, id: command.id}

	if command.action == "aplaySong"
		Playlist.playSong command.id

	if command.action is "init"
		isPlaying = audio.played.length isnt 0
		response = playing: isPlaying
		playPercent = audio.currentTime / audio.duration
		$.extend response,
		song: audio.src
		duration: getFormattedTime(audio.duration)
		currentTime: getFormattedTime(audio.currentTime)
		playPercent: playPercent
		bufferPercent: getBufferPercent()
		paused: audio.paused
		id: $(audio).data("id")
		volume: parseInt(audio.volume * 10)
		allSongs: localStorage["playlist"]
		loopValue: LocalStorage.get("loop")
		shuffleValue: LocalStorage.get("shuffle")
		sendResponse response

	if command.action is "loopPlaying"
		loopValue = Playlist.toggleLoopPlaying()

	if command.action is "shufflePlaylist"
		Playlist.toggleShufflePlaylist()



getFormattedTime = (time) ->
	time = (if isNaN(time) then 0 else parseInt(time))
	seconds = (time % 60) + ""
	s = (if seconds.length is 1 then "0" + seconds else seconds)
	m = parseInt((time / 60) % 60)
	m + "." + s

sendAudioBuffering = ->
	sendMessage	{action: "bufferpercent", value: getBufferPercent()}


getBufferPercent = ->
	return 0  if audio.buffered.length is 0
	buffered = (if audio.buffered.length is 0 then 0 else audio.buffered.length - 1)
	durationLoaded = audio.buffered.end(buffered)
	durationLoaded / audio.duration

sendMessage = (message) ->
	chrome.extension.sendMessage message: message

audio.addEventListener("timeupdate", ()->
		currentPercent = audio.currentTime / audio.duration
		sendMessage	{action: "timeupdate",	value: getFormattedTime(audio.currentTime),	percent: currentPercent}
		sendAudioBuffering()
	, false)
audio.addEventListener("loadedmetadata", () ->
		sendMessage	action: "loadedmetadata", value: getFormattedTime(audio.duration)
	, false)
audio.addEventListener "loadstart", (() -> 	sendAudioBuffering()), false
audio.addEventListener "progress", (() -> sendAudioBuffering()), false
audio.addEventListener "ended", () -> 	
		Playlist.playNext()
	, false

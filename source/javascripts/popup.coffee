#GA Code
_gaq = _gaq or []
_gaq.push ["_setAccount", "UA-41329375-1"]
_gaq.push ["_trackPageview"]
(->
  ga = document.createElement("script")
  ga.type = "text/javascript"
  ga.async = true
  ga.src = "https://ssl.google-analytics.com/ga.js"
  s = document.getElementsByTagName("script")[0]
  s.parentNode.insertBefore ga, s
)()

#GA Code ends
$ ->
  
  # var songScrapper = "http://localhost:3000";
  setVolumeState = (volumeVal) ->
    volumeVal = parseInt(volumeVal)
    sendMessage
      action: "volume"
      value: parseFloat(volumeVal / 10)

    volume.val volumeVal
    volState = (if volumeVal isnt 0 then "ON" else "OFF")
    localStorage["volume"] = volState
    if volState is "ON"
      $("i", volumeIcon).attr "class", "icon-volume-up"
      localStorage["lastVolumeVal"] = volumeVal
    else
      $("i", volumeIcon).attr "class", "icon-volume-off"
  addSongsFromAlbum = (songs) ->
    $.each songs, (key, value) ->
      value = $(value)
      movie = value.data("movie")
      song = value.data("song")
      code = value.data("url")
      vId = value.data("vid")
      newID = addToLocalstorage(
        movie: movie
        song: song
        constructedUrl: code
        vId: vId
      )
      addToNowPlaying
        movie: movie
        song: song
        id: newID


  showSearchResult = ->
    results.show()
    album.hide()
    albumList.html ""
  showNowPlaying = ->
    $("#search_panel").hide()
  bindPlay = ->
    results.on "click", ".addsong", (e) ->
      target = $(e.currentTarget)
      movie = target.data("movie")
      song = target.data("song")
      url = target.data("url")
      vId = target.data("vid")
      newID = addToLocalstorage(
        movie: movie
        song: song
        constructedUrl: url
        vId: vId
      )
      addToNowPlaying
        movie: movie
        song: song
        id: newID

      displayPurr()
      e.preventDefault()

    results.on "click", ".viewentries", (e) ->
      target = $(e.currentTarget)
      movieID = target.data("by")
      name = target.data("name")
      type = target.data("type")
      fetchAndAddAllToAlbumSongs movieID, name, type
      results.hide()
      album.show()
      e.preventDefault()

    results.on "click", ".addall", (e) ->
      target = $(e.currentTarget)
      movieID = target.data("by")
      type = target.data("type")
      fetchAndAddAllToNowPlayingSongs movieID, type
      displayPurr()
      e.preventDefault()

    nowPlaying.on "click", ".playsong", (e) ->
      index = $(e.currentTarget).data("id")
      sendMessage
        action: "playSong"
        value: index

      e.preventDefault()

    nowPlaying.on "click", ".remove_song", (e) ->
      indexToRemove = $(e.currentTarget).data("id")
      $("a[data-id='" + indexToRemove + "']", nowPlaying).parent("li").remove()
      chrome.extension.sendMessage
        message:
          action: "removeIfPlaying"
          id: indexToRemove
      , (res) ->
        removeFromLocalStorage indexToRemove

      e.stopPropagation()
      e.preventDefault()

    clear_all.click (e) ->
      localStorage["playlist"] = ""
      sendMessage action: "next"
      setPlayPause "play"
      nowPlaying.html ""
      e.preventDefault()

  getSongs = ->
    playlist = localStorage["playlist"]
    (if (playlist is `undefined` or playlist is "" or not playlist?) then [] else JSON.parse(playlist))
  fetchAndAddAllToAlbumSongs = (movieID, movieName, type) ->
    albumName.html movieName
    $.get songScrapper + "/" + type + "s/" + movieID, (data) ->
      $.each data, (key, value) ->
        addView = "<input type='checkbox' data-movie='" + value.movie_name + "' data-song='" + value.name + "' data-url='" + value.url + "' data-vid='" + value._id + "'/>"
        albumList.append "<li><label>" + addView + value.name + "<label></li>"


  fetchAndAddAllToNowPlayingSongs = (movieID, type) ->
    $.get songScrapper + "/" + type + "s/" + movieID, (data) ->
      $.each data, (key, value) ->
        movie = value.movie_name
        song = value.name
        vId = value._id
        newID = addToLocalstorage(
          movie: movie
          song: song
          constructedUrl: value.url
          vId: vId
        )
        addToNowPlaying
          movie: movie
          song: song
          id: newID



  addToLocalstorage = (songJson) ->
    existingPlaylist = getSongs()
    playlistLength = existingPlaylist.length
    newID = (if playlistLength is 0 then 0 else existingPlaylist[playlistLength - 1].id + 1)
    $.extend songJson,
      id: newID

    existingPlaylist.push songJson
    localStorage["playlist"] = JSON.stringify(existingPlaylist)
    newID
  removeFromLocalStorage = (index) ->
    existingPlaylist = getSongs()
    newSongList = []
    $.each existingPlaylist, (ind, value) ->
      newSongList.push value  unless value.id is index

    localStorage["playlist"] = JSON.stringify(newSongList)
  addToNowPlaying = (songJson, playImmediately) ->
    playImmediately = (if typeof playImmediately isnt "undefined" then playImmediately else true)
    dataID = (if songJson.id isnt `undefined` then "data-id='" + songJson.id + "'" else "")
    nowPlaying.append "<li><span><a class='playsong' data-song='" + songJson.song + "' " + dataID + " data-movie='" + songJson.movie + "' href >" + songJson.song + "-" + songJson.movie + "</a></span><a class='remove_song' href='' " + dataID + "><i class='icon-remove-sign'></i></a></li>"
    if playImmediately
      sendMessage
        action: "playSongIfNotPlaying"
        id: songJson.id

      _gaq.push ["_trackEvent", "AddSong", "Added", songJson.song + " - " + songJson.movie]
  setPlayPause = (action) ->
    removeAction = (if action is "play" then "pause" else "play")
    icon = $("i", playpause)
    icon.removeClass "icon-" + removeAction
    icon.addClass "icon-" + action
    playpause.data "action", action
  displayPurr = (notification) ->
    notification = (if typeof notification isnt "undefined" then notification else "Added")
    purr.html notification
    purr.fadeIn(200).delay(800).fadeOut 200
  sendMessage = (message) ->
    chrome.extension.sendMessage
      message: message
    , (response) ->

  init = ->
    chrome.extension.sendMessage
      message:
        action: "init"
    , (response) ->
      console.log response
      playing.width response.playPercent * playerLength
      currentTime.html response.currentTime
      duration.html response.duration
      buffering.width response.bufferPercent * playerLength
      setVolumeState response.volume
      songName.html response.songName
      $(".playsong[data-id='" + response.currentSongIndex + "'] ").addClass "current"
      unless response.paused
        setPlayPause "pause"
      else
        setPlayPause "play"

    $.each getSongs(), (index, entry) ->
      addToNowPlaying
        movie: entry.movie
        song: entry.song
        id: entry.id
      , false

  playpause = $("#playpause")
  volume = $("#volume")
  currentTime = $("#currenttime")
  duration = $("#duration")
  buffering = $("#buffering")
  playerTime = $(".player_time")
  playing = $("#playing")
  playerLength = 250
  search = $("#search")
  results = $("#results ul")
  resultsContainer = $("#results")
  nowPlaying = $("#nowplaying ul")
  links = $(".links")
  previous = $("#previous")
  next = $("#next")
  songName = $("#song_name")
  album = $("#album")
  albumList = $("#album ul")
  albumName = $("#album_name")
  albumnAuthor = $("#albumn_author")
  progress = $("#progress")
  album_back = $("#album_back")
  np_add_all = $("#np_add_all")
  np_add_songs = $("#np_add_songs")
  clear_all = $("#np_clear_all")
  np_link = $("#np_link")
  purr = $(".purr")
  thanksLinks = $(".thanks a")
  volumeIcon = $(".volume_icon")
  createPlaylist = $("#np_create_playlist")
  createPlaylistForm = $("#create_playlist_form")
  createPlaylistModal = $("#create_playlist")
  moreCount = $(".more_count")
  playlistName = $("#playlist_name")
  songScrapper = "http://song-scrapper.herokuapp.com"
  init()
  bindPlay()
  showNowPlaying()
  $(window).load ->
    setTimeout (->
      $("a:first").focus()
    ), 50

  delay = (->
    timer = 0
    (callback, ms) ->
      clearTimeout timer
      timer = setTimeout(callback, ms)
  )()
  playpause.click (e) ->
    target = $(e.currentTarget)
    todo = target.data("action")
    nextAction = (if target.data("action") is "play" then "pause" else "play")
    setPlayPause nextAction
    sendMessage action: todo
    e.preventDefault()

  search.keyup ->
    delay (->
      searchVal = search.val()
      results.html ""
      resultsContainer.removeClass "loading"
      showSearchResult()
      if searchVal.length > 1
        resultsContainer.addClass "loading"
        _gaq.push ["_trackEvent", "search", "searched", searchVal]
        searchURL = songScrapper + "/search?q=" + encodeURIComponent(searchVal)
        $.getJSON searchURL, null, (data) ->
          results.html ""
          resultsContainer.removeClass "loading"
          results.append "<li><span class='no_results'>No results found</span></li>"  if data.length is 0
          $.each data, (index, result) ->
            addView = ""
            if result._type is "song"
              addView = "<a href class='addsong' data-movie='" + result.movie_name + "' data-song='" + result.name + "' data-url='" + result.url + "' title='Add Song' data-vid='" + result._id + "'><i class='icon-plus-sign'></i></a>"
              results.append "<li><span>" + result.name + " - " + result.movie_name + "</span>" + addView + "</li>"
            else
              addView = "<a href class='addall' data-by='" + result._id + "' data-name='" + result.name + "' data-type='" + result._type + "' title='Add all songs in album'><i class='icon-plus-sign'></i></a>" + "<a href class='viewentries' data-by='" + result._id + "' data-name='" + result.name + "' data-type='" + result._type + "' title='View album'><i class='icon-list'></i></a>"
              results.append "<li><span>" + result.name + " - " + result._type + " </span>" + addView + "</li>"


    ), 250

  progress.click (e) ->
    posX = $(this).offset().left
    posY = $(this).offset().top
    seekPos = (e.pageX - posX)
    console.log (e.pageX - posX) + " , " + (e.pageY - posY)
    sendMessage
      action: "setSeek"
      value: seekPos / progress.width()

    e.preventDefault()
    e.stopPropagation()

  links.click (e) ->
    target = $(e.currentTarget)
    loc = target.attr("href")
    $(".panel").show()
    $(loc).hide()
    $(".nav-pills .active").removeClass "active"
    target.parent().addClass "active"
    e.preventDefault()

  album_back.click (e) ->
    showSearchResult()
    e.preventDefault()

  previous.click (e) ->
    sendMessage action: "previous"
    e.preventDefault()

  next.click (e) ->
    sendMessage action: "next"
    e.preventDefault()

  np_add_all.click (e) ->
    songList = $("#album ul input[type='checkbox']")
    addSongsFromAlbum songList
    target = $(e.currentTarget)
    displayPurr()
    e.preventDefault()

  np_add_songs.click (e) ->
    songList = $("#album ul input[type='checkbox']:checked")
    addSongsFromAlbum songList
    target = $(e.currentTarget)
    displayPurr()
    e.preventDefault()

  thanksLinks.click (e) ->
    url = $(this).attr("href")
    chrome.tabs.create url: url
    e.preventDefault()

  volume.change ->
    setVolumeState @value

  volumeIcon.click (e) ->
    volumeState = localStorage["volume"]
    volumeVal = (if (volumeState is "ON" or volumeState is `undefined`) then 0 else localStorage["lastVolumeVal"])
    setVolumeState volumeVal

  createPlaylist.click (e) ->
    e.preventDefault()
    songs = getSongs()
    if songs.length < 15
      moreCount.html 15 - songs.length
      createPlaylist.attr "href", "#need_more"
    else
      createPlaylist.attr "href", "#create_playlist"

  createPlaylistForm.submit (e) ->
    e.preventDefault()
    name = playlistName.val().trim()
    songs = getSongs()
    if name is ""
      playlistName.val ""
      return
    songIds = []
    $.each songs, (index, entry) ->
      songIds.push entry.vId

    $.post songScrapper + "/playlists",
      name: name
      songIds: songIds
    , (data) ->
      console.log "playlist created"
      displayPurr name + " created"

    playlistName.val ""
    createPlaylistModal.modal "hide"

  chrome.extension.onMessage.addListener (request, sender, sendResponse) ->
    command = request.message
    if command.action is "timeupdate"
      playing.width command.percent * playerLength
      currentTime.html command.value
    if command.action is "loadedmetadata"
      duration.html command.value
      setPlayPause "pause"
      playerTime.removeClass "audio_loading"
    buffering.width command.value * playerLength  if command.action is "bufferpercent"
    if command.action is "ended"
      setPlayPause "play"
      currentTime.html "0.0"
      playing.width 0
    if command.action is "displaySongName"
      songName.html command.value
      currentTime.html "0.00"
      duration.html "0.00"
      playing.width "0px"
      buffering.width "0px"
      action = (if not command.value? then "play" else "pause")
      setPlayPause action
      $(".playsong").removeClass "current"
      $(".playsong[data-id='" + command.songIndex + "'] ").addClass "current"
    if command.action is "setPlayingNew"
      setPlayPause "play"
      playerTime.addClass "audio_loading"


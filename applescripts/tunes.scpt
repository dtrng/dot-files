(* Get the current song from iTunes or Spotify *)
if application "Spotify" is running then
  tell application "Spotify"
    set theName to name of the current track
    set theArtist to artist of the current track
    set theAlbum to album of the current track
    set theUrl to spotify url of the current track
    set state to player state
    try
      if state is playing then
        return "▶︎ " & theName & " - " & theArtist
      else if state is stopped then
        return ""
      else if state is paused then
        return theName & " - " & theArtist
      else
        return "♫  " & theName & " - " & theArtist
      end if
    on error err
    end try
  end tell
end if


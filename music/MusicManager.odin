package music

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"

Queue :: struct{
  pos : u32, //1 more than current_music
  current_music : u32,
  music : [dynamic]rl.Music,
  volume : f32
}

wait_for_dropped_files :: proc(q: ^Queue) {
  if rl.IsFileDropped() {
    dropped_files := rl.LoadDroppedFiles()
    defer rl.UnloadDroppedFiles(dropped_files)

    paths := dropped_files.paths[:dropped_files.count]

    for &path in paths {
      is_wav := rl.IsFileExtension(path, ".wav")
      is_mp3 := rl.IsFileExtension(path, ".mp3")
      is_ogg := rl.IsFileExtension(path, ".ogg")
      if is_wav || is_mp3 || is_ogg {
        queue_load_music(path, q)
      }
    }
  }
}

queue_load_music :: proc(file_path: cstring, q: ^Queue) {
  music := rl.LoadMusicStream(file_path)
  music.looping = false
  append_elem(&q.music, music)
} 

set_song_loop :: proc(q: ^Queue) {
  song : ^rl.Music = &q.music[q.current_music]
  if song.looping {
    song.looping = false
  } else {
    song.looping = true
  } 
}

set_volume :: proc(q: ^Queue, volume : f32) {
  song : ^rl.Music = &q.music[q.current_music]
  rl.SetMusicVolume(song^, volume)
}

queue_play_next :: proc(q: ^Queue) {
  queue_count := cast(u32)len(q.music)

  if queue_count > 0 && q.pos < queue_count {
    queue_play(q, q.pos)
    q.pos += 1
    fmt.println("Play next!")
  }
}
  
queue_play :: proc(q: ^Queue, pos: u32) {
  q.current_music = pos
  rl.PlayMusicStream(q.music[q.current_music])
}

queue_is_playing :: proc(q: ^Queue) -> bool {
  queue_count := cast(u32)len(q.music)
  if queue_count == 0 || q.current_music >= queue_count {
    return false
  }
  return rl.IsMusicStreamPlaying(q.music[q.current_music])
}

queue_update :: proc(q: ^Queue) {
  rl.UpdateMusicStream(q.music[q.current_music])
}

queue_pause :: proc(q: ^Queue) {
  rl.PauseMusicStream(q.music[q.current_music])
}

queue_stop :: proc(q: ^Queue) {
  rl.StopMusicStream(q.music[q.current_music])
}

queue_clear :: proc(q: ^Queue) {
  //Maybe we don't have to delete all the music loaded
  //if the user decides to clear queue? 
  for &music in q.music {
    rl.UnloadMusicStream(music)
  }

  if len(q.music) > 0 do clear(&q.music)
  q.pos = 0
  q.current_music = 0
}

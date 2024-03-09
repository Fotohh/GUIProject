package music

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"

Queue :: struct{
  current_music : u32,
  music_list: string,
  music : [dynamic]rl.Music,
  volume : f32
}

@(private)
retrieve_filename :: proc(filepath: cstring) -> string {
  @(static)
  unknown_file_counter := 0
  
  filename: string

  count: i32 = 0
  split := rl.TextSplit(filepath, '\\', &count)
  if count == 0 do split = rl.TextSplit(filepath, '/', &count)

  if count == 0 {
    filename = fmt.aprint("unnamed_music_file", unknown_file_counter)
    unknown_file_counter += 1
  } else {
    filename = strings.clone_from_cstring(split[count - 1])
  }

  return filename
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
        new_filename := retrieve_filename(path)
        if len(q.music_list) > 0 {
          q.music_list = fmt.aprintf("%s;%s", q.music_list, new_filename)
        } else {
          q.music_list = new_filename
        }
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
  song.looping = !song.looping 
}

set_volume :: proc(q: ^Queue, volume : f32) {
  if cast(int)q.current_music < len(q.music) {
    song : ^rl.Music = &q.music[q.current_music]
    rl.SetMusicVolume(song^, volume)
  }
}
  
queue_skip :: proc(q: ^Queue) {
  queue_count := cast(u32)len(q.music)

  if queue_count > 1 && q.current_music < queue_count - 1 {
    q.current_music += 1
    queue_play(q, q.current_music)
  } else {
    q.current_music = 0
  }
}

queue_play :: proc(q: ^Queue, pos: u32) {
  q.current_music = pos
  rl.StopMusicStream(q.music[q.current_music])
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

  delete(q.music_list)

  if len(q.music) > 0 do clear(&q.music)

  q.current_music = 0
}

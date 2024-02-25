package MusicManager;

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"

Queue :: struct{
  path_list : [dynamic] cstring,
  pos : i32,
  music : rl.Music
}

add_path :: proc(file_path: cstring, q: ^Queue){
   append_elem(&q.path_list, strings.clone_to_cstring(cast(string)file_path))
} 
play_next :: proc(q: ^Queue){
  prev_music := q.music
  q.pos += 1
  q.music = rl.LoadMusicStream(q.path_list[q.pos])
  rl.UnloadMusicStream(prev_music)
  ordered_remove(&q.path_list, cast(int) q.pos - 1)
  rl.PlayMusicStream(q.music)
}
  
play :: proc(q: ^Queue){
  path : cstring = q.path_list[0]
  q.music = rl.LoadMusicStream(path)
  rl.PlayMusicStream(q.music) 
}

is_playing :: proc(q: ^Queue) -> bool {
  return rl.IsMusicStreamPlaying(q.music)
}

update :: proc(m: rl.Music){
  rl.UpdateMusicStream(m)
}

pause :: proc(q: ^Queue){
  rl.PauseMusicStream(q.music)
}

stop :: proc(q: ^Queue){
  rl.StopMusicStream(q.music)
}

clear_queue :: proc(q: ^Queue) {
  clear(&q.path_list) 
}

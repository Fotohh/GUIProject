package music

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"

pause_button :: proc(music_queue: ^Queue, x:f32, y:f32){
  @(static) pause_button_text : cstring = "Pause"
  pause_button_text = queue_is_playing(music_queue) ? "Pause" : "Resume"
  if rl.GuiButton(rl.Rectangle{x,y,200,50}, pause_button_text) {
    if len(&music_queue.music) > 0 {
     song : ^rl.Music = &music_queue.music[music_queue.current_music] 
     if rl.IsMusicStreamPlaying(song^) {
        rl.PauseMusicStream(song^)
      } else {
       rl.ResumeMusicStream(song^)
      }
    }
  }  
}

loop_button :: proc(music_queue: ^Queue,x:f32,y:f32){
  @(static) loop_button_text : cstring = "Loop Song: Off"
  if rl.GuiButton(rl.Rectangle{x,y,200,50}, loop_button_text) {
    if len(&music_queue.music) > 0 {
      song : ^rl.Music = &music_queue.music[music_queue.current_music]
      if song.looping {
        loop_button_text = "Loop Song: Off"
        song.looping = false
      } else {
        loop_button_text = "Loop Song: On"
        song.looping = true
      }
    }
  }
}

volume_slider :: proc(music_queue: ^Queue, x: f32, y: f32) {
  rl.GuiSlider(rl.Rectangle{ x, y, 250, 50}, "Minimum Volume", "Maximum Volume", &music_queue.volume, 0.0, 100.0)
}

music_time_slider :: proc(music_queue: ^Queue, x: f32,y: f32) {
  if cast(int)music_queue.current_music > len(music_queue.music) - 1 do return
  s : f32 = rl.GetMusicTimeLength(music_queue.music[music_queue.current_music])
  current : f32 = rl.GetMusicTimePlayed(music_queue.music[music_queue.current_music])
  total_time := rl.TextFormat("%.1f", s)
  current_time := rl.TextFormat("%.1f", current)
  rl.GuiProgressBar(
    rl.Rectangle{x, y, 250, 50}, 
    current_time, 
    total_time, 
    &current, 
    0.0, 
    rl.GetMusicTimeLength(music_queue.music[music_queue.current_music]),
  )
}

skip_button :: proc(music_queue: ^Queue, x: f32, y: f32, selected: ^i32){
  if rl.GuiButton(rl.Rectangle{x,y,200,50}, "Skip Song") {
    if len(&music_queue.music) > 0 {
      queue_skip(music_queue) 
      selected^ = cast(i32)music_queue.current_music
    }
  }
}

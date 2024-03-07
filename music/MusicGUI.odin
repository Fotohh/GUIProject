package music

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"

pause_button :: proc(music_queue: ^Queue, x:f32,y:f32){
  @(static) pause_button_text : cstring = "Pause"
  if rl.GuiButton(rl.Rectangle{x,y,200,50}, pause_button_text) {
    if len(&music_queue.music) > 0 {
     song : ^rl.Music = &music_queue.music[music_queue.current_music] 
     if rl.IsMusicStreamPlaying(song^) {
        pause_button_text = "Unpause"
        rl.PauseMusicStream(song^)
      } else {
       pause_button_text = "Pause"
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

volume_silder :: proc(music_queue: ^Queue,x:f32,y:f32) {
  rl.GuiSlider(rl.Rectangle{x,y,250,50}, "Minimum Volume", "Maximum Volume", &music_queue.volume, 0.0, 1.0)
}

music_time_slider :: proc(music_queue: ^Queue,x:f32,y:f32){
  make_string := strings.builder_make()
  make_current := strings.builder_make()
  s : f32 = rl.GetMusicTimeLength(music_queue.music[music_queue.current_music])
  current : f32 = rl.GetMusicTimePlayed(music_queue.music[music_queue.current_music])
  strings.write_f32(&make_current, current, 'g')
  strings.write_f32(&make_string, s, 'g')
  cstr : cstring = strings.clone_to_cstring(strings.to_string(make_current))
  str : cstring = strings.clone_to_cstring(strings.to_string(make_string))  
  rl.GuiProgressBar(rl.Rectangle{x, y, 250, 50}, cstr, str, &current, 0.0, rl.GetMusicTimeLength(music_queue.music[music_queue.current_music]))
}

skip_button :: proc(music_queue: ^Queue,x:f32,y:f32){
  if rl.GuiButton(rl.Rectangle{x,y,200,50}, "Skip Song") {
    if len(&music_queue.music) > 0 {
      song : rl.Music = music_queue.music[music_queue.current_music]
      queue_skip(music_queue) 
    }
  }
}

package music

import rl "vendor:raylib"
import "core:fmt"

pause_button :: proc(music_queue: ^Queue){
  @(static) pause_button_text : cstring = "Pause"
  if rl.GuiButton(rl.Rectangle{50,500,200,50}, pause_button_text) {
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

loop_button :: proc(music_queue: ^Queue){
  @(static) loop_button_text : cstring = "Loop Song: On"
  if rl.GuiButton(rl.Rectangle{50,510,200,50}, loop_button_text) {
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

volume_silder :: proc(music_queue: ^Queue) {
  rl.GuiSlider(rl.Rectangle{50,300,50,50}, "Minimum Volume", "Maximum Volume", &music_queue.volume, 0, 100)
}

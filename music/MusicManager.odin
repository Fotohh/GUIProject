package MusicManager;

import rl "vendor:raylib"

musicQueue := [dynamic]rl.Music{}
pos : i32 = 0
currentStream : rl.Music

loadMusicFile :: proc(file_name:string){
  append(&musicQueue, rl.LoadMusicStream(file_name))
}

playNext :: proc(){
  pos += 1
  
}

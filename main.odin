package main

import tracy "odin-tracy"
import rl "vendor:raylib"

import "core:fmt"
import cmd "cmd-line"
import "app"
import "painter"
import serialize "serialization"

main :: proc() {  
  when ODIN_DEBUG {
    tracy.SetThreadName("Main")

    context.allocator = tracy.MakeProfiledAllocator(
		  self              = &tracy.ProfiledAllocatorData{},
		  callstack_size    = 5,
		  backing_allocator = context.allocator,
		  secure            = true,
	  )
  }

  px_map_size_x, px_map_size_y, file_path, load_file_path, cmd_read_success := cmd.cmd_read_args()

  if !rl.FileExists(load_file_path) && len(load_file_path) > 0 {
    fmt.println("Cannot open file!")
    return
  }
  if !cmd_read_success {
    return
  }
  
  app.app_init(120)

  app_data: app.AppData 
  if !app.app_create(&app_data, px_map_size_x, px_map_size_y, load_file_path) {
    fmt.println("Failed to create app...")
    return
  }

  app_data.file_name = file_path
  
  defer app.app_destroy(&app_data)
 
  rl.SetExitKey(rl.KeyboardKey.KEY_NULL)

  app_controls := app.app_control_init()

  icon := rl.LoadImage("icon.png")
  defer rl.UnloadImage(icon)
  rl.SetWindowIcon(icon)
 
  for !rl.WindowShouldClose() { 

    defer when ODIN_DEBUG do tracy.FrameMark("MainLoop") 

    when ODIN_DEBUG do tracy.Zone()
    
    app.app_update_basic_controls(&app_data, &app_controls)
    app.app_update_camera(&app_data)
  
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.Color { 25, 26, 38, 1 })
    
    app.app_draw_canvas(&app_data)
    app.app_draw_gui(&app_data, &app_controls)

    painter.painter_update_pixel_map(&app_data.pixel_map, &app_data.data)

  }
}

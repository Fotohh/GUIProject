package main

import tracy "odin-tracy"
import rl "vendor:raylib"

import "core:fmt"
import cmd "cmd-line"
import "app"
import "painter"
import serialize "serialization"

main :: proc() {  
  tracy.SetThreadName("Main")

  context.allocator = tracy.MakeProfiledAllocator(
		self              = &tracy.ProfiledAllocatorData{},
		callstack_size    = 5,
		backing_allocator = context.allocator,
		secure            = true,
	)

  px_map_size_x, px_map_size_y, cmd_read_success, file_path := cmd.cmd_read_args()
  if !cmd_read_success {
    return
  }
  
  app.app_init(120)

  app_data: app.AppData 
  if !app.app_create(&app_data, px_map_size_x, px_map_size_y) {
    fmt.println("Failed to create app...")
    return
  }

  app_data.file_name = file_path
  
  defer app.app_destroy(&app_data)
 
  rl.SetExitKey(rl.KeyboardKey.KEY_NULL)

  app_controls := app.app_control_init()
 
  for !rl.WindowShouldClose() { 

    defer tracy.FrameMark("MainLoop") 

    tracy.Zone()  
    
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

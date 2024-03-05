package main

/*
  How to run:

  -- px width height
  
  Ex: px 100 100

  Initializes a 100x100 pixel grid
*/

import tracy "odin-tracy"
import rl "vendor:raylib"

import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"

import m "music"
import px "pixel"
import painter "painter"

main :: proc() { 
  args := os.args[1:]
  if len(args) > 2 {
    fmt.println("Expected 2 arguments. Try 'px help'?")
    return
  } else if len(args) == 1 {
    if args[0] == "help" {
      fmt.println("px [width] [height]")
      fmt.println("Initializes the app with a [width]x[height] pixel grid.")
      fmt.println("Minimum size is 16x16 and maximum height is 1024x1024.")
      return
    }
  } else if len(args) == 0{
    fmt.println("Try 'px help'?")
    return
  }

  map_width, arg_1_ok := strconv.parse_int(args[0])
  if !arg_1_ok {
    fmt.println("Invalid width.")
    return
  }
  map_height, arg_2_ok := strconv.parse_int(args[0])
  if !arg_2_ok {
    fmt.println("Invalid height.")
    return
  }

  if map_width > 1024 || map_height > 1024 || map_width < 16 || map_height < 16 {
    fmt.println("Map width and height must be between the range 16..1024")
    return
  }

  config_flags : rl.ConfigFlags = { rl.ConfigFlag.WINDOW_RESIZABLE, rl.ConfigFlag.BORDERLESS_WINDOWED_MODE }
  rl.SetConfigFlags(config_flags)
  rl.SetTraceLogLevel(rl.TraceLogLevel.FATAL)
  rl.InitWindow(600, 480, "Sqr")
  
  rl.SetTargetFPS(120)

  tracy.SetThreadName("Main")
 
  current_monitor := rl.GetCurrentMonitor()

  w := rl.GetMonitorWidth(current_monitor)
  h := rl.GetMonitorHeight(current_monitor)

  rl.SetWindowPosition(
    cast(i32)rl.GetMonitorWidth(current_monitor) / 2 - (1600 / 2), 
    cast(i32)rl.GetMonitorHeight(current_monitor) / 2 - (1480 / 2),
  )

  rl.SetWindowSize(w / 2, h / 2)

  screen_center_w := cast(i32)rl.GetScreenWidth() / 2
  screen_center_h := cast(i32)rl.GetScreenHeight() / 2
  
  camera := rl.Camera2D {
    zoom = 2.0,
    offset = rl.Vector2 { cast(f32)screen_center_w, cast(f32)screen_center_h },
    rotation = 0.0,
    target = rl.Vector2 { 0.0, 0.0 },
  }

  px_map_size_x : i32 = cast(i32)map_width
  px_map_size_y : i32 = cast(i32)map_height

  pixel_map, ok := px.pixel_map_create(px_map_size_x, px_map_size_y)
  defer if ok do px.pixel_map_destroy(&pixel_map) 

  rl.InitAudioDevice()
  defer rl.CloseAudioDevice()

  music_queue : m.Queue
  defer m.queue_clear(&music_queue)
 
	context.allocator = tracy.MakeProfiledAllocator(
		self              = &tracy.ProfiledAllocatorData{},
		callstack_size    = 5,
		backing_allocator = context.allocator,
		secure            = true,
	)
 
  center_x := px_map_size_x / 2.0
  center_y := px_map_size_y / 2.0

  canvas := painter.Canvas {}
  canvas = make_map(map[[2]i32]bool, px_map_size_x * px_map_size_y)
  defer delete_map(canvas)
 
  data := painter.PainterData {}

  data.width = px_map_size_x
  data.height = px_map_size_y
  data.cxf = cast(f32)center_x
  data.cyf = cast(f32)center_y
  data.x0 = 0
  data.y0 = 0
  data.camera = camera

  data.radius = 5.0 

  reserve(&data.updated, len(canvas))
  defer delete_dynamic_array(data.updated)

  painter.painter_worker_create(&data)
  defer painter.painter_worker_destroy()

  current_color : rl.Color = rl.BLACK
  color : rl.Color = current_color

  data.color = []px.Pixel { px.Pixel { color.r, color.g, color.b, color.a } }

  controls_on := false

  rl.SetExitKey(rl.KeyboardKey.KEY_NULL)


  for !rl.WindowShouldClose() { 

    defer tracy.FrameMark("MainLoop") 

    tracy.Zone() 

    if (rl.IsKeyPressed(rl.KeyboardKey.C)) {
      painter.painter_clear_pixel_map(&pixel_map, &data) 
    }

    if (rl.IsKeyPressed(rl.KeyboardKey.TAB)) {
      controls_on = !controls_on
      painter.painter_lock_canvas(controls_on)
    }
     
    data.camera = camera
 
    painter.painter_update_pixel_map(&pixel_map, &data)

    screen_center_w = cast(i32)rl.GetScreenWidth() / 2
    screen_center_h = cast(i32)rl.GetScreenHeight() / 2

    camera.target.x = cast(f32)screen_center_w - camera.offset.x
    camera.target.y = cast(f32)screen_center_h - camera.offset.y

    if rl.IsWindowResized() {
      camera.offset = rl.Vector2 { cast(f32)screen_center_w, cast(f32)screen_center_h }
    }

    if rl.IsMouseButtonDown(rl.MouseButton.MIDDLE) {
      screen_center : rl.Vector2 = { cast(f32)screen_center_w, cast(f32)screen_center_h }
      camera.offset += rl.GetMouseDelta() * 50.0 * rl.GetFrameTime() / camera.zoom
    } 
  
    mouse_wheel_delta := rl.GetMouseWheelMove()
    camera.zoom = math.clamp(camera.zoom + cast(f32)mouse_wheel_delta / 5.0, 1.0, 20.0)

    m.wait_for_dropped_files(&music_queue)
    if !m.queue_is_playing(&music_queue) {
      m.queue_play_next(&music_queue) 
    } else {
      m.queue_update(&music_queue)
    }

    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.Color { 25, 26, 38, 1 })

    rl.BeginMode2D(camera)
 
    rl.DrawTexture(
      pixel_map.texture,
      0 - center_x, 
      0 - center_y, 
      rl.WHITE,
    ) 
    
    rl.DrawRectangleLines(0 - center_x, 0 - center_y, px_map_size_x, px_map_size_y, rl.BLACK)

    rl.EndMode2D()

    rl.DrawFPS(0, 0)

    rl.DrawRectangle(30, 50, 800, 200, rl.GRAY)
    rl.DrawText("Color:", 40, 80, 32, rl.BLACK)
    rl.DrawCircle(190, 95, 20, current_color)
    rl.DrawText(rl.TextFormat("Size: %.1f", data.radius), 40, 120, 32, rl.BLACK)
    rl.DrawText("C: Clear -- Mouse Wheel Scroll: Zoom", 40, 160, 32, rl.BLACK)
    rl.DrawText("Tab: Open Panel -- Mouse Wheel Down: Pan", 35, 205, 32, rl.BLACK)

    
    if controls_on {
      wf := cast(f32)screen_center_w
      hf := cast(f32)screen_center_h
      rl.DrawRectangle(cast(i32)wf - 400, cast(i32)hf - 400, 800, 800, rl.Color { 0, 0, 46, 255 })
      rl.GuiColorPicker(rl.Rectangle { wf - 220, hf - 200, 200.0, 200.0 }, "Colors", &color)

      rl.GuiSetStyle(cast(i32)rl.GuiControl.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 32)
      if rl.GuiButton(rl.Rectangle { wf - 220, hf + 10, 200.0, 50.0 }, "Set Color") {
        current_color = color
        data.color = []px.Pixel { px.Pixel { current_color.r, current_color.g, current_color.b, 255 } }
        painter.painter_reset_canvas_update(&data)
      }

      rl.GuiSetStyle(cast(i32)rl.GuiControl.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 24)
      rl.GuiSliderBar(
        rl.Rectangle { wf - 90, hf + 100, 100.0, 50.0 }, 
        "Brush Size:", 
        rl.TextFormat("%.1f", data.radius),
        &data.radius,
        1,
        50,
      )
    }
  }
  rl.CloseWindow()
}

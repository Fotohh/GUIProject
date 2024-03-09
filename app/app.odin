package app

import rl "vendor:raylib"

import "core:math"
import "core:strings"

import px "../pixel"
import "../painter"
import "../music"

AppData :: struct {
  camera: rl.Camera2D,
  pixel_map: px.PixelMap,
  canvas: painter.Canvas,
  data: painter.PainterData,
  music_queue: music.Queue 
}

AppControls :: struct {
  controls_on: bool,
  current_brush: painter.BrushType,
  current_color: rl.Color,
  gui_color: rl.Color, //changed by color picker
  eraser_color: []px.Pixel,
  prev_eraser_on: bool,
  eraser_on: bool,
  music_player_toggled: bool,
  scroll_index: i32,
  selected_item: i32
}

app_init :: proc(target_fps: i32) {
  config_flags : rl.ConfigFlags = { rl.ConfigFlag.WINDOW_RESIZABLE, rl.ConfigFlag.BORDERLESS_WINDOWED_MODE }
  rl.SetConfigFlags(config_flags)
  //rl.SetTraceLogLevel(rl.TraceLogLevel.FATAL)
  rl.InitWindow(600, 480, "Sqr")
  
  rl.SetTargetFPS(target_fps)
 
  current_monitor := rl.GetCurrentMonitor()

  w := rl.GetMonitorWidth(current_monitor)
  h := rl.GetMonitorHeight(current_monitor)

  rl.SetWindowPosition(
    cast(i32)rl.GetMonitorWidth(current_monitor) / 2 - (1600 / 2), 
    cast(i32)rl.GetMonitorHeight(current_monitor) / 2 - (1480 / 2),
  )

  rl.SetWindowSize(w / 2, h / 2)
}

app_get_screen_center :: proc() -> (i32, i32) {
  screen_center_w := cast(i32)rl.GetScreenWidth() / 2
  screen_center_h := cast(i32)rl.GetScreenHeight() / 2

  return screen_center_w, screen_center_h 
}

app_create :: proc(app: ^AppData, px_map_size_x: i32, px_map_size_y: i32) -> bool {
  screen_center_w, screen_center_h := app_get_screen_center()

  app.camera = rl.Camera2D {
    zoom = 2.0,
    offset = rl.Vector2 { cast(f32)screen_center_w, cast(f32)screen_center_h },
    rotation = 0.0,
    target = rl.Vector2 { 0.0, 0.0 },
  }

  ok: bool = false
  app.pixel_map, ok = px.pixel_map_create(px_map_size_x, px_map_size_y)
  if !ok do return false
  
  center_x := px_map_size_x / 2.0
  center_y := px_map_size_y / 2.0

  app.canvas = painter.Canvas {}
  app.canvas = make_map(map[[2]i32]bool, px_map_size_x * px_map_size_y)

  app.data = painter.PainterData {}

  app.data.width = px_map_size_x
  app.data.height = px_map_size_y
  app.data.cxf = cast(f32)px_map_size_x / 2.0
  app.data.cyf = cast(f32)px_map_size_y / 2.0
  app.data.x0 = 0
  app.data.y0 = 0
  app.data.camera = app.camera
  app.data.brush = painter.circle_brush
  app.data.radius = 5.0 
  app.data.color = px.Pixel { 0, 0, 0, 255 } 

  reserve(&app.data.updated, len(app.canvas))  

  painter.painter_worker_create(&app.data)

  rl.InitAudioDevice()

  app.music_queue.volume = 20 //20%
 
  return true
}

app_destroy :: proc(app: ^AppData) {
  rl.CloseAudioDevice()
  rl.CloseWindow()

  music.queue_clear(&app.music_queue)

  px.pixel_map_destroy(&app.pixel_map) 
  delete_map(app.canvas)
  delete_dynamic_array(app.data.updated)
  painter.painter_worker_destroy()
}

app_update_camera :: proc(app: ^AppData) {
  screen_center_w, screen_center_h := app_get_screen_center()
  app.data.camera = app.camera
 
  screen_center_w = cast(i32)rl.GetScreenWidth() / 2
  screen_center_h = cast(i32)rl.GetScreenHeight() / 2

  app.camera.target.x = cast(f32)screen_center_w - app.camera.offset.x
  app.camera.target.y = cast(f32)screen_center_h - app.camera.offset.y

  if rl.IsWindowResized() {
    app.camera.offset = rl.Vector2 { cast(f32)screen_center_w, cast(f32)screen_center_h }
  }

  if rl.IsMouseButtonDown(rl.MouseButton.MIDDLE) {
    screen_center : rl.Vector2 = { cast(f32)screen_center_w, cast(f32)screen_center_h }
    app.camera.offset += rl.GetMouseDelta() * 50.0 * rl.GetFrameTime() / app.camera.zoom
  } 
  
  mouse_wheel_delta := rl.GetMouseWheelMove()
  app.camera.zoom = math.clamp(app.camera.zoom + cast(f32)mouse_wheel_delta / 5.0, 1.0, 20.0) 
}

app_control_init :: proc() -> AppControls {
  controls_on := false
  current_brush : painter.BrushType = painter.BrushType.Circle
  current_color : rl.Color = rl.BLACK
  color : rl.Color = current_color
  eraser_color := []px.Pixel { px.Pixel { 255, 255, 255, 255 } }
  prev_eraser_on := false
  eraser_on := false

  return AppControls { 
    controls_on, 
    current_brush, 
    current_color, 
    color, 
    eraser_color, 
    prev_eraser_on, 
    eraser_on,
    false,
    0,
    0,
  }
}

app_update_basic_controls :: proc(app: ^AppData, controls: ^AppControls) {
  music.wait_for_dropped_files(&app.music_queue)

  if music.queue_is_playing(&app.music_queue) do music.queue_update(&app.music_queue)

  if (rl.IsKeyPressed(rl.KeyboardKey.C)) {
    painter.painter_clear_pixel_map(&app.pixel_map, &app.data) 
  }

  if (rl.IsKeyPressed(rl.KeyboardKey.TAB)) {
    controls.controls_on = !controls.controls_on
    painter.painter_lock_canvas(controls.controls_on)
  }
}

app_draw_canvas :: proc(app: ^AppData) {
  center_x, center_y := app.pixel_map.width / 2, app.pixel_map.height / 2
  rl.BeginMode2D(app.camera)
 
  rl.DrawTexture(
    app.pixel_map.texture,
    0 - center_x, 
    0 - center_y, 
    rl.WHITE,
  ) 
    
  rl.DrawRectangleLines(0 - center_x, 0 - center_y, app.pixel_map.width, app.pixel_map.height, rl.BLACK)

  rl.EndMode2D()
}

app_draw_gui :: proc(app: ^AppData, controls: ^AppControls) {
  screen_center_w, screen_center_h := app_get_screen_center()
  rl.DrawFPS(0, 0)

  rl.DrawRectangle(30, 50, 800, 200, rl.BLUE)
  rl.DrawText("Color:", 40, 80, 32, rl.BLACK)
  rl.DrawCircle(190, 95, 20, controls.current_color)
  rl.DrawText(rl.TextFormat("Map: %dx%d px", app.pixel_map.width, app.pixel_map.height), 230, 80, 32, rl.BLACK)
  rl.DrawText(rl.TextFormat("Brush Size: %.1f", app.data.radius), 40, 120, 32, rl.BLACK)
  rl.DrawText("C: Clear -- Mouse Wheel Scroll: Zoom", 40, 160, 32, rl.BLACK)
  rl.DrawText("Tab: Open Panel -- Mouse Wheel Down: Pan", 35, 205, 32, rl.BLACK)
    
  switch controls.current_brush {
    case .Circle: rl.DrawText("Circle Brush", 510, 70, 24, rl.WHITE)
    case .Box: rl.DrawText("Box Brush", 510, 70, 24, rl.WHITE)
    case .Calligraphy: rl.DrawText("Calligraphy Brush", 510, 70, 24, rl.WHITE)
  }

  text : cstring = controls.eraser_on ? "Eraser On" : "Eraser Off"
  rl.DrawText(text, 510, 100, 24, rl.WHITE)
    
  if controls.controls_on {
    wf := cast(f32)screen_center_w
    hf := cast(f32)screen_center_h 

    rl.DrawRectangle(cast(i32)wf - 400, cast(i32)hf - 400, 800, 800, rl.Color { 0, 0, 46, 255 })

    if rl.GuiButton(
      rl.Rectangle{ wf - 80, hf - 300, 200, 100},
      "Music Player", 
    ) {
      controls.music_player_toggled = !controls.music_player_toggled
    }

    if controls.music_player_toggled {
      if len(app.music_queue.music) > 0 {
        music.loop_button(&app.music_queue, wf - 380, hf - 300)
        music.pause_button(&app.music_queue, wf - 380, hf + 100)
        music.music_time_slider(&app.music_queue, wf - 200, hf)
        music.volume_slider(&app.music_queue, wf - 200, hf - 100)
        music.skip_button(&app.music_queue, wf - 380, hf - 200, &controls.selected_item)
        music.set_volume(&app.music_queue, app.music_queue.volume / 100)

        rl.GuiListView(
          rl.Rectangle { wf - 400, hf + 200, 800, 200 }, 
          strings.unsafe_string_to_cstring(app.music_queue.music_list),
          &controls.scroll_index, 
          &controls.selected_item,
        )

        if rl.GuiButton(rl.Rectangle { wf + 200, hf - 300, 100, 50 }, "Play") {
          if controls.selected_item >= 0 {
            selected_item := cast(u32)controls.selected_item
            music.queue_play(&app.music_queue, selected_item)
          } 
        }
        return
      }
    }

    rl.GuiColorPicker(rl.Rectangle { wf - 380, hf - 300, 200.0, 200.0 }, "Colors", &controls.gui_color)

    rl.GuiSetStyle(cast(i32)rl.GuiControl.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 32)
    if rl.GuiButton(rl.Rectangle { wf - 380, hf - 50, 200.0, 50.0 }, "Set Color") && !controls.eraser_on {
      controls.current_color = controls.gui_color
      app.data.color = { controls.current_color.r, controls.current_color.g, controls.current_color.b, 255 }
      painter.painter_reset_canvas_update(&app.data)
    }

    rl.GuiSetStyle(cast(i32)rl.GuiControl.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 24)
    rl.GuiSliderBar(
      rl.Rectangle { wf - 250, hf + 50, 100.0, 50.0 }, 
      "Brush Size:", 
      rl.TextFormat("%.1f", app.data.radius),
      &app.data.radius,
      1,
      50,
    )

    if rl.GuiLabelButton(
      rl.Rectangle { wf - 300, hf + 200, 100.0, 50.0 },
      "Circle Brush",
    ) {
      painter.set_brush_type(&app.data, painter.circle_brush)
      controls.current_brush = painter.BrushType.Circle
    }

    if rl.GuiLabelButton(
      rl.Rectangle { wf - 100, hf + 200, 100.0, 50.0 },
      "Box Brush",
    ) {
      painter.set_brush_type(&app.data, painter.pixel_brush)
      controls.current_brush = painter.BrushType.Box
    }

    if rl.GuiLabelButton(
      rl.Rectangle { wf + 100, hf + 200, 100.0, 50.0 },
      "Calligraphy Brush",
    ) {
      painter.set_brush_type(&app.data, painter.calligraphy)
      controls.current_brush = painter.BrushType.Calligraphy
    }

    rl.GuiCheckBox(rl.Rectangle { wf - 60, hf + 45, 60.0, 60.0 }, "Eraser", &controls.eraser_on)

    if controls.eraser_on != controls.prev_eraser_on {
      controls.prev_eraser_on = controls.eraser_on
      color := controls.eraser_on ? rl.WHITE : controls.current_color
      app.data.color = { color.r, color.g, color.b, 255 }
      
      painter.painter_reset_canvas_update(&app.data)
    } 
  }
}

package main

import "core:fmt"
import "core:math"
import "core:math/rand"

import rl "vendor:raylib"
import m "music"

main :: proc() { 
  config_flags : rl.ConfigFlags = { rl.ConfigFlag.WINDOW_RESIZABLE, rl.ConfigFlag.BORDERLESS_WINDOWED_MODE }
  rl.SetConfigFlags(config_flags)
  rl.InitWindow(1600, 1480, "Sqr")

  current_monitor := rl.GetCurrentMonitor()
  rl.SetWindowPosition(
    cast(i32)rl.GetMonitorWidth(current_monitor) / 2 - (1600 / 2), 
    cast(i32)rl.GetMonitorHeight(current_monitor) / 2 - (1480 / 2),
  )

  pixel_map : [dynamic][64 * 64][2]i32

  offset_x : i32 = 0
  offset_y : i32 = 0
  
  pixels : [64 * 64][2]i32
  for i in 0..<36 {
    for x in 0..<64 { 
      for y in 0..<64 {
        pixels[x + y * 64] = [2]i32 { cast(i32)x + offset_x, cast(i32)y + offset_y }
      } 
    } 
    append(&pixel_map, pixels) 
    offset_x += 64
    if (offset_x % (64 * 6)) == 0 {
      offset_y += 64
      offset_x = 0
    }
  }

  screen_center_w := cast(i32)rl.GetScreenWidth() / 2
  screen_center_h := cast(i32)rl.GetScreenHeight() / 2
  
  px_map_size : i32 = cast(i32)len(pixel_map) * 64 
  px_map_size = 6 * 64

  camera := rl.Camera2D {
    zoom = 2.0,
    offset = rl.Vector2 { cast(f32)screen_center_w, cast(f32)screen_center_h },
    rotation = 0.0,
    target = rl.Vector2 { 0.0, 0.0 },
  }

  pixel_buffer := rl.LoadRenderTexture(64 * 6, 64 * 6)
  rl.BeginTextureMode(pixel_buffer)
  for pixel_data in pixel_map {
    for pixel in pixel_data {
      h := rand.float32_gamma(1.0, 5.0)
      s := rand.float32_gamma(1.0, 5.0)
      v := rand.float32_gamma(1.0, 5.0)


      rl.DrawPixel(pixel.x, pixel.y, rl.ColorFromHSV(h, s, v))
    }
  }
  rl.EndTextureMode()

  px_format := cast(i32)rl.PixelFormat.UNCOMPRESSED_R32G32B32A32
  px_data_raw := rl.rlReadTexturePixels(pixel_buffer.texture.id, px_map_size, px_map_size, px_format)
  fmt.println(size_of(px_data_raw))
  px_data_mem := cast([^]u8)px_data_raw
  px_data := px_data_mem[:px_map_size*px_map_size]

  rl.InitAudioDevice()
  defer rl.CloseAudioDevice()

  music_queue : m.Queue
  defer m.queue_clear(&music_queue)

  pause_button_text : cstring = "Pause"

  for !rl.WindowShouldClose() { 
    screen_center_w = cast(i32)rl.GetScreenWidth() / 2
    screen_center_h = cast(i32)rl.GetScreenHeight() / 2

    camera.target.x = cast(f32)screen_center_w - camera.offset.x
    camera.target.y = cast(f32)screen_center_h - camera.offset.y

    if rl.IsWindowResized() {
      camera.offset = rl.Vector2 { cast(f32)screen_center_w, cast(f32)screen_center_h }
    }

    if rl.IsMouseButtonDown(rl.MouseButton.MIDDLE) {
      screen_center : rl.Vector2 = { cast(f32)screen_center_w, cast(f32)screen_center_h }
      camera.offset += rl.GetMouseDelta() * 100.0 * rl.GetFrameTime()
    }
    
    if (rl.IsMouseButtonDown(rl.MouseButton.RIGHT)) {
    
    }
    
    mouse_wheel_delta := rl.GetMouseWheelMove()
    camera.zoom = math.clamp(camera.zoom + cast(f32)mouse_wheel_delta / 5.0, 1.0, 4.0)

    m.wait_for_dropped_files(&music_queue)
    if !m.queue_is_playing(&music_queue) {
      m.queue_play_next(&music_queue) 
    } else {
      m.queue_update(&music_queue)
    }

    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.RAYWHITE)

    rl.BeginMode2D(camera)
 
    center_x : i32 = px_map_size / 2 
    center_y := center_x

    rl.DrawTexture(pixel_buffer.texture, 0 - center_x, 0 - center_y, rl.WHITE) 

    rl.DrawRectangleLines(0 - center_x, 0 - center_y, px_map_size, px_map_size, rl.BLACK)

    rl.EndMode2D()

    rl.DrawFPS(0, 0)

    m.pause_button(&music_queue)
  }
  rl.CloseWindow()
}

package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

add_pixels :: proc(pixels: ^[dynamic][2]i32) {
  mouse_pos := rl.GetMousePosition()

  x_min := cast(i32)mouse_pos.x - 100
  y_min := cast(i32)mouse_pos.y - 100

  for x in 0..=100 {
    for y in 0..=100 {
      append(pixels, [2]i32 { x_min + cast(i32)x, y_min + cast(i32)y })
    }
  }
}



main :: proc() { 
  config_flags : rl.ConfigFlags = { rl.ConfigFlag.WINDOW_RESIZABLE }
  rl.SetConfigFlags(config_flags)
  rl.InitWindow(1600, 1480, "Sqr")

  pixel_map : [dynamic][64 * 64][2]i32

  offset : i32 = 0
  
  pixels : [64 * 64][2]i32
  for i in 0..<5 {
    for x in 0..<64 { 
      for y in 0..<64 {
        pixels[x + y * 64] = [2]i32 { cast(i32)x + offset, cast(i32)y + offset }
      } 
    } 
    append(&pixel_map, pixels) 
    offset += 64
  }

  camera := rl.Camera2D {
    zoom = 1.0,
    offset = rl.Vector2 { 0.0, 0.0 },
    rotation = 0.0,
    target = rl.Vector2 { 0.0, 0.0 },
  }

  for !rl.WindowShouldClose() {

    screen_center_w := cast(f32)rl.GetScreenWidth() / 2
    screen_center_h := cast(f32)rl.GetScreenHeight() / 2

    camera.target.x = screen_center_w - camera.offset.x
    camera.target.y = screen_center_h - camera.offset.y

    if rl.IsMouseButtonDown(rl.MouseButton.MIDDLE) {
      camera.offset += rl.GetMouseDelta()
    }

    mouse_wheel_delta := rl.GetMouseWheelMove()
    camera.zoom = math.clamp(camera.zoom + cast(f32)mouse_wheel_delta / 5.0, 0.1, 4.0)

    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.RAYWHITE)

    rl.BeginMode2D(camera)

    for pixel_data in pixel_map {
      for pixel in pixel_data {
        rl.DrawRectangle(pixel.x * 20, pixel.y * 20, 20, 20, rl.RED)
        rl.DrawRectangleLines(pixel.x * 20, pixel.y * 20, 20, 20, rl.BLACK)
      }
    }

    rl.EndMode2D()

    rl.DrawFPS(0, 0)

  }

  rl.CloseWindow()
}

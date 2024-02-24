package main

import "core:fmt"
import rl "vendor:raylib"

main :: proc() { 
  rl.InitWindow(1600, 1480, "Sqr")

  for !rl.WindowShouldClose() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.RAYWHITE)
  }

  rl.CloseWindow()
}

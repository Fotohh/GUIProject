package painter

import tracy "../odin-tracy"
import rl "vendor:raylib"
import lin "core:math/linalg"

import "core:thread"
import "core:sync"
import "core:math"
import "core:slice"

import px "../pixel"

Canvas :: map[[2]i32]bool

@(private)
data_lock: sync.Mutex
@(private)
data_cond: sync.Cond
@(private)
data_wait: bool

@(private)
lock_canvas_cond: sync.Cond
@(private)
lock_canvas: bool = false

@(private)
painter_thread: ^thread.Thread

Operation :: enum u8 {
  Draw,
  Clear
}

Action:: struct {
  operation: Operation,
  color: px.Pixel,
  pixels: [][2]i32
}

PainterData :: struct {
  canvas: Canvas,
  brush: proc(data: ^PainterData, x_pos, y_pos: i32),
  width, height: i32,
  x0, y0, cxf, cyf: f32,
  camera: rl.Camera2D,
  updated: [dynamic][2]i32,
  updated_buf: [dynamic][2]i32,
  color: px.Pixel,
  radius: f32,
  undo_buffer: [dynamic]Action,
  redo_buffer: [dynamic]Action
}

 
bresenham_line :: proc(data: ^PainterData, x1, y1: i32) { 
  tracy.ZoneNS("bresenham_line")   

  for data_wait do sync.cond_wait(&data_cond, &data_lock)


  x0 := cast(i32)data.x0
  y0 := cast(i32)data.y0

  dx := x1 - x0   
  dy := y1 - y0

  sx : i32 = dx >= 0 ? 1 : -1
  sy : i32 = dy >= 0 ? 1 : -1

  is_swapped := false
  if math.abs(dy) > math.abs(dx) {
    is_swapped = true
    dx, dy = dy, dx 
  }
  
  p := 2 * (math.abs(dy)) - math.abs(dx)

  data.brush(data, x0, y0)

  for i in 0..<math.abs(dx) {
    if p < 0 {
      if !is_swapped {
        x0 += sx
        data.brush(data, x0, y0)
      } else {
        y0 += sy
        data.brush(data, x0, y0)
      }
      p = p + 2 * math.abs(dy)
    } else {
      x0 += sx
      y0 += sy

      data.brush(data, x0, y0)

      p = p + 2 * math.abs(dy) - 2 * math.abs(dx) 
    }
  }
}

mouse_to_pixels :: proc(world_x, world_y, map_w, map_h: f32) -> (f32, f32) {
  return math.abs(-world_x - (map_w / 2)), math.abs(-world_y - (map_h / 2))
}

import "core:fmt"

mouse_on_grid :: proc(
  data: ^PainterData
) {
  tracy.ZoneN("mouse_on_grid")

  sync.lock(&data_lock)

  for lock_canvas do sync.cond_wait(&lock_canvas_cond, &data_lock)
 
  mouse_position := rl.GetMousePosition()
  world := rl.GetScreenToWorld2D(mouse_position, data.camera)

  in_grid := rl.CheckCollisionPointRec(world, { -data.cxf, -data.cyf, cast(f32)data.width, cast(f32)data.height })

  mouse_delta_magnitude := lin.length2(rl.GetMouseDelta())
  is_mouse_same := data.x0 == 0 && data.y0 == 0

  should_move := mouse_delta_magnitude > 3.0 || is_mouse_same

  if rl.IsMouseButtonDown(rl.MouseButton.LEFT) && in_grid && should_move {
    world_after := rl.GetScreenToWorld2D(rl.GetMousePosition(), data.camera)
 
    if data.x0 == 0 || data.y0 == 0 {
      data.x0, data.y0 = mouse_to_pixels(world.x, world.y, cast(f32)data.width, cast(f32)data.height)
    }

    x1, y1 := mouse_to_pixels(world_after.x, world_after.y, cast(f32)data.width, cast(f32)data.height)

    bresenham_line(
      data,
      cast(i32)x1, 
      cast(i32)y1, 
    )

    data.x0, data.y0 = x1, y1 
  } 

  sync.unlock(&data_lock)
}

painter_undo_redo :: proc(data: ^PainterData, pixel_map: ^px.PixelMap) {
  if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
    data.x0, data.y0 = 0, 0 

    action : Action

    action.color = data.color
    action.pixels = slice.clone(data.updated_buf[:])
    clear(&data.updated_buf)

    action.operation = .Draw
    
    append(&data.undo_buffer, action)
    clear(&data.redo_buffer)
  }


  if rl.IsKeyPressed(rl.KeyboardKey.U) && len(data.undo_buffer) > 0 {
    painter_reset_to_original(pixel_map, data)
    prev_color := data.color
    append(&data.redo_buffer, pop(&data.undo_buffer))
    for i in 0..<len(data.undo_buffer) {
      action := &data.undo_buffer[i]
      if action.operation == .Draw {
        data.updated = slice.clone_to_dynamic(action.pixels)
        data.color = action.color
        painter_update_pixel_map(pixel_map, data)  
        painter_reset_canvas_update(data)
      } else if action.operation == .Clear {
        painter_clear_pixel_map(pixel_map, data, { action.color.r, action.color.g, action.color.b, action.color.a })
      }
    } 

    data.color = prev_color
  }

  if rl.IsKeyPressed(rl.KeyboardKey.R) && len(data.redo_buffer) > 0 {
    prev_color := data.color

    action := pop(&data.redo_buffer)

    if action.operation == .Draw {
      data.updated = slice.clone_to_dynamic(action.pixels)
      data.color = action.color
      painter_update_pixel_map(pixel_map, data)  
      painter_reset_canvas_update(data)
    } else if action.operation == .Clear {
      painter_clear_pixel_map(pixel_map, data, { action.color.r, action.color.g, action.color.b, action.color.a })
    }

    append(&data.undo_buffer, action)


    data.color = prev_color
  }

}

painter_get_pixel_color :: proc(pixel_map: ^px.PixelMap, data: ^PainterData) -> px.Pixel {
  sync.lock(&data_lock)
  defer sync.unlock(&data_lock)

  world := rl.GetScreenToWorld2D(rl.GetMousePosition(), data.camera)
  x, y := mouse_to_pixels(world.x, world.y, cast(f32)data.width, cast(f32)data.height)
  in_grid := rl.CheckCollisionPointRec(world, { -data.cxf, -data.cyf, cast(f32)data.width, cast(f32)data.height })

  if in_grid {
    format := rl.PixelFormat.UNCOMPRESSED_R8G8B8A8
    pixels := 
      cast([^]px.Pixel)rl.rlReadTexturePixels(pixel_map.texture.id, pixel_map.texture.width, pixel_map.texture.height, cast(i32)format)
    pixel := pixels[cast(i32)x + cast(i32)y * cast(i32)data.width]
    return pixel
  }

  return data.color
}

painter_update_pixel_map :: proc(pixel_map: ^px.PixelMap, data: ^PainterData) {
  if len(data.updated) > 0 {
    data_wait = true
    sync.lock(&data_lock)
  }

  color : [1]px.Pixel
  color[0] = data.color

  for len(data.updated) > 0 {
    pos, ok := pop_safe(&data.updated)
    if ok {
      px.pixel_map_update_rect(pixel_map, cast(f32)pos.x, cast(f32)pos.y, 1, 1, color[:])
    }

    if (len(data.updated) == 0) {
      data_wait = false
      sync.cond_signal(&data_cond)
      sync.unlock(&data_lock)
    }
  }
}

painter_reset_canvas_update :: proc(painter: ^PainterData) {
  sync.lock(&data_lock)

  for pos in painter.canvas {
    painter.canvas[pos] = false 
  }

  sync.unlock(&data_lock)
}

painter_clear_pixel_map :: proc(pixel_map: ^px.PixelMap, painter: ^PainterData, clear_color: rl.Color) {
  sync.lock(&data_lock)
  defer sync.unlock(&data_lock)
 
  pixels: []px.Pixel = slice.clone(pixel_map.original[:painter.width*painter.height])
  for i in 0..<painter.width*painter.height {
    pixels[i] = { clear_color.r, clear_color.g, clear_color.b, clear_color.a }
  }
 
  px.pixel_map_update_rect(pixel_map, 0, 0, cast(f32)painter.width, cast(f32)painter.height, pixels[:])
  for pos in painter.canvas {
    painter.canvas[pos] = false 
  }
}

painter_reset_to_original :: proc(pixel_map: ^px.PixelMap, painter: ^PainterData) {
  sync.lock(&data_lock)
  defer sync.unlock(&data_lock)

  len := cast(int)(painter.width * painter.height)

  px.pixel_map_update_rect(pixel_map, 0, 0, cast(f32)painter.width, cast(f32)painter.height, pixel_map.original[:len])

  for pos in painter.canvas {
    painter.canvas[pos] = false 
  }
}

painter_worker :: proc(worker: ^thread.Thread) {
  tracy.SetThreadName("other_thread")

  for {
    data := cast(^PainterData)worker.data
    mouse_on_grid(data)
  }
}

painter_worker_create :: proc(data: ^PainterData) {
  painter_thread = thread.create(painter_worker)
  painter_thread.data = data
  thread.start(painter_thread)
}

painter_worker_destroy :: proc() {
  if !thread.is_done(painter_thread) {
    thread.terminate(painter_thread, 0)
  }
  thread.destroy(painter_thread)
}

painter_lock_canvas :: proc(lock: bool) {
  sync.lock(&data_lock) 

  lock_canvas = lock
  sync.cond_signal(&lock_canvas_cond)

  sync.unlock(&data_lock)
}

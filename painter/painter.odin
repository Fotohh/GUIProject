package painter

import tracy "../odin-tracy"
import rl "vendor:raylib"
import lin "core:math/linalg"

import "core:thread"
import "core:sync"
import "core:math"

import px "../pixel"

Canvas :: map[[2]i32]bool

@(private)
data_lock: sync.Mutex
@(private)
data_cond: sync.Cond
@(private)
data_wait: bool

@(private)
painter_thread: ^thread.Thread

PainterData :: struct {
  canvas: Canvas,
  width, height: i32,
  x0, y0, cxf, cyf: f32,
  camera: rl.Camera2D,
  updated: [dynamic][2]i32,
  color: []px.Pixel,
  radius: f32
}

bresenham_circle :: proc(data: ^PainterData, x_pos, y_pos: i32, radius: f32) {
  tracy.ZoneN("bresenham_circle")

  sync.lock(&data_lock)

  for data_wait do sync.cond_wait(&data_cond, &data_lock)

  for x := -radius; x < radius; x += 1 {
    hh := cast(i32)math.sqrt(cast(f32)(radius * radius - x * x))
    rx := (x_pos + cast(i32)x)
    ph := y_pos + hh
 
    for y := y_pos - hh; y < ph; y += 1 {
      pos := [2]i32 { rx, y }

      if pos.x > 0 && pos.x < data.width - 1 && pos.y > 0 && pos.y < data.height - 1 {
        if data.canvas[pos] == false do append(&data.updated, pos)
        data.canvas[pos] = true
      }
    } 
  }
 
  sync.unlock(&data_lock)
}
 
bresenham_line :: proc(data: ^PainterData, x1, y1: i32) { 
  tracy.ZoneNS("bresenham_line")   

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

  radius : f32 = data.radius
  half_radius : f32 = radius * 0.5

  bresenham_circle(data, x0, y0, radius)

  for i in 0..<math.abs(dx) - cast(i32)half_radius {
    if p < 0 {
      if !is_swapped {
        x0 += sx
        bresenham_circle(data, x0, y0, radius)
      } else {
        y0 += sy
        bresenham_circle(data, x0, y0, radius)
      }
      p = p + 2 * math.abs(dy)
    } else {
      x0 += sx
      y0 += sy

      bresenham_circle(data, x0, y0, radius)

      p = p + 2 * math.abs(dy) - 2 * math.abs(dx)
    }
  }

}

mouse_to_pixels :: proc(world_x, world_y, map_w, map_h: f32) -> (f32, f32) {
  return math.abs(-world_x - (map_w / 2)), math.abs(-world_y - (map_h / 2))
}

mouse_on_grid :: proc(
  data: ^PainterData
) {
  tracy.ZoneN("mouse_on_grid")
 
  mouse_position := rl.GetMousePosition()
  world := rl.GetScreenToWorld2D(mouse_position, data.camera)

  in_grid := rl.CheckCollisionPointRec(world, { -data.cxf, -data.cyf, cast(f32)data.width, cast(f32)data.height })

  mouse_delta_magnitude := lin.length2(rl.GetMouseDelta())
  is_mouse_same := data.x0 == 0 && data.y0 == 0

  should_move := mouse_delta_magnitude > 3.0 || is_mouse_same

  if rl.IsMouseButtonDown(rl.MouseButton.LEFT) && in_grid && should_move {
    world_after := rl.GetScreenToWorld2D(rl.GetMousePosition(), data.camera)

    red : [1*1]px.Pixel
    red[0] = { 0, 0, 0, 255 }

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
  } else if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
    data.x0, data.y0 = 0, 0
  } 
}

painter_update_pixel_map :: proc(pixel_map: ^px.PixelMap, data: ^PainterData) {
  if len(data.updated) > 0 {
    data_wait = true
    sync.lock(&data_lock)
  }
 
  for len(data.updated) > 0 {
    pos, ok := pop_safe(&data.updated)
    if ok {
      px.pixel_map_update_rect(pixel_map, cast(f32)pos.x, cast(f32)pos.y, 1, 1, data.color[:])
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

painter_clear_pixel_map :: proc(pixel_map: ^px.PixelMap, painter: ^PainterData) {
  sync.lock(&data_lock)
  defer sync.unlock(&data_lock)

  format := cast(i32)rl.PixelFormat.UNCOMPRESSED_R8G8B8A8
  pixels := cast([^]px.Pixel)rl.rlReadTexturePixels(pixel_map.texture.id, painter.width, painter.height, format)
  len := cast(int)(painter.width * painter.height)
  for i in 0..<len {
    pixels[i] = { 255, 255, 255, 255 }
  }
  px.pixel_map_update_rect(pixel_map, 0, 0, cast(f32)painter.width, cast(f32)painter.height, pixels[:len])
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

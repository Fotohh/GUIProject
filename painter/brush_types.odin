package painter

import "core:math"
import tracy "../odin-tracy"
import sync "core:sync"

BrushType :: enum {
  Circle,
  Box,
  Calligraphy
}

circle_brush :: proc(data: ^PainterData, x_pos, y_pos: i32) {
  tracy.ZoneN("bresenham_circle")

  radius := data.radius

  for x := -radius; x < radius; x += 1 {
    hh := cast(i32)math.sqrt(cast(f32)(radius * radius - x * x))
    rx := (x_pos + cast(i32)x)
    ph := y_pos + hh
 
    for y := y_pos - hh; y < ph; y += 1 {
      pos := [2]i32 { rx, y }

      if pos.x > 0 && pos.x < data.width - 1 && pos.y > 0 && pos.y < data.height - 1 {
        if data.canvas[pos] == false {
          append(&data.updated_buf, pos)
          append(&data.updated, pos)
        }
        data.canvas[pos] = true
      }
    } 
  } 
}

pixel_brush :: proc(data: ^PainterData, x_pos, y_pos: i32) {
  x_start := x_pos - cast(i32)data.radius
  y_start := y_pos - cast(i32)data.radius
  x_end := x_pos + cast(i32)data.radius
  y_end := y_pos + cast(i32)data.radius

  if data.radius == 1.0 {
    pos := [2] i32 { x_pos, y_pos }
    if pos.x > 0 && pos.x < data.width - 1 && pos.y > 0 && pos.y < data.height - 1 {
      if data.canvas[pos] == false {
        append(&data.updated_buf, pos)
        append(&data.updated, pos)
      }
      data.canvas[pos] = true
    }
    return
  }

  for x := x_start; x < x_end; x += 1 {
    for y := y_start; y < y_end; y += 1 {
      pos := [2] i32 { x, y }
      if pos.x > 0 && pos.x < data.width - 1 && pos.y > 0 && pos.y < data.height - 1 {
        if data.canvas[pos] == false {
          append(&data.updated_buf, pos)
          append(&data.updated, pos)
        }         
        data.canvas[pos] = true
      }
    }
  }
}

calligraphy :: proc(data: ^PainterData, x_pos, y_pos: i32) {

  div_factor : f32 = data.radius >= 5.0 ? 5.0 : 2.0

  x_start := x_pos - cast(i32)(data.radius / div_factor)
  y_start := y_pos - cast(i32)data.radius
  x_end := x_pos + cast(i32)(data.radius / div_factor)
  y_end := y_pos + cast(i32)data.radius

  if data.radius < 3.0 {
    x_end += 1
    y_end += 2
  }

  x_end = math.clamp(x_end, x_pos + 1, x_pos + 3)

  for x := x_start; x < x_end; x += 1 {
    for y := y_start; y < y_end; y += 1 {
      pos := [2] i32 { x, y }
      if pos.x > 0 && pos.x < data.width - 1 && pos.y > 0 && pos.y < data.height - 1 {
        if data.canvas[pos] == false {
          append(&data.updated_buf, pos)
          append(&data.updated, pos)
        }         
        data.canvas[pos] = true
      }
    }
  }
}

set_brush_type :: proc(data: ^PainterData, brush: proc(data: ^PainterData, x_pos, y_pos: i32)) {
  sync.lock(&data_lock)
  data.brush = brush
  sync.unlock(&data_lock)
}

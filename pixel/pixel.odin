package pixel

import rl "vendor:raylib"
import "core:mem"
import "core:fmt"

Pixel :: [4]u8

PixelMap :: struct {
  texture: rl.Texture2D,
  width, height: i32, //width and height of chunks not individual pixels
  original: [^]Pixel
}

pixel_map_create :: proc(width: i32, height: i32) -> (PixelMap, bool) {
  pixel_map : PixelMap

  if width < 16 || height < 16 {
    return pixel_map, false
  }
  
  pixel_map.width = width
  pixel_map.height = height

  data, alloc_err := mem.alloc_bytes(cast(int)(width * height) * 4)
  if alloc_err != mem.Allocator_Error.None {
    fmt.println("Unable to allocate pixel map data")
    return pixel_map, false
  }
  defer mem.free_bytes(data)

  mem.set(raw_data(data), 255, len(data))

  image : rl.Image
  image.width = width
  image.height = height
  image.mipmaps = 1
  image.format = rl.PixelFormat.UNCOMPRESSED_R8G8B8A8
  image.data = raw_data(data)

  rl.SetTextureFilter(pixel_map.texture, rl.TextureFilter.POINT)
  pixel_map.texture = rl.LoadTextureFromImage(image)

  format := cast(i32)rl.PixelFormat.UNCOMPRESSED_R8G8B8A8
  pixel_map.original = cast([^]Pixel)rl.rlReadTexturePixels(pixel_map.texture.id, pixel_map.width, pixel_map.height, format)
  
  return pixel_map, true
}

pixel_map_update_rect :: proc(pixel_map: ^PixelMap, x, y, w, h: f32, pixels: []Pixel) {
  rl.UpdateTextureRec(pixel_map.texture, rl.Rectangle { x, y, w, h }, raw_data(pixels))
}

pixel_map_destroy :: proc(pixel_map: ^PixelMap) {
  rl.UnloadTexture(pixel_map.texture)
  rl.MemFree(pixel_map.original)
}

package serialize
import rl "vendor:raylib"

load_texture :: proc(texture: rl.Texture2D, path:cstring) -> bool{
  image : rl.Image = rl.LoadImageFromTexture(texture)
  defer rl.UnloadImage(image)
  check : bool = rl.ExportImage(image, path)
  //beautiful
  return check
}

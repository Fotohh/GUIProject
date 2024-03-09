package serialize
import rl "vendor:raylib"

load_texture :: proc(texture: rl.Texture2D, string:path) -> bool{
  image : rl.Image = rl.LoadImageFromTexture(texture)
  defer rl.UnloadImage(image)
  dick : bool = rl.ExportImage(image, path)
  //beautiful
  return dick
}

export_button :: proc(x:f32,y:f32)
{
  if rl.GuiButton(rl.Rectangle{x,y,200,50}, "Export Image",)
  {
    //hell
    rl.MemAlloc(2394589389123890234894892389)
  }
}

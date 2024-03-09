package cmd

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

cmd_read_args :: proc() -> (i32, i32, bool, cstring) {
  if len(os.args) == 1 {
    fmt.println("Try 'sqr help'?")
    return 0, 0, false, ""
  }
  args := os.args[1:]
  if len(args) > 3 {
    fmt.println("Expected 3 arguments. Try 'sqr help'?")
    return 0, 0, false, ""
  } else if len(args) <= 2 {
    if args[0] == "help" {
      fmt.println("sqr width height <file_name>")
      fmt.println("Initializes the app with a [width]x[height] pixel grid.")
      fmt.println("Exports the file once finished using the file name provided.")
      fmt.println("Minimum size is 16x16 and maximum height is 1024x1024.")
    } else {
      fmt.println("Expected 3 arguments. Try 'sqr help'?")
    }
    return 0, 0, false, ""
  } 

  map_width, arg_1_ok := strconv.parse_int(args[0])
  if !arg_1_ok {
    fmt.println("Invalid width.")
    return 0, 0, false, ""
  }
  map_height, arg_2_ok := strconv.parse_int(args[1])
  if !arg_2_ok {
    fmt.println("Invalid height.")
    return 0, 0, false, ""
  }

  file_name_str := args[2]
  if !strings.has_suffix(args[2], ".png") {
    file_name_str = strings.join({ args[2], ".png" }, "")
  }

  file_name : cstring = strings.clone_to_cstring(file_name_str)

  if map_width > 1024 || map_height > 1024 || map_width < 16 || map_height < 16 {
    fmt.println("Map width and height must be between the range 16..1024")
    return 0, 0, false, ""
  }

  return cast(i32)map_width, cast(i32)map_height, true, file_name
}

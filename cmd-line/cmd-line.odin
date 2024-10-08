package cmd

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

cmd_read_args :: proc() -> (i32, i32, cstring, cstring, bool) {
  if len(os.args) == 1 {
    fmt.println("Try 'sqr help'?")
    return 0, 0,  "", "", false
  }
  args := os.args[1:]
  if len(args) > 3 {
    fmt.println("Expected at least 2 arguments. Try 'sqr help'?")
    return 0, 0, "", "", false
  } else if len(args) <= 2 {
    if args[0] == "help" {
      fmt.println("sqr width height <file_name>")
      fmt.println("Initializes the app with an empty [width]x[height] pixel grid.")
      fmt.println("Exports the file using the file name provided.")
      fmt.println("")
      fmt.println("To load a file:")
      fmt.println("sqr <save_file_name> <file_to_load>")
      fmt.println("<file_to_load>: Name of the file to load into pixel grid.")
      fmt.println("<save_file_name>: The file to export to.")
      fmt.println("")
      fmt.println("Minimum size is 16x16 and maximum height is 1024x1024.")
      return 0, 0, "", "", false
    }
    if len(args) == 1 {
      fmt.println("Expected at least 2 arguments. Try 'sqr help'?")
      return 0, 0, "", "", false
    }
  } 

  map_width, arg_1_ok := strconv.parse_int(args[0])
  if !arg_1_ok do map_width = 0
  map_height, arg_2_ok := strconv.parse_int(args[1])
  if !arg_2_ok do map_height = 0

  if !arg_1_ok && !arg_2_ok {
    file_name_str := args[0]
    if !strings.has_suffix(args[0], ".png") {
      file_name_str = strings.join({ args[0], ".png" }, "")
    }

    in_file_name_str := args[1]
    if !strings.has_suffix(args[1], ".png") {
      in_file_name_str = strings.join({ args[1], ".png" }, "")
    }

    out_file_name : cstring = strings.clone_to_cstring(file_name_str)
    in_file_name : cstring = len(in_file_name_str) > 0 ? strings.clone_to_cstring(in_file_name_str) : ""
    return 0, 0, out_file_name, in_file_name, true
  }

  if map_width > 1024 || map_height > 1024 || map_width < 16 || map_height < 16 {
    fmt.println("Map width and height must be between the range 16..1024")
    return 0, 0, "", "", false
  }

  if len(args) != 3 {
    fmt.println("Expected 3 arguments. Try 'sqr help'?")
    return 0, 0, "", "", false
  }

  file_name_str := args[2]
  if !strings.has_suffix(args[2], ".png") {
    file_name_str = strings.join({ args[2], ".png" }, "")
  } 

  return cast(i32)map_width, cast(i32)map_height, strings.clone_to_cstring(file_name_str), "", true
}

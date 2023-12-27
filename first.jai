#run {
  w := compiler_create_workspace("Game-of-Life");

  if !w {
    print("Failed to create workspace!\n");
  }

  bo := get_build_options(w);
  bo.output_executable_name = "game-of-life";

  import_path: [..]string;

  array_add(*import_path, .. bo.import_path);
  array_add(*import_path, "src/");

  bo.import_path = import_path;

  set_build_options(bo, w);
  add_build_file("src/game-of-life.jai", w);

  set_build_options_dc(.{do_output=false});
}

#import "Basic";
#import "Compiler";


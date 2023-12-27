#import "Basic";
#import "String";
#import "SDL";
#import "GL";

ENGINE_RUNNING := true;
WINDOW_WIDTH   : s32 = 640;
WINDOW_HEIGHT  : s32 = 480;

main :: () {
  print("Game of life! - programming etude.\n");
  defer print("All went well - goodbye.\n");

  SDL_Init(SDL_INIT_VIDEO);
  defer SDL_Quit();

  window := SDL_CreateWindow(
    "Game of life!",
    SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOWPOS_UNDEFINED,
    WINDOW_WIDTH,
    WINDOW_HEIGHT,
    SDL_WINDOW_OPENGL
  );

  if !window {
    print("Could not create window: %s\n", to_string(SDL_GetError()));
    return;
  }

  defer SDL_DestroyWindow(window);

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

  gl_context := SDL_GL_CreateContext(window);

  if !gl_context {
    print("Could not create OpenGL context: %s\n", to_string(SDL_GetError()));
    return;
  }

  gl_load(*gl, SDL_GL_GetProcAddress);
  using gl;

  print("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
  print("GL Version = %\n", to_string(glGetString(GL_VERSION)));

  while ENGINE_RUNNING {
    event : SDL_Event;
    while SDL_PollEvent(*event) {
      if event.type == {
        case SDL_QUIT; ENGINE_RUNNING = false;
        case SDL_KEYDOWN;
          if event.key.keysym.sym == SDLK_ESCAPE ENGINE_RUNNING = false;
        case SDL_WINDOWEVENT;
          if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
            WINDOW_WIDTH  = event.window.data1;
            WINDOW_HEIGHT = event.window.data2;
          }
        }
      }

    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    SDL_GL_SwapWindow(window);
  }

}

#import "Basic";
#import "String";
#import "SDL";
#import "GL";

ENGINE_RUNNING := true;
WINDOW_WIDTH   : s32 = 640;
WINDOW_HEIGHT  : s32 = 480;

/*
TRIANGLE_DATA := float.[
   -.5, -.5, 0.0, 1.0, 0.0, 0.0,
    .5, -.5, 0.0, 0.0, 1.0, 0.0,
   0.0,  .5, 0.0, 0.0, 0.0, 1.0
];
*/

/*
TRIANGLE_INDICES := float.[
  0, 1, 2,
];
*/

Triangle :: struct {
  triangle_verts := GLfloat.[
     -.5, -.5, 0.0,
      .5, -.5, 0.0,
     0.0,  .5, 0.0,
  ];

  triangle_colors := GLfloat.[
    1.0, 0.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 0.0, 1.0,
  ];
}

triangle: Triangle;

VERTEX_SHADER :: #string GLSL
  #version 460 core
  layout(location = 0) in vec3 vertexPosition_modelspace;

  out vec3 fragmentColor;

  void main() {
      gl_Position = vec4(vertexPosition_modelspace, 1);

      fragmentColor = vec3(1.0, 0.0, 0.0);
  }
GLSL

/*
// This is shader without camera
VERTEX_SHADER :: #string GLSL
  #version 460 core
  layout(location = 0) in vec3 vertexPosition_modelspace;
  layout(location = 1) in vec3 vertexColor;

  out vec3 fragmentColor;

  void main() {
      gl_Position = vec4(vertexPosition_modelspace, 1);

      fragmentColor = vertexColor;
  }
GLSL
*/

/*
// This is shader with camera
VERTEX_SHADER :: #string GLSL
  #version 460 core
  layout(location = 0) in vec3 vertexPosition_modelspace;
  layout(location = 1) in vec3 vertexColor;

  out vec3 fragmentColor;
  
  uniform mat4 u_view_projection;

  void main() {
      gl_Position = u_view_projection * vec4(vertexPosition_modelspace, 1);

      fragmentColor = vertexColor;
  }
GLSL
*/

FRAGMENT_SHADER  :: #string GLSL
  #version 460 core

  in vec3 fragmentColor;

  out vec3 color;

  void main() {
    color = fragmentColor;
  }
GLSL

render_triangle :: (vbo: GLuint, shader_program: GLuint) {
  glUseProgram(shader_program);

  glEnableVertexAttribArray(0);

  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0 );

  glDrawArrays(GL_TRIANGLES, 0, 3);

  glDisableVertexAttribArray(0);

  //glUseProgram(shader_program);

  // glBindVertexArray(vao);
  // glDrawArrays(GL_TRIANGLES, 0, 3);

  // glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, null);
}

create_triangle_buffers :: (triangle_verts : []float) -> GLuint {
  VBO : u32;


  glGenBuffers(1, *VBO);
  glBindBuffer(GL_ARRAY_BUFFER, VBO);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(triangle_verts)), triangle_verts.data, GL_STATIC_DRAW);

  print("Triangle data size: %\n", size_of(float) * triangle_verts.count);

  // Bind vertex data
  // glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(type_of(triangle_data)), null);
  // glEnableVertexAttribArray(0);

  // Bind fragment data
  /*
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * size_of(type_of(triangle_data)), cast(*void) (3 * size_of(type_of(triangle_data))));
  glEnableVertexAttribArray(1);
  */

  // glBindBuffer(GL_ARRAY_BUFFER, 0);
  // glBindVertexArray(0);

  // glDisableVertexAttribArray(0);
  // glDisableVertexAttribArray(1);

  return VBO;
}

load_shaders :: (vertex_shader : string, fragment_shader : string) -> GLuint {
  program_id : GLuint;
  shader_program : GLuint;
  vertex_shader_id : GLuint;
  fragment_shader_id : GLuint;
  result_vertex : GLint;
  result_fragment : GLint;
  result_program : GLint;
  info_log_length_vertex : s32;
  info_log_length_fragment : s32;
  info_log_length_program : s32;

  shader_program = glCreateProgram();
  vertex_shader_id = glCreateShader(GL_VERTEX_SHADER);
  fragment_shader_id = glCreateShader(GL_FRAGMENT_SHADER);

  glShaderSource(vertex_shader_id, 1, *to_c_string(vertex_shader), null);
  glCompileShader(vertex_shader_id);

  glGetShaderiv(vertex_shader_id, GL_COMPILE_STATUS, *result_vertex);
  glGetShaderiv(vertex_shader_id, GL_INFO_LOG_LENGTH, *info_log_length_vertex);

  // @TODO ragnar: add checking for errors
  if (info_log_length_vertex > 0) {
    vertex_shader_error_log : [512]u8;
    glGetShaderInfoLog(vertex_shader_id, cast(u32)info_log_length_vertex, null, cast(*GLchar) *vertex_shader_error_log);
    print("%\n", cast(string) vertex_shader_error_log);
  }

  glShaderSource(fragment_shader_id, 1, *to_c_string(fragment_shader), null);
  glCompileShader(fragment_shader_id);

  glGetShaderiv(fragment_shader_id, GL_COMPILE_STATUS, *result_fragment);
  glGetShaderiv(fragment_shader_id, GL_INFO_LOG_LENGTH, *info_log_length_fragment);

  // @TODO ragnar: add checking for errors
  if (info_log_length_fragment > 0) {
    fragment_shader_error_log : [512]u8;
    glGetShaderInfoLog(fragment_shader_id, cast(u32)info_log_length_fragment, null, cast(*GLchar) *fragment_shader_error_log);
    print("%\n", cast(string) fragment_shader_error_log);
  }

  // Creating and attaching compiled shaders to program
  program_id = glCreateProgram();
  glAttachShader(program_id, vertex_shader_id);
  glAttachShader(program_id, fragment_shader_id);
  glLinkProgram(program_id);

  glGetProgramiv(program_id, GL_LINK_STATUS, *result_program);
  glGetProgramiv(program_id, GL_INFO_LOG_LENGTH, *info_log_length_program);

  // @TODO ragnar: add checking for errors
  if (info_log_length_program > 0) {
    program_error_log : string;
    glGetProgramInfoLog(program_id, cast(u32)info_log_length_fragment, null, to_c_string(program_error_log));
    print("%\n", program_error_log);
  }

  // Now we can detach and delete shaders
  glDetachShader(program_id, vertex_shader_id);
  glDetachShader(program_id, fragment_shader_id);

  glDeleteShader(vertex_shader_id);
  glDeleteShader(fragment_shader_id);

  return program_id;
}

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

  glEnable(GL_DEPTH_TEST);

  print("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
  print("GL Version = %\n", to_string(glGetString(GL_VERSION)));

  shader_program := load_shaders(VERTEX_SHADER, FRAGMENT_SHADER);

  print("Shader program id = %\n", shader_program);

  VAO : GLuint;
  glGenVertexArrays(1, *VAO);
  glBindVertexArray(VAO);

  print("VAO = %\n", VAO);

  triangle_vbo := create_triangle_buffers(triangle.triangle_verts);

  print("Triangle VBO = %\n", triangle_vbo);

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

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glClearColor(0.2, 0.3, 0.1, 1.0);
    
    // Rendering triangle
    render_triangle(triangle_vbo, shader_program);

    SDL_GL_SwapWindow(window);
  }

  // Cleaning up Buffers and stuff
  glDeleteVertexArrays(1, *VAO);
  glDeleteBuffers(1, *triangle_vbo);
  glDeleteProgram(shader_program);
}

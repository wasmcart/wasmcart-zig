//! hello_gl - a GLES3 wasmcart cart in Zig.
//!
//! Sets gpu_api = GPU_API_WEBGL2, so the host builds a real GL context and
//! routes the "gl" import module to it. Compiles a shader pair, uploads a
//! triangle, and spins it. No framebuffer writes at all: the GL surface IS the
//! output for a gpu_api=1 cart.

const wc = @import("wasmcart");
const gl = wc.gl;

/// Report panics through wc_log and trap. Must be in the ROOT source file.
pub const panic = wc.panic;

const W = 640;
const H = 480;

const cart = wc.Cart(.{
    .width = W,
    .height = H,
    .gpu_api = wc.GPU_API_WEBGL2,
});

const vert_src: [*:0]const u8 =
    \\#version 300 es
    \\precision highp float;
    \\layout(location = 0) in vec2 a_pos;
    \\layout(location = 1) in vec3 a_color;
    \\uniform float u_angle;
    \\out vec3 v_color;
    \\void main() {
    \\  float c = cos(u_angle);
    \\  float s = sin(u_angle);
    \\  vec2 p = vec2(a_pos.x * c - a_pos.y * s, a_pos.x * s + a_pos.y * c);
    \\  gl_Position = vec4(p, 0.0, 1.0);
    \\  v_color = a_color;
    \\}
;

const frag_src: [*:0]const u8 =
    \\#version 300 es
    \\precision highp float;
    \\in vec3 v_color;
    \\out vec4 outColor;
    \\void main() { outColor = vec4(v_color, 1.0); }
;

// x, y, r, g, b per vertex.
const verts = [_]f32{
    0.0,  0.7,  1.0, 0.2, 0.2,
    -0.7, -0.6, 0.2, 1.0, 0.3,
    0.7,  -0.6, 0.3, 0.4, 1.0,
};

var program: gl.GLuint = 0;
var vbo: gl.GLuint = 0;
var vao: gl.GLuint = 0;
var u_angle: gl.GLint = -1;
var ready = false;

export fn wc_get_info() *wc.WcInfo {
    return cart.getInfo();
}

fn compile(kind: gl.GLenum, src: [*:0]const u8) gl.GLuint {
    const sh = gl.glCreateShader(kind);
    var srcs = [_][*]const u8{src};
    gl.glShaderSource(sh, 1, &srcs, null);
    gl.glCompileShader(sh);
    var status: gl.GLint = 0;
    gl.glGetShaderiv(sh, gl.COMPILE_STATUS, @ptrCast(&status));
    if (status == 0) {
        var log: [512]u8 = undefined;
        gl.glGetShaderInfoLog(sh, log.len, null, &log);
        wc.logStr("hello_gl: shader compile failed");
        wc.wc_log(&log, log.len);
    }
    return sh;
}

export fn wc_init() void {
    const vs = compile(gl.VERTEX_SHADER, vert_src);
    const fs = compile(gl.FRAGMENT_SHADER, frag_src);

    program = gl.glCreateProgram();
    gl.glAttachShader(program, vs);
    gl.glAttachShader(program, fs);
    gl.glLinkProgram(program);

    var status: gl.GLint = 0;
    gl.glGetProgramiv(program, gl.LINK_STATUS, @ptrCast(&status));
    if (status == 0) {
        var log: [512]u8 = undefined;
        gl.glGetProgramInfoLog(program, log.len, null, &log);
        wc.logStr("hello_gl: program link failed");
        wc.wc_log(&log, log.len);
        return;
    }
    gl.glDeleteShader(vs);
    gl.glDeleteShader(fs);

    u_angle = gl.glGetUniformLocation(program, "u_angle");

    gl.glGenVertexArrays(1, @ptrCast(&vao));
    gl.glBindVertexArray(vao);

    gl.glGenBuffers(1, @ptrCast(&vbo));
    gl.glBindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.glBufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(verts)), &verts, gl.STATIC_DRAW);

    const stride: gl.GLsizei = 5 * @sizeOf(f32);
    gl.glEnableVertexAttribArray(0);
    gl.glVertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, stride, @ptrFromInt(0));
    gl.glEnableVertexAttribArray(1);
    gl.glVertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, stride, @ptrFromInt(2 * @sizeOf(f32)));

    ready = true;
    wc.logStr("hello_gl: zig gl cart ready");
}

export fn wc_render() void {
    gl.glViewport(0, 0, W, H);
    gl.glClearColor(0.05, 0.07, 0.12, 1.0);
    gl.glClear(gl.COLOR_BUFFER_BIT);
    if (!ready) return;

    gl.glUseProgram(program);
    gl.glBindVertexArray(vao);
    // Rebind explicitly: a host whose VAO emulation is thin still draws.
    gl.glBindBuffer(gl.ARRAY_BUFFER, vbo);
    const stride: gl.GLsizei = 5 * @sizeOf(f32);
    gl.glEnableVertexAttribArray(0);
    gl.glVertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, stride, @ptrFromInt(0));
    gl.glEnableVertexAttribArray(1);
    gl.glVertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, stride, @ptrFromInt(2 * @sizeOf(f32)));

    if (u_angle >= 0) {
        const angle = @as(f32, @floatFromInt(cart.time.frame)) * 0.02;
        gl.glUniform1f(u_angle, angle);
    }
    gl.glDrawArrays(gl.TRIANGLES, 0, 3);
}

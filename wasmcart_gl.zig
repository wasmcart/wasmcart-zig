//! wasmcart_gl.zig - OpenGL ES 3.0 / WebGL2 bindings for wasmcart carts.
//!
//! Mirrors the `WC_USE_GL` half of `wasmcart.h`. Every function here is an
//! extern from the "gl" wasm import module, which the host routes to native
//! EGL+GLES3, ANGLE, or WebGL2. Set `gpu_api = wc.GPU_API_WEBGL2` in your info
//! struct so the host knows to make you a context.
//!
//! An UNCALLED extern is not emitted into the wasm binary, so `@import`ing this
//! namespace adds zero imports until you call something.
//!
//! Reached via `wasmcart.zig` as `wc.gl`; there is no need to import it directly.

// ── Types ────────────────────────────────────────────────────────────

pub const GLenum = u32;
pub const GLboolean = u8;
pub const GLbitfield = u32;
pub const GLint = i32;
pub const GLuint = u32;
pub const GLsizei = i32;
pub const GLfloat = f32;
pub const GLsizeiptr = i32; // wasm32: 4 bytes
pub const GLintptr = i32;

// ── Constants ────────────────────────────────────────────────────────

pub const FALSE: GLboolean = 0;
pub const TRUE: GLboolean = 1;
pub const NONE: GLenum = 0;

// Clear bits
pub const DEPTH_BUFFER_BIT: GLbitfield = 0x00000100;
pub const STENCIL_BUFFER_BIT: GLbitfield = 0x00000400;
pub const COLOR_BUFFER_BIT: GLbitfield = 0x00004000;

// Primitives
pub const POINTS: GLenum = 0x0000;
pub const LINES: GLenum = 0x0001;
pub const LINE_LOOP: GLenum = 0x0002;
pub const LINE_STRIP: GLenum = 0x0003;
pub const TRIANGLES: GLenum = 0x0004;
pub const TRIANGLE_STRIP: GLenum = 0x0005;
pub const TRIANGLE_FAN: GLenum = 0x0006;

// Data types
pub const BYTE: GLenum = 0x1400;
pub const UNSIGNED_BYTE: GLenum = 0x1401;
pub const SHORT: GLenum = 0x1402;
pub const UNSIGNED_SHORT: GLenum = 0x1403;
pub const INT: GLenum = 0x1404;
pub const UNSIGNED_INT: GLenum = 0x1405;
pub const FLOAT: GLenum = 0x1406;
pub const HALF_FLOAT: GLenum = 0x140B;

// Enable / Disable
pub const BLEND: GLenum = 0x0BE2;
pub const CULL_FACE: GLenum = 0x0B44;
pub const DEPTH_TEST: GLenum = 0x0B71;
pub const DITHER: GLenum = 0x0BD0;
pub const POLYGON_OFFSET_FILL: GLenum = 0x8037;
pub const SCISSOR_TEST: GLenum = 0x0C11;
pub const STENCIL_TEST: GLenum = 0x0B90;

// Blend factors
pub const ZERO: GLenum = 0;
pub const ONE: GLenum = 1;
pub const SRC_COLOR: GLenum = 0x0300;
pub const ONE_MINUS_SRC_COLOR: GLenum = 0x0301;
pub const SRC_ALPHA: GLenum = 0x0302;
pub const ONE_MINUS_SRC_ALPHA: GLenum = 0x0303;
pub const DST_ALPHA: GLenum = 0x0304;
pub const ONE_MINUS_DST_ALPHA: GLenum = 0x0305;
pub const DST_COLOR: GLenum = 0x0306;
pub const ONE_MINUS_DST_COLOR: GLenum = 0x0307;

// Blend equations
pub const FUNC_ADD: GLenum = 0x8006;
pub const FUNC_SUBTRACT: GLenum = 0x800A;
pub const FUNC_REVERSE_SUBTRACT: GLenum = 0x800B;

// Depth / stencil funcs and ops
pub const NEVER: GLenum = 0x0200;
pub const LESS: GLenum = 0x0201;
pub const EQUAL: GLenum = 0x0202;
pub const LEQUAL: GLenum = 0x0203;
pub const GREATER: GLenum = 0x0204;
pub const NOTEQUAL: GLenum = 0x0205;
pub const GEQUAL: GLenum = 0x0206;
pub const ALWAYS: GLenum = 0x0207;
pub const KEEP: GLenum = 0x1E00;
pub const REPLACE: GLenum = 0x1E01;
pub const INCR: GLenum = 0x1E02;
pub const DECR: GLenum = 0x1E03;
pub const INCR_WRAP: GLenum = 0x8507;
pub const DECR_WRAP: GLenum = 0x8508;
pub const INVERT: GLenum = 0x150A;

// Culling
pub const FRONT: GLenum = 0x0404;
pub const BACK: GLenum = 0x0405;
pub const FRONT_AND_BACK: GLenum = 0x0408;
pub const CW: GLenum = 0x0900;
pub const CCW: GLenum = 0x0901;

// Buffers
pub const ARRAY_BUFFER: GLenum = 0x8892;
pub const ELEMENT_ARRAY_BUFFER: GLenum = 0x8893;
pub const STATIC_DRAW: GLenum = 0x88E4;
pub const DYNAMIC_DRAW: GLenum = 0x88E8;
pub const STREAM_DRAW: GLenum = 0x88E0;

// Textures
pub const TEXTURE_2D: GLenum = 0x0DE1;
pub const TEXTURE_CUBE_MAP: GLenum = 0x8513;
pub const TEXTURE_MIN_FILTER: GLenum = 0x2801;
pub const TEXTURE_MAG_FILTER: GLenum = 0x2800;
pub const TEXTURE_WRAP_S: GLenum = 0x2802;
pub const TEXTURE_WRAP_T: GLenum = 0x2803;
pub const NEAREST: GLenum = 0x2600;
pub const LINEAR: GLenum = 0x2601;
pub const NEAREST_MIPMAP_NEAREST: GLenum = 0x2700;
pub const LINEAR_MIPMAP_NEAREST: GLenum = 0x2701;
pub const NEAREST_MIPMAP_LINEAR: GLenum = 0x2702;
pub const LINEAR_MIPMAP_LINEAR: GLenum = 0x2703;
pub const CLAMP_TO_EDGE: GLenum = 0x812F;
pub const REPEAT: GLenum = 0x2901;
pub const MIRRORED_REPEAT: GLenum = 0x8370;
pub const TEXTURE0: GLenum = 0x84C0;

// Pixel formats
pub const ALPHA: GLenum = 0x1906;
pub const RGB: GLenum = 0x1907;
pub const RGBA: GLenum = 0x1908;
pub const LUMINANCE: GLenum = 0x1909;
pub const LUMINANCE_ALPHA: GLenum = 0x190A;
pub const RED: GLenum = 0x1903;
pub const RG: GLenum = 0x8227;
pub const R8: GLenum = 0x8229;
pub const RG8: GLenum = 0x822B;
pub const RGB8: GLenum = 0x8051;
pub const RGBA8: GLenum = 0x8058;

// Shaders
pub const VERTEX_SHADER: GLenum = 0x8B31;
pub const FRAGMENT_SHADER: GLenum = 0x8B30;
pub const COMPILE_STATUS: GLenum = 0x8B81;
pub const LINK_STATUS: GLenum = 0x8B82;
pub const VALIDATE_STATUS: GLenum = 0x8B83;
pub const INFO_LOG_LENGTH: GLenum = 0x8B84;

// Framebuffers
pub const FRAMEBUFFER: GLenum = 0x8D40;
pub const READ_FRAMEBUFFER: GLenum = 0x8CA8;
pub const DRAW_FRAMEBUFFER: GLenum = 0x8CA9;
pub const RENDERBUFFER: GLenum = 0x8D41;
pub const COLOR_ATTACHMENT0: GLenum = 0x8CE0;
pub const DEPTH_ATTACHMENT: GLenum = 0x8D00;
pub const STENCIL_ATTACHMENT: GLenum = 0x8D20;
pub const DEPTH_STENCIL_ATTACHMENT: GLenum = 0x821A;
pub const FRAMEBUFFER_COMPLETE: GLenum = 0x8CD5;
pub const DEPTH_COMPONENT16: GLenum = 0x81A5;
pub const DEPTH_COMPONENT24: GLenum = 0x81A6;
pub const DEPTH24_STENCIL8: GLenum = 0x88F0;

// GetString
pub const VENDOR: GLenum = 0x1F00;
pub const RENDERER: GLenum = 0x1F01;
pub const VERSION: GLenum = 0x1F02;

pub const NO_ERROR: GLenum = 0;

// ── Functions ────────────────────────────────────────────────────────
//
// Names keep the `gl` prefix so they read the same as the C header and every
// GLES reference page: `wc.gl.glClear(...)`.

// State
pub extern "gl" fn glEnable(cap: GLenum) void;
pub extern "gl" fn glDisable(cap: GLenum) void;
pub extern "gl" fn glGetError() GLenum;
pub extern "gl" fn glFinish() void;
pub extern "gl" fn glFlush() void;
pub extern "gl" fn glHint(target: GLenum, mode: GLenum) void;
pub extern "gl" fn glPixelStorei(pname: GLenum, param: GLint) void;
pub extern "gl" fn glGetIntegerv(pname: GLenum, data: [*]GLint) void;
pub extern "gl" fn glGetString(name: GLenum) ?[*:0]const u8;

// Viewport / clear
pub extern "gl" fn glViewport(x: GLint, y: GLint, w: GLsizei, h: GLsizei) void;
pub extern "gl" fn glScissor(x: GLint, y: GLint, w: GLsizei, h: GLsizei) void;
pub extern "gl" fn glClear(mask: GLbitfield) void;
pub extern "gl" fn glClearColor(r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat) void;
pub extern "gl" fn glClearDepthf(d: GLfloat) void;
pub extern "gl" fn glClearStencil(s: GLint) void;

// Blending
pub extern "gl" fn glBlendFunc(sfactor: GLenum, dfactor: GLenum) void;
pub extern "gl" fn glBlendFuncSeparate(srcRGB: GLenum, dstRGB: GLenum, srcA: GLenum, dstA: GLenum) void;
pub extern "gl" fn glBlendEquation(mode: GLenum) void;
pub extern "gl" fn glBlendEquationSeparate(modeRGB: GLenum, modeAlpha: GLenum) void;
pub extern "gl" fn glBlendColor(r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat) void;
pub extern "gl" fn glColorMask(r: GLboolean, g: GLboolean, b: GLboolean, a: GLboolean) void;

// Depth / stencil
pub extern "gl" fn glDepthFunc(func: GLenum) void;
pub extern "gl" fn glDepthMask(flag: GLboolean) void;
pub extern "gl" fn glDepthRangef(n: GLfloat, f: GLfloat) void;
pub extern "gl" fn glStencilFunc(func: GLenum, ref: GLint, mask: GLuint) void;
pub extern "gl" fn glStencilFuncSeparate(face: GLenum, func: GLenum, ref: GLint, mask: GLuint) void;
pub extern "gl" fn glStencilOp(sfail: GLenum, zfail: GLenum, zpass: GLenum) void;
pub extern "gl" fn glStencilOpSeparate(face: GLenum, sfail: GLenum, dpfail: GLenum, dppass: GLenum) void;
pub extern "gl" fn glStencilMask(mask: GLuint) void;
pub extern "gl" fn glStencilMaskSeparate(face: GLenum, mask: GLuint) void;

// Culling
pub extern "gl" fn glCullFace(mode: GLenum) void;
pub extern "gl" fn glFrontFace(mode: GLenum) void;
pub extern "gl" fn glPolygonOffset(factor: GLfloat, units: GLfloat) void;
pub extern "gl" fn glLineWidth(width: GLfloat) void;

// Buffers
pub extern "gl" fn glGenBuffers(n: GLsizei, buffers: [*]GLuint) void;
pub extern "gl" fn glDeleteBuffers(n: GLsizei, buffers: [*]const GLuint) void;
pub extern "gl" fn glBindBuffer(target: GLenum, buffer: GLuint) void;
pub extern "gl" fn glBufferData(target: GLenum, size: GLsizeiptr, data: ?*const anyopaque, usage: GLenum) void;
pub extern "gl" fn glBufferSubData(target: GLenum, offset: GLintptr, size: GLsizeiptr, data: ?*const anyopaque) void;

// Textures
pub extern "gl" fn glGenTextures(n: GLsizei, textures: [*]GLuint) void;
pub extern "gl" fn glDeleteTextures(n: GLsizei, textures: [*]const GLuint) void;
pub extern "gl" fn glBindTexture(target: GLenum, texture: GLuint) void;
pub extern "gl" fn glActiveTexture(texture: GLenum) void;
pub extern "gl" fn glTexImage2D(target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, type: GLenum, pixels: ?*const anyopaque) void;
pub extern "gl" fn glTexSubImage2D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, type: GLenum, pixels: ?*const anyopaque) void;
pub extern "gl" fn glTexParameteri(target: GLenum, pname: GLenum, param: GLint) void;
pub extern "gl" fn glTexParameterf(target: GLenum, pname: GLenum, param: GLfloat) void;
pub extern "gl" fn glGenerateMipmap(target: GLenum) void;
pub extern "gl" fn glCompressedTexImage2D(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, data: ?*const anyopaque) void;

// Shaders
pub extern "gl" fn glCreateShader(type: GLenum) GLuint;
pub extern "gl" fn glDeleteShader(shader: GLuint) void;
pub extern "gl" fn glShaderSource(shader: GLuint, count: GLsizei, string: [*]const [*]const u8, length: ?[*]const GLint) void;
pub extern "gl" fn glCompileShader(shader: GLuint) void;
pub extern "gl" fn glGetShaderiv(shader: GLuint, pname: GLenum, params: [*]GLint) void;
pub extern "gl" fn glGetShaderInfoLog(shader: GLuint, bufSize: GLsizei, length: ?[*]GLsizei, infoLog: [*]u8) void;

// Programs
pub extern "gl" fn glCreateProgram() GLuint;
pub extern "gl" fn glDeleteProgram(program: GLuint) void;
pub extern "gl" fn glAttachShader(program: GLuint, shader: GLuint) void;
pub extern "gl" fn glDetachShader(program: GLuint, shader: GLuint) void;
pub extern "gl" fn glLinkProgram(program: GLuint) void;
pub extern "gl" fn glUseProgram(program: GLuint) void;
pub extern "gl" fn glGetProgramiv(program: GLuint, pname: GLenum, params: [*]GLint) void;
pub extern "gl" fn glGetProgramInfoLog(program: GLuint, bufSize: GLsizei, length: ?[*]GLsizei, infoLog: [*]u8) void;
pub extern "gl" fn glValidateProgram(program: GLuint) void;
pub extern "gl" fn glBindAttribLocation(program: GLuint, index: GLuint, name: [*:0]const u8) void;
pub extern "gl" fn glGetAttribLocation(program: GLuint, name: [*:0]const u8) GLint;
pub extern "gl" fn glGetUniformLocation(program: GLuint, name: [*:0]const u8) GLint;
pub extern "gl" fn glGetActiveAttrib(program: GLuint, index: GLuint, bufSize: GLsizei, length: ?[*]GLsizei, size: [*]GLint, type: [*]GLenum, name: [*]u8) void;
pub extern "gl" fn glGetActiveUniform(program: GLuint, index: GLuint, bufSize: GLsizei, length: ?[*]GLsizei, size: [*]GLint, type: [*]GLenum, name: [*]u8) void;

// Uniforms
pub extern "gl" fn glUniform1i(location: GLint, v0: GLint) void;
pub extern "gl" fn glUniform2i(location: GLint, v0: GLint, v1: GLint) void;
pub extern "gl" fn glUniform3i(location: GLint, v0: GLint, v1: GLint, v2: GLint) void;
pub extern "gl" fn glUniform4i(location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint) void;
pub extern "gl" fn glUniform1f(location: GLint, v0: GLfloat) void;
pub extern "gl" fn glUniform2f(location: GLint, v0: GLfloat, v1: GLfloat) void;
pub extern "gl" fn glUniform3f(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat) void;
pub extern "gl" fn glUniform4f(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat) void;
pub extern "gl" fn glUniform1iv(location: GLint, count: GLsizei, value: [*]const GLint) void;
pub extern "gl" fn glUniform2iv(location: GLint, count: GLsizei, value: [*]const GLint) void;
pub extern "gl" fn glUniform3iv(location: GLint, count: GLsizei, value: [*]const GLint) void;
pub extern "gl" fn glUniform4iv(location: GLint, count: GLsizei, value: [*]const GLint) void;
pub extern "gl" fn glUniform1fv(location: GLint, count: GLsizei, value: [*]const GLfloat) void;
pub extern "gl" fn glUniform2fv(location: GLint, count: GLsizei, value: [*]const GLfloat) void;
pub extern "gl" fn glUniform3fv(location: GLint, count: GLsizei, value: [*]const GLfloat) void;
pub extern "gl" fn glUniform4fv(location: GLint, count: GLsizei, value: [*]const GLfloat) void;
pub extern "gl" fn glUniformMatrix2fv(location: GLint, count: GLsizei, transpose: GLboolean, value: [*]const GLfloat) void;
pub extern "gl" fn glUniformMatrix3fv(location: GLint, count: GLsizei, transpose: GLboolean, value: [*]const GLfloat) void;
pub extern "gl" fn glUniformMatrix4fv(location: GLint, count: GLsizei, transpose: GLboolean, value: [*]const GLfloat) void;

// Vertex attribs
pub extern "gl" fn glEnableVertexAttribArray(index: GLuint) void;
pub extern "gl" fn glDisableVertexAttribArray(index: GLuint) void;
pub extern "gl" fn glVertexAttribPointer(index: GLuint, size: GLint, type: GLenum, normalized: GLboolean, stride: GLsizei, pointer: ?*const anyopaque) void;

// Drawing
pub extern "gl" fn glDrawArrays(mode: GLenum, first: GLint, count: GLsizei) void;
pub extern "gl" fn glDrawElements(mode: GLenum, count: GLsizei, type: GLenum, indices: ?*const anyopaque) void;

// FBOs
pub extern "gl" fn glGenFramebuffers(n: GLsizei, framebuffers: [*]GLuint) void;
pub extern "gl" fn glDeleteFramebuffers(n: GLsizei, framebuffers: [*]const GLuint) void;
pub extern "gl" fn glBindFramebuffer(target: GLenum, framebuffer: GLuint) void;
pub extern "gl" fn glCheckFramebufferStatus(target: GLenum) GLenum;
pub extern "gl" fn glFramebufferTexture2D(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) void;
pub extern "gl" fn glFramebufferRenderbuffer(target: GLenum, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint) void;

// RBOs
pub extern "gl" fn glGenRenderbuffers(n: GLsizei, renderbuffers: [*]GLuint) void;
pub extern "gl" fn glDeleteRenderbuffers(n: GLsizei, renderbuffers: [*]const GLuint) void;
pub extern "gl" fn glBindRenderbuffer(target: GLenum, renderbuffer: GLuint) void;
pub extern "gl" fn glRenderbufferStorage(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei) void;

// Readback
pub extern "gl" fn glReadPixels(x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, type: GLenum, pixels: ?*anyopaque) void;

// ES3 / VAO / instancing
pub extern "gl" fn glGenVertexArrays(n: GLsizei, arrays: [*]GLuint) void;
pub extern "gl" fn glDeleteVertexArrays(n: GLsizei, arrays: [*]const GLuint) void;
pub extern "gl" fn glBindVertexArray(array: GLuint) void;
pub extern "gl" fn glDrawArraysInstanced(mode: GLenum, first: GLint, count: GLsizei, instancecount: GLsizei) void;
pub extern "gl" fn glDrawElementsInstanced(mode: GLenum, count: GLsizei, type: GLenum, indices: ?*const anyopaque, instancecount: GLsizei) void;
pub extern "gl" fn glVertexAttribDivisor(index: GLuint, divisor: GLuint) void;
pub extern "gl" fn glDrawBuffers(n: GLsizei, bufs: [*]const GLenum) void;

// UBOs / storage
pub extern "gl" fn glBindBufferBase(target: GLenum, index: GLuint, buffer: GLuint) void;
pub extern "gl" fn glBindBufferRange(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr, size: GLsizeiptr) void;
pub extern "gl" fn glGetUniformBlockIndex(program: GLuint, uniformBlockName: [*:0]const u8) GLuint;
pub extern "gl" fn glUniformBlockBinding(program: GLuint, uniformBlockIndex: GLuint, uniformBlockBinding: GLuint) void;
pub extern "gl" fn glTexStorage2D(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) void;

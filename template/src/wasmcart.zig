//! wasmcart.zig - Zig bindings for the wasmcart ABI (version 3).
//!
//! Mirrors `wasmcart.h` and `wc_cart.h` from the wasmcart repo. This file is
//! self-contained: copy it next to your cart source and `@import("wasmcart.zig")`.
//! It has no dependency on the Zig standard library, so it works on
//! `wasm32-freestanding` with no runtime at all.
//!
//! A cart must export three functions:
//!
//!     export fn wc_get_info() *wc.WcInfo   // pointer to a LIVE struct
//!     export fn wc_init() void
//!     export fn wc_render() void
//!
//! `Cart()` below declares every buffer the ABI expects and fills the info
//! struct for you, so a cart body is only the three exports plus your game.
//!
//! Build (see README for the build.zig route):
//!
//!     zig build-exe cart.zig -target wasm32-freestanding \
//!         -fno-entry -rdynamic -O ReleaseSmall
//!
//! `-rdynamic` is what surfaces `export fn` symbols in the wasm export
//! section. Without it the module links but has no exports and the host
//! rejects it with "Cart must export wc_render".

// ── Panic handler ────────────────────────────────────────────────────
//
// Zig's DEFAULT panic handler formats a message, which pulls in std.fmt and
// std.io. On wasm32-freestanding that is ~11 KB of dead weight in a cart that
// can never print anywhere. `panic` below reports the message through wc_log
// (which a debug-capable host captures, so a trapping cart says WHY instead of
// dying silently) and then traps.
//
// Opt in from your cart's root source file with one line:
//
//     pub const panic = @import("wasmcart").panic;
//
// It has to live in YOUR file because Zig only looks for `panic` in the root
// module. Without it a cart still works; it is just bigger and quieter.

pub const panic = struct {
    pub fn call(msg: []const u8, ret_addr: ?usize) noreturn {
        @branchHint(.cold);
        _ = ret_addr;
        wc_log(msg.ptr, @intCast(msg.len));
        @trap();
    }
    pub fn sentinelMismatch(_: anytype, _: anytype) noreturn {
        call("sentinel mismatch", null);
    }
    pub fn unwrapError(_: anyerror) noreturn {
        call("attempt to unwrap error", null);
    }
    pub fn outOfBounds(_: usize, _: usize) noreturn {
        call("index out of bounds", null);
    }
    pub fn startGreaterThanEnd(_: usize, _: usize) noreturn {
        call("start index is larger than end index", null);
    }
    pub fn inactiveUnionField(_: anytype, _: anytype) noreturn {
        call("access of inactive union field", null);
    }
    pub fn sliceCastLenRemainder(_: usize) noreturn {
        call("slice length has leftover bytes", null);
    }
    pub fn reachedUnreachable() noreturn {
        call("reached unreachable code", null);
    }
    pub fn unwrapNull() noreturn {
        call("attempt to use null value", null);
    }
    pub fn castToNull() noreturn {
        call("cast causes pointer to be null", null);
    }
    pub fn incorrectAlignment() noreturn {
        call("incorrect alignment", null);
    }
    pub fn invalidErrorCode() noreturn {
        call("invalid error code", null);
    }
    pub fn integerOutOfBounds() noreturn {
        call("integer does not fit in destination type", null);
    }
    pub fn integerOverflow() noreturn {
        call("integer overflow", null);
    }
    pub fn shlOverflow() noreturn {
        call("left shift overflowed bits", null);
    }
    pub fn shrOverflow() noreturn {
        call("right shift overflowed bits", null);
    }
    pub fn divideByZero() noreturn {
        call("division by zero", null);
    }
    pub fn exactDivisionRemainder() noreturn {
        call("exact division produced remainder", null);
    }
    pub fn integerPartOutOfBounds() noreturn {
        call("integer part of floating point value out of bounds", null);
    }
    pub fn corruptSwitch() noreturn {
        call("switch on corrupt value", null);
    }
    pub fn shiftRhsTooBig() noreturn {
        call("shift amount is greater than the type size", null);
    }
    pub fn invalidEnumValue() noreturn {
        call("invalid enum value", null);
    }
    pub fn forLenMismatch() noreturn {
        call("for loop over objects with non-equal lengths", null);
    }
    pub fn copyLenMismatch() noreturn {
        call("source and destination arguments have non-equal lengths", null);
    }
    pub fn memcpyAlias() noreturn {
        call("@memcpy arguments alias", null);
    }
    pub fn noreturnReturned() noreturn {
        call("'noreturn' function returned", null);
    }
};

// ── ABI version ──────────────────────────────────────────────────────

pub const ABI_VERSION: u32 = 3;

// ── Buttons (wc_pad_t.buttons bitmask) ───────────────────────────────

pub const BTN_A: u16 = 1 << 0;
pub const BTN_B: u16 = 1 << 1;
pub const BTN_X: u16 = 1 << 2;
pub const BTN_Y: u16 = 1 << 3;
pub const BTN_L: u16 = 1 << 4;
pub const BTN_R: u16 = 1 << 5;
pub const BTN_START: u16 = 1 << 6;
pub const BTN_SELECT: u16 = 1 << 7;
pub const BTN_UP: u16 = 1 << 8;
pub const BTN_DOWN: u16 = 1 << 9;
pub const BTN_LEFT: u16 = 1 << 10;
pub const BTN_RIGHT: u16 = 1 << 11;
pub const BTN_L3: u16 = 1 << 12;
pub const BTN_R3: u16 = 1 << 13;

// ── Cart info flags (WcInfo.flags) ───────────────────────────────────

pub const FLAG_AUDIO_F32: u32 = 1 << 0; // audio ring is f32 (default here)
pub const FLAG_NET_WS: u32 = 1 << 1; // cart wants WebSocket imports
pub const FLAG_NET_DC: u32 = 1 << 2; // cart wants data-channel imports
pub const FLAG_POINTER: u32 = 1 << 3; // cart wants pointer input
pub const FLAG_KEYBOARD: u32 = 1 << 4; // cart wants raw keyboard input
pub const FLAG_DEBUG: u32 = 1 << 5; // cart exports wc_debug_state()
pub const FLAG_DETERMINISTIC: u32 = 1 << 6; // cart honors deterministic mode

// ── Host-info flags (WcHostInfo.flags, host writes before wc_init) ───

pub const HOST_FLAG_DETERMINISTIC: u32 = 1 << 0;

// ── GPU API selector (WcInfo.gpu_api) ────────────────────────────────

pub const GPU_API_NONE: u32 = 0; // 2D framebuffer only
pub const GPU_API_WEBGL2: u32 = 1; // WebGL2 / GLES3 via the "gl" import module
pub const GPU_API_WEBGPU: u32 = 2; // reserved
pub const GPU_API_VULKAN: u32 = 3; // reserved

// ── Structs ──────────────────────────────────────────────────────────

/// 16 bytes. One connected gamepad. The host writes this before wc_render.
pub const WcPad = extern struct {
    buttons: u16 = 0,
    left_x: i16 = 0,
    left_y: i16 = 0,
    right_x: i16 = 0,
    right_y: i16 = 0,
    left_trigger: u8 = 0,
    right_trigger: u8 = 0,
    connected: u8 = 0,
    _pad: [3]u8 = .{ 0, 0, 0 },

    /// True if `mask` (one of the BTN_* constants, or an OR of several) is held.
    pub inline fn down(self: WcPad, mask: u16) bool {
        return (self.buttons & mask) != 0;
    }
};

/// 20 bytes, 8-byte aligned. The host writes this before every wc_render.
pub const WcTime = extern struct {
    time_ms: f64 = 0,
    delta_ms: f64 = 0,
    frame: u32 = 0,
};

/// 20 bytes. The host writes this ONCE, before wc_init. Read it in wc_init to
/// adapt your resolution; do not read it per frame.
pub const WcHostInfo = extern struct {
    preferred_width: u32 = 0, // 0 = no preference
    preferred_height: u32 = 0, // 0 = no preference
    _reserved0: u32 = 0, // was host_fps; use WcTime.delta_ms instead
    audio_sample_rate: u32 = 0,
    flags: u32 = 0,
};

/// 8 bytes. Unified mouse/touch pointer. Only populated if you set FLAG_POINTER.
pub const WcPointer = extern struct {
    x: i16 = 0,
    y: i16 = 0,
    buttons: u8 = 0, // bit0 primary, bit1 secondary, bit2 middle
    active: u8 = 0, // 1 if this pointer exists
    _pad: [2]u8 = .{ 0, 0 },
};

/// 68 bytes, seventeen u32 fields. The ORDER IS LOAD-BEARING: the host reads
/// this by byte offset. `wc_get_info` must return a pointer to a live instance
/// of this (not a copy) because the host re-reads it after wc_init.
pub const WcInfo = extern struct {
    version: u32 = ABI_VERSION,
    width: u32 = 0,
    height: u32 = 0,
    fb_ptr: u32 = 0,
    audio_ptr: u32 = 0,
    audio_cap: u32 = 0, // capacity in STEREO FRAMES, not samples
    audio_write_ptr: u32 = 0, // points at a u32 write cursor in cart memory
    input_ptr: u32 = 0, // -> WcPad[4]
    save_ptr: u32 = 0,
    save_size: u32 = 0,
    time_ptr: u32 = 0, // -> WcTime
    host_info_ptr: u32 = 0, // -> WcHostInfo
    flags: u32 = 0,
    audio_sample_rate: u32 = 0, // 0 = let the host decide
    pointer_ptr: u32 = 0, // -> WcPointer[10], 0 = unused
    keys_ptr: u32 = 0, // -> [32]u8 key bitmask, 0 = unused
    gpu_api: u32 = GPU_API_NONE,
};

/// 16 bytes. One entry in the OPTIONAL debug field table (see FLAG_DEBUG).
pub const WcDebugField = extern struct {
    name_ptr: u32 = 0, // NUL-terminated name; 0 terminates the table
    value_ptr: u32 = 0,
    type: u8 = 0,
    _pad: [3]u8 = .{ 0, 0, 0 },
    len: u32 = 0, // element count (scalar = 1)
};

pub const DBG_U8: u8 = 0;
pub const DBG_I8: u8 = 1;
pub const DBG_U16: u8 = 2;
pub const DBG_I16: u8 = 3;
pub const DBG_U32: u8 = 4;
pub const DBG_I32: u8 = 5;
pub const DBG_F32: u8 = 6;
pub const DBG_F64: u8 = 7;
pub const DBG_BYTES: u8 = 8;

// ── Sizes (compile-time checked against the spec below) ──────────────

pub const PAD_SIZE = 16;
pub const MAX_PADS = 4;
pub const TIME_SIZE = 20;
pub const HOST_INFO_SIZE = 20;
pub const INFO_SIZE = 68;
pub const POINTER_SIZE = 8;
pub const MAX_POINTERS = 10;
pub const KEYS_SIZE = 32;
pub const DEBUG_FIELD_SIZE = 16;
pub const MAX_RUMBLE_MS: u32 = 5000;

comptime {
    if (@sizeOf(WcPad) != PAD_SIZE) @compileError("WcPad must be 16 bytes");
    if (@sizeOf(WcTime) != TIME_SIZE + 4) {
        // wc_time_t is 20 bytes of DATA but 8-byte aligned, so Zig's @sizeOf
        // rounds to 24. Only the first 20 bytes are read by the host, and the
        // struct is never arrayed, so this is fine -- but assert the field
        // offsets so a reordering is caught.
        @compileError("WcTime layout changed unexpectedly");
    }
    if (@offsetOf(WcTime, "time_ms") != 0) @compileError("WcTime.time_ms must be at 0");
    if (@offsetOf(WcTime, "delta_ms") != 8) @compileError("WcTime.delta_ms must be at 8");
    if (@offsetOf(WcTime, "frame") != 16) @compileError("WcTime.frame must be at 16");
    if (@sizeOf(WcHostInfo) != HOST_INFO_SIZE) @compileError("WcHostInfo must be 20 bytes");
    if (@sizeOf(WcPointer) != POINTER_SIZE) @compileError("WcPointer must be 8 bytes");
    if (@sizeOf(WcInfo) != INFO_SIZE) @compileError("WcInfo must be 68 bytes");
    if (@sizeOf(WcDebugField) != DEBUG_FIELD_SIZE) @compileError("WcDebugField must be 16 bytes");
    // The v3 tail is the part hand-written bindings get wrong. Pin it.
    if (@offsetOf(WcInfo, "pointer_ptr") != 56) @compileError("WcInfo.pointer_ptr must be at 56");
    if (@offsetOf(WcInfo, "keys_ptr") != 60) @compileError("WcInfo.keys_ptr must be at 60");
    if (@offsetOf(WcInfo, "gpu_api") != 64) @compileError("WcInfo.gpu_api must be at 64");
}

// ── Keyboard scancodes (USB HID) ─────────────────────────────────────

pub const KEY_A: u8 = 0x04;
pub const KEY_B: u8 = 0x05;
pub const KEY_C: u8 = 0x06;
pub const KEY_D: u8 = 0x07;
pub const KEY_E: u8 = 0x08;
pub const KEY_F: u8 = 0x09;
pub const KEY_G: u8 = 0x0A;
pub const KEY_H: u8 = 0x0B;
pub const KEY_I: u8 = 0x0C;
pub const KEY_J: u8 = 0x0D;
pub const KEY_K: u8 = 0x0E;
pub const KEY_L: u8 = 0x0F;
pub const KEY_M: u8 = 0x10;
pub const KEY_N: u8 = 0x11;
pub const KEY_O: u8 = 0x12;
pub const KEY_P: u8 = 0x13;
pub const KEY_Q: u8 = 0x14;
pub const KEY_R: u8 = 0x15;
pub const KEY_S: u8 = 0x16;
pub const KEY_T: u8 = 0x17;
pub const KEY_U: u8 = 0x18;
pub const KEY_V: u8 = 0x19;
pub const KEY_W: u8 = 0x1A;
pub const KEY_X: u8 = 0x1B;
pub const KEY_Y: u8 = 0x1C;
pub const KEY_Z: u8 = 0x1D;
pub const KEY_1: u8 = 0x1E;
pub const KEY_2: u8 = 0x1F;
pub const KEY_3: u8 = 0x20;
pub const KEY_4: u8 = 0x21;
pub const KEY_5: u8 = 0x22;
pub const KEY_6: u8 = 0x23;
pub const KEY_7: u8 = 0x24;
pub const KEY_8: u8 = 0x25;
pub const KEY_9: u8 = 0x26;
pub const KEY_0: u8 = 0x27;
pub const KEY_ENTER: u8 = 0x28;
pub const KEY_ESCAPE: u8 = 0x29;
pub const KEY_BACKSPACE: u8 = 0x2A;
pub const KEY_TAB: u8 = 0x2B;
pub const KEY_SPACE: u8 = 0x2C;
pub const KEY_MINUS: u8 = 0x2D;
pub const KEY_EQUAL: u8 = 0x2E;
pub const KEY_LBRACKET: u8 = 0x2F;
pub const KEY_RBRACKET: u8 = 0x30;
pub const KEY_BACKSLASH: u8 = 0x31;
pub const KEY_SEMICOLON: u8 = 0x33;
pub const KEY_QUOTE: u8 = 0x34;
pub const KEY_GRAVE: u8 = 0x35;
pub const KEY_COMMA: u8 = 0x36;
pub const KEY_PERIOD: u8 = 0x37;
pub const KEY_SLASH: u8 = 0x38;
pub const KEY_CAPSLOCK: u8 = 0x39;
pub const KEY_F1: u8 = 0x3A;
pub const KEY_F2: u8 = 0x3B;
pub const KEY_F3: u8 = 0x3C;
pub const KEY_F4: u8 = 0x3D;
pub const KEY_F5: u8 = 0x3E;
pub const KEY_F6: u8 = 0x3F;
pub const KEY_F7: u8 = 0x40;
pub const KEY_F8: u8 = 0x41;
pub const KEY_F9: u8 = 0x42;
pub const KEY_F10: u8 = 0x43;
pub const KEY_F11: u8 = 0x44;
pub const KEY_F12: u8 = 0x45;
pub const KEY_INSERT: u8 = 0x49;
pub const KEY_HOME: u8 = 0x4A;
pub const KEY_PAGEUP: u8 = 0x4B;
pub const KEY_DELETE: u8 = 0x4C;
pub const KEY_END: u8 = 0x4D;
pub const KEY_PAGEDOWN: u8 = 0x4E;
pub const KEY_RIGHT: u8 = 0x4F;
pub const KEY_LEFT: u8 = 0x50;
pub const KEY_DOWN: u8 = 0x51;
pub const KEY_UP: u8 = 0x52;
pub const KEY_NUMLOCK: u8 = 0x53;
pub const KEY_KP_DIVIDE: u8 = 0x54;
pub const KEY_KP_MULTIPLY: u8 = 0x55;
pub const KEY_KP_MINUS: u8 = 0x56;
pub const KEY_KP_PLUS: u8 = 0x57;
pub const KEY_KP_ENTER: u8 = 0x58;
pub const KEY_KP_1: u8 = 0x59;
pub const KEY_KP_2: u8 = 0x5A;
pub const KEY_KP_3: u8 = 0x5B;
pub const KEY_KP_4: u8 = 0x5C;
pub const KEY_KP_5: u8 = 0x5D;
pub const KEY_KP_6: u8 = 0x5E;
pub const KEY_KP_7: u8 = 0x5F;
pub const KEY_KP_8: u8 = 0x60;
pub const KEY_KP_9: u8 = 0x61;
pub const KEY_KP_0: u8 = 0x62;
pub const KEY_KP_PERIOD: u8 = 0x63;
pub const KEY_LCTRL: u8 = 0xE0;
pub const KEY_LSHIFT: u8 = 0xE1;
pub const KEY_LALT: u8 = 0xE2;
pub const KEY_LMETA: u8 = 0xE3;
pub const KEY_RCTRL: u8 = 0xE4;
pub const KEY_RSHIFT: u8 = 0xE5;
pub const KEY_RALT: u8 = 0xE6;
pub const KEY_RMETA: u8 = 0xE7;

pub const MOD_SHIFT: u8 = 0x01;
pub const MOD_CTRL: u8 = 0x02;
pub const MOD_ALT: u8 = 0x04;
pub const MOD_META: u8 = 0x08;

/// Test a key in a 32-byte key-state bitmask (see `Cart.keys`).
pub inline fn keyIsDown(keys: []const u8, keycode: u8) bool {
    return (keys[keycode >> 3] & (@as(u8, 1) << @intCast(keycode & 7))) != 0;
}

// ── Host imports ─────────────────────────────────────────────────────
//
// An UNCALLED extern is not emitted into the wasm binary, so merely declaring
// these keeps a cart that never calls them at zero imports.

/// Write a debug line to the host's log/trace. `logStr` is the ergonomic form.
pub extern "env" fn wc_log(ptr: [*]const u8, len: u32) void;

/// Log a string (usually a literal). Zero imports unless you call it.
pub inline fn logStr(s: []const u8) void {
    wc_log(s.ptr, @intCast(s.len));
}

/// Stamp {frame, id} into a debug-capable host's event trace. Play-only hosts
/// stub it. Keep call sites out of shipping builds.
pub extern "env" fn wc_debug_mark(id: u32) void;

/// Copy the host's name for a gamepad into `buf`. Returns bytes written.
pub extern "env" fn wc_pad_name(pad_id: u32, buf: [*]u8, buf_len: u32) i32;

/// Nonzero if this pad has rumble motors. Capability is per DEVICE, so ask.
pub extern "env" fn wc_pad_has_rumble(pad_id: u32) u32;

/// Run the motors. low/high are 0..1 (clamped by the host); duration_ms is
/// capped at MAX_RUMBLE_MS. Re-arm each frame for sustained rumble.
pub extern "env" fn wc_pad_rumble(pad_id: u32, low: f32, high: f32, duration_ms: u32) void;

pub extern "env" fn wc_pad_rumble_stop(pad_id: u32) void;

/// Size of an asset inside a .wasc archive, or -1 if absent.
pub extern "env" fn wc_asset_size(path: [*]const u8, path_len: u32) i32;

/// Read an asset into cart memory. Returns bytes read, or -1.
pub extern "env" fn wc_load_asset(path: [*]const u8, path_len: u32, dest: [*]u8, max_size: u32) i32;

/// Slice-flavored `wc_asset_size`.
pub inline fn assetSize(path: []const u8) i32 {
    return wc_asset_size(path.ptr, @intCast(path.len));
}

/// Slice-flavored `wc_load_asset`.
pub inline fn loadAsset(path: []const u8, dest: []u8) i32 {
    return wc_load_asset(path.ptr, @intCast(path.len), dest.ptr, @intCast(dest.len));
}

// ── Cart() - the buffer/info helper ──────────────────────────────────

/// Configuration for `Cart`.
pub const CartConfig = struct {
    /// Resolution reported to the host at startup.
    width: u32,
    height: u32,
    /// Backing-store size. Must be >= width/height. Make these larger than
    /// the defaults if you intend to adopt the host's preferred resolution
    /// in wc_init: the host refuses a resolution the framebuffer cannot hold.
    max_width: ?u32 = null,
    max_height: ?u32 = null,
    /// Audio ring capacity in STEREO FRAMES (the buffer is 2x this many samples).
    audio_cap: u32 = 4096,
    /// f32 samples (default, and sets FLAG_AUDIO_F32) or legacy i16.
    audio_f32: bool = true,
    /// Extra flags OR'd into WcInfo.flags. FLAG_AUDIO_F32 is added for you.
    flags: u32 = 0,
    /// 0 = 2D framebuffer, 1 = GLES3 via the "gl" import module.
    gpu_api: u32 = GPU_API_NONE,
    /// Bytes of persistent save storage (0 = none).
    save_size: u32 = 0,
    /// Ring-buffer sample rate; 0 lets the host pick (typically 48000).
    audio_sample_rate: u32 = 0,
};

/// Declares every buffer the wasmcart ABI expects, plus a pre-filled live
/// `WcInfo`, as a namespace you instantiate once at file scope.
///
///     const wc = @import("wasmcart.zig");
///     const cart = wc.Cart(.{ .width = 320, .height = 240 });
///
///     export fn wc_get_info() *wc.WcInfo { return cart.getInfo(); }
///     export fn wc_init() void {}
///     export fn wc_render() void {
///         for (cart.fb[0..320 * 240]) |*px| px.* = 0xFF3050C0;
///     }
///
/// The three exports stay in YOUR file on purpose. Zig cannot emit an
/// `export fn` from inside a generic struct without the caller naming it, and
/// forcing them to be visible is what stops a cart from accidentally
/// exporting the same symbol twice (the WC_EXPORT trap on the C side).
///
/// Pixels are little-endian XRGB u32: 0xAARRGGBB, so 0xFF3050C0 is a blue.
pub fn Cart(comptime cfg: CartConfig) type {
    const max_w = cfg.max_width orelse cfg.width;
    const max_h = cfg.max_height orelse cfg.height;
    if (max_w < cfg.width or max_h < cfg.height) {
        @compileError("Cart: max_width/max_height must be >= width/height");
    }
    const Sample = if (cfg.audio_f32) f32 else i16;

    return struct {

        /// Current resolution. Assign BOTH these and info.width/height if you
        /// adopt the host's preferred size in wc_init.
        pub var width: u32 = cfg.width;
        pub var height: u32 = cfg.height;

        /// Framebuffer, `max_width * max_height` XRGB pixels. Row-major, stride
        /// is the CURRENT width, so index with `y * width + x`.
        pub var fb: [max_w * max_h]u32 = @splat(0);

        /// Interleaved stereo audio ring, `audio_cap * 2` samples.
        pub var audio: [cfg.audio_cap * 2]Sample = @splat(0);

        /// Cart's write cursor into `audio`, in stereo frames. You advance it.
        pub var audio_write: u32 = 0;

        /// Gamepads 0..3. The host writes these before each wc_render.
        pub var pads: [MAX_PADS]WcPad = @splat(.{});

        /// Frame timing, written by the host before each wc_render.
        pub var time: WcTime = .{};

        /// Written by the host ONCE, before wc_init.
        pub var host_info: WcHostInfo = .{};

        /// Mouse/touch pointers. Only populated if you set FLAG_POINTER.
        pub var pointers: [MAX_POINTERS]WcPointer = @splat(.{});

        /// Key-state bitmask. Only populated if you set FLAG_KEYBOARD.
        /// Use `wc.keyIsDown(&cart.keys, wc.KEY_SPACE)`.
        pub var keys: [KEYS_SIZE]u8 = @splat(0);

        /// Persistent save storage, if `save_size` was nonzero.
        pub var save: [if (cfg.save_size == 0) 1 else cfg.save_size]u8 = @splat(0);

        /// The live info struct the host reads. Mutate fields here (width,
        /// height, flags) rather than returning a different struct.
        pub var info: WcInfo = .{};

        pub const max_width = max_w;
        pub const max_height = max_h;
        pub const audio_cap = cfg.audio_cap;
        pub const AudioSample = Sample;

        /// Fill and return the live info struct. Call this from your
        /// `wc_get_info` export. Safe to call more than once: the host does.
        pub fn getInfo() *WcInfo {
            info.version = ABI_VERSION;
            info.width = width;
            info.height = height;
            info.fb_ptr = @intFromPtr(&fb);
            info.audio_ptr = @intFromPtr(&audio);
            info.audio_cap = cfg.audio_cap;
            info.audio_write_ptr = @intFromPtr(&audio_write);
            info.input_ptr = @intFromPtr(&pads);
            info.save_ptr = if (cfg.save_size == 0) 0 else @intFromPtr(&save);
            info.save_size = cfg.save_size;
            info.time_ptr = @intFromPtr(&time);
            info.host_info_ptr = @intFromPtr(&host_info);
            info.flags = cfg.flags | (if (cfg.audio_f32) FLAG_AUDIO_F32 else 0);
            info.audio_sample_rate = cfg.audio_sample_rate;
            info.pointer_ptr = @intFromPtr(&pointers);
            info.keys_ptr = @intFromPtr(&keys);
            info.gpu_api = cfg.gpu_api;
            return &info;
        }

        /// The live framebuffer at the CURRENT resolution.
        pub inline fn pixels() []u32 {
            return fb[0 .. width * height];
        }

        /// Write one pixel. Out-of-bounds coordinates are dropped.
        pub inline fn set(x: i32, y: i32, color: u32) void {
            if (x < 0 or y < 0) return;
            const ux: u32 = @intCast(x);
            const uy: u32 = @intCast(y);
            if (ux >= width or uy >= height) return;
            fb[uy * width + ux] = color;
        }

        /// Fill the whole visible framebuffer with one color.
        pub inline fn clear(color: u32) void {
            for (pixels()) |*px| px.* = color;
        }

        /// Filled axis-aligned rectangle, clipped to the framebuffer.
        pub fn rect(x: i32, y: i32, w: u32, h: u32, color: u32) void {
            const x0: u32 = if (x < 0) 0 else @intCast(x);
            const y0: u32 = if (y < 0) 0 else @intCast(y);
            var x1: i64 = @as(i64, x) + @as(i64, w);
            var y1: i64 = @as(i64, y) + @as(i64, h);
            if (x1 > width) x1 = width;
            if (y1 > height) y1 = height;
            if (x1 <= x0 or y1 <= y0) return;
            var yy: u32 = y0;
            while (yy < @as(u32, @intCast(y1))) : (yy += 1) {
                const row = fb[yy * width ..][x0..@intCast(x1)];
                for (row) |*px| px.* = color;
            }
        }

        /// Adopt the host's preferred resolution if it fits the backing store.
        /// Call from wc_init. Returns true if the resolution changed.
        pub fn adoptHostResolution() bool {
            const w = host_info.preferred_width;
            const h = host_info.preferred_height;
            if (w == 0 or h == 0) return false;
            if (w > max_w or h > max_h) return false;
            if (w == width and h == height) return false;
            width = w;
            height = h;
            info.width = w;
            info.height = h;
            return true;
        }

        /// Pack 8-bit channels into the XRGB word the host expects.
        pub inline fn rgb(r: u8, g: u8, b: u8) u32 {
            return 0xFF000000 |
                (@as(u32, r) << 16) |
                (@as(u32, g) << 8) |
                @as(u32, b);
        }

        /// Push one interleaved stereo frame into the audio ring and advance
        /// the write cursor. Wraps at `audio_cap`.
        pub inline fn pushSample(left: Sample, right: Sample) void {
            const i = (audio_write % cfg.audio_cap) * 2;
            audio[i] = left;
            audio[i + 1] = right;
            audio_write = audio_write +% 1;
        }
    };
}

// ── Deterministic RNG (OPT-IN) ───────────────────────────────────────
//
// Pair this with FLAG_DETERMINISTIC in your info flags AND an exported
// wc_set_seed. Branch-free xorshift32, so the per-frame path is identical in
// deterministic and normal runs.
//
//     var rng = wc.Rng{};
//     export fn wc_set_seed(s: u32) void { rng.seed(s); }
//     ... rng.range(64) ...

pub const Rng = struct {
    state: u32 = 2463534242,

    pub fn seed(self: *Rng, s: u32) void {
        self.state = if (s != 0) s else 2463534242;
    }

    pub fn next(self: *Rng) u32 {
        var x = self.state;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        self.state = x;
        return x;
    }

    /// Uniform-ish value in [0, n). Returns 0 when n is 0.
    pub fn range(self: *Rng, n: u32) u32 {
        if (n == 0) return 0;
        return self.next() % n;
    }
};

// ── OpenGL ES 3.0 (gpu_api = GPU_API_WEBGL2) ─────────────────────────
//
// `gl` is a namespace of externs from the "gl" import module plus the GLES3
// constants. An uncalled extern is not emitted, so importing this namespace
// costs nothing until you actually draw.

pub const gl = @import("wasmcart_gl.zig");

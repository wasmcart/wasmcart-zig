//! Your wasmcart cart. Rename it, keep the three exports.
//!
//! Build and run:
//!   zig build
//!   npx wasmcart pack --wasm zig-out/bin/cart.wasm --name mygame -o mygame.wasc
//!   npx wasmcart mygame.wasc

const wc = @import("wasmcart.zig");

/// Panics go to wc_log and trap, instead of pulling std.fmt into the cart.
/// Must be declared in the ROOT source file. Drop it and the cart grows ~11 KB.
pub const panic = wc.panic;

const WIDTH = 320;
const HEIGHT = 240;

const cart = wc.Cart(.{
    .width = WIDTH,
    .height = HEIGHT,
    // For a GLES3 cart instead of a 2D one:
    //   .gpu_api = wc.GPU_API_WEBGL2,
    // and then draw with wc.gl.* in wc_render, ignoring the framebuffer.
});

var x: i32 = WIDTH / 2;
var y: i32 = HEIGHT / 2;

/// The host reads this to learn your resolution and buffer addresses. It must
/// return a pointer to the LIVE struct: the host re-reads it after wc_init.
export fn wc_get_info() *wc.WcInfo {
    return cart.getInfo();
}

/// Called once, after the host has filled in cart.host_info.
export fn wc_init() void {
    wc.logStr("cart: init");
    // Uncomment to run at the host's native resolution instead of yours.
    // Set .max_width / .max_height in the Cart config first, or this is a
    // no-op because the framebuffer cannot hold a larger frame.
    // _ = cart.adoptHostResolution();
}

/// Called once per frame. Draw here.
export fn wc_render() void {
    cart.clear(cart.rgb(0x10, 0x14, 0x20));

    const pad = cart.pads[0];
    if (pad.down(wc.BTN_LEFT)) x -= 2;
    if (pad.down(wc.BTN_RIGHT)) x += 2;
    if (pad.down(wc.BTN_UP)) y -= 2;
    if (pad.down(wc.BTN_DOWN)) y += 2;

    cart.rect(x - 8, y - 8, 16, 16, cart.rgb(0xF0, 0xC0, 0x40));
}

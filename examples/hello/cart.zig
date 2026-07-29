//! hello - a 2D wasmcart cart in Zig.
//!
//! Draws a moving plasma-ish gradient with a bouncing square you can push
//! around with the d-pad or left stick. No imports, no allocator, no runtime.

const wc = @import("wasmcart");

/// Report panics through wc_log and trap, instead of dragging std.fmt into the
/// cart. Worth ~11 KB. Must be declared in the ROOT source file.
pub const panic = wc.panic;

const W = 320;
const H = 240;

const cart = wc.Cart(.{
    .width = W,
    .height = H,
});

var box_x: i32 = W / 2 - 16;
var box_y: i32 = H / 2 - 16;
var vx: i32 = 2;
var vy: i32 = 1;

export fn wc_get_info() *wc.WcInfo {
    return cart.getInfo();
}

export fn wc_init() void {
    wc.logStr("hello: zig cart init");
}

export fn wc_render() void {
    const t: u32 = cart.time.frame;

    // Background gradient, animated by frame number.
    var y: u32 = 0;
    while (y < H) : (y += 1) {
        const g: u8 = @intCast((y * 255) / H);
        var x: u32 = 0;
        while (x < W) : (x += 1) {
            const r: u8 = @intCast((x * 255) / W);
            const b: u8 = @truncate((x +% y +% t) >> 1);
            cart.fb[y * W + x] = cart.rgb(r, g, b);
        }
    }

    // Player input moves the square; otherwise it drifts and bounces.
    const pad = cart.pads[0];
    var moved = false;
    if (pad.connected != 0) {
        if (pad.down(wc.BTN_LEFT) or pad.left_x < -8000) {
            box_x -= 3;
            moved = true;
        }
        if (pad.down(wc.BTN_RIGHT) or pad.left_x > 8000) {
            box_x += 3;
            moved = true;
        }
        if (pad.down(wc.BTN_UP) or pad.left_y < -8000) {
            box_y -= 3;
            moved = true;
        }
        if (pad.down(wc.BTN_DOWN) or pad.left_y > 8000) {
            box_y += 3;
            moved = true;
        }
    }
    if (!moved) {
        box_x += vx;
        box_y += vy;
        if (box_x < 0 or box_x > W - 32) vx = -vx;
        if (box_y < 0 or box_y > H - 32) vy = -vy;
    }
    if (box_x < 0) box_x = 0;
    if (box_y < 0) box_y = 0;
    if (box_x > W - 32) box_x = W - 32;
    if (box_y > H - 32) box_y = H - 32;

    // Drop shadow, then the square itself.
    cart.rect(box_x + 3, box_y + 3, 32, 32, cart.rgb(0x10, 0x10, 0x18));
    const flash: u8 = if (pad.down(wc.BTN_A)) 0xFF else 0x30;
    cart.rect(box_x, box_y, 32, 32, cart.rgb(0xFF, 0xD0, flash));
}

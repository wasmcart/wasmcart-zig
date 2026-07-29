# wasmcart-zig

Zig bindings for [wasmcart](https://github.com/wasmcart/wasmcart) carts.

This is a **bindings package, not a runtime**. There is no interpreter, no GC,
and no engine here. You write a cart in Zig, it compiles to a freestanding
wasm32 module, and a wasmcart host runs it directly. A complete cart is a few
hundred bytes with zero imports.

## Pinned Zig version

**Zig 0.16.0** (released 2026-04-13). Verified on `x86_64-linux`.

Zig is pre-1.0 and breaks across minor versions. `build.zig` in particular has
changed shape in most recent releases. If you are on a different Zig, expect
the build script to need edits before anything else does; `wasmcart.zig` itself
is plain structs and externs and travels better.

Install without touching your system (this is how it was verified):

```sh
mkdir -p ~/toolchains/zig && cd ~/toolchains/zig
curl -LO https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz
tar -xf zig-x86_64-linux-0.16.0.tar.xz
export PATH="$PWD/zig-x86_64-linux-0.16.0:$PATH"
zig version   # 0.16.0
```

## Quick start

Copy `template/` and start editing `src/cart.zig`:

```sh
cp -r template mygame && cd mygame
zig build
npx wasmcart pack --wasm zig-out/bin/cart.wasm --name mygame -o mygame.wasc
npx wasmcart mygame.wasc
```

That is the whole loop. The template already contains `wasmcart.zig` and
`wasmcart_gl.zig` in `src/`.

## Installing the bindings

Either as a package dependency, or by copying two files.

**As a dependency:**

```sh
zig fetch --save=wasmcart https://github.com/wasmcart/wasmcart-zig/archive/refs/tags/v0.1.1.tar.gz
```

Then wire the module up in your `build.zig`:

```zig
const dep = b.dependency("wasmcart", .{});
mod.addImport("wasmcart", dep.module("wasmcart"));
```

and import it by name:

```zig
const wc = @import("wasmcart");
```

**Or copy `wasmcart.zig` and `wasmcart_gl.zig`** next to your source and
import by path:

```zig
const wc = @import("wasmcart.zig");
```

Both work. The copy is worth knowing about because the manifest format has
changed in most recent Zig releases, and two files that never change are easy
to vendor if a future Zig breaks the dependency route.

## Writing a cart

A cart is three exports plus your game:

```zig
const wc = @import("wasmcart.zig");

pub const panic = wc.panic;

const cart = wc.Cart(.{ .width = 320, .height = 240 });

export fn wc_get_info() *wc.WcInfo { return cart.getInfo(); }
export fn wc_init() void {}
export fn wc_render() void { cart.clear(0xFF3050C0); }
```

That is 432 bytes stripped at `ReleaseSmall`, with zero imports.

`wc.Cart(...)` is the analogue of `WC_CART_BUFFERS` / `WC_FILL_INFO` in the C
`wc_cart.h`: it declares the framebuffer, audio ring, pad array, time struct,
host-info struct, pointer array and key bitmask, and fills a live `WcInfo`
pointing at all of them.

The three `export fn`s stay in your file on purpose. Zig will not emit an
export from inside a generic struct without the caller naming it, and keeping
them visible is what prevents the "duplicate export name" trap the C macros
have.

### What `Cart` gives you

| Member | What it is |
|---|---|
| `cart.fb` | `max_width * max_height` XRGB `u32` pixels |
| `cart.pixels()` | slice of the framebuffer at the current resolution |
| `cart.pads[0..4]` | `WcPad`, written by the host before each `wc_render` |
| `cart.time` | `WcTime` (`time_ms`, `delta_ms`, `frame`) |
| `cart.host_info` | `WcHostInfo`, written by the host once before `wc_init` |
| `cart.pointers`, `cart.keys` | pointer/keyboard state (set the matching flag) |
| `cart.audio`, `cart.audio_write` | interleaved stereo ring + write cursor |
| `cart.getInfo()` | fills and returns the live `WcInfo` |
| `cart.clear`, `cart.set`, `cart.rect`, `cart.rgb` | small 2D helpers |
| `cart.adoptHostResolution()` | switch to the host's preferred size in `wc_init` |
| `cart.pushSample(l, r)` | push one stereo frame and advance the cursor |

### Pixel format

`u32` little-endian XRGB, i.e. `0xAARRGGBB`. `cart.rgb(0x30, 0x50, 0xC0)` and
the literal `0xFF3050C0` are the same blue.

### Panics

`pub const panic = wc.panic;` in your **root** source file routes panic
messages through `wc_log` (which debug-capable hosts capture, so a trapping
cart says why) and then traps.

It also matters for size. Zig's default panic handler formats its message,
which drags `std.fmt` and `std.io` into a freestanding cart: the `hello`
example is 4.3 KB with `wc.panic` and 14.5 KB without it. If the optimizer can
prove no panic is reachable, neither handler is emitted and the cart keeps zero
imports either way.

### Zero imports

An uncalled `extern` is not emitted into the wasm binary, so importing the
bindings costs nothing. A cart only gains an import when it actually calls one:
`wc.logStr` pulls in `env.wc_log`, and `wc.gl.*` pulls in the `gl` module.
The `hello` example imports `env.wc_log` only because it deliberately logs at
init; delete that line and it drops to zero imports.

### Optional host imports

`wc.logStr` / `wc.wc_log`, `wc.wc_debug_mark`, `wc.wc_pad_name`,
`wc.wc_pad_has_rumble` / `wc_pad_rumble` / `wc_pad_rumble_stop`, and
`wc.assetSize` / `wc.loadAsset` for reading assets out of a `.wasc` archive.

### GL carts

Set `.gpu_api = wc.GPU_API_WEBGL2` and draw with `wc.gl.*`. The host builds a
real GLES3/WebGL2 context and routes the `gl` import module to it. A GL cart
ignores the framebuffer entirely; the GL surface is the output.

```zig
const gl = wc.gl;
const cart = wc.Cart(.{ .width = 640, .height = 480, .gpu_api = wc.GPU_API_WEBGL2 });

export fn wc_render() void {
    gl.glViewport(0, 0, 640, 480);
    gl.glClearColor(0.05, 0.07, 0.12, 1.0);
    gl.glClear(gl.COLOR_BUFFER_BIT);
    // ... draw ...
}
```

Note the bundled terminal player is 2D only and refuses GL carts. Run them
through a host with a real context (`wasmcart-play` in a window, or `CartHost`
with a `glBackend`).

### Deterministic runs

`wc.Rng` is a branch-free xorshift32. Pair it with `FLAG_DETERMINISTIC` and an
exported `wc_set_seed`, and take **all** timing from `cart.time`:

```zig
var rng = wc.Rng{};
export fn wc_set_seed(s: u32) void { rng.seed(s); }
```

## Building without `build.zig`

```sh
zig build-exe cart.zig \
  -target wasm32-freestanding \
  -fno-entry -rdynamic -fstrip -OReleaseSmall
```

Four flags, all load-bearing:

- **`-rdynamic`** surfaces `export fn` symbols in the wasm export section.
  Without it the module links cleanly and has **no exports at all** (43 bytes),
  and the host rejects it with `Cart must export wc_render`. This is the first
  thing that goes wrong.
- **`-fno-entry`** because a cart has no `main`.
- **`-fstrip`** because DWARF and name sections are ~97% of an unstripped cart
  and no host reads them. A 4 KB cart is 577 KB without this.
- **`-OReleaseSmall`** for size. `ReleaseFast` also works.

**Use `build-exe`, not `build-lib`.** `zig build-lib -dynamic` produces a
shared wasm library that requires position-independent code, and a plain cart
fails to link with:

```
relocation R_WASM_MEMORY_ADDR_SLEB cannot be used against symbol `.Lcart.fb`;
recompile with -fPIC
```

An entry-less executable is the right shape for a cart.

In `build.zig` the same settings are:

```zig
const cart = b.addExecutable(.{ .name = "cart", .root_module = mod });
cart.entry = .disabled;   // -fno-entry
cart.rdynamic = true;     // -rdynamic
// and .strip = true on the module
```

## Examples

```sh
zig build              # both, into zig-out/bin/
zig build hello        # 2D framebuffer
zig build hello_gl     # GLES3 triangle
```

| Example | Size | Imports | What it does |
|---|---|---|---|
| `hello` | 4.3 KB | `env.wc_log` | animated gradient, a bouncing square you can drive with the d-pad |
| `hello_gl` | 2.8 KB | 26x `gl.*`, `env.wc_log` | spinning Gouraud triangle at 640x480 |

Run them:

```sh
zig build
npx wasmcart pack --wasm zig-out/bin/hello.wasm --name hello -o hello.wasc
npx wasmcart hello.wasc --frames 30 --shot hello.png
```

## The ABI

`wasmcart.zig` transcribes ABI v3 as `extern struct`s, which carry C layout
guarantees, and a `comptime` block asserts every size and the v3 tail offsets
(`pointer_ptr` at 56, `keys_ptr` at 60, `gpu_api` at 64) so a field reordering
is a compile error rather than a silent misread.

One quirk worth knowing: `WcTime` holds 20 bytes of data but is 8-byte aligned,
so Zig reports `@sizeOf(WcTime) == 24`. C does the same thing. The host only
ever reads the first 20 bytes and the struct is never arrayed, so this is fine;
the field offsets (0, 8, 16) are what matter and they are asserted.

`wc_get_info()` must return a pointer to a **live** struct, not a copy. The
host re-reads it after `wc_init` so a cart can adapt its resolution to
`host_info.preferred_width/height`. `cart.getInfo()` returns `&info`, a
file-scope variable, so this holds.

## License

MIT.

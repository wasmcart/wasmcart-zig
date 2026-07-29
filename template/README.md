# my wasmcart game

A [wasmcart](https://github.com/wasmcart/wasmcart) cart in Zig.

Requires **Zig 0.16.0**. Zig is pre-1.0 and `build.zig` breaks across minor
versions, so pin it.

## Build and run

```sh
zig build
npx wasmcart pack --wasm zig-out/bin/cart.wasm --name mygame -o mygame.wasc
npx wasmcart mygame.wasc
```

Headless, with a screenshot:

```sh
npx wasmcart mygame.wasc --frames 30 --shot shot.png
```

## Layout

```
build.zig          entry = .disabled + rdynamic = true; both are required
src/cart.zig       your game: wc_get_info, wc_init, wc_render
src/wasmcart.zig   the ABI bindings (copy, do not edit)
src/wasmcart_gl.zig  GLES3 bindings, only used by gpu_api = 1 carts
```

## Going 3D

Set `.gpu_api = wc.GPU_API_WEBGL2` in the `wc.Cart(...)` config, then draw with
`wc.gl.*` in `wc_render` and ignore the framebuffer. The host supplies a real
GLES3 context.

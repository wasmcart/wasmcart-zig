#!/usr/bin/env bash
# Full gate: build both examples + the template, pack each, run headless, and
# confirm the host REJECTS a cart missing wc_get_info (a control that must
# fail, so a green run proves the harness can move).
#
# Needs `zig` on PATH and the `wasmcart` CLI (npx wasmcart, or set WASMCART).
set -euo pipefail

cd "$(dirname "$0")"
OUT="${OUT:-build-test}"
WASMCART="${WASMCART:-npx wasmcart}"
mkdir -p "$OUT"

echo "== zig version: $(zig version)"

echo
echo "== template copies must match the root bindings"
for f in wasmcart.zig wasmcart_gl.zig; do
  if ! cmp -s "$f" "template/src/$f"; then
    echo "FAIL: template/src/$f differs from $f (run: cp $f template/src/$f)"
    exit 1
  fi
  echo "ok: template/src/$f"
done

echo
echo "== build examples"
zig build
ls -l zig-out/bin

echo
echo "== build template"
( cd template && zig build && ls -l zig-out/bin )

echo
echo "== pack + run: hello (2D)"
$WASMCART pack --wasm zig-out/bin/hello.wasm --name hello --width 320 --height 240 -o "$OUT/hello.wasc"
$WASMCART "$OUT/hello.wasc" --frames 30 --shot "$OUT/hello.png"
echo "wrote $OUT/hello.png -- LOOK AT IT. A cart that runs 30 frames while"
echo "rendering a blank screen is the standard failure here."

echo
echo "== pack + run: template"
$WASMCART pack --wasm template/zig-out/bin/cart.wasm --name template --width 320 --height 240 -o "$OUT/template.wasc"
$WASMCART "$OUT/template.wasc" --frames 30 --shot "$OUT/template.png"

echo
echo "== pack: hello_gl (needs a GL host to RUN; the terminal player is 2D only)"
$WASMCART pack --wasm zig-out/bin/hello_gl.wasm --name hello_gl --width 640 --height 480 -o "$OUT/hello_gl.wasc"

echo
echo "== CONTROL: a cart missing wc_get_info must be REJECTED"
sed 's/export fn wc_get_info/export fn wc_get_info_BROKEN/' examples/hello/cart.zig > "$OUT/broken.zig"
zig build-exe -target wasm32-freestanding -fno-entry -rdynamic -fstrip -OReleaseSmall \
  --dep wasmcart -Mroot="$OUT/broken.zig" -Mwasmcart=wasmcart.zig -femit-bin="$OUT/broken.wasm"
$WASMCART pack --wasm "$OUT/broken.wasm" --name broken -o "$OUT/broken.wasc" >/dev/null
set +e
BROKEN_OUT=$($WASMCART "$OUT/broken.wasc" --frames 5 2>&1)
set -e
case "$BROKEN_OUT" in
  *"Cart must export wc_get_info"*)
    echo "ok: host rejected it (control failed as required)" ;;
  *)
    echo "FAIL: the control did NOT fail -- the harness is broken, ignore the green above"
    echo "  host said: $BROKEN_OUT"
    exit 1 ;;
esac

echo
echo "== CONTROL: without -rdynamic a cart has NO exports"
zig build-exe -target wasm32-freestanding -fno-entry -fstrip -OReleaseSmall \
  --dep wasmcart -Mroot=examples/hello/cart.zig -Mwasmcart=wasmcart.zig \
  -femit-bin="$OUT/nordynamic.wasm"
set +e
$WASMCART pack --wasm "$OUT/nordynamic.wasm" --name nordyn -o "$OUT/nordyn.wasc" >/dev/null 2>&1
NORDYN_OUT=$($WASMCART "$OUT/nordyn.wasc" --frames 5 2>&1)
set -e
case "$NORDYN_OUT" in
  *"must export"*)
    echo "ok: host rejected the no-rdynamic build" ;;
  *)
    echo "FAIL: expected the no-rdynamic build to be rejected"
    echo "  host said: $NORDYN_OUT"
    exit 1 ;;
esac

echo
echo "ALL PASS. Now open $OUT/*.png and confirm they are not blank."

//! Build a wasmcart cart. `zig build` puts cart.wasm in zig-out/bin/.
//!
//! Two settings are non-negotiable for a cart:
//!   entry = .disabled   there is no main()
//!   rdynamic = true     surfaces `export fn` in the wasm export section
//! Drop rdynamic and the module links fine but has NO exports, and the host
//! rejects it with "Cart must export wc_render".
//!
//! Use addExecutable, not addLibrary: a `-dynamic` wasm library demands PIC
//! and fails to link with "relocation R_WASM_MEMORY_ADDR_SLEB cannot be used
//! against symbol ... recompile with -fPIC".

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    const cart = b.addExecutable(.{
        .name = "cart",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cart.zig"),
            .target = target,
            .optimize = optimize,
            // Debug info is ~97% of an unstripped cart and no host reads it.
            .strip = true,
        }),
    });
    cart.entry = .disabled;
    cart.rdynamic = true;

    b.installArtifact(cart);
}

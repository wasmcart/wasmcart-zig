//! Builds the wasmcart-zig examples.
//!
//!   zig build            # both examples into zig-out/bin/
//!   zig build hello      # just the 2D one
//!   zig build hello_gl   # just the GL one
//!   zig build -Doptimize=ReleaseSmall   # (this is already the default)
//!
//! The two settings that matter for a cart are `entry = .disabled` and
//! `rdynamic = true`. Without rdynamic the module links but carries NO export
//! section, and the host rejects it with "Cart must export wc_render".
//!
//! Note this uses addExecutable, not addLibrary. A `-dynamic` wasm library
//! wants position-independent code and fails to link a plain cart with
//! "relocation R_WASM_MEMORY_ADDR_SLEB cannot be used against symbol ...
//! recompile with -fPIC". An entry-less executable is the right shape.

const std = @import("std");

pub fn build(b: *std.Build) void {
    // Carts are always freestanding wasm32. Nothing else makes sense here, so
    // this is not exposed as an option.
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    // Debug info in a cart is dead weight: no host reads it, and it is ~97%
    // of an unstripped binary. Pass -Dstrip=false when you want it.
    const strip = b.option(bool, "strip", "Strip debug info (default true)") orelse true;

    const wasmcart = b.addModule("wasmcart", .{
        .root_source_file = b.path("wasmcart.zig"),
    });

    const examples = [_][]const u8{ "hello", "hello_gl" };
    for (examples) |name| {
        const src = b.fmt("examples/{s}/cart.zig", .{name});
        const mod = b.createModule(.{
            .root_source_file = b.path(src),
            .target = target,
            .optimize = optimize,
            // Without this the wasm carries DWARF + name custom sections and
            // a trivial cart weighs ~570 KB instead of a few KB. Nothing in
            // the host reads them.
            .strip = strip,
        });
        mod.addImport("wasmcart", wasmcart);

        const cart = b.addExecutable(.{
            .name = name,
            .root_module = mod,
        });
        cart.entry = .disabled; // -fno-entry: a cart has no main()
        cart.rdynamic = true; // -rdynamic: surface `export fn` in the wasm export section

        const install = b.addInstallArtifact(cart, .{});
        b.getInstallStep().dependOn(&install.step);

        const step = b.step(name, b.fmt("Build the {s} example", .{name}));
        step.dependOn(&install.step);
    }
}

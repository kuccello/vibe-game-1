const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build GLFW first
    const glfw = b.addStaticLibrary(.{
        .name = "glfw",
        .target = target,
        .optimize = optimize,
    });

    // Add GLFW source files
    const glfw_flags = &[_][]const u8{
        "-fno-sanitize=undefined",
        "-D_GLFW_COCOA",
        "-DPLATFORM_DESKTOP",
        "-DGRAPHICS_API_OPENGL_33",
        "-x",
        "objective-c",
    };

    // Core GLFW files
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/context.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/init.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/input.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/monitor.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/vulkan.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/window.c" }, .flags = glfw_flags });

    // Platform-specific files for macOS
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_init.m" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_joystick.m" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_monitor.m" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_window.m" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_time.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/posix_thread.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/nsgl_context.m" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/egl_context.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/osmesa_context.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/platform.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_init.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_joystick.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_monitor.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_window.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/posix_module.c" }, .flags = glfw_flags });

    // Add GLFW include directories
    glfw.addIncludePath(.{ .cwd_relative = "raylib/src/external/glfw/include" });

    // Link system frameworks for GLFW
    glfw.linkFramework("Foundation");
    glfw.linkFramework("Cocoa");
    glfw.linkFramework("OpenGL");
    glfw.linkFramework("IOKit");
    glfw.linkFramework("CoreFoundation");
    glfw.linkFramework("CoreVideo");

    // Build raylib
    const raylib = b.addStaticLibrary(.{
        .name = "raylib",
        .target = target,
        .optimize = optimize,
    });

    // Add raylib source files
    const raylib_flags = &[_][]const u8{
        "-fno-sanitize=undefined",
        "-DPLATFORM_DESKTOP",
        "-DGRAPHICS_API_OPENGL_33",
    };

    raylib.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/rcore.c" }, .flags = raylib_flags });
    raylib.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/rshapes.c" }, .flags = raylib_flags });
    raylib.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/rtextures.c" }, .flags = raylib_flags });
    raylib.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/rtext.c" }, .flags = raylib_flags });
    raylib.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/rmodels.c" }, .flags = raylib_flags });
    raylib.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/raudio.c" }, .flags = raylib_flags });
    raylib.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/utils.c" }, .flags = raylib_flags });

    // Add raylib include directories
    raylib.addIncludePath(.{ .cwd_relative = "raylib/src" });
    raylib.addIncludePath(.{ .cwd_relative = "raylib/src/external/glfw/include" });

    // Link GLFW with raylib
    raylib.linkLibrary(glfw);

    // Link system frameworks for raylib
    raylib.linkFramework("Foundation");
    raylib.linkFramework("Cocoa");
    raylib.linkFramework("OpenGL");
    raylib.linkFramework("IOKit");
    raylib.linkFramework("CoreFoundation");
    raylib.linkFramework("CoreVideo");

    // Create the game executable
    const game = b.addExecutable(.{
        .name = "game1",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Link with raylib and GLFW
    game.addIncludePath(.{ .cwd_relative = "raylib/src" });
    game.linkLibrary(raylib);
    game.linkLibrary(glfw);

    // Create the generate_assets executable
    const generate_assets = b.addExecutable(.{
        .name = "generate_assets",
        .root_source_file = .{ .cwd_relative = "src/generate_assets.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Link raylib and GLFW for generate_assets
    generate_assets.addIncludePath(.{ .cwd_relative = "raylib/src" });
    generate_assets.linkLibrary(raylib);
    generate_assets.linkLibrary(glfw);
    generate_assets.linkFramework("CoreServices");

    // Create the run command for generate_assets
    const run_generate_assets = b.addRunArtifact(generate_assets);
    run_generate_assets.step.dependOn(&generate_assets.step);
    run_generate_assets.expectExitCode(0);

    // Add the generate_assets step as a dependency for the game
    game.step.dependOn(&run_generate_assets.step);

    // Expose the generate_assets step
    const generate_assets_step = b.step("generate_assets", "Generate game assets");
    generate_assets_step.dependOn(&run_generate_assets.step);
    b.default_step.dependOn(generate_assets_step);

    // Create the run command for the game
    const run_cmd = b.addRunArtifact(game);
    run_cmd.step.dependOn(b.getInstallStep());

    // Create the run step
    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}

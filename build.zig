const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build GLFW
    const glfw = b.addStaticLibrary(.{
        .name = "glfw",
        .target = target,
        .optimize = optimize,
    });

    // Add GLFW source files
    const glfw_flags = &[_][]const u8{
        "-fno-sanitize=undefined",
        "-D_GLFW_COCOA",
    };

    glfw.addIncludePath(.{ .cwd_relative = "raylib/src/external/glfw/include" });
    glfw.addIncludePath(.{ .cwd_relative = "raylib/src/external/glfw/src" });

    // Common GLFW source files
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/context.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/init.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/input.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/monitor.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/vulkan.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/window.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/platform.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_init.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_monitor.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_window.c" }, .flags = glfw_flags });
    glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_joystick.c" }, .flags = glfw_flags });

    // macOS-specific files
    if (target.result.os.tag == .macos) {
        glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_init.m" }, .flags = glfw_flags });
        glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_joystick.m" }, .flags = glfw_flags });
        glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_monitor.m" }, .flags = glfw_flags });
        glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_window.m" }, .flags = glfw_flags });
        glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_time.c" }, .flags = glfw_flags });
        glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/posix_thread.c" }, .flags = glfw_flags });
        glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/nsgl_context.m" }, .flags = glfw_flags });
        glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/egl_context.c" }, .flags = glfw_flags });
        glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/osmesa_context.c" }, .flags = glfw_flags });
        glfw.addCSourceFile(.{ .file = .{ .cwd_relative = "raylib/src/external/glfw/src/posix_module.c" }, .flags = glfw_flags });

        glfw.linkFramework("Foundation");
        glfw.linkFramework("Cocoa");
        glfw.linkFramework("OpenGL");
        glfw.linkFramework("IOKit");
        glfw.linkFramework("CoreFoundation");
        glfw.linkFramework("CoreVideo");
        glfw.linkFramework("CoreServices");
    }

    // Build raylib
    const raylib = b.addStaticLibrary(.{
        .name = "raylib",
        .target = target,
        .optimize = optimize,
    });

    // Add raylib source files with necessary flags
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

    // Add include paths
    raylib.addIncludePath(.{ .cwd_relative = "raylib/src" });
    raylib.addIncludePath(.{ .cwd_relative = "raylib/src/external/glfw/include" });

    // Link with GLFW
    raylib.linkLibrary(glfw);

    // Create mkdir step
    const mkdir = b.addSystemCommand(&.{ "mkdir", "-p", "assets/story" });

    // Create the asset generation executable
    const generate_assets = b.addExecutable(.{
        .name = "generate_assets",
        .root_source_file = .{ .cwd_relative = "src/generate_assets.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Link with raylib and GLFW
    generate_assets.addIncludePath(.{ .cwd_relative = "raylib/src" });
    generate_assets.linkLibrary(raylib);
    generate_assets.linkLibrary(glfw);

    // Make generate_assets depend on mkdir
    generate_assets.step.dependOn(&mkdir.step);

    // Create the run command for generate_assets
    const run_generate_assets = b.addRunArtifact(generate_assets);
    run_generate_assets.setCwd(.{ .cwd_relative = "assets/story" });
    run_generate_assets.expectExitCode(0);

    // Create the main game executable
    const exe = b.addExecutable(.{
        .name = "game1",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Link with raylib and GLFW
    exe.addIncludePath(.{ .cwd_relative = "raylib/src" });
    exe.linkLibrary(raylib);
    exe.linkLibrary(glfw);

    // Make the main executable depend on generate_assets
    exe.step.dependOn(&run_generate_assets.step);

    // Install the executable
    b.installArtifact(exe);

    // Create a run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // Add it as the default "run" step
    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}

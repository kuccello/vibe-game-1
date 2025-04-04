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
    const exe = b.addExecutable(.{
        .name = "AncientPowers",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Link with raylib and GLFW
    exe.addIncludePath(.{ .cwd_relative = "raylib/src" });
    exe.linkLibrary(raylib);
    exe.linkLibrary(glfw);
    exe.linkSystemLibrary("c");

    // This declares intent for the executable to be installed into the standard location when the user invokes the "install" step
    b.installArtifact(exe);

    // Creates a step for unit testing.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Creates a step for running the executable
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // Creates a step for creating a release build
    const release = b.addExecutable(.{
        .name = "AncientPowers",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = .ReleaseFast,
    });

    // Link with raylib and GLFW for release build
    release.addIncludePath(.{ .cwd_relative = "raylib/src" });
    release.linkLibrary(raylib);
    release.linkLibrary(glfw);
    release.linkSystemLibrary("c");

    // This declares intent for the release executable to be installed
    b.installArtifact(release);

    // Creates a step for creating a release build
    const release_cmd = b.addRunArtifact(release);
    release_cmd.step.dependOn(b.getInstallStep());

    // Creates a step for unit testing.
    const run_unit_tests_cmd = b.addRunArtifact(unit_tests);
    if (b.args) |args| {
        run_unit_tests_cmd.addArgs(args);
    }
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests_cmd.step);

    // Creates a step for running the executable.
    const run_step = b.step("run", "Run the executable");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for creating a release build.
    const release_step = b.step("release", "Create a release build");
    release_step.dependOn(&release.step);

    // Create the sprite generator executable
    const sprite_gen = b.addExecutable(.{
        .name = "SpriteGenerator",
        .root_source_file = .{ .cwd_relative = "src/sprite_generator.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Link with raylib and GLFW for sprite generator
    sprite_gen.addIncludePath(.{ .cwd_relative = "raylib/src" });
    sprite_gen.linkLibrary(raylib);
    sprite_gen.linkLibrary(glfw);
    sprite_gen.linkSystemLibrary("c");

    // Creates a step for running the sprite generator
    const run_sprite_gen = b.addRunArtifact(sprite_gen);

    // Creates a step for generating sprites
    const gen_sprites_step = b.step("gen-sprites", "Generate placeholder sprites");
    gen_sprites_step.dependOn(&run_sprite_gen.step);
}

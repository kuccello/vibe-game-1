const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "game1",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add GLFW as a static library
    const glfw = b.addStaticLibrary(.{
        .name = "glfw",
        .target = target,
        .optimize = optimize,
    });

    // Add GLFW source files
    glfw.addIncludePath(.{ .cwd_relative = "raylib/src/external/glfw/include" });
    glfw.addIncludePath(.{ .cwd_relative = "raylib/src/external/glfw/src" });

    const glfw_flags = [_][]const u8{
        "-D_GLFW_COCOA",
        "-D_GLFW_USE_MENUBAR",
        "-D_GLFW_USE_RETINA",
    };

    // Add core GLFW source files
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/context.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/init.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/input.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/monitor.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/window.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/platform.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/vulkan.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/egl_context.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/osmesa_context.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_init.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_monitor.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_window.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/null_joystick.c" },
        .flags = &glfw_flags,
    });

    // Add macOS-specific GLFW source files
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_init.m" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_joystick.m" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_monitor.m" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_window.m" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/cocoa_time.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/nsgl_context.m" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/posix_module.c" },
        .flags = &glfw_flags,
    });
    glfw.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/external/glfw/src/posix_thread.c" },
        .flags = &glfw_flags,
    });

    // Link macOS frameworks for GLFW
    glfw.linkFramework("Foundation");
    glfw.linkFramework("CoreFoundation");
    glfw.linkFramework("CoreVideo");
    glfw.linkFramework("IOKit");
    glfw.linkFramework("Cocoa");
    glfw.linkFramework("OpenGL");

    // Add raylib as a static library
    const raylib = b.addStaticLibrary(.{
        .name = "raylib",
        .target = target,
        .optimize = optimize,
    });

    // Add raylib source files
    raylib.addIncludePath(.{ .cwd_relative = "raylib/src" });
    raylib.addIncludePath(.{ .cwd_relative = "raylib/src/external/glfw/include" });

    const base_flags = [_][]const u8{
        "-DPLATFORM_DESKTOP",
        "-DGRAPHICS_API_OPENGL_33",
    };

    const macos_flags = [_][]const u8{
        "-DPLATFORM_DESKTOP",
        "-DGRAPHICS_API_OPENGL_33",
        "-DPLATFORM_APPLE",
        "-D_DARWIN_C_SOURCE",
        "-D_POSIX_C_SOURCE=200809L",
    };

    const flags = if (target.result.os.tag == .macos) &macos_flags else &base_flags;

    // Add source files with platform-specific flags
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/rcore.c" },
        .flags = flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/rshapes.c" },
        .flags = flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/rtextures.c" },
        .flags = flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/rtext.c" },
        .flags = flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/utils.c" },
        .flags = flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "raylib/src/raudio.c" },
        .flags = flags,
    });

    // Link system libraries based on target OS
    if (target.result.os.tag == .windows) {
        raylib.linkSystemLibrary("winmm");
        raylib.linkSystemLibrary("gdi32");
        raylib.linkSystemLibrary("opengl32");
    } else if (target.result.os.tag == .macos) {
        raylib.linkFramework("CoreFoundation");
        raylib.linkFramework("CoreVideo");
        raylib.linkFramework("IOKit");
        raylib.linkFramework("Cocoa");
        raylib.linkFramework("OpenGL");
    } else if (target.result.os.tag == .linux) {
        raylib.linkSystemLibrary("GL");
        raylib.linkSystemLibrary("rt");
        raylib.linkSystemLibrary("dl");
        raylib.linkSystemLibrary("m");
        raylib.linkSystemLibrary("X11");
    }

    // Link GLFW with raylib
    raylib.linkLibrary(glfw);

    // Link raylib with our executable
    exe.linkLibrary(raylib);
    exe.addIncludePath(.{ .cwd_relative = "raylib/src" });

    // Install the executable
    b.installArtifact(exe);

    // Add run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}

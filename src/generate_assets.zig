const std = @import("std");

const ray = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    // Initialize window
    ray.SetConfigFlags(ray.FLAG_WINDOW_HIDDEN); // Hide window since we don't need to show it
    ray.InitWindow(800, 450, "Generate Story Panels");
    if (!ray.IsWindowReady()) {
        std.debug.print("Failed to initialize window\n", .{});
        return error.WindowInitFailed;
    }
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    // Create images for each panel
    const panels = [_]struct { name: [*:0]const u8, color: ray.Color }{
        .{ .name = "panel1.png", .color = ray.DARKBLUE },
        .{ .name = "panel2.png", .color = ray.DARKPURPLE },
        .{ .name = "panel3.png", .color = ray.DARKGREEN },
    };

    for (panels) |panel| {
        // Check if file exists
        if (std.fs.cwd().openFile(panel.name[0..std.mem.len(panel.name)], .{})) |file| {
            file.close();
            std.debug.print("Skipping {s} (already exists)\n", .{panel.name});
        } else |err| {
            switch (err) {
                error.FileNotFound => {
                    // File doesn't exist, generate it
                    std.debug.print("Generating {s}...\n", .{panel.name});

                    // Create image
                    const image = ray.GenImageColor(800, 450, panel.color);

                    // Export image
                    const success = ray.ExportImage(image, panel.name);
                    if (!success) {
                        std.debug.print("Failed to export image: {s}\n", .{panel.name});
                        return error.ImageExportFailed;
                    }

                    // Unload image
                    ray.UnloadImage(image);
                },
                else => {
                    std.debug.print("Error checking file {s}: {any}\n", .{ panel.name, err });
                    return err;
                },
            }
        }
    }
}

const std = @import("std");

const ray = @cImport({
    @cInclude("raylib.h");
});

const AdvancementLevel = struct {
    title: [*:0]const u8,
    color: ray.Color,
};

const CharacterClass = struct {
    name: [*:0]const u8,
    base_color: ray.Color,
    advancement_levels: []const AdvancementLevel,
};

pub fn main() !void {
    // Initialize raylib
    ray.InitWindow(800, 450, "Generate Assets");
    defer ray.CloseWindow();

    // Create assets directory if it doesn't exist
    std.fs.cwd().makeDir("assets") catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    // Create story directory if it doesn't exist
    std.fs.cwd().makeDir("assets/story") catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    // Create avatars directory if it doesn't exist
    std.fs.cwd().makeDir("assets/avatars") catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    // Generate story panels
    const panel_width = 800;
    const panel_height = 450;

    // Generate panel 1
    var image1 = ray.GenImageColor(panel_width, panel_height, ray.BLACK);
    ray.ImageDrawText(&image1, "In a world where darkness threatens to consume all...", 100, 200, 30, ray.WHITE);
    _ = ray.ExportImage(image1, "assets/story/panel1.png");
    ray.UnloadImage(image1);

    // Generate panel 2
    var image2 = ray.GenImageColor(panel_width, panel_height, ray.BLACK);
    ray.ImageDrawText(&image2, "Three ancient powers awaken, each with their own destiny...", 100, 200, 30, ray.WHITE);
    _ = ray.ExportImage(image2, "assets/story/panel2.png");
    ray.UnloadImage(image2);

    // Generate panel 3
    var image3 = ray.GenImageColor(panel_width, panel_height, ray.BLACK);
    ray.ImageDrawText(&image3, "Choose your path, and let your journey begin...", 100, 200, 30, ray.WHITE);
    _ = ray.ExportImage(image3, "assets/story/panel3.png");
    ray.UnloadImage(image3);

    // Generate avatar images
    const avatar_size = 128;

    // Generate strength avatar
    var strength_image = ray.GenImageColor(avatar_size, avatar_size, ray.RED);
    ray.ImageDrawCircle(&strength_image, @divTrunc(avatar_size, 2), @divTrunc(avatar_size, 2), 50, ray.MAROON);
    ray.ImageDrawText(&strength_image, "W", @divTrunc(avatar_size - 20, 2), @divTrunc(avatar_size - 30, 2), 30, ray.WHITE);
    _ = ray.ExportImage(strength_image, "assets/avatars/avatar_strength_0.png");
    ray.UnloadImage(strength_image);

    // Generate speed avatar
    var speed_image = ray.GenImageColor(avatar_size, avatar_size, ray.BLUE);
    ray.ImageDrawCircle(&speed_image, @divTrunc(avatar_size, 2), @divTrunc(avatar_size, 2), 50, ray.DARKBLUE);
    ray.ImageDrawText(&speed_image, "S", @divTrunc(avatar_size - 20, 2), @divTrunc(avatar_size - 30, 2), 30, ray.WHITE);
    _ = ray.ExportImage(speed_image, "assets/avatars/avatar_speed_0.png");
    ray.UnloadImage(speed_image);

    // Generate balanced avatar
    var balanced_image = ray.GenImageColor(avatar_size, avatar_size, ray.GREEN);
    ray.ImageDrawCircle(&balanced_image, @divTrunc(avatar_size, 2), @divTrunc(avatar_size, 2), 50, ray.DARKGREEN);
    ray.ImageDrawText(&balanced_image, "G", @divTrunc(avatar_size - 20, 2), @divTrunc(avatar_size - 30, 2), 30, ray.WHITE);
    _ = ray.ExportImage(balanced_image, "assets/avatars/avatar_balanced_0.png");
    ray.UnloadImage(balanced_image);
}

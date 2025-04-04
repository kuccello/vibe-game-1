const std = @import("std");

const ray = @cImport({
    @cInclude("raylib.h");
});

// Define custom colors not available in raylib
const DARKRED = ray.Color{ .r = 139, .g = 0, .b = 0, .a = 255 };
const DARKGREEN = ray.Color{ .r = 0, .g = 100, .b = 0, .a = 255 };
const DARKBLUE = ray.Color{ .r = 0, .g = 0, .b = 139, .a = 255 };
const DARKPURPLE = ray.Color{ .r = 75, .g = 0, .b = 130, .a = 255 };
const DARKBROWN = ray.Color{ .r = 101, .g = 67, .b = 33, .a = 255 };
const SKYBLUE = ray.Color{ .r = 135, .g = 206, .b = 235, .a = 255 };
const BEIGE = ray.Color{ .r = 245, .g = 245, .b = 220, .a = 255 };
const LIME = ray.Color{ .r = 0, .g = 255, .b = 0, .a = 255 };
const MAROON = ray.Color{ .r = 128, .g = 0, .b = 0, .a = 255 };
const VIOLET = ray.Color{ .r = 238, .g = 130, .b = 238, .a = 255 };

// Function to create a placeholder sprite sheet with frame numbers
fn createSpriteSheet(name: []const u8, width: i32, height: i32, frames: i32, color: ray.Color) !void {
    // Create image for sprite sheet
    const image_width = width * frames;
    var image = ray.GenImageColor(image_width, height, ray.BLANK);
    defer ray.UnloadImage(image);

    // Create font for frame numbers
    const font_size = @divTrunc(@min(width, height), 3);

    // Draw each frame
    for (0..@as(usize, @intCast(frames))) |i| {
        const x = @as(i32, @intCast(i)) * width;

        // Draw colored rectangle with border
        ray.ImageDrawRectangle(&image, x, 0, width, height, color);
        ray.ImageDrawRectangleLines(&image, (ray.Rectangle){ .x = @floatFromInt(x), .y = 0, .width = @floatFromInt(width), .height = @floatFromInt(height) }, 2, ray.BLACK);

        // Draw frame number
        const frame_text = std.fmt.allocPrintZ(std.heap.page_allocator, "{d}", .{i + 1}) catch continue;
        defer std.heap.page_allocator.free(frame_text);

        // Calculate position for centered text
        const text_size = ray.MeasureText(frame_text, font_size);
        const text_x = x + @divTrunc(width - text_size, 2);
        const text_y = @divTrunc(height - font_size, 2);

        // Draw frame number
        ray.ImageDrawText(&image, frame_text, text_x, text_y, font_size, ray.BLACK);
    }

    // Save the image as PNG
    const filename = try std.fmt.allocPrintZ(std.heap.page_allocator, "assets/sprites/{s}.png", .{name});
    defer std.heap.page_allocator.free(filename);

    _ = ray.ExportImage(image, filename);
    std.debug.print("Generated sprite sheet: {s}\n", .{filename});
}

pub fn main() !void {
    // Initialize Raylib
    ray.InitWindow(800, 450, "Sprite Generator");
    defer ray.CloseWindow();

    // Generate player sprites
    try createSpriteSheet("player_warrior_idle", 64, 64, 4, ray.BLUE);
    try createSpriteSheet("player_warrior_run", 64, 64, 4, SKYBLUE);
    try createSpriteSheet("player_warrior_attack", 64, 64, 4, DARKBLUE);

    try createSpriteSheet("player_scout_idle", 64, 64, 4, ray.GREEN);
    try createSpriteSheet("player_scout_run", 64, 64, 4, LIME);
    try createSpriteSheet("player_scout_attack", 64, 64, 4, DARKGREEN);

    try createSpriteSheet("player_guardian_idle", 64, 64, 4, ray.PURPLE);
    try createSpriteSheet("player_guardian_run", 64, 64, 4, VIOLET);
    try createSpriteSheet("player_guardian_attack", 64, 64, 4, DARKPURPLE);

    // Generate enemy sprites
    try createSpriteSheet("enemy_melee_idle", 64, 64, 4, ray.RED);
    try createSpriteSheet("enemy_melee_run", 64, 64, 4, MAROON);
    try createSpriteSheet("enemy_melee_attack", 64, 64, 4, DARKRED);

    try createSpriteSheet("enemy_ranged_idle", 64, 64, 4, ray.YELLOW);
    try createSpriteSheet("enemy_ranged_run", 64, 64, 4, ray.GOLD);
    try createSpriteSheet("enemy_ranged_attack", 64, 64, 4, ray.ORANGE);

    try createSpriteSheet("enemy_charger_idle", 64, 64, 4, ray.BROWN);
    try createSpriteSheet("enemy_charger_run", 64, 64, 4, BEIGE);
    try createSpriteSheet("enemy_charger_attack", 64, 64, 4, DARKBROWN);

    // Generate projectile sprite
    try createSpriteSheet("projectile", 32, 32, 4, ray.WHITE);

    // Generate loot sprites
    try createSpriteSheet("loot_experience", 32, 32, 4, ray.PURPLE);
    try createSpriteSheet("loot_gold", 32, 32, 4, ray.GOLD);
    try createSpriteSheet("loot_energy", 32, 32, 4, ray.BLUE);

    std.debug.print("All sprite sheets generated successfully!\n", .{});
}

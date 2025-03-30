const std = @import("std");

const ray = @cImport({
    @cInclude("raylib.h");
});

const MenuOption = enum {
    StartGame,
    Quit,
};

const CharacterClass = struct {
    name: [*:0]const u8,
    title: [*:0]const u8,
    description: [*:0]const u8,
    stats: struct {
        strength: i32,
        speed: i32,
        health: i32,
    },
    avatar: ray.Texture2D,
};

const GameState = struct {
    screen_width: i32,
    screen_height: i32,
    font_size: i32,
    title_font_size: i32,
    menu_spacing: i32,
    selected_option: MenuOption,
    current_state: enum {
        Menu,
        Story,
        AvatarSelection,
        Playing,
    },
    story_panel: i32,
    story_transition: f32,
    story_panels: [3]ray.Texture2D,
    story_texts: [3][:0]const u8,
    character_cursor: i32,
    character_classes: [3]CharacterClass,
    story_music: ray.Music,
    character_select_music: ray.Music,
    title_music: ray.Music,
    show_help: bool,
    title_background: ray.Texture2D,
};

fn cleanupGameState(game_state: *GameState) void {
    // Unload story panel textures
    for (game_state.story_panels) |texture| {
        ray.UnloadTexture(texture);
    }

    // Unload character avatars
    for (game_state.character_classes) |character| {
        ray.UnloadTexture(character.avatar);
    }

    // Unload music
    ray.UnloadMusicStream(game_state.story_music);
    ray.UnloadMusicStream(game_state.character_select_music);
    ray.UnloadMusicStream(game_state.title_music);

    // Unload title background
    ray.UnloadTexture(game_state.title_background);
}

pub fn main() !void {
    ray.InitWindow(800, 450, "Ancient Powers");
    defer ray.CloseWindow();

    // Initialize audio system
    ray.InitAudioDevice();
    defer ray.CloseAudioDevice();

    ray.SetTargetFPS(60);

    var game_state = initGameState();
    defer cleanupGameState(&game_state);

    // Load story panel textures
    game_state.story_panels[0] = ray.LoadTexture("assets/story/panel1.png");
    game_state.story_panels[1] = ray.LoadTexture("assets/story/panel2.png");
    game_state.story_panels[2] = ray.LoadTexture("assets/story/panel3.png");

    // Load character avatars
    game_state.character_classes[0].avatar = ray.LoadTexture("assets/avatars/avatar_strength_0.png");
    game_state.character_classes[1].avatar = ray.LoadTexture("assets/avatars/avatar_speed_0.png");
    game_state.character_classes[2].avatar = ray.LoadTexture("assets/avatars/avatar_balanced_0.png");

    // Load title background
    game_state.title_background = ray.LoadTexture("assets/title/title1.png");
    if (game_state.title_background.id == 0) {
        std.debug.print("Warning: Could not load title background image. Please ensure 'assets/title/title1.png' exists.\n", .{});
    } else {
        std.debug.print("Successfully loaded title background image.\n", .{});
    }

    // Start title music
    ray.PlayMusicStream(game_state.title_music);

    while (!ray.WindowShouldClose()) {
        updateHelp(&game_state);

        // Update music based on current state
        switch (game_state.current_state) {
            .Menu => ray.UpdateMusicStream(game_state.title_music),
            .Story => ray.UpdateMusicStream(game_state.story_music),
            .AvatarSelection => ray.UpdateMusicStream(game_state.character_select_music),
            .Playing => {},
        }

        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.BLACK);

        switch (game_state.current_state) {
            .Menu => {
                if (!game_state.show_help) updateMenu(&game_state);
                drawMenu(&game_state);
            },
            .Story => {
                if (!game_state.show_help) updateStory(&game_state);
                drawStory(&game_state);
            },
            .AvatarSelection => {
                if (!game_state.show_help) updateCharacterSelect(&game_state);
                drawCharacterSelect(&game_state);
            },
            .Playing => {
                if (!game_state.show_help) updateGame(&game_state);
                drawGame(&game_state);
            },
        }

        // Draw help icon and overlay
        drawHelpIcon(&game_state);
        drawHelpOverlay(&game_state);
    }
}

fn initGameState() GameState {
    // Load music
    const story_music = ray.LoadMusicStream("assets/music/Music1.mp3");
    const character_select_music = ray.LoadMusicStream("assets/music/Music2.mp3");
    const title_music = ray.LoadMusicStream("assets/music/TitleScreen.mp3");

    return .{
        .screen_width = 800,
        .screen_height = 450,
        .font_size = 20,
        .title_font_size = 40,
        .menu_spacing = 40,
        .selected_option = .StartGame,
        .current_state = .Menu,
        .story_panel = 0,
        .story_transition = 0.0,
        .story_panels = undefined,
        .story_texts = [_][:0]const u8{
            "In a world where darkness threatens to consume all...",
            "Three ancient powers awaken, each with their own destiny...",
            "Choose your path, and let your journey begin...",
        },
        .character_cursor = 0,
        .character_classes = [_]CharacterClass{
            .{
                .name = "strength",
                .title = "Warrior",
                .description = "A mighty warrior who excels in close combat. Your strength is legendary, and your presence on the battlefield is feared by all.",
                .stats = .{
                    .strength = 8,
                    .speed = 4,
                    .health = 7,
                },
                .avatar = undefined,
            },
            .{
                .name = "speed",
                .title = "Scout",
                .description = "A swift and agile scout who strikes with precision. Your speed and reflexes make you a deadly opponent in any situation.",
                .stats = .{
                    .strength = 4,
                    .speed = 8,
                    .health = 5,
                },
                .avatar = undefined,
            },
            .{
                .name = "balanced",
                .title = "Guardian",
                .description = "A balanced warrior who combines strength and agility. Your versatility makes you a formidable opponent in any situation.",
                .stats = .{
                    .strength = 6,
                    .speed = 6,
                    .health = 6,
                },
                .avatar = undefined,
            },
        },
        .story_music = story_music,
        .character_select_music = character_select_music,
        .title_music = title_music,
        .show_help = false,
        .title_background = undefined,
    };
}

fn updateMenu(game_state: *GameState) void {
    if (ray.IsKeyPressed(ray.KEY_UP)) {
        game_state.selected_option = switch (game_state.selected_option) {
            .StartGame => .Quit,
            .Quit => .StartGame,
        };
    }
    if (ray.IsKeyPressed(ray.KEY_DOWN)) {
        game_state.selected_option = switch (game_state.selected_option) {
            .StartGame => .Quit,
            .Quit => .StartGame,
        };
    }
    if (ray.IsKeyPressed(ray.KEY_ENTER) or ray.IsKeyPressed(ray.KEY_SPACE)) {
        switch (game_state.selected_option) {
            .StartGame => {
                ray.StopMusicStream(game_state.title_music);
                game_state.current_state = .Story;
                game_state.story_panel = 0;
                game_state.story_transition = 0.0;
                ray.PlayMusicStream(game_state.story_music);
            },
            .Quit => {
                ray.CloseWindow();
            },
        }
    }
}

fn updateStory(game_state: *GameState) void {
    // Update music
    ray.UpdateMusicStream(game_state.story_music);

    if (ray.IsKeyPressed(ray.KEY_SPACE) or ray.IsKeyPressed(ray.KEY_ENTER)) {
        if (game_state.story_panel < 2) {
            game_state.story_panel += 1;
            game_state.story_transition = 0.0;
        } else {
            ray.StopMusicStream(game_state.story_music);
            ray.PlayMusicStream(game_state.character_select_music);
            game_state.current_state = .AvatarSelection;
        }
    }
    if (ray.IsKeyPressed(ray.KEY_ESCAPE)) {
        ray.StopMusicStream(game_state.story_music);
        ray.PlayMusicStream(game_state.character_select_music);
        game_state.current_state = .AvatarSelection;
    }

    // Update transition animation
    if (game_state.story_transition < 1.0) {
        game_state.story_transition += 0.02;
    }
}

fn updateCharacterSelect(game_state: *GameState) void {
    // Update music
    ray.UpdateMusicStream(game_state.character_select_music);

    if (ray.IsKeyPressed(ray.KEY_LEFT)) {
        game_state.character_cursor = if (game_state.character_cursor == 0) 2 else game_state.character_cursor - 1;
    }
    if (ray.IsKeyPressed(ray.KEY_RIGHT)) {
        game_state.character_cursor = if (game_state.character_cursor == 2) 0 else game_state.character_cursor + 1;
    }
    if (ray.IsKeyPressed(ray.KEY_ENTER) or ray.IsKeyPressed(ray.KEY_SPACE)) {
        ray.StopMusicStream(game_state.character_select_music);
        game_state.current_state = .Playing;
    }
    if (ray.IsKeyPressed(ray.KEY_ESCAPE)) {
        ray.StopMusicStream(game_state.character_select_music);
        ray.PlayMusicStream(game_state.story_music);
        game_state.current_state = .Story;
    }
}

fn drawMenu(game_state: *GameState) void {
    // Draw title background if available
    if (game_state.title_background.id != 0) {
        ray.DrawTexture(game_state.title_background, 0, 0, ray.WHITE);
    } else {
        // Fallback: Draw a gradient background
        ray.DrawRectangleGradientV(0, 0, game_state.screen_width, game_state.screen_height, ray.BLUE, ray.BLACK);
    }

    // Draw menu options
    const options = [_][*:0]const u8{ "Start Game", "Quit" };
    for (options, 0..) |option, i| {
        const option_width = ray.MeasureText(option, game_state.font_size);
        const option_x = @divTrunc(game_state.screen_width - option_width, 2);
        const option_y = 250 + (@as(i32, @intCast(i)) * game_state.menu_spacing);
        const color = if (i == @intFromEnum(game_state.selected_option)) ray.WHITE else ray.GRAY;
        ray.DrawText(option, option_x, option_y, game_state.font_size, color);
    }
}

fn drawStory(game_state: *GameState) void {
    // Draw current story panel
    const panel = game_state.story_panels[@as(usize, @intCast(game_state.story_panel))];
    ray.DrawTexture(panel, 0, 0, ray.ColorAlpha(ray.WHITE, game_state.story_transition));
}

fn drawCharacterSelect(game_state: *GameState) void {
    // Draw title
    const title = "Choose Your Character";
    const title_width = ray.MeasureText(title, game_state.title_font_size);
    const title_x = @divTrunc(game_state.screen_width - title_width, 2);
    ray.DrawText(title, title_x, 50, game_state.title_font_size, ray.WHITE);

    // Draw character avatars and info
    const selected_char = &game_state.character_classes[@as(usize, @intCast(game_state.character_cursor))];
    const avatar_size = 128;
    const avatar_y = 100;
    const spacing = 200;
    const center_x = @divTrunc(game_state.screen_width, 2);

    // Draw avatars and titles
    for (game_state.character_classes, 0..) |character, i| {
        const x = center_x + (@as(i32, @intCast(i)) - 1) * spacing;
        const y = avatar_y;
        const source_rect = ray.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(avatar_size), .height = @floatFromInt(avatar_size) };
        const dest_rect = ray.Rectangle{ .x = @floatFromInt(x - @divTrunc(avatar_size, 2)), .y = @floatFromInt(y), .width = @floatFromInt(avatar_size), .height = @floatFromInt(avatar_size) };
        const color = if (i == @as(usize, @intCast(game_state.character_cursor))) ray.WHITE else ray.GRAY;
        ray.DrawTexturePro(character.avatar, source_rect, dest_rect, .{ .x = 0, .y = 0 }, 0, color);

        // Draw character title
        const title_width_char = ray.MeasureText(character.title, game_state.font_size);
        ray.DrawText(character.title, x - @divTrunc(title_width_char, 2), y + avatar_size + 20, game_state.font_size, color);
    }

    // Calculate two-column layout dimensions
    const content_y = avatar_y + avatar_size + 60; // Start content below avatars
    const column_width = @divTrunc(game_state.screen_width, 2) - 40; // Leave margin on sides
    const left_column_x = 40;
    const right_column_x = @divTrunc(game_state.screen_width, 2) + 20;

    // Draw stats in left column
    if (game_state.character_cursor >= 0) {
        const bar_width = column_width - 60; // Leave space for labels
        const bar_height = 15;
        const bar_spacing = 25;
        const stats_y = content_y;

        // Draw stat labels and bars
        const stats = [_]struct { name: [*:0]const u8, value: i32, color: ray.Color }{
            .{ .name = "Health", .value = selected_char.stats.health, .color = ray.RED },
            .{ .name = "Speed", .value = selected_char.stats.speed, .color = ray.BLUE },
            .{ .name = "Strength", .value = selected_char.stats.strength, .color = ray.GREEN },
        };

        for (stats, 0..) |stat, stat_index| {
            const bar_y = stats_y + (@as(i32, @intCast(stat_index)) * bar_spacing);

            // Draw stat label
            const label_width = ray.MeasureText(stat.name, game_state.font_size);
            ray.DrawText(stat.name, left_column_x, bar_y, game_state.font_size, ray.WHITE);

            // Draw stat value
            const value_text = ray.TextFormat("%d/10", stat.value);
            ray.DrawText(value_text, left_column_x + bar_width + 10, bar_y, game_state.font_size, ray.WHITE);

            // Draw bar background
            ray.DrawRectangle(left_column_x + label_width + 10, bar_y, bar_width - label_width - 10, bar_height, ray.ColorAlpha(ray.WHITE, 0.2));

            // Draw filled bar
            const fill_width = @as(i32, @intFromFloat(@as(f32, @floatFromInt(stat.value)) / 10.0 * @as(f32, @floatFromInt(bar_width - label_width - 10))));
            ray.DrawRectangle(left_column_x + label_width + 10, bar_y, fill_width, bar_height, stat.color);

            // Draw bar border
            ray.DrawRectangleLines(left_column_x + label_width + 10, bar_y, bar_width - label_width - 10, bar_height, ray.WHITE);
        }
    }

    // Draw description in right column with word wrapping
    var current_x: i32 = right_column_x;
    var current_y: i32 = content_y;
    var current_word: [100]u8 = undefined;
    var word_index: usize = 0;
    var char_index: usize = 0;

    while (selected_char.description[char_index] != 0) : (char_index += 1) {
        if (selected_char.description[char_index] == ' ') {
            current_word[word_index] = 0;
            const word_width = ray.MeasureText(&current_word, game_state.font_size);

            if (current_x + word_width > right_column_x + column_width) {
                current_x = right_column_x;
                current_y += game_state.font_size + 5;
            }

            ray.DrawText(&current_word, current_x, current_y, game_state.font_size, ray.WHITE);
            current_x += word_width + ray.MeasureText(" ", game_state.font_size);
            word_index = 0;
        } else {
            current_word[word_index] = selected_char.description[char_index];
            word_index += 1;
        }
    }

    // Draw the last word if any
    if (word_index > 0) {
        current_word[word_index] = 0;
        const word_width = ray.MeasureText(&current_word, game_state.font_size);

        if (current_x + word_width > right_column_x + column_width) {
            current_x = right_column_x;
            current_y += game_state.font_size + 5;
        }

        ray.DrawText(&current_word, current_x, current_y, game_state.font_size, ray.WHITE);
    }
}

fn updateGame(game_state: *GameState) void {
    if (ray.IsKeyPressed(ray.KEY_ESCAPE)) {
        game_state.current_state = .Menu;
    }
}

fn drawGame(game_state: *GameState) void {
    // Draw placeholder game screen
    const text = "Game in progress...";
    const text_width = ray.MeasureText(text, game_state.font_size);
    const text_x = @divTrunc(game_state.screen_width - text_width, 2);
    const text_y = @divTrunc(game_state.screen_height - game_state.font_size, 2);
    ray.DrawText(text, text_x, text_y, game_state.font_size, ray.WHITE);
}

fn drawHelpIcon(game_state: *GameState) void {
    const icon_size = 30;
    const padding = 10;
    const x = game_state.screen_width - icon_size - padding;
    const y = padding;

    // Draw circle background
    ray.DrawCircle(x + @divTrunc(icon_size, 2), y + @divTrunc(icon_size, 2), @as(f32, @floatFromInt(icon_size)) / 2.0, ray.WHITE);

    // Draw "?" text
    const question_mark = "?";
    const text_size = 24;
    const text_width = ray.MeasureText(question_mark, text_size);
    const text_x = x + @divTrunc(icon_size - text_width, 2);
    const text_y = y + @divTrunc(icon_size - text_size, 2);
    ray.DrawText(question_mark, text_x, text_y, text_size, ray.BLACK);
}

fn drawHelpOverlay(game_state: *GameState) void {
    if (!game_state.show_help) return;

    // Draw semi-transparent black background
    ray.DrawRectangle(0, 0, game_state.screen_width, game_state.screen_height, ray.ColorAlpha(ray.BLACK, 0.8));

    const help_text = switch (game_state.current_state) {
        .Menu => "Menu Controls:\n\nUse UP/DOWN arrow keys to navigate\nPress SPACE or ENTER to select\n\nPress ? or ESC to close help",
        .Story => "Story Controls:\n\nPress SPACE or ENTER to continue\nPress ESC to skip to character selection\n\nPress ? or ESC to close help",
        .AvatarSelection => "Character Selection Controls:\n\nUse LEFT/RIGHT arrow keys to choose character\nPress SPACE or ENTER to confirm selection\nPress ESC to return to story\n\nPress ? or ESC to close help",
        .Playing => "Game Controls:\n\nPress ESC to return to menu\n\nPress ? or ESC to close help",
    };

    // Calculate text dimensions for the background box
    const line_height = game_state.font_size + 5;
    var max_line_width: i32 = 0;
    var num_lines: i32 = 1;
    var i: usize = 0;

    while (i < help_text.len) : (i += 1) {
        if (help_text[i] == '\n') {
            num_lines += 1;
        } else {
            var line_end = i;
            while (line_end < help_text.len and help_text[line_end] != '\n') : (line_end += 1) {}
            const line = help_text[i..line_end];
            const line_width = ray.MeasureText(@ptrCast(line.ptr), game_state.font_size);
            if (line_width > max_line_width) max_line_width = line_width;
            i = line_end;
        }
    }

    const box_padding = 20;
    const box_width = max_line_width + (box_padding * 2);
    const box_height = (num_lines * line_height) + (box_padding * 2);
    const box_x = @divTrunc(game_state.screen_width - box_width, 2);
    const box_y = @divTrunc(game_state.screen_height - box_height, 2);

    // Draw help box background
    ray.DrawRectangle(box_x, box_y, box_width, box_height, ray.BLACK);
    ray.DrawRectangleLines(box_x, box_y, box_width, box_height, ray.WHITE);

    // Draw help text
    var current_y = box_y + box_padding;
    var start: usize = 0;
    i = 0;

    while (i <= help_text.len) : (i += 1) {
        if (i == help_text.len or help_text[i] == '\n') {
            const line = help_text[start..i];
            const text_x = box_x + box_padding;
            ray.DrawText(@ptrCast(line.ptr), text_x, current_y, game_state.font_size, ray.WHITE);
            current_y += line_height;
            start = i + 1;
        }
    }
}

fn updateHelp(game_state: *GameState) void {
    // Toggle help with question mark key
    if (ray.IsKeyPressed(ray.KEY_SLASH)) {
        game_state.show_help = !game_state.show_help;
    }

    // Toggle help with mouse click on icon
    if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_LEFT)) {
        const mouse_pos = ray.GetMousePosition();
        const icon_size = 30;
        const padding = 10;
        const x = game_state.screen_width - icon_size - padding;
        const y = padding;

        if (mouse_pos.x >= @as(f32, @floatFromInt(x)) and
            mouse_pos.x <= @as(f32, @floatFromInt(x + icon_size)) and
            mouse_pos.y >= @as(f32, @floatFromInt(y)) and
            mouse_pos.y <= @as(f32, @floatFromInt(y + icon_size)))
        {
            game_state.show_help = !game_state.show_help;
        }
    }

    // Close help with escape key
    if (game_state.show_help and ray.IsKeyPressed(ray.KEY_ESCAPE)) {
        game_state.show_help = false;
    }
}

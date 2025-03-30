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

    while (!ray.WindowShouldClose()) {
        switch (game_state.current_state) {
            .Menu => {
                updateMenu(&game_state);
                drawMenu(&game_state);
            },
            .Story => {
                updateStory(&game_state);
                drawStory(&game_state);
            },
            .AvatarSelection => {
                updateCharacterSelect(&game_state);
                drawCharacterSelect(&game_state);
            },
            .Playing => {
                updateGame(&game_state);
                drawGame(&game_state);
            },
        }
    }
}

fn initGameState() GameState {
    // Load music
    const story_music = ray.LoadMusicStream("assets/music/Music1.mp3");
    const character_select_music = ray.LoadMusicStream("assets/music/Music2.mp3");

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
    ray.BeginDrawing();
    defer ray.EndDrawing();

    ray.ClearBackground(ray.BLACK);

    // Draw title
    const title = "Ancient Powers";
    const title_width = ray.MeasureText(title, game_state.title_font_size);
    const title_x = @divTrunc(game_state.screen_width - title_width, 2);
    ray.DrawText(title, title_x, 100, game_state.title_font_size, ray.WHITE);

    // Draw menu options
    const options = [_][*:0]const u8{ "Start Game", "Quit" };
    for (options, 0..) |option, i| {
        const option_width = ray.MeasureText(option, game_state.font_size);
        const option_x = @divTrunc(game_state.screen_width - option_width, 2);
        const option_y = 250 + (@as(i32, @intCast(i)) * game_state.menu_spacing);
        const color = if (i == @intFromEnum(game_state.selected_option)) ray.WHITE else ray.GRAY;
        ray.DrawText(option, option_x, option_y, game_state.font_size, color);
    }

    // Draw instructions
    const instructions = "Use UP/DOWN to select, SPACE/ENTER to confirm";
    const inst_width = ray.MeasureText(instructions, game_state.font_size);
    const inst_x = @divTrunc(game_state.screen_width - inst_width, 2);
    ray.DrawText(instructions, inst_x, game_state.screen_height - 50, game_state.font_size, ray.LIGHTGRAY);
}

fn drawStory(game_state: *GameState) void {
    ray.BeginDrawing();
    defer ray.EndDrawing();

    ray.ClearBackground(ray.BLACK);

    // Draw current story panel
    const panel = game_state.story_panels[@as(usize, @intCast(game_state.story_panel))];
    ray.DrawTexture(panel, 0, 0, ray.ColorAlpha(ray.WHITE, game_state.story_transition));

    // Draw story text
    const text = game_state.story_texts[@as(usize, @intCast(game_state.story_panel))];
    const text_width = ray.MeasureText(text.ptr, game_state.font_size);
    const text_x = @divTrunc(game_state.screen_width - text_width, 2);
    const text_y = game_state.screen_height - 100;
    ray.DrawText(text.ptr, text_x, text_y, game_state.font_size, ray.ColorAlpha(ray.WHITE, game_state.story_transition));

    // Draw instructions
    const instructions = "Press SPACE/ENTER to continue, ESC to skip";
    const inst_width = ray.MeasureText(instructions, game_state.font_size);
    const inst_x = @divTrunc(game_state.screen_width - inst_width, 2);
    ray.DrawText(instructions, inst_x, game_state.screen_height - 50, game_state.font_size, ray.LIGHTGRAY);
}

fn drawCharacterSelect(game_state: *GameState) void {
    ray.BeginDrawing();
    defer ray.EndDrawing();

    ray.ClearBackground(ray.BLACK);

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

    // Draw selected character info
    const info_y = avatar_y + avatar_size + 80;
    const desc_width = 500;
    const desc_x = center_x - @divTrunc(desc_width, 2);
    ray.DrawText(selected_char.description, desc_x, info_y, game_state.font_size, ray.WHITE);

    // Draw stats
    const stats_y = info_y + 80;
    const stats_spacing = 40;
    const stats = [_]struct { name: [*:0]const u8, value: i32 }{
        .{ .name = "Strength", .value = selected_char.stats.strength },
        .{ .name = "Speed", .value = selected_char.stats.speed },
        .{ .name = "Health", .value = selected_char.stats.health },
    };

    for (stats, 0..) |stat, i| {
        const y = stats_y + (@as(i32, @intCast(i)) * stats_spacing);
        const text = ray.TextFormat("%s: %d", stat.name, stat.value);
        const text_width = ray.MeasureText(text, game_state.font_size);
        ray.DrawText(text, center_x - @divTrunc(text_width, 2), y, game_state.font_size, ray.WHITE);
    }

    // Draw instructions
    const instructions = "Use LEFT/RIGHT to select, ENTER/SPACE to confirm, ESC to go back";
    const inst_width = ray.MeasureText(instructions, game_state.font_size);
    const inst_x = @divTrunc(game_state.screen_width - inst_width, 2);
    ray.DrawText(instructions, inst_x, game_state.screen_height - 50, game_state.font_size, ray.LIGHTGRAY);
}

fn updateGame(game_state: *GameState) void {
    if (ray.IsKeyPressed(ray.KEY_ESCAPE)) {
        game_state.current_state = .Menu;
    }
}

fn drawGame(game_state: *GameState) void {
    ray.BeginDrawing();
    defer ray.EndDrawing();

    ray.ClearBackground(ray.BLACK);

    // Draw placeholder game screen
    const text = "Game in progress... Press ESC to return to menu";
    const text_width = ray.MeasureText(text, game_state.font_size);
    const text_x = @divTrunc(game_state.screen_width - text_width, 2);
    const text_y = @divTrunc(game_state.screen_height - game_state.font_size, 2);
    ray.DrawText(text, text_x, text_y, game_state.font_size, ray.WHITE);
}

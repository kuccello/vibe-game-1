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

const Vector2 = struct {
    x: f32,
    y: f32,

    pub fn add(self: Vector2, other: Vector2) Vector2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: Vector2, other: Vector2) Vector2 {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn scale(self: Vector2, factor: f32) Vector2 {
        return .{ .x = self.x * factor, .y = self.y * factor };
    }

    pub fn length(self: Vector2) f32 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }

    pub fn normalize(self: Vector2) Vector2 {
        const len = self.length();
        if (len == 0) return .{ .x = 0, .y = 0 };
        return self.scale(1.0 / len);
    }

    pub fn toRaylib(self: Vector2) ray.Vector2 {
        return .{ .x = self.x, .y = self.y };
    }

    pub fn fromRaylib(v: ray.Vector2) Vector2 {
        return .{ .x = v.x, .y = v.y };
    }
};

const CharacterType = enum {
    Warrior,
    Scout,
    Guardian,
};

const Player = struct {
    position: Vector2,
    velocity: Vector2,
    direction: Vector2,
    health: f32,
    max_health: f32,
    attack_damage: f32,
    attack_range: f32,
    attack_speed: f32,
    attack_timer: f32,
    character_type: CharacterType,
    level: i32,
    experience: f32,
    gold: i32,
    energy: f32,
    hit_timer: f32,
    // Animation fields
    sprite_state: enum {
        Idle,
        Running,
        Attacking,
    } = .Idle,
    animation_frame: i32 = 0,
    animation_timer: f32 = 0,
    animation_speed: f32 = 0.15, // Time in seconds per frame
    is_facing_left: bool = false,
};

const EnemyType = enum {
    Melee,
    Ranged,
    Charger,
};

const Enemy = struct {
    position: Vector2,
    velocity: Vector2,
    health: f32,
    max_health: f32,
    damage: f32,
    attack_range: f32,
    attack_speed: f32,
    attack_timer: f32,
    enemy_type: EnemyType,
    charge_direction: Vector2,
    charge_energy: f32,
    is_charging: bool,
    hit_timer: f32,
    // Animation fields
    sprite_state: enum {
        Idle,
        Running,
        Attacking,
    } = .Idle,
    animation_frame: i32 = 0,
    animation_timer: f32 = 0,
    animation_speed: f32 = 0.15, // Time in seconds per frame
    is_facing_left: bool = false,
};

const Projectile = struct {
    position: Vector2,
    velocity: Vector2,
    damage: f32,
    range: f32,
    distance_traveled: f32,
};

const Loot = struct {
    position: Vector2,
    experience: f32,
    gold: i32,
    energy: f32,
    pickup_radius: f32,
};

const GameWorld = struct {
    player: Player,
    enemies: std.ArrayList(Enemy),
    projectiles: std.ArrayList(Projectile),
    loot: std.ArrayList(Loot),
    spawn_timer: f32,
    spawn_interval: f32,
    difficulty: f32,
    camera: ray.Camera2D,
    level_timer: f32, // Timer in seconds
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
        GameOver,
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
    level_music: ray.Music,
    collect_sound: ray.Sound,
    spawn_sound: ray.Sound,
    warrior_attack_sound: ray.Sound,
    show_help: bool,
    title_background: ray.Texture2D,
    game_world: ?*GameWorld,
    floor_tiles: [3]ray.Texture2D,
    font: ray.Font,
    should_quit: bool,
    // Sprite sheets
    player_sprites: struct {
        warrior: struct {
            idle: ray.Texture2D,
            run: ray.Texture2D,
            attack: ray.Texture2D,
        },
        scout: struct {
            idle: ray.Texture2D,
            run: ray.Texture2D,
            attack: ray.Texture2D,
        },
        guardian: struct {
            idle: ray.Texture2D,
            run: ray.Texture2D,
            attack: ray.Texture2D,
        },
    },
    enemy_sprites: struct {
        melee: struct {
            idle: ray.Texture2D,
            run: ray.Texture2D,
            attack: ray.Texture2D,
        },
        ranged: struct {
            idle: ray.Texture2D,
            run: ray.Texture2D,
            attack: ray.Texture2D,
        },
        charger: struct {
            idle: ray.Texture2D,
            run: ray.Texture2D,
            attack: ray.Texture2D,
        },
    },
    projectile_sprite: ray.Texture2D,
    loot_sprites: struct {
        experience: ray.Texture2D,
        gold: ray.Texture2D,
        energy: ray.Texture2D,
    },
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

    // Unload floor tiles
    for (game_state.floor_tiles) |texture| {
        ray.UnloadTexture(texture);
    }

    // Unload music
    ray.UnloadMusicStream(game_state.story_music);
    ray.UnloadMusicStream(game_state.character_select_music);
    ray.UnloadMusicStream(game_state.title_music);
    ray.UnloadMusicStream(game_state.level_music);

    // Unload sounds
    ray.UnloadSound(game_state.collect_sound);
    ray.UnloadSound(game_state.spawn_sound);
    ray.UnloadSound(game_state.warrior_attack_sound);

    // Unload title background
    ray.UnloadTexture(game_state.title_background);

    // Unload player sprites
    ray.UnloadTexture(game_state.player_sprites.warrior.idle);
    ray.UnloadTexture(game_state.player_sprites.warrior.run);
    ray.UnloadTexture(game_state.player_sprites.warrior.attack);
    ray.UnloadTexture(game_state.player_sprites.scout.idle);
    ray.UnloadTexture(game_state.player_sprites.scout.run);
    ray.UnloadTexture(game_state.player_sprites.scout.attack);
    ray.UnloadTexture(game_state.player_sprites.guardian.idle);
    ray.UnloadTexture(game_state.player_sprites.guardian.run);
    ray.UnloadTexture(game_state.player_sprites.guardian.attack);

    // Unload enemy sprites
    ray.UnloadTexture(game_state.enemy_sprites.melee.idle);
    ray.UnloadTexture(game_state.enemy_sprites.melee.run);
    ray.UnloadTexture(game_state.enemy_sprites.melee.attack);
    ray.UnloadTexture(game_state.enemy_sprites.ranged.idle);
    ray.UnloadTexture(game_state.enemy_sprites.ranged.run);
    ray.UnloadTexture(game_state.enemy_sprites.ranged.attack);
    ray.UnloadTexture(game_state.enemy_sprites.charger.idle);
    ray.UnloadTexture(game_state.enemy_sprites.charger.run);
    ray.UnloadTexture(game_state.enemy_sprites.charger.attack);

    // Unload projectile and loot sprites
    ray.UnloadTexture(game_state.projectile_sprite);
    ray.UnloadTexture(game_state.loot_sprites.experience);
    ray.UnloadTexture(game_state.loot_sprites.gold);
    ray.UnloadTexture(game_state.loot_sprites.energy);
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

    while (!ray.WindowShouldClose() and !game_state.should_quit) {
        updateHelp(&game_state);

        // Update music based on current state
        switch (game_state.current_state) {
            .Menu => ray.UpdateMusicStream(game_state.title_music),
            .Story => ray.UpdateMusicStream(game_state.story_music),
            .AvatarSelection => ray.UpdateMusicStream(game_state.character_select_music),
            .Playing => {},
            .GameOver => {},
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
            .GameOver => {
                if (!game_state.show_help) {
                    if (ray.IsKeyPressed(ray.KEY_ENTER)) {
                        game_state.current_state = .Menu;
                        ray.PlayMusicStream(game_state.title_music);
                    }
                }
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
    const level_music = ray.LoadMusicStream("assets/music/level-music-1.mp3");

    // Load sound effects
    const collect_sound = ray.LoadSound("assets/sounds/Collected1.mp3");
    const spawn_sound = ray.LoadSound("assets/sounds/CreatureArrives.mp3");
    const warrior_attack_sound = ray.LoadSound("assets/sounds/WarriorAttack.mp3");

    // Load floor tiles
    const floor_tiles = [_]ray.Texture2D{
        ray.LoadTexture("assets/tiles/floor-dun-1.png"),
        ray.LoadTexture("assets/tiles/floor-dun-2.png"),
        ray.LoadTexture("assets/tiles/floor-dun-3.png"),
    };

    // Load font
    const font = ray.LoadFont("assets/fonts/font.ttf");

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
        .level_music = level_music,
        .collect_sound = collect_sound,
        .spawn_sound = spawn_sound,
        .warrior_attack_sound = warrior_attack_sound,
        .show_help = false,
        .title_background = undefined,
        .game_world = null,
        .floor_tiles = floor_tiles,
        .font = font,
        .should_quit = false,
        // Sprite sheets
        .player_sprites = .{
            .warrior = .{
                .idle = ray.LoadTexture("assets/sprites/player_warrior_idle.png"),
                .run = ray.LoadTexture("assets/sprites/player_warrior_run.png"),
                .attack = ray.LoadTexture("assets/sprites/player_warrior_attack.png"),
            },
            .scout = .{
                .idle = ray.LoadTexture("assets/sprites/player_scout_idle.png"),
                .run = ray.LoadTexture("assets/sprites/player_scout_run.png"),
                .attack = ray.LoadTexture("assets/sprites/player_scout_attack.png"),
            },
            .guardian = .{
                .idle = ray.LoadTexture("assets/sprites/player_guardian_idle.png"),
                .run = ray.LoadTexture("assets/sprites/player_guardian_run.png"),
                .attack = ray.LoadTexture("assets/sprites/player_guardian_attack.png"),
            },
        },
        .enemy_sprites = .{
            .melee = .{
                .idle = ray.LoadTexture("assets/sprites/enemy_melee_idle.png"),
                .run = ray.LoadTexture("assets/sprites/enemy_melee_run.png"),
                .attack = ray.LoadTexture("assets/sprites/enemy_melee_attack.png"),
            },
            .ranged = .{
                .idle = ray.LoadTexture("assets/sprites/enemy_ranged_idle.png"),
                .run = ray.LoadTexture("assets/sprites/enemy_ranged_run.png"),
                .attack = ray.LoadTexture("assets/sprites/enemy_ranged_attack.png"),
            },
            .charger = .{
                .idle = ray.LoadTexture("assets/sprites/enemy_charger_idle.png"),
                .run = ray.LoadTexture("assets/sprites/enemy_charger_run.png"),
                .attack = ray.LoadTexture("assets/sprites/enemy_charger_attack.png"),
            },
        },
        .projectile_sprite = ray.LoadTexture("assets/sprites/projectile.png"),
        .loot_sprites = .{
            .experience = ray.LoadTexture("assets/sprites/loot_experience.png"),
            .gold = ray.LoadTexture("assets/sprites/loot_gold.png"),
            .energy = ray.LoadTexture("assets/sprites/loot_energy.png"),
        },
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
                game_state.should_quit = true;
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
        ray.PlayMusicStream(game_state.level_music);

        // Initialize game world with selected character
        var character_type: CharacterType = undefined;
        switch (game_state.character_cursor) {
            0 => character_type = .Warrior,
            1 => character_type = .Scout,
            2 => character_type = .Guardian,
            else => unreachable,
        }

        game_state.game_world = initGameWorld(std.heap.page_allocator, character_type) catch {
            std.debug.print("Failed to initialize game world\n", .{});
            return;
        };

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
    if (game_state.game_world == null) return;
    const world = game_state.game_world.?;
    const delta_time = ray.GetFrameTime();

    // Update hit timers
    world.player.hit_timer -= delta_time;

    // Update level timer
    world.level_timer -= delta_time;

    // Update level music
    ray.UpdateMusicStream(game_state.level_music);

    // Check for game over conditions
    if (world.player.health <= 0 or world.level_timer <= 0) {
        // Clean up game world
        cleanupGameWorld(std.heap.page_allocator, world);
        game_state.game_world = null;

        // Stop level music and transition to game over
        ray.StopMusicStream(game_state.level_music);
        game_state.current_state = .GameOver;
        return;
    }

    // Update player movement
    const move_speed = 100.0;
    var move_dir = Vector2{ .x = 0, .y = 0 };

    if (ray.IsKeyDown(ray.KEY_W)) move_dir.y -= 1;
    if (ray.IsKeyDown(ray.KEY_S)) move_dir.y += 1;
    if (ray.IsKeyDown(ray.KEY_A)) move_dir.x -= 1;
    if (ray.IsKeyDown(ray.KEY_D)) move_dir.x += 1;

    if (move_dir.length() > 0) {
        move_dir = move_dir.normalize();
        world.player.velocity = move_dir.scale(move_speed);
        world.player.direction = move_dir;

        // Update facing direction for sprites
        if (move_dir.x < 0) {
            world.player.is_facing_left = true;
        } else if (move_dir.x > 0) {
            world.player.is_facing_left = false;
        }

        // Set to running state if not attacking
        if (world.player.sprite_state != .Attacking) {
            world.player.sprite_state = .Running;
        }
    } else {
        world.player.velocity = .{ .x = 0, .y = 0 };

        // Set to idle state if not attacking
        if (world.player.sprite_state != .Attacking) {
            world.player.sprite_state = .Idle;
        }
    }

    // Update player position
    world.player.position = world.player.position.add(world.player.velocity.scale(delta_time));

    // Update camera to follow player
    world.camera.target = world.player.position.toRaylib();
    world.camera.offset = .{ .x = @as(f32, @floatFromInt(game_state.screen_width)) / 2.0, .y = @as(f32, @floatFromInt(game_state.screen_height)) / 2.0 };

    // Update player attack
    world.player.attack_timer -= delta_time;
    if (world.player.attack_timer <= 0) {
        world.player.attack_timer = 1.0 / world.player.attack_speed;

        // Set to attacking sprite state
        world.player.sprite_state = .Attacking;
        world.player.animation_frame = 0; // Reset animation frame for attack
        world.player.animation_timer = 0; // Reset animation timer for attack

        // Perform attack based on character type
        switch (world.player.character_type) {
            .Warrior => {
                // Play warrior attack sound
                ray.PlaySound(game_state.warrior_attack_sound);

                // Melee attack
                for (world.enemies.items) |*enemy| {
                    const dist = enemy.position.sub(world.player.position).length();
                    if (dist <= world.player.attack_range) {
                        enemy.health -= world.player.attack_damage;
                        if (enemy.health <= 0) {
                            // Spawn loot
                            world.loot.append(.{
                                .position = enemy.position,
                                .experience = 10.0 * world.difficulty,
                                .gold = @intFromFloat(5.0 * world.difficulty),
                                .energy = 5.0 * world.difficulty,
                                .pickup_radius = 50,
                            }) catch {};
                        }
                    }
                }
            },
            .Scout => {
                // Ranged attack
                world.projectiles.append(.{
                    .position = world.player.position,
                    .velocity = world.player.direction.scale(300),
                    .damage = world.player.attack_damage,
                    .range = world.player.attack_range,
                    .distance_traveled = 0,
                }) catch {};
            },
            .Guardian => {
                // Balanced attack
                for (world.enemies.items) |*enemy| {
                    const dist = enemy.position.sub(world.player.position).length();
                    if (dist <= world.player.attack_range) {
                        enemy.health -= world.player.attack_damage;
                        if (enemy.health <= 0) {
                            world.loot.append(.{
                                .position = enemy.position,
                                .experience = 10.0 * world.difficulty,
                                .gold = @intFromFloat(5.0 * world.difficulty),
                                .energy = 5.0 * world.difficulty,
                                .pickup_radius = 50,
                            }) catch {};
                        }
                    }
                }
            },
        }
    } else if (world.player.sprite_state == .Attacking) {
        // Return to idle or running after attack animation completes (4 frames)
        if (world.player.animation_frame >= 3) {
            world.player.sprite_state = if (world.player.velocity.length() > 0) .Running else .Idle;
        }
    }

    // Update player animation timer and frame
    world.player.animation_timer += delta_time;
    if (world.player.animation_timer >= world.player.animation_speed) {
        world.player.animation_timer = 0;
        world.player.animation_frame = @mod(world.player.animation_frame + 1, 4); // 4 frames per animation
    }

    // Update projectiles
    var i: usize = 0;
    while (i < world.projectiles.items.len) {
        const proj = &world.projectiles.items[i];
        proj.position = proj.position.add(proj.velocity.scale(delta_time));
        proj.distance_traveled += proj.velocity.length() * delta_time;

        var should_remove = false;

        // Check for hits on player only
        const dist_to_player = world.player.position.sub(proj.position).length();
        if (dist_to_player < 20) {
            world.player.health -= proj.damage;
            world.player.hit_timer = 0.5; // Set hit timer for 0.5 seconds
            should_remove = true;
        }

        // Check if projectile has traveled its range
        if (!should_remove and proj.distance_traveled >= proj.range) {
            should_remove = true;
        }

        // Remove projectile if needed
        if (should_remove) {
            _ = world.projectiles.orderedRemove(i);
        } else {
            i += 1;
        }
    }

    // Update enemies
    i = 0;
    while (i < world.enemies.items.len) {
        const enemy = &world.enemies.items[i];
        enemy.hit_timer -= delta_time;

        // Update enemy position
        const dir_to_player = world.player.position.sub(enemy.position).normalize();
        enemy.velocity = dir_to_player.scale(50.0);
        enemy.position = enemy.position.add(enemy.velocity.scale(delta_time));

        // Update enemy facing direction
        if (dir_to_player.x < 0) {
            enemy.is_facing_left = true;
        } else {
            enemy.is_facing_left = false;
        }

        // Update enemy sprite state
        if (enemy.velocity.length() > 0) {
            if (enemy.sprite_state != .Attacking) {
                enemy.sprite_state = .Running;
            }
        } else if (enemy.sprite_state != .Attacking) {
            enemy.sprite_state = .Idle;
        }

        // Update enemy animation timer and frame
        enemy.animation_timer += delta_time;
        if (enemy.animation_timer >= enemy.animation_speed) {
            enemy.animation_timer = 0;
            enemy.animation_frame = @mod(enemy.animation_frame + 1, 4); // 4 frames per animation
        }

        // Update enemy attack
        enemy.attack_timer -= delta_time;
        if (enemy.attack_timer <= 0) {
            enemy.attack_timer = 1.0 / enemy.attack_speed;

            // Set to attacking sprite state
            enemy.sprite_state = .Attacking;
            enemy.animation_frame = 0; // Reset animation frame for attack
            enemy.animation_timer = 0; // Reset animation timer for attack

            switch (enemy.enemy_type) {
                .Melee => {
                    const dist = enemy.position.sub(world.player.position).length();
                    if (dist <= enemy.attack_range) {
                        world.player.health -= enemy.damage;
                        world.player.hit_timer = 0.5; // Set hit timer for 0.5 seconds
                    }
                },
                .Ranged => {
                    world.projectiles.append(.{
                        .position = enemy.position,
                        .velocity = dir_to_player.scale(300),
                        .damage = enemy.damage,
                        .range = enemy.attack_range,
                        .distance_traveled = 0,
                    }) catch {};
                },
                .Charger => {
                    if (!enemy.is_charging) {
                        enemy.charge_energy += delta_time;
                        if (enemy.charge_energy >= 2.0) {
                            enemy.is_charging = true;
                            enemy.charge_direction = dir_to_player;
                            enemy.charge_energy = 0;
                        }
                    } else {
                        enemy.velocity = enemy.charge_direction.scale(300.0);
                        enemy.position = enemy.position.add(enemy.velocity.scale(delta_time));
                        const dist = enemy.position.sub(world.player.position).length();
                        if (dist < 20) {
                            world.player.health -= enemy.damage * 2;
                            enemy.is_charging = false;
                        }
                    }
                },
            }
        } else if (enemy.sprite_state == .Attacking) {
            // Return to idle or running after attack animation completes
            if (enemy.animation_frame >= 3) {
                enemy.sprite_state = if (enemy.velocity.length() > 0) .Running else .Idle;
            }
        }

        // Remove dead enemies
        if (enemy.health <= 0) {
            _ = world.enemies.swapRemove(i);
        } else {
            i += 1;
        }
    }

    // Update loot collection
    i = 0;
    while (i < world.loot.items.len) {
        const loot = &world.loot.items[i];
        const dist = loot.position.sub(world.player.position).length();
        if (dist <= loot.pickup_radius) {
            world.player.experience += loot.experience;
            world.player.gold += loot.gold;
            world.player.energy += loot.energy;
            ray.PlaySound(game_state.collect_sound);
            _ = world.loot.swapRemove(i);
        } else {
            i += 1;
        }
    }

    // Spawn new enemies
    world.spawn_timer -= delta_time;
    if (world.spawn_timer <= 0) {
        world.spawn_timer = world.spawn_interval;
        ray.PlaySound(game_state.spawn_sound);

        // Spawn position away from player
        const spawn_dist = 400.0;
        const angle = @as(f32, @floatFromInt(world.enemies.items.len)) * 2.0 * std.math.pi / 3.0;
        const spawn_pos = Vector2{
            .x = world.player.position.x + @cos(angle) * spawn_dist,
            .y = world.player.position.y + @sin(angle) * spawn_dist,
        };

        // Random enemy type
        const enemy_type = @as(EnemyType, @enumFromInt(world.enemies.items.len % 3));
        const enemy = switch (enemy_type) {
            .Melee => Enemy{
                .position = spawn_pos,
                .velocity = .{ .x = 0, .y = 0 },
                .health = 50 * world.difficulty,
                .max_health = 50 * world.difficulty,
                .damage = 10 * world.difficulty,
                .attack_range = 40,
                .attack_speed = 1.0,
                .attack_timer = 0,
                .enemy_type = .Melee,
                .charge_direction = .{ .x = 0, .y = 0 },
                .charge_energy = 0,
                .is_charging = false,
                .hit_timer = 0,
                .sprite_state = .Idle,
                .animation_frame = 0,
                .animation_timer = 0,
                .animation_speed = 0.15,
                .is_facing_left = false,
            },
            .Ranged => Enemy{
                .position = spawn_pos,
                .velocity = .{ .x = 0, .y = 0 },
                .health = 30 * world.difficulty,
                .max_health = 30 * world.difficulty,
                .damage = 8 * world.difficulty,
                .attack_range = 200,
                .attack_speed = 1.5,
                .attack_timer = 0,
                .enemy_type = .Ranged,
                .charge_direction = .{ .x = 0, .y = 0 },
                .charge_energy = 0,
                .is_charging = false,
                .hit_timer = 0,
                .sprite_state = .Idle,
                .animation_frame = 0,
                .animation_timer = 0,
                .animation_speed = 0.15,
                .is_facing_left = false,
            },
            .Charger => Enemy{
                .position = spawn_pos,
                .velocity = .{ .x = 0, .y = 0 },
                .health = 70 * world.difficulty,
                .max_health = 70 * world.difficulty,
                .damage = 15 * world.difficulty,
                .attack_range = 100,
                .attack_speed = 0.5,
                .attack_timer = 0,
                .enemy_type = .Charger,
                .charge_direction = .{ .x = 0, .y = 0 },
                .charge_energy = 0,
                .is_charging = false,
                .hit_timer = 0,
                .sprite_state = .Idle,
                .animation_frame = 0,
                .animation_timer = 0,
                .animation_speed = 0.15,
                .is_facing_left = false,
            },
        };

        world.enemies.append(enemy) catch {};
    }
}

fn invertColor(color: ray.Color) ray.Color {
    return .{
        .r = @as(u8, @intCast(255 - color.r)),
        .g = @as(u8, @intCast(255 - color.g)),
        .b = @as(u8, @intCast(255 - color.b)),
        .a = color.a,
    };
}

fn drawGame(game_state: *GameState) void {
    // Draw game over message if in game over state
    if (game_state.current_state == .GameOver) {
        // Draw semi-transparent black background
        ray.DrawRectangle(0, 0, game_state.screen_width, game_state.screen_height, ray.ColorAlpha(ray.BLACK, 0.7));

        // Draw game over message
        const message = "The Ancient Power has eluded you!";
        const message_size = 40;
        const message_width = ray.MeasureText(message, message_size);
        const message_x = @divTrunc(game_state.screen_width - message_width, 2);
        const message_y = @divTrunc(game_state.screen_height, 2) - message_size;

        // Draw message with shadow for better visibility
        ray.DrawText(message, message_x + 2, message_y + 2, message_size, ray.BLACK);
        ray.DrawText(message, message_x, message_y, message_size, ray.WHITE);

        // Draw continue prompt
        const prompt = "Press ENTER to continue";
        const prompt_size = 20;
        const prompt_width = ray.MeasureText(prompt, prompt_size);
        const prompt_x = @divTrunc(game_state.screen_width - prompt_width, 2);
        const prompt_y = message_y + message_size + 20;
        ray.DrawText(prompt, prompt_x, prompt_y, prompt_size, ray.WHITE);
        return;
    }

    // Only draw game world if we're in the playing state
    if (game_state.game_world == null) return;
    const world = game_state.game_world.?;

    // Begin camera mode
    ray.BeginMode2D(world.camera);

    // Draw floor tiles
    const tile_size = 32.0; // Assuming tiles are 32x32 pixels
    const camera_pos = world.camera.target;
    const camera_zoom = world.camera.zoom;
    const screen_width = @as(f32, @floatFromInt(game_state.screen_width));
    const screen_height = @as(f32, @floatFromInt(game_state.screen_height));

    // Calculate visible area in world coordinates
    const visible_width = screen_width / camera_zoom;
    const visible_height = screen_height / camera_zoom;

    // Calculate tile grid boundaries
    const start_x = camera_pos.x - visible_width / 2 - tile_size;
    const start_y = camera_pos.y - visible_height / 2 - tile_size;
    const end_x = camera_pos.x + visible_width / 2 + tile_size;
    const end_y = camera_pos.y + visible_height / 2 + tile_size;

    // Align to tile grid
    const grid_start_x = @floor(start_x / tile_size) * tile_size;
    const grid_start_y = @floor(start_y / tile_size) * tile_size;

    var x = grid_start_x;
    while (x < end_x) : (x += tile_size) {
        var y = grid_start_y;
        while (y < end_y) : (y += tile_size) {
            // Use a more robust hashing method that handles negative numbers
            const tile_x = @as(i32, @intFromFloat(@divFloor(x, tile_size)));
            const tile_y = @as(i32, @intFromFloat(@divFloor(y, tile_size)));
            const hash = @as(u32, @intCast(@abs(tile_x *% tile_y)));
            const tile_index = if (hash % 100 < 5) // 5% chance for variant tiles
                @as(usize, @intFromFloat(@mod(@as(f32, @floatFromInt(hash)), 3)))
            else
                0; // Use main tile (floor-dun-1) 95% of the time

            const tile = game_state.floor_tiles[tile_index];
            ray.DrawTextureV(tile, .{ .x = x, .y = y }, ray.WHITE);
        }
    }

    // Draw player with appropriate sprite
    {
        // Select the appropriate sprite texture based on player state and character type
        const sprite_texture = switch (world.player.character_type) {
            .Warrior => switch (world.player.sprite_state) {
                .Idle => game_state.player_sprites.warrior.idle,
                .Running => game_state.player_sprites.warrior.run,
                .Attacking => game_state.player_sprites.warrior.attack,
            },
            .Scout => switch (world.player.sprite_state) {
                .Idle => game_state.player_sprites.scout.idle,
                .Running => game_state.player_sprites.scout.run,
                .Attacking => game_state.player_sprites.scout.attack,
            },
            .Guardian => switch (world.player.sprite_state) {
                .Idle => game_state.player_sprites.guardian.idle,
                .Running => game_state.player_sprites.guardian.run,
                .Attacking => game_state.player_sprites.guardian.attack,
            },
        };

        // Calculate frame width based on the sprite sheet width divided by 4 (frames per animation)
        const frame_width = @divTrunc(sprite_texture.width, 4);
        const frame_height = sprite_texture.height;

        // Calculate source rectangle for current animation frame
        const source_rect = ray.Rectangle{
            .x = @as(f32, @floatFromInt(world.player.animation_frame * frame_width)),
            .y = 0,
            .width = @as(f32, @floatFromInt(frame_width)),
            .height = @as(f32, @floatFromInt(frame_height)),
        };

        // Calculate destination rectangle
        const sprite_size = 64; // The size to render the sprite
        const dest_rect = ray.Rectangle{
            .x = world.player.position.x - @as(f32, @floatFromInt(sprite_size)) / 2.0,
            .y = world.player.position.y - @as(f32, @floatFromInt(sprite_size)) / 2.0,
            .width = @as(f32, @floatFromInt(sprite_size)),
            .height = @as(f32, @floatFromInt(sprite_size)),
        };

        // Determine whether to flip the sprite horizontally
        const flip_horizontal = world.player.is_facing_left;
        const sprite_width = if (flip_horizontal) -@as(f32, @floatFromInt(frame_width)) else @as(f32, @floatFromInt(frame_width));

        // Draw the sprite with the current animation frame
        const modified_source_rect = ray.Rectangle{
            .x = source_rect.x,
            .y = source_rect.y,
            .width = sprite_width,
            .height = source_rect.height,
        };
        ray.DrawTexturePro(sprite_texture, modified_source_rect, dest_rect, .{ .x = 0, .y = 0 }, 0, ray.WHITE);

        // Draw player hit indicator
        if (world.player.hit_timer > 0) {
            const hit_pos = world.player.position.sub(.{ .x = 0, .y = 30 });
            const hit_x = @as(i32, @intFromFloat(hit_pos.toRaylib().x - 5));
            const hit_y = @as(i32, @intFromFloat(hit_pos.toRaylib().y - 10));
            ray.DrawText("!", hit_x, hit_y, 20, ray.RED);
        }
    }

    // Draw enemies with appropriate sprites
    for (world.enemies.items) |enemy| {
        // Select the appropriate sprite texture based on enemy state and type
        const sprite_texture = switch (enemy.enemy_type) {
            .Melee => switch (enemy.sprite_state) {
                .Idle => game_state.enemy_sprites.melee.idle,
                .Running => game_state.enemy_sprites.melee.run,
                .Attacking => game_state.enemy_sprites.melee.attack,
            },
            .Ranged => switch (enemy.sprite_state) {
                .Idle => game_state.enemy_sprites.ranged.idle,
                .Running => game_state.enemy_sprites.ranged.run,
                .Attacking => game_state.enemy_sprites.ranged.attack,
            },
            .Charger => switch (enemy.sprite_state) {
                .Idle => game_state.enemy_sprites.charger.idle,
                .Running => game_state.enemy_sprites.charger.run,
                .Attacking => game_state.enemy_sprites.charger.attack,
            },
        };

        // Calculate frame width based on the sprite sheet width divided by 4 (frames per animation)
        const frame_width = @divTrunc(sprite_texture.width, 4);
        const frame_height = sprite_texture.height;

        // Calculate source rectangle for current animation frame
        const source_rect = ray.Rectangle{
            .x = @as(f32, @floatFromInt(enemy.animation_frame * frame_width)),
            .y = 0,
            .width = @as(f32, @floatFromInt(frame_width)),
            .height = @as(f32, @floatFromInt(frame_height)),
        };

        // Calculate destination rectangle
        const sprite_size = 64; // The size to render the sprite
        const dest_rect = ray.Rectangle{
            .x = enemy.position.x - @as(f32, @floatFromInt(sprite_size)) / 2.0,
            .y = enemy.position.y - @as(f32, @floatFromInt(sprite_size)) / 2.0,
            .width = @as(f32, @floatFromInt(sprite_size)),
            .height = @as(f32, @floatFromInt(sprite_size)),
        };

        // Determine whether to flip the sprite horizontally
        const flip_horizontal = enemy.is_facing_left;
        const sprite_width = if (flip_horizontal) -@as(f32, @floatFromInt(frame_width)) else @as(f32, @floatFromInt(frame_width));

        // Draw the sprite with the current animation frame
        const modified_source_rect = ray.Rectangle{
            .x = source_rect.x,
            .y = source_rect.y,
            .width = sprite_width,
            .height = source_rect.height,
        };
        ray.DrawTexturePro(sprite_texture, modified_source_rect, dest_rect, .{ .x = 0, .y = 0 }, 0, ray.WHITE);

        // Draw enemy hit indicator
        if (enemy.hit_timer > 0) {
            const hit_pos = enemy.position.sub(.{ .x = 0, .y = 25 });
            const hit_x = @as(i32, @intFromFloat(hit_pos.toRaylib().x - 5));
            const hit_y = @as(i32, @intFromFloat(hit_pos.toRaylib().y - 10));
            ray.DrawText("!", hit_x, hit_y, 20, ray.RED);
        }

        // Draw health bar
        const health_percent = enemy.health / enemy.max_health;
        ray.DrawRectangleV(enemy.position.sub(.{ .x = 20, .y = 25 }).toRaylib(), .{ .x = 40, .y = 5 }, ray.RED);
        ray.DrawRectangleV(enemy.position.sub(.{ .x = 20, .y = 25 }).toRaylib(), .{ .x = 40 * health_percent, .y = 5 }, ray.GREEN);

        // Draw charge indicator for charger enemies
        if (enemy.enemy_type == .Charger and enemy.is_charging) {
            ray.DrawLineV(enemy.position.toRaylib(), enemy.position.add(enemy.charge_direction.scale(50)).toRaylib(), ray.YELLOW);
        }
    }

    // Draw projectiles
    for (world.projectiles.items) |proj| {
        // Calculate animation frame (cycling through frames)
        const frame_time = @as(f32, @floatCast(ray.GetTime()));
        const animation_frame = @as(i32, @intFromFloat(@mod(frame_time * 5.0, 4.0)));

        // Calculate frame width based on the sprite sheet width divided by 4 (frames per animation)
        const frame_width = @divTrunc(game_state.projectile_sprite.width, 4);
        const frame_height = game_state.projectile_sprite.height;

        // Calculate source rectangle for current animation frame
        const source_rect = ray.Rectangle{
            .x = @as(f32, @floatFromInt(animation_frame * frame_width)),
            .y = 0,
            .width = @as(f32, @floatFromInt(frame_width)),
            .height = @as(f32, @floatFromInt(frame_height)),
        };

        // Calculate destination rectangle
        const sprite_size = 32; // The size to render the sprite
        const dest_rect = ray.Rectangle{
            .x = proj.position.x - @as(f32, @floatFromInt(sprite_size)) / 2.0,
            .y = proj.position.y - @as(f32, @floatFromInt(sprite_size)) / 2.0,
            .width = @as(f32, @floatFromInt(sprite_size)),
            .height = @as(f32, @floatFromInt(sprite_size)),
        };

        // Draw the projectile sprite
        const modified_source_rect = ray.Rectangle{
            .x = source_rect.x,
            .y = source_rect.y,
            .width = source_rect.width,
            .height = source_rect.height,
        };
        ray.DrawTexturePro(game_state.projectile_sprite, modified_source_rect, dest_rect, .{ .x = 0, .y = 0 }, 0, ray.WHITE);
    }

    // Draw loot with distinct sprites
    for (world.loot.items) |loot| {
        // Calculate animation frame (cycling through frames based on time)
        const frame_time = @as(f32, @floatCast(ray.GetTime()));
        const animation_frame = @as(i32, @intFromFloat(@mod(frame_time * 5.0, 4.0)));

        // Select the appropriate sprite texture based on loot type
        const sprite_texture = if (loot.experience > 0)
            game_state.loot_sprites.experience // Experience orbs
        else if (loot.gold > 0)
            game_state.loot_sprites.gold // Gold coins
        else
            game_state.loot_sprites.energy; // Energy crystals

        // Calculate frame width based on the sprite sheet width divided by 4 (frames per animation)
        const frame_width = @divTrunc(sprite_texture.width, 4);
        const frame_height = sprite_texture.height;

        // Calculate source rectangle for current animation frame
        const source_rect = ray.Rectangle{
            .x = @as(f32, @floatFromInt(animation_frame * frame_width)),
            .y = 0,
            .width = @as(f32, @floatFromInt(frame_width)),
            .height = @as(f32, @floatFromInt(frame_height)),
        };

        // Calculate destination rectangle
        const sprite_size = 32; // The size to render the sprite
        const dest_rect = ray.Rectangle{
            .x = loot.position.x - @as(f32, @floatFromInt(sprite_size)) / 2.0,
            .y = loot.position.y - @as(f32, @floatFromInt(sprite_size)) / 2.0,
            .width = @as(f32, @floatFromInt(sprite_size)),
            .height = @as(f32, @floatFromInt(sprite_size)),
        };

        // Draw the loot sprite
        const modified_source_rect = ray.Rectangle{
            .x = source_rect.x,
            .y = source_rect.y,
            .width = source_rect.width,
            .height = source_rect.height,
        };
        ray.DrawTexturePro(sprite_texture, modified_source_rect, dest_rect, .{ .x = 0, .y = 0 }, 0, ray.WHITE);
    }

    ray.EndMode2D();

    // Draw UI elements (not affected by camera)
    const ui_y = 10;
    ray.DrawText(ray.TextFormat("Health: %.1f/%.1f", world.player.health, world.player.max_health), 10, ui_y, 20, ray.WHITE);
    ray.DrawText(ray.TextFormat("Level: %d", world.player.level), 10, ui_y + 25, 20, ray.WHITE);
    ray.DrawText(ray.TextFormat("Experience: %.1f", world.player.experience), 10, ui_y + 50, 20, ray.WHITE);
    ray.DrawText(ray.TextFormat("Gold: %d", world.player.gold), 10, ui_y + 75, 20, ray.WHITE);
    ray.DrawText(ray.TextFormat("Energy: %.1f", world.player.energy), 10, ui_y + 100, 20, ray.WHITE);

    // Draw timer
    const minutes = @as(i32, @intFromFloat(world.level_timer / 60.0));
    const seconds = @as(i32, @intFromFloat(@mod(world.level_timer, 60.0)));
    const timer_text = std.fmt.allocPrint(
        std.heap.page_allocator,
        "{:0>2}:{:0>2}",
        .{ minutes, seconds },
    ) catch return;
    defer std.heap.page_allocator.free(timer_text);

    const timer_font_size = 40;
    const timer_width = ray.MeasureText(timer_text.ptr, timer_font_size);
    const timer_x = @divTrunc(game_state.screen_width - timer_width, 2);
    const timer_y = 20;

    // Draw timer background
    const padding = 10;
    ray.DrawRectangle(
        timer_x - padding,
        timer_y - padding,
        timer_width + (padding * 2),
        timer_font_size + (padding * 2),
        ray.ColorAlpha(ray.BLACK, 0.5),
    );

    // Draw timer text
    ray.DrawText(timer_text.ptr, timer_x, timer_y, timer_font_size, ray.WHITE);

    // Draw game over message if timer is running low
    if (world.level_timer <= 30.0) {
        const warning_text = "Time's running out!";
        const warning_font_size = 30;
        const warning_width = ray.MeasureText(warning_text.ptr, warning_font_size);
        const warning_x = @divTrunc(game_state.screen_width - warning_width, 2);
        const warning_y = timer_y + timer_font_size + padding;

        // Draw warning background
        ray.DrawRectangle(
            warning_x - padding,
            warning_y - padding,
            warning_width + (padding * 2),
            warning_font_size + (padding * 2),
            ray.ColorAlpha(ray.RED, 0.5),
        );

        // Draw warning text
        ray.DrawText(warning_text.ptr, warning_x, warning_y, warning_font_size, ray.WHITE);
    }
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
        .GameOver => "Game Over:\n\nPress ENTER to return to menu\n\nPress ? or ESC to close help",
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

fn initGameWorld(allocator: std.mem.Allocator, character_type: CharacterType) !*GameWorld {
    const game_world = try allocator.create(GameWorld);
    errdefer allocator.destroy(game_world);

    // Initialize player based on character type
    const player = switch (character_type) {
        .Warrior => Player{
            .position = .{ .x = 0, .y = 0 },
            .velocity = .{ .x = 0, .y = 0 },
            .direction = .{ .x = 1, .y = 0 },
            .health = 100,
            .max_health = 100,
            .attack_damage = 20,
            .attack_range = 50,
            .attack_speed = 1.0,
            .attack_timer = 0,
            .character_type = .Warrior,
            .level = 1,
            .experience = 0,
            .gold = 0,
            .energy = 0,
            .hit_timer = 0,
        },
        .Scout => Player{
            .position = .{ .x = 0, .y = 0 },
            .velocity = .{ .x = 0, .y = 0 },
            .direction = .{ .x = 1, .y = 0 },
            .health = 80,
            .max_health = 80,
            .attack_damage = 15,
            .attack_range = 200,
            .attack_speed = 1.5,
            .attack_timer = 0,
            .character_type = .Scout,
            .level = 1,
            .experience = 0,
            .gold = 0,
            .energy = 0,
            .hit_timer = 0,
        },
        .Guardian => Player{
            .position = .{ .x = 0, .y = 0 },
            .velocity = .{ .x = 0, .y = 0 },
            .direction = .{ .x = 1, .y = 0 },
            .health = 120,
            .max_health = 120,
            .attack_damage = 12,
            .attack_range = 75,
            .attack_speed = 1.2,
            .attack_timer = 0,
            .character_type = .Guardian,
            .level = 1,
            .experience = 0,
            .gold = 0,
            .energy = 0,
            .hit_timer = 0,
        },
    };

    game_world.* = .{
        .player = player,
        .enemies = std.ArrayList(Enemy).init(allocator),
        .projectiles = std.ArrayList(Projectile).init(allocator),
        .loot = std.ArrayList(Loot).init(allocator),
        .spawn_timer = 0,
        .spawn_interval = 2.0,
        .difficulty = 1.0,
        .camera = ray.Camera2D{
            .offset = .{ .x = 400, .y = 225 },
            .target = player.position.toRaylib(),
            .rotation = 0,
            .zoom = 1,
        },
        .level_timer = 600.0, // 10 minutes in seconds
    };

    return game_world;
}

fn cleanupGameWorld(allocator: std.mem.Allocator, game_world: *GameWorld) void {
    game_world.enemies.deinit();
    game_world.projectiles.deinit();
    game_world.loot.deinit();
    allocator.destroy(game_world);
}

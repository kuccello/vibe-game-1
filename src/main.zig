const std = @import("std");

const ray = @cImport({
    @cInclude("raylib.h");
});

const MenuOption = enum {
    StartGame,
    Options,
    About,
    Exit,

    pub fn toString(self: MenuOption) [:0]const u8 {
        return switch (self) {
            .StartGame => "Start Game",
            .Options => "Options",
            .About => "About",
            .Exit => "Exit",
        };
    }
};

const GameState = struct {
    selected_option: MenuOption = .StartGame,
    screen_width: i32 = 800,
    screen_height: i32 = 450,
    title_font_size: i32 = 40,
    font_size: i32 = 20,
    menu_spacing: i32 = 40,
    should_exit: bool = false,
    current_state: enum {
        Menu,
        Story,
        AvatarSelection,
    } = .Menu,
    story_panel: i32 = 0,
    story_transition: f32 = 0.0,
    story_panels: [3]ray.Texture2D = undefined,
    story_texts: [3][:0]const u8 = .{
        "In the year 2157, humanity faced its greatest challenge...",
        "The alien fleet appeared without warning, their ships blotting out the stars...",
        "But humanity would not go quietly into the night...",
    },
};

pub fn main() !void {
    var game_state = GameState{};

    // Initialize GLFW first
    ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT);
    ray.InitWindow(game_state.screen_width, game_state.screen_height, "Game Menu");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    // Load story panel images
    game_state.story_panels[0] = ray.LoadTexture("assets/story/panel1.png");
    game_state.story_panels[1] = ray.LoadTexture("assets/story/panel2.png");
    game_state.story_panels[2] = ray.LoadTexture("assets/story/panel3.png");

    // Defer unloading textures
    defer {
        for (game_state.story_panels) |panel| {
            ray.UnloadTexture(panel);
        }
    }

    while (!ray.WindowShouldClose() and !game_state.should_exit) {
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
                // TODO: Implement avatar selection
                game_state.current_state = .Menu;
            },
        }
    }
}

fn updateMenu(game_state: *GameState) void {
    if (ray.IsKeyPressed(ray.KEY_UP) or ray.IsKeyPressed(ray.KEY_W)) {
        game_state.selected_option = switch (game_state.selected_option) {
            .StartGame => .Exit,
            .Options => .StartGame,
            .About => .Options,
            .Exit => .About,
        };
    }
    if (ray.IsKeyPressed(ray.KEY_DOWN) or ray.IsKeyPressed(ray.KEY_S)) {
        game_state.selected_option = switch (game_state.selected_option) {
            .StartGame => .Options,
            .Options => .About,
            .About => .Exit,
            .Exit => .StartGame,
        };
    }
    if (ray.IsKeyPressed(ray.KEY_ENTER) or ray.IsKeyPressed(ray.KEY_SPACE)) {
        switch (game_state.selected_option) {
            .StartGame => {
                game_state.current_state = .Story;
                game_state.story_panel = 0;
                game_state.story_transition = 0.0;
            },
            .Options => {
                // Show options menu
            },
            .About => {
                // Show about screen
            },
            .Exit => {
                game_state.should_exit = true;
            },
        }
    }
}

fn updateStory(game_state: *GameState) void {
    // Update transition
    if (game_state.story_transition < 1.0) {
        game_state.story_transition += 0.02;
    }

    // Handle input
    if (ray.IsKeyPressed(ray.KEY_SPACE) or ray.IsKeyPressed(ray.KEY_ENTER)) {
        if (game_state.story_panel < 2) {
            game_state.story_panel += 1;
            game_state.story_transition = 0.0;
        } else {
            game_state.current_state = .AvatarSelection;
        }
    }
    if (ray.IsKeyPressed(ray.KEY_ESCAPE)) {
        game_state.current_state = .AvatarSelection;
    }
}

fn drawMenu(game_state: *GameState) void {
    ray.BeginDrawing();
    defer ray.EndDrawing();

    ray.ClearBackground(ray.BLACK);

    const title = "My Game";
    const title_width = ray.MeasureText(title, game_state.title_font_size);
    const title_x = @divTrunc(game_state.screen_width - title_width, 2);
    const title_y = @divTrunc(game_state.screen_height, 4);

    ray.DrawText(title, title_x, title_y, game_state.title_font_size, ray.WHITE);

    var menu_y = @divTrunc(game_state.screen_height, 2);
    inline for (std.meta.fields(MenuOption)) |field| {
        const option = @field(MenuOption, field.name);
        const text = option.toString();
        const text_width = ray.MeasureText(text.ptr, game_state.font_size);
        const text_x = @divTrunc(game_state.screen_width - text_width, 2);

        const color = if (game_state.selected_option == option) ray.GREEN else ray.LIGHTGRAY;
        ray.DrawText(text.ptr, text_x, menu_y, game_state.font_size, color);
        menu_y += game_state.menu_spacing;
    }
}

fn drawStory(game_state: *GameState) void {
    ray.BeginDrawing();
    defer ray.EndDrawing();

    ray.ClearBackground(ray.BLACK);

    // Draw current panel with transition
    const panel = game_state.story_panels[@intCast(game_state.story_panel)];
    const tint = ray.ColorAlpha(ray.WHITE, game_state.story_transition);

    // Center the panel
    const panel_x = @divTrunc(game_state.screen_width - panel.width, 2);
    const panel_y = @divTrunc(game_state.screen_height - panel.height, 2);

    ray.DrawTexture(panel, panel_x, panel_y, tint);

    // Draw story text
    const text = game_state.story_texts[@intCast(game_state.story_panel)];
    const text_width = ray.MeasureText(text.ptr, game_state.font_size);
    const text_x = @divTrunc(game_state.screen_width - text_width, 2);
    const text_y = game_state.screen_height - 100;

    ray.DrawText(text.ptr, text_x, text_y, game_state.font_size, ray.WHITE);

    // Draw instructions
    const skip_text = "Press SPACE/ENTER to continue, ESC to skip";
    const skip_width = ray.MeasureText(skip_text, game_state.font_size);
    const skip_x = @divTrunc(game_state.screen_width - skip_width, 2);
    const skip_y = game_state.screen_height - 50;

    ray.DrawText(skip_text, skip_x, skip_y, game_state.font_size, ray.LIGHTGRAY);
}

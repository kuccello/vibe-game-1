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
};

pub fn main() !void {
    var game_state = GameState{};

    // Initialize GLFW first
    ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT);
    ray.InitWindow(game_state.screen_width, game_state.screen_height, "Game Menu");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose() and !game_state.should_exit) {
        updateMenu(&game_state);
        drawMenu(&game_state);
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
                // Start the game
            },
            .Options => {
                // Show options menu
            },
            .About => {
                // Show about screen
            },
            .Exit => {
                // Set the exit flag to true
                game_state.should_exit = true;
            },
        }
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

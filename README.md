# Game1

A simple game project using Zig and raylib.

## Prerequisites

- Zig (latest version)
- Git

## Building

```bash
zig build
```

## Creating a binary

```bash
# Clean everything
rm -rf zig-out .zig-cache

# Build release with verbose output
zig build release --verbose

# Check the cache directory for the executable
ls -l .zig-cache/o/*/AncientPowers

zig build install
```

The output of this will be that in the `./zig-out/bin` directory there will be a binary app called `AncientPowers` that you can run

## Running

```bash
zig build run
```

## Project Structure

- `src/main.zig` - Main game code
- `build.zig` - Build configuration
- `raylib/` - raylib library (git submodule)

## Development Setup

### Cloning the Repository

When cloning this repository, you'll need to initialize and update the raylib submodule:

```bash
git clone <repository-url>
cd game1
git submodule update --init --recursive
```

### Updating raylib

To update raylib to the latest version:

```bash
git submodule update --remote raylib
git add raylib
git commit -m "Update raylib to latest version"
```

## Controls

- Arrow keys or W/S: Navigate menu options
- Enter or Space: Select menu option
- ESC: Close window

## Features

- Main menu with Start Game, Options, About, and Exit options
- Clean and modern UI
- Smooth menu navigation
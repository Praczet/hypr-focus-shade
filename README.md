# hypr-focus-shade

Hyprland plugin experiment for focus-aware window shading.

This repository is currently a fork of
[`Hypr-DarkWindow`](https://github.com/micha4w/Hypr-DarkWindow), a plugin that
can modify the fragment shader of specific windows. The fork exists because
normal Hyprland config can dim windows, but it cannot cleanly express the
effect this project is aiming for:

```text
when one configured window is active,
shade/desaturate sibling windows of the same class on the current workspace
```

The first target is Ghostty. The desired behavior is:

```text
active Ghostty on current workspace        -> normal
other Ghostty windows on current workspace -> quieter / desaturated
Ghostty on other workspaces                -> unchanged
unrelated windows                          -> unchanged
```

This is not meant to be a global night-mode tool. It is a small focus contrast
plugin: the active terminal stays readable, nearby sibling terminals step back.

## Status

Working `0.1.0` prototype.

The upstream `Hypr-DarkWindow` functionality is still the base. This fork keeps
that shader plumbing and adds focus-aware sibling shading on top.

## Why This Fork Exists

Hyprland already has several related tools, but each solves a different problem:

- `opacity = "active inactive"` can dim one app by class, but it uses
  transparency rather than saturation.
- `decoration:dim_inactive` dims inactive windows globally, not per class.
- `dim_around` dims the area around a focused window, not sibling windows.
- `hyprsunset` changes gamma/temperature globally, not per window.
- `screen_shader`/shader tools generally affect the whole screen.

This fork is for per-window, focus-aware shading.

## Compatibility

Hyprland plugins are ABI-sensitive. Build this plugin against headers matching
the running Hyprland commit. The plugin checks the build/runtime Hyprland hashes
on load and refuses to start if they do not match.

This project is currently versioned as `0.1.0`.

## Installation

### hyprpm

```sh
hyprpm add https://github.com/Praczet/hypr-focus-shade
hyprpm enable hypr-focus-shade
hyprpm reload
```

### Manual local build

```sh
make all -j
hyprctl plugin load "$PWD/out/hypr-focus-shade.so"
hyprctl reload
```

For local development, use:

```sh
scripts/dev-reload
```

### NixOS / Home Manager

You should already have a fully working Home Manager setup before adding this
plugin.

```nix
# flake.nix
inputs = {
    home-manager = { ... };
    hyprland = { ... };

    hypr-focus-shade = {
      url = "github:Praczet/hypr-focus-shade";
      inputs.hyprland.follows = "hyprland";
    };
};

outputs = {
  home-manager,
  hypr-focus-shade,
  ...
}: {
  ... = {
    home-manager.users.praczet = {
      wayland.windowManager.hyprland.plugins = [
        hypr-focus-shade.packages.${pkgs.system}.hypr-focus-shade
      ];
    };
  };
}
```

## Current Usage

Simple Lua config shape:

```lua
hl.config({
    plugin = {
        focus_shade = {
            enabled = true,
            classes = "com.mitchellh.ghostty",
            shader = "focusshade saturation=0.25 brightness=0.86 contrast=0.82",
            same_workspace_only = true,
        },
    },
})
```

For multiple class groups or different shaders per app, register rules after the
plugin is loaded:

```lua
if hl.plugin.focus_shade ~= nil then
    hl.plugin.focus_shade.rule({
        classes = "com.mitchellh.ghostty",
        shader = "focusshade saturation=0.25 brightness=0.86 contrast=0.82",
        same_workspace_only = true,
    })
end
```

If one or more `hl.plugin.focus_shade.rule(...)` calls are present, they take
priority over the simple `hl.config({ plugin = { focus_shade = ... } })`
fallback.

The Ghostty values above are intentionally stronger than a small opacity tweak:
inactive sibling terminals become darker, flatter, and less colorful while the
active terminal remains untouched.

## Commands

For local development, rebuild and reload the plugin with:

```sh
scripts/dev-reload
```

or:

```sh
make dev-reload
```

The script builds `out/hypr-focus-shade.so`, unloads the previous instance from
this checkout if present, loads the new build, reloads Hyprland, and prints
`hyprctl focus-shade status`.

Inspect current focus-shade state with:

```sh
hyprctl focus-shade status
hyprctl focus-shade rules
hyprctl focus-shade shaded
```

Temporarily enable, disable, or toggle focus shading:

```sh
hyprctl focus-shade enable
hyprctl focus-shade disable
hyprctl focus-shade toggle
```

JSON output is also available:

```sh
hyprctl -j focus-shade status
hyprctl -j focus-shade rules
hyprctl -j focus-shade shaded
```

The `status` output includes the active window, configured rules, and windows
that currently have plugin-owned focus shading applied. Use `rules` or `shaded`
when you only need one part of that state.

`enabled` controls the default state after config reload. Runtime commands like
`hyprctl focus-shade disable` are session-only and reset to the configured value
on reload.

Internally, this registers Hyprland plugin config keys such as
`plugin:focus_shade:classes`, matching Hyprland's `plugin:<namespace>:<key>`
plugin-value format.

## Finding Window Classes

Use `hyprctl clients` to inspect the class names Hyprland sees:

```sh
hyprctl clients -j | jq -r '.[] | "\(.class)\t\(.title)"'
```

For one app family, filter by class or title:

```sh
hyprctl clients -j |
  jq -r '.[] | select((.class | test("firefox|zen"; "i")) or (.title | test("firefox|zen"; "i"))) | "\(.class)\t\(.title)"'
```

The `classes` value in `hl.plugin.focus_shade.rule(...)` is comma-separated.
Keep it literal and boring: `firefox,org.mozilla.firefox,zen`.

## Runtime Behavior

The plugin recomputes shading when:

- active window changes
- a window opens or closes
- workspace changes
- config reloads

It tracks plugin-owned effects separately, so clearing focus shading
does not remove shaders that the user applied explicitly through upstream
`darkwindow:shade` rules or dispatchers.

## Known Limits

- Only one shader can be applied to a window at a time.
- Runtime `enable`, `disable`, and `toggle` state is session-only.
- Config reload resets runtime enabled state to `plugin:focus_shade:enabled`.
- Rules are class-based. Title/process matching is not part of focus shading yet.
- The current rule API is Lua-first. Hyprlang compatibility exists mainly for
  the upstream shader plumbing.

## Development Notes

Hyprland plugins are loaded into the compositor process. A broken plugin can
affect the session, so this should be built and tested carefully.

Current development path:

1. Keep the working Ghostty/browser focus-shade path stable.
2. Improve status/debug output before adding more behavior.
3. Keep upstream shader/window-rule compatibility unless there is a concrete
   reason to remove it.
4. Test reload behavior after plugin lifecycle changes.

Test in a nested Hyprland session before loading experimental builds into a
main desktop session.

## Upstream Base: Hypr-DarkWindow

The content below is the original upstream README material, kept because this
fork still depends on the same shader and configuration model.

![preview](./res/preview.png)

> [!IMPORTANT]
> The main branch is always™ up to date with Hyprlands main branch,
> if you are using a release version of Hyprland check the Readme of the specific tag.

## Shaders

> [!NOTE]
> You can only have one shader applied at the same time.
> Applying a shader to a window which already has one applied will override the first one.
> Shaders that were applied using a dispatcher take priority over windowrule shaders.

There are few shaders already included in this plugin.
All of them get loaded with the plugin, if you want to only load specific ones you can limit the shaders that are loaded.

```lua
hl.config({
    plugin = {
        focus_shade = {
            load_shaders = "invert, tint" -- defaults to "all"
            load_shaders = "" -- dont load any default shaders
        },
    }
})

```

| **Name**      | **Description**                                                                                                                                                                                                                                                                                                                                                              |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **invert**    | _No uniforms_ <br> Applies smart color inversion                                                                                                                                                                                                                                                                                                                             |
| **tint**      | <ul><li>_tintStrength_ = `float` (0-1) </li><li>_tintColor_ = `vec3`</li></ul> Tints the Window <br>                                                                                                                                                                                                                                                                         |
| **desaturate** | <ul><li>_saturation_ = `float` (0-1, default `0.35`)</li></ul> Moves the window color toward grayscale. `1.0` keeps the original color; `0.0` is fully grayscale. |
| **focusshade** | <ul><li>_saturation_ = `float` (0-1, default `0.35`)</li><li>_brightness_ = `float` (0-2, default `0.92`)</li><li>_contrast_ = `float` (0-2, default `0.9`)</li></ul> Combines desaturation, brightness, and contrast adjustment for inactive sibling windows. `1.0` is neutral for each uniform. |
| **chromakey** | <ul> <li>_bkg_ = `vec3` <br> The background color of the Window </li> <li>_similarity_ = `float` <br> How many similar colors should be affected</li> <li>_amount_ = `float` <br> How much similar colors should be changed</li> <li>_targetOpacity_ = `float` <br> Target opacity for similar colors</li> </ul> Applies opacity changes to pixels similar to one color <br> |

If you want to use your own Shaders, check [this](#custom-shaders) out.

## Configuration

#### Lua

```lua
-- hyprland.lua

if hl.plugin.focus_shade ~= nil then
  -- To modify the uniforms of an already existing shader, create a new shader and set the uniforms you want
  hl.plugin.focus_shade.load_shader("tintRed", {
      from = "tint",
      args = "tintColor=[1 0 0] tintStrength=0.1",
  })

  -- Use a custom shader from a file
  hl.plugin.focus_shade.load_shader("chromakeyv2", {
      --  see the section below (#custom-shaders) for the content of this file
      path = "~/path/to/shader.glsl",
      args = "wow=[1.0 0 0]",
      -- if you modify the alpha value make sure to set this value to true so hyprland knows it should enable blur
      introduces_transparency = true,
  })

  -- Then to apply the shader to a window you can use window rules
  hl.window_rule({
      match = { class = "pb250.exe" },
      ["focus-shade:shade"] = "invert",
  })

  -- Uniforms can also be passed on the fly
  hl.window_rule({
      match = { fullscreen = true },
      ["focus-shade:shade"] = "tint tintColor=[0 1 0]",
  })

  -- Or use a dispatcher
  hl.bind(mainMod .. " + I", hl.plugin.focus_shade.dsp_shade({
      shader = "invert",

      -- see https://wiki.hypr.land/Configuring/Basics/Dispatchers/#window
      -- if no window field is specified, it targets the active window
      window = "class:nemo",
  }))

  hl.bind(mainMod .. " + O", hl.plugin.focus_shade.dsp_shade({
      -- also works with on-the-fly uniforms
      shader = "chromakey bkg=[0.234 0.234 0.234] targetOpacity=0.5",
  }))
end
```

#### Hyprlang (deprecated)

```ini
# hyprland.conf

plugin:focus_shade {
  # To modify the uniforms of an already existing shader, create a new shader and set the uniforms you want
  shader[tintRed] {
      from = tint
      args = tintColor=[1 0 0] tintStrength=0.1
  }

  # Use a custom shader from a file
  shader[cool] {
      path = /path/to/shader.glsl # see the section below (#custom-shaders) for the content of this file
      args = wow=[1.0 0 0]
      introduces_transparency = true # if you modify the alpha value make sure to set this value to true so hyprland knows it should enable blur
  }
}

# Then to apply the shader to a window you can use window rules
windowrule = focus-shade:shade invert, match:class (pb170.exe)
# Uniforms can also be passed on the fly, but make sure to not use commas inside the arrays
windowrule = focus-shade:shade tint tintColor=[0 1 0], match:fullscreen true

# Or use a dispatcher
bind = $mainMod, T, focus-shade:shadeactive, tint tintColor=[0 0.5 1] tintStrength=0.3
# There is also a `focus-shade:shade WINDOW_REGEX SHADER_NAME` available (see https://wiki.hypr.land/Configuring/Basics/Dispatchers/#window)
```

### Custom Shaders

To add custom shaders use the `plugin:focus_shade:shader` config category (see example above).
The file at `.path` is a glsl file that should contain a `void windowShader(inout vec4 color)` function and
uniform declarations for your `.args`.
It can also contain more functions but be careful to not clash with names that are already used by hyprland.

The custom shader code will then be injected into the fragment shader used by hyprland.
You can see examples of shaders by looking at the [predefined shaders](./src/PredefinedShaders.h).
Feel free to make a pull request to add your own shaders!

#### Special Variables

You can use these variables anywhere in your shader code.
Do not add the uniform declarations.
This plugin will automatically detect the used variables and set them at each render.

| **Name**            | **Type**                        | **Description**                                                                                                                                      |
| ------------------- | ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **x_Time**          | `float`                         | Current time in seconds<br>_using this will cause the entire window to rerender every frame_                                                         |
| **x_PixelPos**      | `vec2`                          | Position of the current pixel in window space<br>(top left of the window is [0,0], monitor scaling already applied)                                  |
| **x_CursorPos**     | `vec2`                          | Position of the cursor, same coordinate space as `x_PixelPos`<br>_using this will cause the entire window to rerender every time the mouse is moved_ |
| **x_WindowSize**    | `vec2`                          | Size of the current window, same scaling as `x_PixelPos`                                                                                             |
| **x_MonitorScale**  | `float`                         | Scaling of the monitor as seen in `hyprctl monitors`                                                                                                 |
| **x_Texture**       | `fn (vec2 texCoord) -> vec4`    | Gets the color of a pixel<br>(the difference of using this vs. using `texture(x_Tex, texCoord)` is that this function handles opaque windows)        |
| **x_TextureOffset** | `fn (vec2 pixelOffset) -> vec4` | Gets the color at a pixel offset to the currently drawn pixel                                                                                        |
| **x_Tex**           | `sampler2D`                     | The texture that gets sampled from                                                                                                                   |
| **x_TexCoord**      | `vec2`                          | The coordinate that was used to get the current pixel color                                                                                          |

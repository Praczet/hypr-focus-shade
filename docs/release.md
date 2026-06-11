# Release Checklist

## 0.1.0

Before tagging:

```sh
make clean
make all -j
scripts/dev-reload
hyprctl focus-shade status
hyprctl focus-shade rules
hyprctl focus-shade shaded
hyprctl -j focus-shade status
hyprctl -j focus-shade rules
hyprctl -j focus-shade shaded
```

Check version metadata:

- `src/main.cpp` plugin version is `0.1.0`.
- `flake.nix` package version is `0.1.0`.
- `README.md` mentions `0.1.0`.
- `hyprpm.toml` output is `out/hypr-focus-shade.so`.

Tag:

```sh
git tag v0.1.0
```

Push:

```sh
git push
git push origin v0.1.0
```

After tagging:

- Verify HyprPM install instructions against the published repository URL.
- Verify Nix consumers can build against a matching Hyprland input.

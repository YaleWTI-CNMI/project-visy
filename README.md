# VISY — Godot desktop client

Use this repository's `desktop-onboarding` branch with the Python repository's matching branch. For the full setup and the commands to enter in the VISYB shell, see **[the Python quick start](../visyb/README.md)** in a sibling checkout.

1. Install the standard [Godot 4.6 macOS editor](https://godotengine.org/download/archive/4.6-stable/).
2. Import this repository's `project.godot` in Godot. Let the first import finish.
3. In a terminal in the sibling `visyb/` repository, activate its Conda environment and run `python -m visyb`.
4. Press **Play Project / F5** in Godot. The default is **`intro_scene_debug.tscn`**, the desktop workspace. A headset is not required.
5. At Python's `In [...]` prompt, use the `%run` and `await add_plot(...)` commands in the Python README. The blank client will populate when you send a plot.

Alternatively, launch the same desktop client directly from Terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . res://intro_scene_debug.tscn
```

Run this command from the Godot repository. Adjust the application path if you installed Godot elsewhere.

The interface starts at 125%. Use **UI size** in the top bar for 100%, 125%, or 150%; the choice is saved.

Click points to send selections to Python. Drag to orbit, Shift + drag to pan, and scroll/pinch to zoom. Inspector sliders update the Python-generated plots. Reset camera fits the current workspace. Connection status appears at the bottom; existing Python plots return after reconnecting.

## Existing VR scene

The headset scene remains `intro_scene.tscn`. Desktop settings disable OpenXR and use Compatibility rendering. On a machine with a supported OpenXR runtime, explicitly opt into VR:

```bash
godot --path . --rendering-method mobile --xr-mode on res://intro_scene.tscn
```

The desktop onboarding changes were tested on macOS; headset behavior has not been retested.

## Development checks

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/desktop_smoke.gd
```

The smoke test uses synthetic data. The private ATLAS and Kuramoto data stays in the Python repository's ignored directory. Consult its `VALIDATION.md` for the real-data test results.

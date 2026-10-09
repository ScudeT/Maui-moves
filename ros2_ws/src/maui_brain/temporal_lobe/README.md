# `temporal_lobe` — Reflex, Memory, Fatigue (RMF)

Safety and mission management layer. Handles button-triggered events, rosbag recording, and autonomous timeout.

---

## Launch files

### `reflex_memory_fatigue.launch.py`
The only launch file in this package. Used in all mission launches.  
Config: [`config/ReflexMemoryFatigue.yaml`](config/ReflexMemoryFatigue.yaml)

| Node | Role |
|---|---|
| `reflex` (`button_service_caller_node`) | On button press (`/button_state`), calls a configured list of Trigger services (e.g. start/stop recording, reset controllers, toggle depth/yaw). Service list is defined in the top-level config YAML under `reflex/service_names` |
| `memory` (`record_service_node`) | Rosbag recorder. Toggles recording on/off via the `/record` Trigger service. Topics and output folder are defined in the config YAML under `memory/topics` and `memory/parent_folder` |
| `fatigue` (`button_timeout_node`) | Autonomous timeout: after a configurable duration (`time_out` seconds), publishes to `/button_state` to trigger the same reflex chain as a physical button press |

---

## Other nodes (not in the main launch)

| Node | Role |
|---|---|
| `button_read_node` | Reads a physical GPIO button and publishes to `/button_state`. Started by `brain_stem/peripheral_nervous_system.launch.py` |
| `depth_service_caller_node` | Calls Trigger services on water entry/exit depth transitions |
| `depth_setter_node` | Alternates between surface and dive depth targets on configurable timers |
| `titan_control.py` | Joystick/gamepad teleoperation node |

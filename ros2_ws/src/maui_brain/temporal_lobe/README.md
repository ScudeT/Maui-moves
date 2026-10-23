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
| `fatigue` (`button_timeout_node`) | Autonomous timeout, armed through the `/fatigue` Trigger service (normally called by `reflex` on the first button press). After `time_out` seconds it publishes `True` on `/button_state`, which fires the same reflex chain as a second physical press and so ends the mission. Calling `/fatigue` again before the timeout cancels it |

The defaults in `ReflexMemoryFatigue.yaml` are a minimal example. The `maui` launches override them with their own config through the `config_file` launch argument. Every service in `reflex/service_names` must exist in the running launch: the reflex waits up to 5 s for each unavailable service before moving on.

---

## Other nodes (not in the main launch)

| Node | Role |
|---|---|
| `button_read_node` | Reads a physical GPIO button (`gpio_line`, default 4) and publishes to `/button_state`. The line is sampled at `freq` and debounced with a leaky integrator (press/release accepted after `press_time`/`release_time` of mostly-stable level, presses ignored for `refractory_time` after a release) to reject water-induced misfires. Started by `brain_stem/peripheral_nervous_system.launch.py`, parameters in `brain_stem/config/PNS.yaml` |

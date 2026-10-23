# `maui` — Top-level Launch Package

This package is the entry point for running the robot. It contains no control logic of its own — it orchestrates the subsystem packages through three launch files, each starting the hardware drivers, state estimation and controllers.

Each launch file declares a `config_file` argument that defaults to a matching YAML in [`config/`](config/). For details on each subsystem, refer to the README in its source package under [`maui_brain/`](../maui_brain/).

| Launch | Config | Purpose |
|---|---|---|
| `just_keep_swimming.launch.py` | [`JustKeepSwimming.yaml`](config/JustKeepSwimming.yaml) | Swim straight at a fixed depth, no yaw control. **Started at boot** |
| `maui.launch.py` | [`maui.yaml`](config/maui.yaml) | Integrated-yaw (circle) path with a sinusoidal depth reference |
| `target_follow.launch.py` | [`TargetFollow.yaml`](config/TargetFollow.yaml) | GPS waypoint following with periodic surfacing |

---

## Launch Files

### `just_keep_swimming.launch.py`
Minimal swimming mission: the robot swims forward at the open-loop speed set by `A_m` while holding roll, pitch and depth. No path planners are started.  
Config: [`JustKeepSwimming.yaml`](config/JustKeepSwimming.yaml)

```bash
ros2 launch maui just_keep_swimming.launch.py
```

It starts the hardware drivers, state estimation, basic motor functions and the reflex/memory/fatigue layer. Unlike the other launches, it declares the attitude (`w_ctrl`, `q_ctrl`, `ypr_to_q`) and depth (`depth/ctrl`) controller nodes itself, so their gains come from `JustKeepSwimming.yaml` instead of the `cerebellum` configs:

| Goal | Parameters to change |
|---|---|
| Re-enable yaw control | `attitude/w_ctrl` → `wz_pid_settings` (all zeros = `A_d` always 0) |
| Roll / pitch rate gains | `attitude/w_ctrl` → `wx_pid_settings`, `wy_pid_settings` |
| Swimming depth | `depth/ctrl` → `set_0` (m, negative = depth; currently `0.05`) |
| Depth gains | `depth/ctrl` → `pid_settings` |
| Mission duration | `fatigue` → `time_out` (s, currently `120.0`) |
| Topics recorded / bag folder | `memory` → `topics` / `parent_folder` (currently `bags/just_keep_swimming`) |

A button press records a rosbag, resets the controllers, starts the fins and arms the timeout. `reflex/service_names` only lists services that exist in this launch, because each missing service stalls the reflex for 5 s.

### `maui.launch.py` and `target_follow.launch.py`

These two start the full stack through the subsystem launch files, and differ only in how the heading reference is generated. Their `config_file` parameterises the mission-level nodes (path planners, cameras, reflex/memory/fatigue), while the controllers keep using the `cerebellum` configs.

| Subsystem | Included launch |
|---|---|
| Hardware drivers | `brain_stem/peripheral_nervous_system.launch.py` |
| State estimation | `parietal_lobe/thalamus.launch.py` |
| Depth + attitude control | `cerebellum/depth_and_attitude_controller.launch.py` |
| Depth reference | `frontal_lobe/depth_sine.launch.py` |
| Heading reference | `frontal_lobe/circle_path.launch.py` (`maui`) or `frontal_lobe/gps_target_follow.launch.py` (`target_follow`) |
| Button / recording / timeout | `temporal_lobe/reflex_memory_fatigue.launch.py` |

An `eyes` camera node (`occipital_lobe/cameras_client_node`) is defined in both launches but is currently not added to the launch description. Uncomment `ld.add_action(eyes)` to enable it.

#### `maui.launch.py`
Closed-loop navigation with an integrated yaw reference and a sinusoidal depth reference.  
Config: [`maui.yaml`](config/maui.yaml)

```bash
ros2 launch maui maui.launch.py
```

With the current config (`wz: 0.0`, `amplitude: 0.0`) the robot holds its heading at a fixed depth of 0.3 m.

**Configuring yaw and depth behaviour**: edit [`maui.yaml`](config/maui.yaml) before launching:

| Goal | Parameters to change |
|---|---|
| Swim in a circle | `path/circle_yaw` → `wz` (rad/s, non-zero) |
| Hold current heading | `wz: 0.0` |
| Deeper / shallower oscillation | `path/depth_sine` → `amplitude` (m) and `offset` (m, negative = depth) |
| Fixed depth | `amplitude: 0.0` |
| Longer / shorter dive cycle | `path/depth_sine` → `period` (s) |
| Cap depth range | `upper_limit` / `lower_limit` (m, negative = depth) |
| Mission duration | `fatigue` → `time_out` (s, currently `60.0`) |
| Services called on button press | `reflex` → `service_names` |
| Topics recorded / bag folder | `memory` → `topics` / `parent_folder` (currently `bags/maui`) |

> In `maui.yaml` the `/record` service is commented out of `reflex/service_names`, so a button press does **not** start a rosbag. Uncomment it to record the run.

Both axes can also be toggled at runtime via the `/path/yaw_toggle` and `/path/depth_toggle` services without restarting the node.

#### `target_follow.launch.py`
GPS-assisted waypoint navigation. The heading setpoint is the bearing from the latest GPS fix to the current waypoint, and the robot advances to the next waypoint once it is within `threshold` metres. A slow depth sine (100 s period, offset above the surface) brings the robot up periodically so it can get new GPS fixes.  
Config: [`TargetFollow.yaml`](config/TargetFollow.yaml)

```bash
ros2 launch maui target_follow.launch.py
```

| Goal | Parameters to change |
|---|---|
| Waypoints | `path/gps_follower` → `points` (flat list `[lat1, lon1, lat2, lon2, …]`) |
| Waypoint acceptance radius | `path/gps_follower` → `threshold` (m) |
| Surfacing cycle | `path/depth_sine` → `period`, `amplitude`, `offset` |
| Mission duration | `fatigue` → `time_out` (s, currently `500.0`) |

### Using a custom config

Any of the launches accepts another YAML file with the same structure as its default config:

```bash
ros2 launch maui maui.launch.py config_file:=/path/to/my_mission.yaml
```

### Running part of the stack

There are no dedicated test launches anymore. To run a subset of the stack, launch the subsystem files directly, for example:

```bash
ros2 launch cerebellum basic_motor_functions.launch.py   # actuator mapping only
ros2 launch parietal_lobe thalamus.launch.py             # state estimation only
```

---

## Changing the Default Launch at Boot

The Docker Compose file [`docker/raspi_ros2/compose.yaml`](../../../docker/raspi_ros2/compose.yaml) defines which launch file runs automatically when the container starts:

```yaml
command:
  - bash
  - -c
  - |
    set -e
    source /opt/ros/jazzy/setup.bash
    cd /home/ros/ros2_ws
    colcon build --symlink-install
    source install/setup.bash
    ros2 launch maui just_keep_swimming.launch.py
```

Replace `just_keep_swimming.launch.py` with the desired launch file and restart the container:

```bash
docker compose down && docker compose up -d
```

To override the launch for a single run without editing the file:

```bash
docker compose run --rm jazzy bash -c \
  "colcon build --symlink-install && source install/local_setup.bash && ros2 launch maui target_follow.launch.py"
```

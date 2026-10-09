# `maui` — Top-level Launch Package

This package is the entry point for running the robot. It contains no control logic of its own — it orchestrates the subsystem packages through a set of launch files, each composing a different configuration of the stack for a specific mission or test.

Every launch file loads a matching YAML config from [`config/`](config/) that parameterises all nodes in that run. For details on each subsystem, refer to the README in its source package under [`maui_brain/`](../maui_brain/).

---

## Launch Files

### Mission launches — full robot

These start the complete hardware and control stack and are the normal operating modes.

#### `circle_path.launch.py`
Closed-loop navigation along a horizontal circular trajectory with sinusoidal depth modulation.  
Config: [`CirclePath.yaml`](config/CirclePath.yaml)

```bash
ros2 launch maui circle_path.launch.py
```

**Configuring yaw and depth behaviour** — edit [`CirclePath.yaml`](config/CirclePath.yaml) before launching:

| Goal | Parameters to change |
|---|---|
| Faster / slower circle | `path/circle_yaw` → `wz` (rad/s) |
| Disable yaw rotation (hover in place) | `wz: 0.0` |
| Deeper / shallower oscillation | `path/depth_sine` → `amplitude` (m) and `offset` (m, negative = depth) |
| Disable depth oscillation (fixed depth) | `amplitude: 0.0` |
| Longer / shorter dive cycle | `path/depth_sine` → `period` (s) |
| Cap depth range | `upper_limit` / `lower_limit` (m, negative = depth) |

Both axes can also be toggled at runtime via the `/path/yaw_toggle` and `/path/depth_toggle` services without restarting the node.

#### `target_follow.launch.py`
GPS-assisted waypoint navigation. The robot resurfaces to get a GPS fix, navigates toward the target heading, and dives again.  
Config: [`TargetFollow.yaml`](config/TargetFollow.yaml)

```bash
ros2 launch maui target_follow.launch.py
```

#### `maui_attitude_ctrl.launch.py`
Attitude and depth stabilisation with a circle path reference, without the RMF safety layer. Useful for tuning the inner control loops.  
Config: [`MauiAttitudeCtrl.yaml`](config/MauiAttitudeCtrl.yaml)

```bash
ros2 launch maui maui_attitude_ctrl.launch.py
```

---

### Test launches — partial stack

These launches are for development and tuning. They generally skip the hardware drivers or reduce the stack to isolate a specific component.

#### `wake_up.launch.py`
Minimal hardware check. Starts all drivers and basic motor functions to verify the robot is operational before a mission.

```bash
ros2 launch maui wake_up.launch.py
```

#### `control_test.launch.py`
Sends raw kinematic commands directly to the actuators to characterise the robot's open-loop response.  
Config: [`ControlTest.yaml`](config/ControlTest.yaml)

```bash
ros2 launch maui control_test.launch.py
```

#### `speed_test.launch.py`
Tests angular velocity control by commanding a body-rate reference and recording the response.  
Config: [`SpeedTest.yaml`](config/SpeedTest.yaml)

```bash
ros2 launch maui speed_test.launch.py
```

#### `test_attitude_ctrl.launch.py`
Tests the quaternion attitude controller in isolation, without hardware. Requires an external odometry source.  
Config: [`TestAttitudeCtrl.yaml`](config/TestAttitudeCtrl.yaml)

```bash
ros2 launch maui test_attitude_ctrl.launch.py
```

#### `test_yaw_depth_ctrl.launch.py`
Tests depth and yaw control using a simulated odometry source. No hardware needed.  
Config: [`TestYawDepthCtrl.yaml`](config/TestYawDepthCtrl.yaml)

```bash
ros2 launch maui test_yaw_depth_ctrl.launch.py
```

#### `test_circle_path.launch.py`
Tests the circle path and depth sine planners with the attitude controller, without the hardware driver layer.  
Config: [`CirclePath.yaml`](config/CirclePath.yaml)

```bash
ros2 launch maui test_circle_path.launch.py
```

#### `sleep.launch.py`
Minimal stack with no hardware drivers. Starts state estimation and basic motor functions only — useful for offline testing.

```bash
ros2 launch maui sleep.launch.py
```

---

## Changing the Default Launch at Boot

The Docker Compose file [`docker/raspi_ros2/compose.yaml`](../../../../docker/raspi_ros2/compose.yaml) defines which launch file runs automatically when the container starts:

```yaml
command: >
  bash -c "
    colcon build --symlink-install &&
    source install/local_setup.bash &&
    ros2 launch maui circle_path.launch.py
  "
```

Replace `circle_path.launch.py` with the desired launch file and restart the container:

```bash
docker compose down && docker compose up -d
```

To override the launch for a single run without editing the file:

```bash
docker compose run --rm jazzy bash -c \
  "colcon build --symlink-install && source install/local_setup.bash && ros2 launch maui target_follow.launch.py"
```

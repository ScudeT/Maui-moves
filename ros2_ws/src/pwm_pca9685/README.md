# `pwm_pca9685` — PWM Servo Controller Driver

ROS 2 driver for the NXP PCA9685 16-channel PWM controller. Receives servo commands from the control stack and writes PWM values to all 16 channels over I²C. Includes a per-channel safety timeout that zeroes any channel not updated within the configured period.

---

## Node: `pca9685_node` (`PcaNode`)

| | |
|---|---|
| **Interface** | I²C `/dev/i2c-1`, address `0x40` |
| **PWM frequency** | 300 Hz (set at init) |
| **Channels** | 16 (all written on every message) |

### Subscribed topics

| Topic | Type | Description |
|---|---|---|
| `/command` | `std_msgs/Int32MultiArray` | Array of exactly 16 PWM values (0–65535), one per channel. Pass `-1` on a channel to skip updating it |

### Parameters — [`config/Test.yaml`](config/Test.yaml)

| Parameter | Default | Description |
|---|---|---|
| `device` | `"/dev/i2c-1"` | I²C bus path |
| `address` | `64` (0x40) | I²C address of the PCA9685 |
| `frequency` | `333` | PWM frequency (Hz) — set to 50 for standard servos |
| `timeout` | `[5000 × 16]` | Per-channel timeout (ms). If a channel is not updated within this time it is set to `timeout_value` |
| `timeout_value` | `[0 × 16]` | Value written to a timed-out channel (0 = servo off) |
| `pwm_min` / `pwm_max` | `0` / `65535` | Per-channel PWM clamp limits |

### Servo mapping (set in `cerebellum` config)

The `ctrl` section of the config defines how kinematic parameters map to PWM:

| Parameter | Value | Description |
|---|---|---|
| `angle_range` | `[-60, 60]` deg | Physical servo angle limits |
| `pwm_range` | `[19500, 43500]` | PWM counts corresponding to the angle limits |
| `start_wing` | `[ω_m, A_m, A_d, α_d]` | Initial kinematic parameters for the pectoral fins |
| `start_flap` | `[θ_m, θ_d]` | Initial caudal fin deflection angles |
| `clamp_flap` | `[-40, 40]` deg | Hard limits on caudal fin deflection |

---

## Launch file

### `test.launch.py`
Standalone launch for testing the PWM driver in isolation.  
In normal operation the node is started by `brain_stem/peripheral_nervous_system.launch.py` instead.

```bash
ros2 launch pwm_pca9685 test.launch.py
```

---

## Credits

This package is based on [ros-pwm-pca9685](https://github.com/dheera/ros-pwm-pca9685) by Dheera Venkatraman and is distributed under the original BSD 3-Clause License — see [LICENSE.txt](LICENSE.txt). The `pwm_wave_node` and the ROS 2 Jazzy adaptations were added for MAUI.

# `pwm_pca9685` — PWM Servo Controller Driver

ROS 2 driver for the NXP PCA9685 16-channel PWM controller. Receives servo commands from the control stack and writes PWM values to all 16 channels over I²C. Includes a safety timeout that switches every channel off if no command arrives for 5 s.

---

## Node: `pca9685_node` (`PcaNode`)

| | |
|---|---|
| **Interface** | I²C `/dev/i2c-1`, address `0x40` (hardcoded) |
| **PWM frequency** | 300 Hz (hardcoded at init) |
| **Channels** | 16 (all written on every message) |
| **Timeout** | If no `/command` message arrives for 5 s, all channels are set to 0 (servos off) |

### Subscribed topics

| Topic | Type | Description |
|---|---|---|
| `/command` | `std_msgs/Int32MultiArray` | Array of exactly 16 PWM values (0–65535), one per channel. Messages with a different length are rejected. Values are cast to 16-bit, so a negative value such as `-1` wraps to 65535 (channel fully on). There is no "skip channel" value |

### Parameters

The node declares no ROS parameters: the bus, address, frequency and timeout are fixed in [`src/pca9685_node.cpp`](src/pca9685_node.cpp). The `pca9685` sections in `brain_stem/config/PNS.yaml` and [`config/Test.yaml`](config/Test.yaml) (`device`, `address`, `frequency`, `timeout`, `timeout_value`, `pwm_min`, `pwm_max`) come from the original parameterised driver and are currently ignored.

The mapping from fin kinematics to PWM counts is done upstream by `cerebellum`'s `ctrl_node` — see the [`cerebellum` README](../maui_brain/cerebellum/README.md) and `config/BMF.yaml`.

---

## Node: `pwm_wave_node` (`PWMWavePublisher`)

Test publisher that sweeps selected channels with a sine wave on `command`, every 20 ms. Useful for checking servo wiring without the control stack.

| Parameter | Default | Description |
|---|---|---|
| `addresses` | `[0]` | Channels (0–15) that receive the sine value |
| `ignore` | `[]` | Channels (0–15) set to `-1`. Note that `pca9685_node` drives these fully on (see above) |
| `center` | `19928` | Centre of the wave (PWM counts) |
| `amplitude` | `7864` | Peak deviation from the centre (PWM counts) |
| `wave_freq` | `0.3` | Wave frequency (Hz) |

All other channels are sent `0`.

```bash
ros2 run pwm_pca9685 pwm_wave_node
```

---

## Launch file

### `test.launch.py`
Standalone launch intended for testing the PWM driver in isolation. In normal operation the node is started by `brain_stem/peripheral_nervous_system.launch.py` instead.

> This launch currently references a `ctrl_node` executable in `pwm_pca9685`, which no longer exists (the actuator mapper now lives in `cerebellum`), so it will fail to start that node. To test the driver alone, run `ros2 run pwm_pca9685 pca9685_node` together with `pwm_wave_node`.

---

## Credits

This package is based on [ros-pwm-pca9685](https://github.com/dheera/ros-pwm-pca9685) by Dheera Venkatraman and is distributed under the original BSD 3-Clause License — see [LICENSE.txt](LICENSE.txt). The `pwm_wave_node` and the ROS 2 Jazzy adaptations were added for MAUI.

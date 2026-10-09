# `ms5837` — Depth/Pressure Sensor Driver

ROS 2 driver for the BlueRobotics MS5837-02BA barometric depth and pressure sensor. Communicates over I²C and publishes depth as a `PoseWithCovarianceStamped` message so it can be fed directly into the state estimator.

---

## Node: `pose_node` (`MS5837Node`)

| | |
|---|---|
| **Interface** | I²C `/dev/i2c-1` |
| **Sensor model** | MS5837-02BA |
| **Fluid density** | 1000 kg/m³ (fresh water — change to 1029 for seawater) |

### Published topics

| Topic | Type | Description |
|---|---|---|
| `/ms5837/pose` | `geometry_msgs/PoseWithCovarianceStamped` | Depth as `pose.position.z` (negative = underwater), covariance set on z only |

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `freq` | `50.0` | Publish rate (Hz) |
| `offset` | `0.0` | Depth offset (m) — use to zero the sensor at the water surface |
| `variance` | `0.0001` | Depth measurement variance (m²) used in the covariance matrix |
| `frame_id` | `"base_link"` | Frame for the published message header |

### Covariance convention

Only the `z`–`z` element of the 6×6 pose covariance is set to `variance`; x, y, and all rotation terms are set to `1e6` (effectively unknown), so the state estimator ignores those axes.

---

## Other nodes in this package

| Node | Description |
|---|---|
| `ms5837_node` | Earlier variant that publishes raw pressure and temperature separately |
| `depth_to_pose` | Utility node that converts a raw depth Float topic to `PoseWithCovarianceStamped` |

---

## Credits

The sensor driver (`MS5837.h` / `MS5837.cpp`) is derived from the [BlueRobotics MS5837 Library](https://github.com/bluerobotics/BlueRobotics_MS5837_Library) (MIT License), ported here to Linux I²C and ROS 2. See [LICENSE](LICENSE) for the full third-party notice.

# `parietal_lobe` — State Estimation

Fuses IMU and barometer data into the odometry estimate used by all controllers. Also publishes the robot URDF and joint states for visualisation.

---

## Launch files

### `thalamus.launch.py`
Main state estimation pipeline. This is the launch file used in all missions.  
Config: [`config/Thalamus.yaml`](config/Thalamus.yaml)

Includes `proprioception.launch.py`, then adds:

| Node | Role |
|---|---|
| `est/imu_base` (`imu_change_ref`) | Rotates IMU data from NED sensor frame to ENU body frame, republishing on `/imu/data_base` |
| `est/simple_odom` (`imu_bar_odom`) | Fuses `/imu/data_base` and `/ms5837/pose` into `/est/odom` (odometry with orientation + depth) |

---

### `proprioception.launch.py`
Visual and structural state. Included by `thalamus.launch.py`.  
Config: [`config/Proprioception.yaml`](config/Proprioception.yaml)

| Node | Role |
|---|---|
| `est/robot_state_publisher` | Publishes the robot URDF (`maui_online.urdf.xacro`) on `/robot_description` |
| `est/joint_pose` (`joint_pose_node`) | Converts `/command` servo outputs to `/est/joint_states` for URDF visualisation |
| `foxglove_bridge` | WebSocket bridge for live monitoring in Foxglove Studio |

---

### Other launch files

| File | Description |
|---|---|
| `local_ekf.launch.py` | Extended Kalman Filter for local odometry fusion. Config: `Local_EKF.yaml` |
| `ekf_global.launch.py` | EKF with global GPS fusion. Config: `ekf.yaml` |
| `dual_ekf.launch.py` | Dual local+global EKF configuration (robot_localization). Config: `dual_ekf_navsat.yaml` |

---

## Credits

The EKF configuration files are adapted from the parameter templates of [robot_localization](https://github.com/cra-ros-pkg/robot_localization) (BSD 3-Clause License, Charles River Analytics). See [LICENSE](LICENSE) for the full third-party notice.

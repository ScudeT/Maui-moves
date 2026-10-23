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
| `foxglove_bridge` | WebSocket bridge for live monitoring in Foxglove Studio (port 8765) |

---

## Robot description

The URDF lives in [`description/`](description/): `maui_online.urdf.xacro` (used at runtime, with joints driven by `/est/joint_states`), `maui.urdf.xacro`, shared `materials.xacro`, and the STL meshes for the body, wings, caudal fins and camera.

# `frontal_lobe` — Navigation and Mission Planning

Generates high-level references (yaw setpoints, depth profiles, GPS waypoints) that are fed into the attitude and depth controllers.

Every launch file here declares a `config_file` argument. The `maui` mission launches pass their own mission YAML through it, so on the robot the values come from `maui/config/` rather than from this package's `config/` folder.

---

## Launch files

### `circle_path.launch.py`
Publishes a continuously integrated yaw setpoint to steer the robot in a circle.  
Config: [`config/CirclePath.yaml`](config/CirclePath.yaml)

| Node | Role |
|---|---|
| `path/circle_yaw` (`yaw_integrator_node`) | Integrates a constant yaw rate `wz` (rad/s) and publishes the result to `/attitude/yaw_set`. Toggled by `/path/yaw_toggle` |

---

### `depth_sine.launch.py`
Publishes a sinusoidal depth reference.  
Config: [`config/SineDepth.yaml`](config/SineDepth.yaml)

| Node | Role |
|---|---|
| `path/depth_sine` (`sine_pub_node`) | Publishes a sine wave on `/depth/z_set` with configurable amplitude, period, and offset. Toggled by `/path/depth_toggle` |

---

### `gps_target_follow.launch.py`
Navigates toward a GPS waypoint by publishing a heading setpoint derived from the current GPS fix.  
Config: [`config/GPSFollow.yaml`](config/GPSFollow.yaml)

| Node | Role |
|---|---|
| `path/gps_follower` (`gps_target_follower_node`) | On each `/gps_data` fix, computes the bearing to the current target and publishes it as a heading on `/attitude/yaw_set`, and the target itself on `/path/gps_target`. When the haversine distance falls below `threshold` (m) it advances to the next waypoint in `points`, looping back to the first after the last |

# `frontal_lobe` — Navigation and Mission Planning

Generates high-level references (yaw setpoints, depth profiles, GPS waypoints) that are fed into the attitude and depth controllers.

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
| `path/gps_follower` (`gps_target_follower_node`) | Computes bearing to target using haversine distance, publishes heading to `/attitude/yaw_set`. Advances through waypoint list as each threshold distance is met |

---

### `circle_path_test.launch.py`
Same as `circle_path.launch.py` but with test parameters. Used for tuning the yaw integrator without running the full stack.

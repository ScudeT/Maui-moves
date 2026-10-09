# `cerebellum` — Motion Control

Implements all closed-loop controllers for attitude, angular rate, and depth. Launch files compose these controllers in different combinations depending on the mission.

---

## Launch files

### `basic_motor_functions.launch.py`
Minimal actuator layer. Translates kinematic inputs into servo commands.  
Config: [`config/BMF.yaml`](config/BMF.yaml)

| Node | Role |
|---|---|
| `input/ctrl` (`ctrl_node`) | Maps kinematic parameters ($A_m$, $A_d$, $\alpha_m$, $\alpha_d$, $\theta_m$, $\theta_d$) to PWM commands on `/command` |

---

### `attitude_controller.launch.py`
Full quaternion attitude control stack. Includes `basic_motor_functions`.  
Config: [`config/AttitudeController.yaml`](config/AttitudeController.yaml)

| Node | Role |
|---|---|
| `input/ctrl` | (from BMF) Actuator command mapper |
| `attitude/w_ctrl` (`w_ctrl_node`) | Angular rate PID — tracks body-rate setpoint `/attitude/w_ref`, outputs fin deflections |
| `attitude/q_ctrl` (`q_ctrl_node`) | Quaternion attitude controller — converts quaternion error to rate setpoint `/attitude/w_ref` |
| `attitude/ypr_to_q` (`ypr2q_node`) | Converts roll/pitch/yaw setpoints to quaternion reference `/attitude/q_ref` |

---

### `depth_and_attitude_controller.launch.py`
Adds a depth PID on top of the full attitude stack.  
Config: [`config/Depth&AttitudeController.yaml`](config/Depth&AttitudeController.yaml)

| Node | Role |
|---|---|
| *(attitude_controller nodes)* | Full attitude stack (included) |
| `depth/ctrl` (`pid_node`) | Depth PID — tracks `/depth/z_set`, outputs pitch setpoint `/attitude/pitch_set` |

---

### Other launch files

| File | Description |
|---|---|
| `attitude_damped_controller.launch.py` | Attitude controller with added damping terms. Config: `AttitudeDampedController.yaml` |
| `compact_attitude_controller.launch.py` | Single-node attitude controller variant. Config: `CompactAttitudeController.yaml` |
| `depth_attitude_speed.launch.py` | Combined depth, attitude, and speed control. Config: `DAS.yaml` |

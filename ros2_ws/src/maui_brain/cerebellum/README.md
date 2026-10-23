# `cerebellum` — Motion Control

Implements all closed-loop controllers for attitude, angular rate, and depth. Launch files compose these controllers in different combinations depending on the mission.

---

## Launch files

### `basic_motor_functions.launch.py`
Minimal actuator layer. Translates kinematic inputs into servo commands.  
Config: [`config/BMF.yaml`](config/BMF.yaml)

| Node | Role |
|---|---|
| `input/ctrl` (`ctrl_node`) | Subscribes to the kinematic parameters `/input/{omega_m, A_m, A_d, alpha_m, alpha_d, theta_m, theta_d}` and maps them to PWM commands on `/command`. Servo output is started/stopped with the `/input/start_and_stop` Trigger service |

| Parameter | Value in `BMF.yaml` | Description |
|---|---|---|
| `freq` | `30` | Command publish rate (Hz) |
| `angle_range` | `[-60, 60]` deg | Physical servo angle limits |
| `pwm_range` | `[19500, 43500]` | PWM counts corresponding to the angle limits |
| `start_wing` | `[0.8, 60.0, 0.0, 0.0, 0.0]` | Initial pectoral fin parameters `[ω_m, A_m, A_d, α_m, α_d]`. `A_m` sets the open-loop forward speed |
| `start_flap` | `[0.0, 0.0]` | Initial caudal fin deflection `[θ_m, θ_d]` |
| `clamp_flap` | `[-40, 40]` deg | Hard limits on caudal fin deflection |

---

### `attitude_controller.launch.py`
Full quaternion attitude control stack. Includes `basic_motor_functions`.  
Config: [`config/AttitudeController.yaml`](config/AttitudeController.yaml)

| Node | Role |
|---|---|
| `input/ctrl` | (from BMF) Actuator command mapper |
| `attitude/w_ctrl` (`w_ctrl_node`) | Angular rate PID — tracks body-rate setpoint `/attitude/w_ref` against `/est/odom`. Outputs roll → `/input/alpha_d`, pitch → `/input/theta_m`, yaw → `/input/A_d`. Reset with `/attitude/reset_ctrl` |
| `attitude/q_ctrl` (`q_ctrl_node`) | Quaternion attitude controller — converts quaternion error to rate setpoint `/attitude/w_ref` |
| `attitude/ypr_to_q` (`ypr2q_node`) | Converts roll/pitch/yaw setpoints to quaternion reference `/attitude/q_ref` |

---

### `depth_and_attitude_controller.launch.py`
Adds a depth PID on top of the full attitude stack.  
Config: [`config/Depth&AttitudeController.yaml`](config/Depth&AttitudeController.yaml)

| Node | Role |
|---|---|
| *(attitude_controller nodes)* | Full attitude stack (included) |
| `depth/ctrl` (`pid_node`) | Depth PID — tracks `/depth/z_set` against the `z` field of `/est/odom`, outputs pitch setpoint `/attitude/pitch_set`. Reset with `/depth/reset_ctrl` |

PID gains in both controller configs use the format `[kp, ki, kd, min, max, filter]`, where `filter` is a low-pass coefficient (0 = full filtering, 1 = no filtering).

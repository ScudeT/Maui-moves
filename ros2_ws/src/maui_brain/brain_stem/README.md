# `brain_stem` — Peripheral Nervous System (PNS)

Hardware driver layer. Bridges all physical sensors and actuators to the ROS 2 topic graph.

---

## Launch files

### `peripheral_nervous_system.launch.py`
Starts all hardware drivers. This is the only launch file and is included by every mission that needs real hardware.  
Config: [`config/PNS.yaml`](config/PNS.yaml)

| Node | Package | Role |
|---|---|---|
| `mpu9250` | `mpu9250` | 9-axis IMU — publishes `/imu/data` and `/imu/mag_raw` |
| `pca9685` | `pwm_pca9685` | PWM controller — subscribes to `/command` and drives all servos |
| `GPS` | `gtu7_gps_comm` | GPS receiver — publishes `/gps_data` |
| `ms5837` | `ms5837` | Depth/pressure sensor — publishes `/ms5837/pose` |
| `button` | `temporal_lobe` | GPIO button reader — publishes `/button_state` |

# `mpu9250` — IMU Driver

ROS 2 driver for the InvenSense MPU-9250 9-axis IMU (accelerometer + gyroscope + magnetometer). Communicates over I²C, runs an onboard attitude filter, and publishes orientation, angular velocity, linear acceleration, and magnetometer data.

---

## Node: `mpu9250_node` (`ImuNode`)

| | |
|---|---|
| **Interface** | I²C `/dev/i2c-1`, address `0x68` |
| **Attitude filter** | Madgwick (default) or Mahony — runs onboard in the driver |

### Published topics

| Topic | Type | Description |
|---|---|---|
| `/imu/data` | `sensor_msgs/Imu` | Orientation quaternion, angular velocity (rad/s), linear acceleration (m/s²) with diagonal covariance |
| `/imu/mag` | `sensor_msgs/MagneticField` | Magnetometer reading in milli-Gauss (axes remapped to ENU) |
| `/imu/temperature` | `std_msgs/Float64` | On-chip temperature (°C) |

### Parameters — [`config/mpu9250_params.yaml`](config/mpu9250_params.yaml)

| Parameter | Default | Description |
|---|---|---|
| `freq` | `100.0` | Publish rate (Hz) — must be ≤ `fifo_sample_rate` |
| `filter` | `1` | Attitude filter: `0` = none, `1` = Madgwick, `2` = Mahony |
| `accel_fs_sel` | `1` | Accelerometer full-scale: `0`=±2G `1`=±4G `2`=±8G `3`=±16G |
| `gyro_fs_sel` | `0` | Gyroscope full-scale: `0`=±250 `1`=±500 `2`=±1000 `3`=±2000 dps |
| `fifo_sample_rate` | `1` | Internal FIFO rate: `0`=1000Hz `1`=500Hz … (see yaml comments) |
| `gyro_dlpf_cfg` | `2` | Gyro low-pass filter cutoff (see yaml comments) |
| `accel_dlpf_cfg` | `2` | Accel low-pass filter cutoff (see yaml comments) |
| `mag_bias` | `[500, 1500, 1250]` | Hard-iron magnetometer offset (mG) — calibrate per robot |
| `acc_cov` / `w_cov` / `rpy_cov` | `0.01` / `0.01` / `0.0003` | Diagonal covariance values for the Imu message |

### Calibration

On startup the node automatically runs an accelerometer and gyroscope bias calibration routine (keep the robot still for ~2 seconds). Magnetometer calibration (`calibrateMag`) is disabled by default — update `mag_bias` in the config after a manual calibration and use the saved values.

---

## Launch file

### `mpu9250.launch.py`
Standalone launch for the IMU node. Loads [`config/mpu9250_params.yaml`](config/mpu9250_params.yaml).  
In normal operation the node is started by `brain_stem/peripheral_nervous_system.launch.py` instead.

```bash
ros2 launch mpu9250 mpu9250.launch.py
```

---

## Credits

The sensor driver and quaternion filters are derived from the [MPU9250 Arduino library](https://github.com/hideakitai/MPU9250) by Hideaki Tai (MIT License), ported here to Linux I²C and ROS 2. The filters implement the Madgwick and Mahony AHRS algorithms, following [Kris Winer's MPU9250 reference code](https://github.com/kriswiner/MPU9250). See [LICENSE](LICENSE) for the full third-party notice.

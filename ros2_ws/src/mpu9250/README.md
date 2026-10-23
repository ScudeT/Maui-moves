# `mpu9250` — IMU Driver

ROS 2 driver for the InvenSense MPU-9250 9-axis IMU (accelerometer + gyroscope + magnetometer). Communicates over I²C, runs an onboard attitude filter, and publishes orientation, angular velocity, linear acceleration, and magnetometer data.

---

## Node: `mpu9250_node` (`ImuNode`)

| | |
|---|---|
| **Interface** | I²C `/dev/i2c-1`, address `0x68` |
| **Attitude filter** | Madgwick (used on the robot) or Mahony (node default) — runs onboard in the driver |

### Published topics

| Topic | Type | Description |
|---|---|---|
| `/imu/data` | `sensor_msgs/Imu` | Orientation quaternion, angular velocity (rad/s), linear acceleration (m/s²) with diagonal covariance |
| `/imu/mag` | `sensor_msgs/MagneticField` | Magnetometer reading in milli-Gauss (axes remapped to ENU). Remapped to `/imu/mag_raw` by the `brain_stem` launch |
| `/imu/temperature` | `std_msgs/Float64` | On-chip temperature (°C) |

### Parameters

On the robot the node is configured from [`brain_stem/config/PNS.yaml`](../maui_brain/brain_stem/config/PNS.yaml). The enum indices for the sensor settings are listed in the comments of that file.

| Parameter | Node default | Robot (`PNS.yaml`) | Description |
|---|---|---|---|
| `freq` | `50.0` | `100.0` | Publish rate (Hz) — must be ≤ `fifo_sample_rate` |
| `frame_id` | `"base_link"` | `"imu_link"` | Frame for the published message headers |
| `filter` | `2` | `1` | Attitude filter: `0` = none, `1` = Madgwick, `2` = Mahony |
| `accel_fs_sel` | `1` | `1` | Accelerometer full-scale: `0`=±2G `1`=±4G `2`=±8G `3`=±16G |
| `gyro_fs_sel` | `1` | `0` | Gyroscope full-scale: `0`=±250 `1`=±500 `2`=±1000 `3`=±2000 dps |
| `mag_output_bits` | `0` | `0` | Magnetometer resolution: `0` = 14 bit, `1` = 16 bit |
| `fifo_sample_rate` | `1` | `1` | Internal FIFO rate: `0`=1000Hz `1`=500Hz `2`=333Hz … |
| `gyro_dlpf_cfg` | `3` | `3` | Gyro low-pass cutoff (`3` = 41 Hz) |
| `accel_dlpf_cfg` | `3` | `3` | Accel low-pass cutoff (`3` = 45 Hz) |
| `g` | `9.81` | `9.80665` | Gravity used to scale accelerations (m/s²) |
| `mag_bias` | `[500, 1500, 1250]` | `[-211, 322, -472]` | Hard-iron magnetometer offset (mG) — calibrate per robot (see below) |
| `acc_cov` / `w_cov` / `rpy_cov` | `0.01` / `0.01` / `0.0003` | `1.0` / `0.01` / `0.001` | Diagonal covariance values for the Imu message |

### Calibration

On startup the node automatically runs an accelerometer and gyroscope bias calibration routine (keep the robot still for ~2 seconds). The onboard magnetometer calibration (`calibrateMag`) is disabled. Instead, the hard-iron offset is measured offline and written to `mag_bias` in `PNS.yaml`:

1. Record raw magnetometer data while rotating the robot through as many orientations as possible:

   ```bash
   ros2 run mpu9250 record_mag mag.csv --duration 120
   ```

   `record_mag` is a standalone executable (not a ROS node) that writes `t,mx,my,mz` (s, mG, no hard/soft-iron correction) to the CSV. Options: `--rate` (Hz, default 10, max 100), `--duration` (s, default until Ctrl+C), `--bits` (`14` or `16`, default 14), `--device` (default `/dev/i2c-1`). Stop `mpu9250_node` first, since both access the sensor.
2. Fit an ellipsoid to the samples, as in [`tools/mag_cal_study.ipynb`](../../../tools/mag_cal_study.ipynb). Its centre is the hard-iron offset.
3. Put the centre in `mag_bias` in [`brain_stem/config/PNS.yaml`](../maui_brain/brain_stem/config/PNS.yaml).

---

## Launch file

### `mpu9250.launch.py`
Standalone launch for the IMU node. It passes [`config/mpu9250_params.yaml`](config/mpu9250_params.yaml), but that file is keyed `mpu9250_node` while the launch names the node `IMU`, so the standalone launch currently runs with the node defaults.  
In normal operation the node is started by `brain_stem/peripheral_nervous_system.launch.py` instead.

```bash
ros2 launch mpu9250 mpu9250.launch.py
```

---

## Credits

The sensor driver and quaternion filters are derived from the [MPU9250 Arduino library](https://github.com/hideakitai/MPU9250) by Hideaki Tai (MIT License), ported here to Linux I²C and ROS 2. The filters implement the Madgwick and Mahony AHRS algorithms, following [Kris Winer's MPU9250 reference code](https://github.com/kriswiner/MPU9250). See [LICENSE](LICENSE) for the full third-party notice.

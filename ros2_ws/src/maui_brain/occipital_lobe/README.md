# `occipital_lobe` — Camera Interface

Fetches frames from the Raspberry Pi cameras and publishes them as ROS Image messages. This package has no launch file of its own — its nodes are included in mission launches that require vision.

---

## Nodes

### `cameras_client_node` (`DualCameraClientNode`)
Connects to the Flask camera bridge running on the host OS and publishes both cameras simultaneously.

| Topic | Type | Description |
|---|---|---|
| `/camera_1` | `sensor_msgs/Image` | Left camera (cam1) |
| `/camera_2` | `sensor_msgs/Image` | Right camera (cam2) |

Parameter: `capture_frequency` (Hz, default 10.0).  
Source URLs: `http://0.0.0.0:5000/capture/cam1` and `/capture/cam2` — served by [`raspiOs_setup/raspi_api_interface/fast_cameras_server.py`](../../../../raspiOs_setup/raspi_api_interface/fast_cameras_server.py).

---

### `camera_client_test` (`ImageClientNode`)
Single-camera test node. Fetches from `http://0.0.0.0:5000/` and publishes on `camera/image`. Used for verifying camera bridge connectivity.

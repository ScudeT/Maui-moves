# `gtu7_gps_comm` — GPS Driver

ROS 2 driver for the GTU7 GPS receiver. Reads NMEA sentences from the Raspberry Pi UART and publishes a standard `NavSatFix` message with position covariance estimated from DOP values.

---

## Node: `gps_node` (`Gtu7GpsNode`)

| | |
|---|---|
| **Interface** | UART `/dev/ttyAMA0` at 9600 baud |
| **Publish rate** | 10 Hz (polled) |

### Published topics

| Topic | Type | Description |
|---|---|---|
| `/gps_data` | `sensor_msgs/NavSatFix` | Latitude, longitude, altitude, and position covariance |

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `uere` | `5.0` | User equivalent range error (m) — used to scale DOP into covariance when no GST sentence is available |

### How covariance is computed

The node parses three NMEA sentence types:

- **GST** — if present, provides direct per-axis standard deviations (`σ_lat`, `σ_lon`, `σ_alt`) → `COVARIANCE_TYPE_APPROXIMATED`
- **GSA** — if no GST, HDOP/VDOP are used: `C_h = (HDOP × uere)²` → `COVARIANCE_TYPE_APPROXIMATED`
- **Neither** → `COVARIANCE_TYPE_UNKNOWN`

Fixes are only published on valid **RMC** (status `A`) or **GGA** (quality > 0) sentences.

---

## Other nodes in this package

| Node | Description |
|---|---|
| `gps_gpsd_node` | Alternative driver using `gpsd` daemon instead of direct serial |
| `gps_node_cov` | Variant with explicit covariance tuning |
| `gps_test` | Simple test node for verifying serial connectivity |

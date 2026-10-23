#!/usr/bin/env python3
import math
import time

import rclpy
from rclpy.node import Node
import gpiod
from std_msgs.msg import Bool


LEAK = 2  # integrator decrement for each sample that disagrees


class ButtonReader(Node):
    """
    Debounced GPIO button reader.

    The line level is sampled at `freq` Hz and fed to a leaky integrator:
    every sample that agrees with the candidate state counts +1, every sample
    that disagrees counts -LEAK (floored at 0), so the line has to agree for
    more than LEAK/(LEAK+1) of the time to make progress. A state change is accepted only
    when the counter reaches the number of samples equivalent to `press_time`
    (or `release_time`). Short splashes or intermittent water bridges between
    the contacts therefore never reach the threshold, while a real press is
    detected after ~press_time instead of waiting for a long lockout.

    After a confirmed release, presses are ignored for `refractory_time`
    seconds to reject contact chatter while the switch drains.
    """

    def __init__(self):
        super().__init__('button_reader')

        # freq:            sampling frequency in Hz.
        # gpio_line:       line number for gpiod.Chip.get_line.
        # press_time:      time (s) the line must be (mostly) high to accept a press.
        # release_time:    time (s) the line must be (mostly) low to accept a release.
        # refractory_time: time (s) after a release during which presses are ignored.
        # release:         publish False on button release.
        self.declare_parameter('freq', 200.0)
        self.declare_parameter('gpio_line', 4)
        self.declare_parameter('press_time', 0.04)
        self.declare_parameter('release_time', 0.04)
        self.declare_parameter('refractory_time', 0.25)
        self.declare_parameter('release', True)

        self.freq = self.get_parameter('freq').value
        self.gpio_line = self.get_parameter('gpio_line').value
        self.press_time = self.get_parameter('press_time').value
        self.release_time = self.get_parameter('release_time').value
        self.refractory_time = self.get_parameter('refractory_time').value
        self.release = self.get_parameter('release').value

        if self.freq <= 0:
            self.get_logger().warn("freq must be > 0, falling back to 200 Hz")
            self.freq = 200.0

        # Thresholds expressed in samples (at least one sample each)
        self.n_press = max(1, math.ceil(self.press_time * self.freq))
        self.n_release = max(1, math.ceil(self.release_time * self.freq))

        self.get_logger().info(
            f"Parameters set: freq={self.freq} Hz, gpio_line={self.gpio_line}, "
            f"press_time={self.press_time}s ({self.n_press} samples), "
            f"release_time={self.release_time}s ({self.n_release} samples), "
            f"refractory_time={self.refractory_time}s, release publishing={self.release}"
        )

        # Publisher for button state (True for pressed, False for released).
        self.publisher_ = self.create_publisher(Bool, 'button_state', 10)

        # Open GPIO chip and request the line as a plain input with pull-down bias.
        self.chip = gpiod.Chip('/dev/gpiochip0')
        self.line = self.chip.get_line(self.gpio_line)
        self.line.request(
            consumer="button_reader",
            type=gpiod.LINE_REQ_DIR_IN,
            flags=gpiod.LINE_REQ_FLAG_BIAS_PULL_DOWN
        )

        # Debounce state
        self.pressed = False       # accepted (debounced) state
        self.counter = 0           # leaky integrator towards the opposite state
        self.ignore_until = 0.0    # end of the refractory window (monotonic time)

        self.timer = self.create_timer(1.0 / self.freq, self.timer_callback)

    def timer_callback(self):
        now = time.monotonic()
        level = bool(self.line.get_value())

        if not self.pressed:
            # Refractory window: do not accumulate towards a new press
            if now < self.ignore_until:
                self.counter = 0
                return

            self.counter = self.counter + 1 if level else max(0, self.counter - LEAK)

            if self.counter >= self.n_press:
                self.pressed = True
                self.counter = 0
                self.get_logger().info("Button pressed")
                self.publisher_.publish(Bool(data=True))
        else:
            self.counter = self.counter + 1 if not level else max(0, self.counter - LEAK)

            if self.counter >= self.n_release:
                self.pressed = False
                self.counter = 0
                self.ignore_until = now + self.refractory_time
                if self.release:
                    self.get_logger().info("Button released")
                    self.publisher_.publish(Bool(data=False))

    def destroy_node(self):
        try:
            self.line.release()
            self.chip.close()
        except Exception:
            pass
        super().destroy_node()


def main(args=None):
    rclpy.init(args=args)
    node = ButtonReader()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()

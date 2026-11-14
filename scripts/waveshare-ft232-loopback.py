#!/usr/bin/env python3
"""Host-only Waveshare FT232 TXD/RXD loopback check (no projector)."""

import argparse
import os
import select
import sys
import termios
import time

PAYLOAD = b"BLISS-WAVESHARE-LOOPBACK-12345"


def run(port: str, timeout: float) -> int:
    fd = None
    old_settings = None
    outcome = 2
    try:
        fd = os.open(port, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        old_settings = termios.tcgetattr(fd)
        settings = termios.tcgetattr(fd)
        settings[0] = 0  # No input transformations
        settings[1] = 0  # No output transformations
        settings[2] = termios.CS8 | termios.CREAD | termios.CLOCAL  # 8N1, no parity
        settings[2] &= ~getattr(termios, 'CRTSCTS', 0)  # No RTS/CTS flow control
        settings[3] = 0  # Noncanonical, no echo
        settings[4] = termios.B115200
        settings[5] = termios.B115200
        settings[6][termios.VMIN] = 0
        settings[6][termios.VTIME] = 0
        termios.tcsetattr(fd, termios.TCSANOW, settings)
        termios.tcflush(fd, termios.TCIOFLUSH)

        print("Sende:", PAYLOAD.decode("ascii"))
        deadline = time.monotonic() + timeout
        sent = 0
        while sent < len(PAYLOAD) and time.monotonic() < deadline:
            remaining = max(0.0, deadline - time.monotonic())
            _, writable, _ = select.select([], [fd], [], remaining)
            if not writable:
                break
            try:
                count = os.write(fd, PAYLOAD[sent:])
            except BlockingIOError:
                continue
            if count == 0:
                break
            sent += count

        received = b""
        while len(received) < len(PAYLOAD) and time.monotonic() < deadline:
            remaining = max(0.0, deadline - time.monotonic())
            readable, _, _ = select.select([fd], [], [], remaining)
            if not readable:
                break
            try:
                chunk = os.read(fd, 4096)
            except BlockingIOError:
                continue
            if not chunk:
                break
            received += chunk

        print("Empfangen:", repr(received))
        outcome = 0 if sent == len(PAYLOAD) and received == PAYLOAD else 1
        print("Ergebnis:", "PASS" if outcome == 0 else "FAIL")
    except (OSError, ValueError) as exc:
        print(f"FEHLER bei {port}: {exc}", file=sys.stderr)
        outcome = 2
    finally:
        if fd is not None:
            if old_settings is not None:
                try:
                    termios.tcsetattr(fd, termios.TCSANOW, old_settings)
                except OSError as exc:
                    print(f"WARNUNG: Port-Einstellungen nicht restauriert: {exc}", file=sys.stderr)
                    outcome = 2
            try:
                os.close(fd)
            except OSError as exc:
                print(f"WARNUNG: Port konnte nicht geschlossen werden: {exc}", file=sys.stderr)
                outcome = 2
    return outcome


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", default="/dev/ttyUSB0", help="Linux UART-Device (default: /dev/ttyUSB0)")
    parser.add_argument("--timeout", type=float, default=3.0, help="Total time limit in seconds (default: 3)")
    args = parser.parse_args()
    if not 0 < args.timeout <= 60:
        parser.error("--timeout must be > 0 and <= 60")
    return run(args.port, args.timeout)


if __name__ == "__main__":
    sys.exit(main())

# Waveshare FT232 USB–UART wiring

1. Disconnect the projector from power before wiring.
2. Set the adapter to the verified UART logic voltage. Do not assume the correct jumper setting.
3. Connect **adapter GND → board GND**, **adapter TXD → board RX**, **adapter RXD → board TX**.
4. **Do not connect adapter VCC** until the device power arrangement is verified.
5. Verify the exact board pads against labeled board photographs before connecting. The pad mapping is **not yet verified in this repository**.
6. On Debian, check `lsusb` and `ls -l /dev/serial/by-id/`; identify the correct `/dev/ttyUSB*` port.
7. Perform an adapter-only TXD/RXD loopback test with the projector disconnected before connecting the board.

Do not connect mains voltage to USB–UART pins.

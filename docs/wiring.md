# Waveshare FT232 wiring — evidence pending

The documented host adapter is Waveshare FT232 (FTDI `0403:6001` was observed on Linux). A working host-only TXD/RXD loopback script exists in the original project (`scripts/local/waveshare_ft232_loopback_v1.py`). **The exact projector PCB pad-to-signal mapping and photo references have not been recovered from accessible project files.** Do not guess pad positions.

Before connecting: identify board GND, UART RX and UART TX from verified photos/measurements; cross adapter TXD to device RX and adapter RXD to device TX; use common GND. Confirm the required UART logic level and adapter jumper setting from the board and adapter documentation. **Do not connect adapter VCC until power topology is established.** Keep the projector disconnected from mains while wiring; use a documented safe power-up procedure. Never feed mains voltage into USB-UART pins.

Capture verified PCB photos and label the actual pads here before a flashing tutorial is declared ready.

# Original Evolve firmware archive

This [archive](evolve-reference-firmware-bk7231n-v1.0.tar.gz) contains a **2 MiB raw flash dump** from another BlissLights Evolve with a BK7231N/CBU module.

| Property | Value |
| --- | --- |
| File | `evolve-reference-firmware-bk7231n-v1.0.tar.gz` |
| Original BIN | `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin` |
| Raw size | 2,097,152 bytes (`0x200000`) |
| Raw SHA-256 | `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0` |
| Archive SHA-256 | `2665124ef072fe579b4f38f85e39352cd08a35a0b71167b4706e0e39b40b6d37` |

Thanks to **[Dawk323](https://www.elektroda.com/rtvforum/topic3984240.html)** for sharing the dump.

**Caution:** A complete raw restore overwrites the bootloader and all storage, including device-specific settings. The CRC-stripped application size `0xDEAC0` is **not** the raw-image flash length `0x200000`.

See [the recovery procedure](../../docs/recovery.md). Check firmware redistribution rights and embedded device-specific data before making the archive public.

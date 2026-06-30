# imlib2

imlib2's PNG loader parses chunk headers at unaligned file offsets. By default, Debian builds without struct packing, causing the compiler to assume natural alignment and emit 32-bit word loads (`ldr`). On ARMv5, unaligned word loads silently return rotated garbage data instead of trapping. This causes the loader to calculate incorrect offsets and jump into unmapped memory, triggering a SIGSEGV in consumers like `icewm` and `feh`.

Appending `--enable-packing` to `dh_auto_configure` in `debian/rules` fixes the crash. It forces the compiler to use alignment-safe byte-wise loads (`ldrb`) for the packed structures, resolving the unaligned access faults on armel.

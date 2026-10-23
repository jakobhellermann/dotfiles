# TODO(ai-review): generated, not yet audited
# Load shared objects of a core from its NT_FILE mappings, for cores whose
# link map gdb cannot find (static-pie loaders like wine-preloader).
import os
import re
import struct

import gdb

PT_INTERP = 3


class NtFileSolibs(gdb.Command):
    """Add symbol files for every ELF the core maps at file offset 0."""

    def __init__(self):
        super().__init__("ntfile-solibs", gdb.COMMAND_FILES)

    def invoke(self, arg, from_tty):
        out = gdb.execute("info proc mappings", to_string=True)
        seen = set()
        for line in out.splitlines():
            m = re.match(r"\s*(0x[0-9a-f]+)\s+0x[0-9a-f]+\s+0x[0-9a-f]+\s+(0x[0-9a-f]+)\s+(?:\S+\s+)?(/\S.*)$", line)
            if not m:
                continue
            start, offset, path = int(m[1], 16), int(m[2], 16), m[3].strip()
            if offset != 0 or path in seen or not os.path.isfile(path):
                continue
            with open(path, "rb") as f:
                if f.read(4) != b"\x7fELF":
                    continue
            seen.add(path)
            gdb.execute(f"add-symbol-file {path} -o {start:#x}", to_string=True)
        gdb.write(f"ntfile-solibs: loaded {len(seen)} objects\n")


def has_interp(path):
    """Whether a 64-bit little-endian ELF has a PT_INTERP program header."""
    with open(path, "rb") as f:
        header = f.read(64)
        phoff, = struct.unpack_from("<Q", header, 0x20)
        phentsize, phnum = struct.unpack_from("<HH", header, 0x36)
        f.seek(phoff)
        table = f.read(phentsize * phnum)
    return any(struct.unpack_from("<I", table, i * phentsize)[0] == PT_INTERP for i in range(phnum))


# Without PT_INTERP gdb has no link map to find the core's shared objects through.
def on_corefile_changed(event):
    if event.inferior.corefile is None:
        return
    exe = gdb.current_progspace().filename
    if exe and not has_interp(exe):
        gdb.execute("ntfile-solibs")


NtFileSolibs()
gdb.events.corefile_changed.connect(on_corefile_changed)

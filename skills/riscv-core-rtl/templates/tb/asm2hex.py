#!/usr/bin/env python3
"""Convert a RISC-V ELF or raw binary into a $readmemh hex image.

Word addresses in the hex file are relative to --ram-base (byte_address - ram_base) / 4
so $readmemh can fill a TB RAM array that starts at index 0.

Engineering decision: ELF32 and ELF64 little-endian are both supported so RV32
and RV64 generated cores share this script.
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

PT_LOAD = 1


def load_elf_le(data: bytes) -> list[tuple[int, bytes]]:
    if data[:4] != b"\x7fELF":
        raise ValueError("not an ELF file")
    if data[5] != 1:
        raise ValueError("only little-endian ELF is supported")
    ei_class = data[4]
    segs: list[tuple[int, bytes]] = []
    if ei_class == 2:
        e_phoff = struct.unpack_from("<Q", data, 32)[0]
        e_phentsize, e_phnum = struct.unpack_from("<HH", data, 54)
        for i in range(e_phnum):
            off = e_phoff + i * e_phentsize
            p_type, _p_flags, p_offset, p_vaddr, _p_paddr, p_filesz, p_memsz, _p_align = (
                struct.unpack_from("<IIQQQQQQ", data, off)
            )
            if p_type != PT_LOAD:
                continue
            payload = bytearray(p_memsz)
            chunk = data[p_offset : p_offset + p_filesz]
            payload[: len(chunk)] = chunk
            segs.append((p_vaddr, bytes(payload)))
    elif ei_class == 1:
        e_phoff = struct.unpack_from("<I", data, 28)[0]
        e_phentsize, e_phnum = struct.unpack_from("<HH", data, 42)
        for i in range(e_phnum):
            off = e_phoff + i * e_phentsize
            p_type, p_offset, p_vaddr, _p_paddr, p_filesz, p_memsz, _p_flags, _p_align = (
                struct.unpack_from("<IIIIIIII", data, off)
            )
            if p_type != PT_LOAD:
                continue
            payload = bytearray(p_memsz)
            chunk = data[p_offset : p_offset + p_filesz]
            payload[: len(chunk)] = chunk
            segs.append((p_vaddr, bytes(payload)))
    else:
        raise ValueError("only ELF32/ELF64 are supported")
    return segs


def bytes_to_words(segments: list[tuple[int, bytes]], ram_base: int) -> dict[int, int]:
    words: dict[int, int] = {}
    for vaddr, blob in segments:
        for i, byte in enumerate(blob):
            addr = vaddr + i
            if addr < ram_base:
                continue
            rel = addr - ram_base
            waddr = rel // 4
            shift = (rel % 4) * 8
            words[waddr] = words.get(waddr, 0) | (byte << shift)
    return words


def write_hex(path: Path, words: dict[int, int]) -> None:
    with path.open("w", encoding="ascii") as fh:
        prev = None
        for waddr in sorted(words):
            if prev is None or waddr != prev + 1:
                fh.write(f"@{waddr:08x}\n")
            fh.write(f"{words[waddr]:08x}\n")
            prev = waddr


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("input", type=Path, help="ELF or raw binary")
    ap.add_argument("output", type=Path, help="hex file for $readmemh")
    ap.add_argument(
        "--ram-base",
        type=lambda s: int(s, 0),
        default=0x80000000,
        help="subtract this base so hex addresses index TB RAM (default 0x80000000)",
    )
    ap.add_argument(
        "--base",
        type=lambda s: int(s, 0),
        default=0,
        help="load address for a raw binary (default 0)",
    )
    args = ap.parse_args()

    data = args.input.read_bytes()
    if data[:4] == b"\x7fELF":
        segments = load_elf_le(data)
    else:
        segments = [(args.base, data)]

    if not segments:
        print("error: no loadable segments", file=sys.stderr)
        return 1

    words = bytes_to_words(segments, args.ram_base)
    if not words:
        print("error: no bytes landed in RAM window", file=sys.stderr)
        return 1

    write_hex(args.output, words)
    return 0


if __name__ == "__main__":
    sys.exit(main())

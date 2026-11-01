"""Compile a Windows Terminal pixel shader with Windows' own d3dcompiler_47.dll, the
compiler Terminal uses at runtime, so a broken shader fails here instead of showing as
a warning in Terminal. No Windows SDK needed.

Usage: python tools/check_shader.py shaders/blackwall.hlsl [--target ps_4_0]
Exit 0 and "ok" on success; exit 1 with the compiler's errors otherwise.
"""
import argparse
import ctypes
import pathlib
import sys
from ctypes import wintypes


def blob_text(blob: ctypes.c_void_p) -> str:
    # ID3DBlob vtable: QueryInterface, AddRef, Release, GetBufferPointer, GetBufferSize.
    vtable = ctypes.cast(blob, ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
    get_pointer = ctypes.WINFUNCTYPE(ctypes.c_void_p, ctypes.c_void_p)(vtable[3])
    get_size = ctypes.WINFUNCTYPE(ctypes.c_size_t, ctypes.c_void_p)(vtable[4])
    data = ctypes.string_at(get_pointer(blob), get_size(blob))
    return data.decode("utf-8", errors="replace").rstrip("\x00")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("shader")
    parser.add_argument("--target", default="ps_4_0")
    args = parser.parse_args()

    source = pathlib.Path(args.shader).read_bytes()
    compiler = ctypes.WinDLL("d3dcompiler_47.dll")
    compile_fn = compiler.D3DCompile
    compile_fn.restype = ctypes.c_long
    compile_fn.argtypes = [
        ctypes.c_void_p, ctypes.c_size_t, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_void_p,
        ctypes.c_char_p, ctypes.c_char_p, wintypes.UINT, wintypes.UINT,
        ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(ctypes.c_void_p),
    ]
    code = ctypes.c_void_p()
    errors = ctypes.c_void_p()
    hr = compile_fn(source, len(source), args.shader.encode(), None, None, b"main",
                    args.target.encode(), 0, 0, ctypes.byref(code), ctypes.byref(errors))
    messages = blob_text(errors) if errors.value else ""
    if hr < 0:
        print(f"FAILED ({args.target}, hr=0x{hr & 0xFFFFFFFF:08x})")
        print(messages)
        return 1
    print(f"ok: {args.shader} compiles as {args.target}")
    if messages:
        print(messages)
    return 0


if __name__ == "__main__":
    sys.exit(main())

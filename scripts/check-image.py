#!/usr/bin/env python3
"""Read-only size and SHA-256 gate for the archived community firmware."""
import argparse
import hashlib
from pathlib import Path
import sys

EXPECTED_SIZE = 2097152
EXPECTED_SHA256 = '07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image', type=Path)
    args = parser.parse_args()
    try:
        with args.image.open('rb') as handle:
            digest = hashlib.sha256()
            size = 0
            while chunk := handle.read(1024 * 1024):
                size += len(chunk)
                digest.update(chunk)
    except OSError as exc:
        print(f'ERROR: {exc}', file=sys.stderr)
        return 2
    sha = digest.hexdigest()
    print(f'size={size} sha256={sha}')
    if size != EXPECTED_SIZE or sha != EXPECTED_SHA256:
        print('FAIL: image is not the documented original community dump', file=sys.stderr)
        return 1
    print('PASS: image bytes match the documented reference (not a flash authorization)')
    return 0

if __name__ == '__main__':
    sys.exit(main())

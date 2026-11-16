#!/usr/bin/env python3
"""Reject sensitive firmware inputs from Git staged changes or outgoing commits.
Fail closed on parse errors; never print credential values.
"""
import argparse
import pathlib
import re
import subprocess
import sys

PRIVATE = re.compile(r"(^|/)(secrets\.ya?ml|[^/]*\.local\.ya?ml|\.env(?:\..*)?)$")
FIELDS = re.compile(r"(?m)^\s*(wifi_ssid|wifi_password|fallback_ap_password|evolve_2024_api_key|evolve_2024_ota_password)\s*:\s*(\S+)")
INLINE = re.compile(r"(?m)^\s*(?:password|key)\s*:\s*(\S+)")
ALLOWED = ("INSERT_", "!secret ", "${", "REDACTED", "example", "placeholder")

def git(*args, data=None):
    p = subprocess.run(["git", *args], input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode:
        raise RuntimeError("git inspection failed: " + " ".join(args[:3]))
    return p.stdout

def inspect(commit):
    names = git("diff-tree", "--no-commit-id", "--name-only", "--diff-filter=d", "-r", "-z", commit).split(b"\0")
    for raw in filter(None, names):
        path = raw.decode("utf-8", "surrogateescape")
        if PRIVATE.search(path):
            raise ValueError("Private file in commit: " + path)
        if path.endswith((".yaml", ".yml")) and "firmware/" in path:
            try:
                body = git("show", commit + ":" + path).decode("utf-8")
            except (UnicodeDecodeError, RuntimeError):
                raise ValueError("Cannot inspect firmware YAML: " + path)
            for pattern in (FIELDS, INLINE):
                for match in pattern.finditer(body):
                    value = match.group(match.lastindex).strip().strip('\"\\\'')
                    if value and not value.startswith(ALLOWED):
                        raise ValueError("Possible embedded firmware credential: " + path)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pre-push", action="store_true")
    args = ap.parse_args()
    if args.pre_push:
        for line in sys.stdin:
            parts = line.split()
            if len(parts) != 4:
                raise ValueError("Unexpected pre-push ref format")
            _, local_sha, _, remote_sha = parts
            if set(local_sha) == {"0"}:
                continue
            if set(remote_sha) == {"0"}:
                commits = git("rev-list", local_sha, "--not", "--remotes").decode().splitlines()
            else:
                commits = git("rev-list", local_sha, "^" + remote_sha).decode().splitlines()
            for commit in commits:
                inspect(commit)
    else:
        names = git("diff", "--cached", "--name-only", "--diff-filter=d", "-z").split(b"\0")
        for raw in filter(None, names):
            path = raw.decode("utf-8", "surrogateescape")
            if PRIVATE.search(path):
                raise ValueError("Private file staged: " + path)
            if path.endswith((".yaml", ".yml")) and "firmware/" in path:
                try:
                    body = git("show", ":" + path).decode("utf-8")
                except (UnicodeDecodeError, RuntimeError):
                    raise ValueError("Cannot inspect staged YAML: " + path)
                for pattern in (FIELDS, INLINE):
                    for match in pattern.finditer(body):
                        value = match.group(match.lastindex).strip().strip('\"\\\'')
                        if value and not value.startswith(ALLOWED):
                            raise ValueError("Possible embedded firmware credential: " + path)
    print("FIRMWARE_SECRET_GUARD_OK")

if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError) as exc:
        print("FIRMWARE_SECRET_GUARD_BLOCKED: " + str(exc), file=sys.stderr)
        sys.exit(1)

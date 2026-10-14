#!/usr/bin/env python3
"""Run PowerShell in the local Windows VM without exposing its password."""

import argparse
import base64
import os
from pathlib import Path
import shutil
import subprocess
import sys

import yaml


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--command", help="PowerShell source to execute")
    source.add_argument("--script", type=Path, help="Host PowerShell file to execute")
    parser.add_argument("--timeout", type=float, default=60, help="SSH timeout in seconds")
    parser.add_argument(
        "--compose", type=Path,
        default=Path("/run/media/nico/200GB_DATA/windows-vm/compose.yml"),
        help="Existing lab Compose configuration",
    )
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if not all(shutil.which(tool) for tool in ("sshpass", "ssh")):
        parser.exit(2, "vm-ssh: sshpass and ssh must be installed\n")

    try:
        configuration = yaml.safe_load(args.compose.read_text())
        environment = configuration["services"]["windows"]["environment"]
        username = environment["USERNAME"]
        password = environment["PASSWORD"]
        if not isinstance(username, str) or not username or not isinstance(password, str) or not password:
            raise ValueError("missing credentials")
    except (OSError, yaml.YAMLError, KeyError, TypeError, ValueError):
        parser.exit(2, "vm-ssh: could not read configured Windows credentials\n")

    try:
        script = args.script.read_text(encoding="utf-8-sig") if args.script else args.command
    except (OSError, UnicodeError):
        parser.exit(2, "vm-ssh: could not read the host PowerShell script\n")
    encoded = base64.b64encode(("$ErrorActionPreference = 'Stop'\n" + script).encode("utf-16le")).decode("ascii")
    child_environment = dict(os.environ, SSHPASS=password)
    command = [
        "sshpass", "-e", "ssh", "-T",
        "-o", "ConnectTimeout=10",
        "-o", "ServerAliveInterval=10",
        "-o", "ServerAliveCountMax=2",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", "UserKnownHostsFile=/run/media/nico/200GB_DATA/windows-vm/known_hosts",
        "-p", "2222", f"{username}@127.0.0.1",
        f"powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand {encoded}",
    ]
    try:
        return subprocess.run(command, env=child_environment, timeout=args.timeout).returncode
    except subprocess.TimeoutExpired:
        print("vm-ssh: SSH timed out; check the guest job before retrying", file=sys.stderr)
        return 124
    except OSError:
        print("vm-ssh: could not start SSH", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Run PowerShell in the local Windows VM without exposing its password."""

import argparse
import base64
import io
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import threading
import time

import yaml

KNOWN_HOSTS = "/run/media/nico/200GB_DATA/windows-vm/known_hosts"
# Silence progress records, which reach SSH as CLIXML noise.
PREAMBLE = "$ErrorActionPreference = 'Stop'\n$ProgressPreference = 'SilentlyContinue'\n"


def ssh_command(username, *options):
    return [
        "sshpass", "-e", "ssh", *options,
        "-o", "ConnectTimeout=10",
        "-o", "ServerAliveInterval=10",
        "-o", "ServerAliveCountMax=2",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", f"UserKnownHostsFile={KNOWN_HOSTS}",
        "-o", "WarnWeakCrypto=no-pq-kex",
        "-p", "2222", f"{username}@127.0.0.1",
    ]


def start(command, environment, stopped_status=143, **options):
    # sshpass doesn't pass SIGTERM on to ssh, so give them their own process
    # group and stop the whole group when this helper is stopped or times out.
    process = subprocess.Popen(
        command, env=environment, stdin=subprocess.DEVNULL, start_new_session=True, **options,
    )

    def stop(signum, _frame):
        stop_group(process)
        sys.exit(stopped_status if signum == signal.SIGTERM else 128 + signum)

    for signum in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(signum, stop)
    return process


def stop_group(process):
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    process.wait()


def pump(source, target):
    # Guest output uses CRLF, which breaks host shell comparisons.
    for line in iter(source.readline, b""):
        target.write(line.replace(b"\r\n", b"\n"))
        target.flush()


def run_powershell(username, environment, script, timeout, errors=None):
    encoded = base64.b64encode((PREAMBLE + script).encode("utf-16le")).decode("ascii")
    command = ssh_command(username, "-T") + [
        f"powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand {encoded}",
    ]
    process = start(command, environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    pumps = [
        threading.Thread(target=pump, args=(process.stdout, sys.stdout.buffer)),
        threading.Thread(target=pump, args=(process.stderr, errors or sys.stderr.buffer)),
    ]
    for thread in pumps:
        thread.start()
    try:
        status = process.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        stop_group(process)
        status = None
    for thread in pumps:
        thread.join()
    return status


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--command", help="PowerShell source to execute")
    action.add_argument("--script", type=Path, help="Host PowerShell file to execute")
    action.add_argument(
        "--wait-ready", type=float, metavar="SECONDS",
        help="Retry until the guest runs commands, warm up CIM, then print READY",
    )
    action.add_argument(
        "--forward", type=int, metavar="PORT",
        help="Forward 127.0.0.1:PORT on the host to the guest's loopback PORT until stopped",
    )
    parser.add_argument("--timeout", type=float, default=120, help="SSH timeout in seconds")
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
    child_environment = dict(os.environ, SSHPASS=password)

    try:
        if args.forward is not None:
            if not 0 < args.forward < 65536:
                parser.error("--forward needs a port number")
            forward = f"127.0.0.1:{args.forward}:127.0.0.1:{args.forward}"
            command = ssh_command(username, "-N", "-o", "ExitOnForwardFailure=yes", "-L", forward)
            # Stopping the tunnel is its normal end.
            return start(command, child_environment, stopped_status=0).wait()

        if args.wait_ready is not None:
            deadline = time.monotonic() + args.wait_ready
            errors = io.BytesIO()
            while time.monotonic() < deadline:
                # The first CIM query after boot can take over a minute.
                probe = "Get-CimInstance Win32_OperatingSystem | Out-Null; Write-Output READY"
                attempt = min(90, max(10, deadline - time.monotonic()))
                # Connection resets are expected while the guest boots; show
                # only the last attempt's errors if it never becomes ready.
                errors = io.BytesIO()
                if run_powershell(username, child_environment, probe, attempt, errors) == 0:
                    return 0
                time.sleep(5)
            sys.stderr.buffer.write(errors.getvalue())
            print("vm-ssh: guest not ready in time; check the console", file=sys.stderr)
            return 124

        try:
            script = args.script.read_text(encoding="utf-8-sig") if args.script else args.command
        except (OSError, UnicodeError):
            parser.exit(2, "vm-ssh: could not read the host PowerShell script\n")
        status = run_powershell(username, child_environment, script, args.timeout)
        if status is None:
            print("vm-ssh: SSH timed out; check the guest job before retrying", file=sys.stderr)
            return 124
        return status
    except OSError:
        print("vm-ssh: could not start SSH", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())

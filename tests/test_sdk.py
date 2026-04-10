# [[file:testing.org::*Test fixtures][Test fixtures:1]]
import os
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
COMMANDS_DIR = Path(__file__).parent / "commands"
EXPECTED_DIR = Path(__file__).parent / "expected"
command_files = sorted(COMMANDS_DIR.glob("*")) if COMMANDS_DIR.exists() else []


@pytest.mark.parametrize(
    "cmd_file",
    command_files,
    ids=[f.name for f in command_files],
)
def test_command(tmp_path, cmd_file):
    env = {**os.environ, "TMP": str(tmp_path), "ROOT": str(ROOT)}
    env["PATH"] = str(ROOT / "tests") + ":" + env.get("PATH", "")
    result = subprocess.run(
        ["bash", str(cmd_file)],
        capture_output=True,
        text=True,
        cwd=str(ROOT),
        env=env,
    )
    assert result.returncode == 0, (
        f"command {cmd_file.name} failed (exit {result.returncode}):\n{result.stderr}"
    )
    expected_file = EXPECTED_DIR / cmd_file.name
    expected = expected_file.read_text().rstrip("\n") if expected_file.exists() else ""
    assert result.stdout.rstrip("\n") == expected, (
        f"{cmd_file.name}: got {result.stdout.rstrip(chr(10))!r}, expected {expected!r}"
    )


# Test fixtures:1 ends here

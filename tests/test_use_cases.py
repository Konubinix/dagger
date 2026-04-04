# [[file:testing.org::*The pytest runner][The pytest runner:1]]
import os
import subprocess
from pathlib import Path

import pytest

TESTS = Path(__file__).parent
SKIP = {"helpers.sh", "dagger"}
scripts = sorted(f.name for f in TESTS.glob("*.sh") if f.name not in SKIP)


@pytest.fixture(autouse=True, scope="session")
def _dagger_engine():
    """Fail fast if the dagger engine is unreachable."""
    subprocess.run(
        ["dagger", "query", "--silent"],
        input="{ defaultPlatform }",
        capture_output=True,
        text=True,
        timeout=10,
        check=True,
        cwd=str(TESTS),
        env={**os.environ, "PATH": f"{TESTS}:{os.environ['PATH']}"},
    )


@pytest.mark.parametrize(
    "script", scripts, ids=[s.removesuffix(".sh") for s in scripts]
)
def test_use_case(script):
    subprocess.check_call(["bash", "-eu", str(TESTS / script)], cwd=str(TESTS))


# The pytest runner:1 ends here

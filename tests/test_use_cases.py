# [[file:testing.org::*The pytest runner][The pytest runner:1]]
from pathlib import Path
from subprocess import check_call

import pytest

TESTS = Path(__file__).parent
SKIP = {"helpers.sh", "dagger"}
scripts = sorted(f.name for f in TESTS.glob("*.sh") if f.name not in SKIP)


@pytest.mark.parametrize(
    "script", scripts, ids=[s.removesuffix(".sh") for s in scripts]
)
def test_use_case(script):
    check_call(["bash", "-eu", str(TESTS / script)], cwd=str(TESTS))


# The pytest runner:1 ends here

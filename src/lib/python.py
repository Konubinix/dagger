# [[file:../python.org::+begin_src python][No heading:1]]
import dagger
from dagger import function
# No heading:1 ends here


# [[file:../python.org::*Creating a Python venv][Creating a Python venv:1]]
@function
def python_venv(
    self,
    ctr: dagger.Container,
    base: str,
    packages: list[str] = (),
) -> dagger.Container:
    """Create a Python venv with --system-site-packages and optionally install packages."""
    ctr = ctr.with_exec(
        [
            "python3",
            "-m",
            "venv",
            "--system-site-packages",
            f"{base}/venv",
        ]
    ).with_env_variable("PATH", f"{base}/venv/bin:$PATH", expand=True)
    if packages:
        ctr = ctr.with_exec(
            [f"{base}/venv/bin/python", "-m", "pip", "--quiet", "install", "--upgrade"]
            + list(packages)
        )
    return ctr


# Creating a Python venv:1 ends here

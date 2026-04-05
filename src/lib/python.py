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


# [[file:../python.org::*Python with a user and virtualenv][Python with a user and virtualenv:1]]
@function
def python_user_venv(
    self,
    ctr: dagger.Container,
    groups: list[str] = (),
    packages: list[str] = (),
    work_dir: str = "/app",
) -> dagger.Container:
    """Add a user, workdir, and virtualenv to a container that already has Python."""
    ctr = self.use_user(ctr, groups=groups)
    ctr = ctr.with_workdir(work_dir)
    return self.python_venv(ctr, base=work_dir, packages=packages)


# Python with a user and virtualenv:1 ends here

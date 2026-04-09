# [[file:../dind.org::+begin_src python][No heading:1]]
import dagger
from dagger import dag, function


_CGROUP_SETUP = (
    "mount -t cgroup2 cgroup2 /sys/fs/cgroup 2>/dev/null || true\n"
    "mkdir -p /sys/fs/cgroup/init\n"
    "xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null || true\n"
    "sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers"
    " > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || true\n"
)

_DOCKERD_START = (
    "mkdir -p /var/lib/docker\n"
    "mount -t tmpfs tmpfs /var/lib/docker\n"
    "dockerd &>/var/log/dockerd.log &\n"
    "for i in $(seq 1 30); do docker info &>/dev/null && break; sleep 0.2; done\n"
)
# No heading:1 ends here


# [[file:../dind.org::*Preparing a DinD-capable container][Preparing a DinD-capable container:1]]
@function
def dind_container(
    self,
    base: dagger.Container | None = None,
    src: dagger.Directory | None = None,
) -> dagger.Container:
    """Return a container with Docker installed, ready for DinD.

    If base is provided, Docker is installed into it (must be Debian/Ubuntu-based).
    Otherwise uses the image from Lib.dind_ubuntu_image.
    src is the module source directory; defaults to the current directory.
    """
    if base is None:
        base = dag.container().from_(self.dind_ubuntu_image)
    if src is None:
        src = dag.current_module().source()

    return (
        base.with_exec(["apt-get", "update"])
        .with_exec(
            [
                "apt-get",
                "install",
                "--yes",
                "ca-certificates",
                "curl",
                "gnupg",
                "iptables",
            ]
        )
        .with_file(
            "/tmp/docker-repo-install.sh",
            src.file("src/lib/docker-repo-install.sh"),
        )
        .with_exec(["sh", "/tmp/docker-repo-install.sh"])
    )


# Preparing a DinD-capable container:1 ends here


# [[file:../dind.org::*Running commands with dockerd][Running commands with dockerd:1]]
@function
def dind_with_docker(
    self,
    cmd: str,
    ctr: dagger.Container | None = None,
) -> dagger.Container:
    """Run a shell command inside the container with dockerd available.

    Handles cgroup v2 setup, tmpfs for /var/lib/docker,
    and dockerd lifecycle. If no container is provided, uses dind_container().
    Runs with insecure_root_capabilities.
    """
    if ctr is None:
        ctr = self.dind_container()
    shell_cmd = _CGROUP_SETUP + _DOCKERD_START + cmd
    return ctr.with_exec(
        ["bash", "-c", shell_cmd],
        insecure_root_capabilities=True,
    )


# Running commands with dockerd:1 ends here

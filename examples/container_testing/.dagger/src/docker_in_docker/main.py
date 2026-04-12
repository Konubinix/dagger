# [[file:../../../readme.org::+begin_src python :tangle .dagger/src/docker_in_docker/main.py :noweb yes][No heading:3]]
from typing import Annotated

import dagger
from dagger import DefaultPath, dag, function, object_type


@object_type
class DockerInDocker:
    @function
    async def test_kind(self) -> str:
        """Run a mocked Kind workflow inside Docker-in-Docker."""
        return await (
            dag.lib()
            .dind_with_docker(
                cmd="kind() { echo 'Creating cluster...'; echo \"Cluster 'test' created.\"; };"
                " kubectl() { echo 'NAME            STATUS   ROLES           AGE';"
                " echo 'test-node       Ready    control-plane   1m'; };"
                " export -f kind kubectl;"
                " kind create cluster --wait 60s && kubectl get nodes",
            )
            .stdout()
        )


# No heading:3 ends here

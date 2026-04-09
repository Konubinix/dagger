# [[file:../../../readme.org::+begin_src python :tangle .dagger/src/production_images/main.py :noweb yes][No heading:4]]
from typing import Annotated

import dagger
from dagger import DefaultPath, dag, function, object_type


@object_type
class ProductionImages:
    @function
    async def run_distroless(
        self, src: Annotated[dagger.Directory, DefaultPath(".")]
    ) -> str:
        """Generated from test spec."""
        return await (
            dag.lib()
            .distroless_python3_debian()
            .with_file("/app/service.py", src.file("service.py"))
            .with_exec(["python3", "/app/service.py"])
            .stdout()
        )


# No heading:4 ends here

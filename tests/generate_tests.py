#!/usr/bin/env python3
"""Generate org drawer content from YAML fixtureyaml specs.

Reads YAML from stdin. Outputs the result drawer content.

Generates:
- Named Python block (noweb target for main.py)
- Named bash block (dagger call <userfunction>)
- Org tangle block for tests/expected/ (noweb reference to bash result)
- Spec file content (YAML without internal keys)

name is always injected by yamldagger.
"""

import os
import re
import sys

import yaml


def _kebab_to_snake(name):
    """Convert kebab-case to snake_case, collapsing digit boundaries."""
    return re.sub(r"-(\d)", r"\1", name).replace("-", "_")


def _has_src_files(spec):
    """Check if any with-file step references ${ROOT}."""
    for step in spec.get("chain", []):
        if isinstance(step, dict) and "with-file" in step:
            source = step["with-file"].get("source", "")
            if "${ROOT}" in source or "$ROOT" in source:
                return True
    return False


def _display_cli(spec):
    """Generate the user-facing CLI command for non-userfunction specs."""
    if "shell" in spec:
        return spec["shell"]

    prefix = "dagger call"
    parts = [prefix, spec["func"]]

    for key, val in spec.get("args", {}).items():
        if isinstance(val, list):
            for item in val:
                parts.append(f"--{key}={item}")
        elif " " in str(val) or "'" in str(val) or "$" in str(val):
            parts.append(f'--{key}="{val}"')
        else:
            parts.append(f"--{key}={val}")

    for step in spec.get("chain", []):
        if step == "stdout":
            parts.append("stdout")
        elif isinstance(step, str) and step.startswith("export"):
            parts.append('export --path="$TMP/out"')
        elif isinstance(step, dict):
            if "with-exec" in step:
                args = ",".join(f'"{a}"' for a in step["with-exec"])
                parts.append(f"with-exec --args={args}")
            elif "export" in step:
                parts.append(f'export --path="{step["export"]}"')
            elif "file" in step:
                parts.append(f'file --path="{step["file"]}"')
            elif "with-file" in step:
                wf = step["with-file"]
                source = wf["source"]
                if "$" in source or " " in source:
                    source = f'"{source}"'
                parts.append(f"with-file --path={wf['path']} --source={source}")

    cli = " ".join(parts)

    if any(isinstance(s, dict) and "export" in s for s in spec.get("chain", [])):
        cli += " > /dev/null"

    if "post" in spec:
        cli += "\n" + spec["post"]

    return cli


def _method_lines(spec):
    """Generate lines for a single @function method from a YAML spec."""
    func_name = _kebab_to_snake(spec["userfunction"])
    lib_method = _kebab_to_snake(spec["func"])

    kwargs_parts = []
    for key, val in spec.get("args", {}).items():
        py_key = key.replace("-", "_")
        kwargs_parts.append(f"{py_key}={val!r}")
    kwargs_str = ", ".join(kwargs_parts)

    has_src = _has_src_files(spec)

    chain_lines = []
    for step in spec.get("chain", []):
        if step == "stdout":
            chain_lines.append(".stdout()")
        elif isinstance(step, dict):
            if "with-exec" in step:
                chain_lines.append(f".with_exec({step['with-exec']!r})")
            elif "with-file" in step:
                wf = step["with-file"]
                source = wf["source"]
                if "${ROOT}" in source or "$ROOT" in source:
                    source = source.replace("${ROOT}/", "").replace("$ROOT/", "")
                    basename = source.split("/")[-1]
                    chain_lines.append(
                        f".with_file({wf['path']!r}, src.file({basename!r}))"
                    )
                else:
                    chain_lines.append(
                        f'.with_file({wf["path"]!r}, dag.file("source", Path({source!r}).read_text()))'
                    )
            elif "file" in step:
                chain_lines.append(f".file({step['file']!r})")
            elif "export" in step:
                chain_lines.append(".export(str(tmp_path / 'out'))")

    params = ["self"]
    if has_src:
        params.append('src: Annotated[dagger.Directory, DefaultPath(".")]')

    indent = "    "
    lines = [
        "@function",
        f"async def {func_name}({', '.join(params)}) -> str:",
        f'{indent}"""Generated from test spec."""',
        f"{indent}return await (",
        f"{indent}    dag.lib().{lib_method}({kwargs_str})",
    ]
    for line in chain_lines:
        lines.append(f"{indent}    {line}")
    lines.append(f"{indent})")
    return lines


def spec_to_method_python(spec):
    """Generate just the @function method (no imports/class)."""
    return "\n".join(_method_lines(spec))


def _write_spec(name, spec, root):
    """Write the spec file for name under root/tests/specs/."""
    specs_dir = os.path.join(root, "tests", "specs")
    os.makedirs(specs_dir, exist_ok=True)
    path = os.path.join(specs_dir, f"{name}.yml")
    with open(path, "w") as f:
        yaml.dump(spec, f, default_flow_style=None, sort_keys=False)


def _drawer(spec, root=None):
    """Generate the org result drawer for a fixtureyaml block."""
    name = spec.pop("name")
    if root:
        _write_spec(name, spec, root)
    parts = []

    if "userfunction" in spec:
        python_code = spec_to_method_python(spec)
        uf = spec["userfunction"]

        # Named Python block (noweb target for main.py)
        parts.append(f"#+NAME: {uf}")
        parts.append("#+begin_src python")
        parts.append(python_code)
        parts.append("#+end_src")
        parts.append("")

        # Named bash block (executable)
        run_name = f"{name}-run"
        parts.append(f"#+NAME: {run_name}")
        parts.append("#+begin_src bash")
        parts.append(f"dagger call {uf}")
        parts.append("#+end_src")

        # Org tangle block for tests/expected/ (noweb evals bash result)
        parts.append("")
        parts.append(
            f'#+BEGIN_SRC org :tangle (expand-file-name "tests/expected/{name}" (locate-dominating-file default-directory ".git"))'
            f" :noweb yes :exports none :comments no :padline no"
        )
        parts.append(f"<<{run_name}()>>")
        parts.append("#+END_SRC")
    else:
        cli = _display_cli(spec)
        run_name = f"{name}-run"
        parts.append(f"#+NAME: {run_name}")
        parts.append("#+begin_src bash :exports code :eval no-export")
        parts.append(cli)
        parts.append("#+end_src")

        parts.append("")
        parts.append(
            f'#+BEGIN_SRC org :tangle (expand-file-name "tests/expected/{name}" (locate-dominating-file default-directory ".git"))'
            f" :noweb yes :exports none :comments no :padline no"
        )
        parts.append(f"<<{run_name}()>>")
        parts.append("#+END_SRC")

    return "\n".join(parts)


if __name__ == "__main__":
    root = sys.argv[1] if len(sys.argv) > 1 else None
    spec = yaml.safe_load(sys.stdin)
    print(_drawer(spec, root=root))

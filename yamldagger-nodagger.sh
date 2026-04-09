#!/usr/bin/env python3
"""Generate result drawers and spec files from fixtureyaml blocks in org files.

For each fixtureyaml block:
1. Calls generate_tests.py to produce the drawer (Python block + bash block)
2. Inserts/replaces the result drawer in the org file
3. Writes the spec file to tests/specs/
"""
import re
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent
SPECS_DIR = ROOT / "tests" / "specs"
GENERATOR = ROOT / "tests" / "generate_tests.py"


def generate_drawer(yaml_body, name, org_path):
    """Call generate_tests.py with the YAML body, return the drawer string."""
    extra = f"\nname: {name}\n"
    result = subprocess.run(
        [sys.executable, str(GENERATOR)],
        input=yaml_body.rstrip() + extra,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"generate_tests.py failed: {result.stderr}", file=sys.stderr)
        return None
    return result.stdout.rstrip("\n")


def process_org_file(org_path):
    """Find fixtureyaml blocks, insert drawers, write specs."""
    text = org_path.read_text()
    lines = text.split("\n")
    output = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Detect #+NAME: followed by fixtureyaml block
        name_match = re.match(r"\s*#\+NAME:\s+(\S+)", line)
        if name_match:
            name = name_match.group(1)
            # Check if next non-empty line is a fixtureyaml block
            j = i + 1
            while j < len(lines) and lines[j].strip() == "":
                j += 1
            if j < len(lines) and "begin_src fixtureyaml" in lines[j]:
                output.append(line)  # #+NAME line
                i = j
                # Collect the fixtureyaml block
                output.append(lines[i])  # begin_src line
                i += 1
                yaml_lines = []
                while i < len(lines) and "end_src" not in lines[i]:
                    yaml_lines.append(lines[i])
                    i += 1
                for yl in yaml_lines:
                    output.append(yl)
                output.append(lines[i])  # end_src line
                i += 1

                yaml_body = "\n".join(yaml_lines)

                # Write spec file
                SPECS_DIR.mkdir(parents=True, exist_ok=True)
                (SPECS_DIR / f"{name}.yml").write_text(yaml_body.strip() + "\n")

                # Generate drawer
                drawer = generate_drawer(yaml_body, name, org_path)
                if drawer:
                    output.append("")
                    output.append(f"#+RESULTS: {name}")
                    output.append(":results:")
                    for dl in drawer.split("\n"):
                        output.append(dl)
                    output.append(":end:")

                # Skip old result drawer if present
                while i < len(lines) and lines[i].strip() == "":
                    i += 1
                if i < len(lines) and re.match(r"\s*#\+RESULTS", lines[i]):
                    # Skip until :end:
                    while i < len(lines) and not lines[i].strip().startswith(":end:"):
                        i += 1
                    if i < len(lines):
                        i += 1  # skip :end:

                continue

        output.append(line)
        i += 1

    org_path.write_text("\n".join(output))
    print(f"Processed {org_path}")


def main():
    if len(sys.argv) > 1:
        files = [Path(f).resolve() for f in sys.argv[1:]]
    else:
        files = sorted(ROOT.glob("examples/*/readme.org"))

    for org_path in files:
        process_org_file(org_path)


if __name__ == "__main__":
    main()

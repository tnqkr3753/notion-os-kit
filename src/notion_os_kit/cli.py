from __future__ import annotations

import os
import subprocess
import sys
from importlib import resources
from pathlib import Path


def main() -> int:
    package_root = resources.files("notion_os_kit")
    script = package_root / "kit" / "scripts" / "notion-os-kit"
    if not script.is_file():
        current = Path(__file__).resolve()
        for parent in current.parents:
            candidate = parent / "kit" / "scripts" / "notion-os-kit"
            if candidate.is_file():
                script = candidate
                break
    env = os.environ.copy()
    completed = subprocess.run(["bash", str(script), *sys.argv[1:]], env=env, check=False)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())

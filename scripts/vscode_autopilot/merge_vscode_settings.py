#!/usr/bin/env python3

import json
import sys
from pathlib import Path


def merge_dicts(base, patch):
    for key, value in patch.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            merge_dicts(base[key], value)
        else:
            base[key] = value
    return base


def load_json(path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def main():
    if len(sys.argv) < 3:
        print("Usage: merge_vscode_settings.py <target-settings.json> <patch1.json> [patch2.json ...]", file=sys.stderr)
        return 1

    target_path = Path(sys.argv[1]).expanduser()
    patch_paths = [Path(item).expanduser() for item in sys.argv[2:]]

    target_path.parent.mkdir(parents=True, exist_ok=True)

    if target_path.exists():
        merged = load_json(target_path)
    else:
        merged = {}

    for patch_path in patch_paths:
        if not patch_path.exists():
            raise FileNotFoundError(f"Patch not found: {patch_path}")
        merged = merge_dicts(merged, load_json(patch_path))

    with open(target_path, "w", encoding="utf-8") as handle:
        json.dump(merged, handle, indent=2, ensure_ascii=True)
        handle.write("\n")

    print(target_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

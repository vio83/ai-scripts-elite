#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def parse_args() -> argparse.Namespace:
    home = Path.home()
    parser = argparse.ArgumentParser(
        description="Salva snapshot di workspace VS Code in file .code-workspace nominati.",
    )
    parser.add_argument("--name", help="Nome esatto da usare per il salvataggio principale.")
    parser.add_argument(
        "--workspace",
        help="Percorso di una cartella workspace da salvare immediatamente anche se non presente tra i Workspaces di VS Code.",
    )
    parser.add_argument(
        "--source-root",
        default=str(home / "Library/Application Support/Code/Workspaces"),
        help="Directory sorgente dei workspace temporanei di VS Code.",
    )
    parser.add_argument(
        "--output-dir",
        default=str(home / "Library/Application Support/VIO/vscode-session-workspaces/named"),
        help="Directory dei workspace nominati aggiornati in-place.",
    )
    parser.add_argument(
        "--archive-dir",
        default=str(home / "Library/Application Support/VIO/vscode-session-workspaces/archive"),
        help="Directory archivio snapshot timestampati.",
    )
    parser.add_argument(
        "--index-path",
        default=str(home / "Library/Application Support/VIO/vscode-session-workspaces/index.json"),
        help="Percorso indice JSON dei salvataggi.",
    )
    parser.add_argument(
        "--only-latest",
        action="store_true",
        help="Salva solo il workspace sorgente piu' recente.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=10,
        help="Numero massimo di workspace sorgente da considerare quando non e' attivo --only-latest.",
    )
    return parser.parse_args()


def slugify(name: str) -> str:
    cleaned = re.sub(r"[\\/:*?\"<>|]", "-", name)
    cleaned = re.sub(r"\s+", " ", cleaned).strip().strip(".")
    return cleaned or "workspace"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def list_workspace_files(source_root: Path) -> list[Path]:
    candidates = sorted(
        source_root.glob("*/workspace.json"),
        key=lambda item: item.stat().st_mtime,
        reverse=True,
    )
    return candidates


def get_window_titles() -> list[str]:
    scripts = [
        'tell application "System Events" to tell process "Code" to get name of every window',
        'tell application "System Events" to tell process "Visual Studio Code" to get name of every window',
    ]
    for script in scripts:
        try:
            output = subprocess.check_output(["osascript", "-e", script], text=True, stderr=subprocess.DEVNULL)
        except Exception:
            continue
        titles = [segment.strip() for segment in output.split(",") if segment.strip()]
        if titles:
            return titles
    return []


def build_workspace_from_folder(folder_path: Path) -> dict:
    return {
        "folders": [{"name": folder_path.name, "path": str(folder_path)}],
        "settings": {},
    }


def derive_display_name(workspace_data: dict, source_path: Path, explicit_name: str | None, title_hint: str | None) -> str:
    if explicit_name:
        return explicit_name
    if title_hint:
        return title_hint
    folders = workspace_data.get("folders") or []
    if folders:
        first_folder = folders[0]
        if first_folder.get("name"):
            return str(first_folder["name"])
        if first_folder.get("path"):
            return Path(first_folder["path"]).name
    return source_path.parent.name


def write_workspace_files(
    workspace_data: dict,
    display_name: str,
    output_dir: Path,
    archive_dir: Path,
    source_path: str,
) -> dict:
    output_dir.mkdir(parents=True, exist_ok=True)
    archive_dir.mkdir(parents=True, exist_ok=True)

    safe_name = slugify(display_name)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    named_path = output_dir / f"{safe_name}.code-workspace"
    archive_path = archive_dir / f"{safe_name}__{timestamp}.code-workspace"

    payload = dict(workspace_data)
    payload.setdefault("settings", {})
    payload["settings"]["vio.sessionWorkspace.displayName"] = display_name
    payload["settings"]["vio.sessionWorkspace.savedAtUtc"] = timestamp
    payload["settings"]["vio.sessionWorkspace.source"] = source_path

    content = json.dumps(payload, ensure_ascii=True, indent=2) + "\n"
    named_path.write_text(content, encoding="utf-8")
    archive_path.write_text(content, encoding="utf-8")

    return {
        "display_name": display_name,
        "safe_name": safe_name,
        "named_path": str(named_path),
        "archive_path": str(archive_path),
        "saved_at_utc": timestamp,
        "source": source_path,
        "folders": [folder.get("path") for folder in workspace_data.get("folders", []) if folder.get("path")],
    }


def main() -> int:
    args = parse_args()
    source_root = Path(args.source_root).expanduser()
    output_dir = Path(args.output_dir).expanduser()
    archive_dir = Path(args.archive_dir).expanduser()
    index_path = Path(args.index_path).expanduser()

    source_files = list_workspace_files(source_root)
    if args.only_latest:
        source_files = source_files[:1]
    else:
        source_files = source_files[: max(args.limit, 1)]

    titles = get_window_titles()
    snapshots: list[dict] = []

    if args.workspace:
        folder_path = Path(args.workspace).expanduser().resolve()
        if not folder_path.exists() or not folder_path.is_dir():
            raise SystemExit(f"Workspace richiesto non trovato: {folder_path}")
        workspace_data = build_workspace_from_folder(folder_path)
        display_name = args.name or folder_path.name
        snapshots.append(
            write_workspace_files(
                workspace_data,
                display_name,
                output_dir,
                archive_dir,
                str(folder_path),
            )
        )

    for index, source_file in enumerate(source_files):
        try:
            workspace_data = load_json(source_file)
        except Exception:
            continue
        title_hint = titles[index] if index < len(titles) else None
        display_name = derive_display_name(workspace_data, source_file, None, title_hint)
        snapshots.append(
            write_workspace_files(
                workspace_data,
                display_name,
                output_dir,
                archive_dir,
                str(source_file),
            )
        )

    index_path.parent.mkdir(parents=True, exist_ok=True)
    index_payload = {
        "updated_at_utc": datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"),
        "snapshots": snapshots,
    }
    index_path.write_text(json.dumps(index_payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    for snapshot in snapshots:
        print(f"SALVATO {snapshot['display_name']} -> {snapshot['named_path']}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

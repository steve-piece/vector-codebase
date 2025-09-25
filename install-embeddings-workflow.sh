#!/usr/bin/env bash
set -euo pipefail

# Installer: Merge deps into root node_modules and scaffold embeddings_workflow files

DEFAULT_PKGS=("@supabase/supabase-js" "openai" "glob" "find-up" "dotenv")
DEST_DIR="embeddings_workflow"
FORCE_OVERWRITE=false
PACKAGE_MANAGER=""

print_usage() {
  echo "Usage: $0 [--force] [--pm npm|yarn|pnpm]"
  echo "  --force      Overwrite existing files in ${DEST_DIR}"
  echo "  --pm         Package manager to use (defaults to auto-detect; npm prioritized)"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_OVERWRITE=true
      shift
      ;;
    --pm)
      PACKAGE_MANAGER=${2:-}
      if [[ -z "$PACKAGE_MANAGER" ]]; then
        echo "Error: --pm requires a value (npm|yarn|pnpm)" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      print_usage
      exit 1
      ;;
  esac
done

# Determine script directory (source files live here)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(pwd)"

# Ensure we're running at project root (where package.json lives). If not present, initialize one.
if [[ ! -f "${ROOT_DIR}/package.json" ]]; then
  echo "No package.json found in ${ROOT_DIR}. Initializing a new one with npm..."
  npm init -y >/dev/null 2>&1 || { echo "Failed to initialize package.json" >&2; exit 1; }
fi

# Choose package manager: honor --pm, else prefer npm, then pnpm, then yarn
choose_pm() {
  if [[ -n "$PACKAGE_MANAGER" ]]; then
    echo "$PACKAGE_MANAGER"
    return
  fi
  if command -v npm >/dev/null 2>&1; then echo npm; return; fi
  if command -v pnpm >/dev/null 2>&1; then echo pnpm; return; fi
  if command -v yarn >/dev/null 2>&1; then echo yarn; return; fi
  echo "npm"
}

PM=$(choose_pm)

echo "Using package manager: ${PM}"

install_deps() {
  local pm="$1"; shift
  local pkgs=("$@")
  case "$pm" in
    npm)
      npm install -D "${pkgs[@]}"
      ;;
    pnpm)
      pnpm add -D "${pkgs[@]}"
      ;;
    yarn)
      yarn add -D "${pkgs[@]}"
      ;;
    *)
      echo "Unsupported package manager: $pm" >&2
      exit 1
      ;;
  esac
}

echo "Installing devDependencies into root node_modules..."
install_deps "$PM" "${DEFAULT_PKGS[@]}"

# Create destination directory
DEST_PATH="${ROOT_DIR}/${DEST_DIR}"
mkdir -p "$DEST_PATH"

copy_file() {
  local src="$1"
  local dst="$2"
  if [[ -e "$dst" && "$FORCE_OVERWRITE" != true ]]; then
    echo "Skip (exists): $(basename "$dst") — use --force to overwrite"
  else
    cp -f "$src" "$dst"
    echo "Wrote: $(basename "$dst")"
  fi
}

echo "Scaffolding ${DEST_DIR} files..."
copy_file "${SCRIPT_DIR}/ingest-embeddings.mjs" "${DEST_PATH}/ingest-embeddings.mjs"
copy_file "${SCRIPT_DIR}/sync-embeddings.yml" "${DEST_PATH}/sync-embeddings.yml"
copy_file "${SCRIPT_DIR}/update_schema.sql" "${DEST_PATH}/update_schema.sql"
copy_file "${SCRIPT_DIR}/env.txt" "${DEST_PATH}/env.txt"
copy_file "${SCRIPT_DIR}/README.md" "${DEST_PATH}/README.md"
copy_file "${SCRIPT_DIR}/LICENSE" "${DEST_PATH}/LICENSE"

cat <<"EONEXT"

Done.

Next steps:
  1) Rename embeddings_workflow/env.txt to .env at your project root and fill values
     mv embeddings_workflow/env.txt .env
  2) Enable pgvector and create table using embeddings_workflow/update_schema.sql (or README)
  3) Run the ingestion script from project root:
     node embeddings_workflow/ingest-embeddings.mjs

Tips:
  - Re-run with --force to overwrite files if you update this template
  - Use --pm npm|yarn|pnpm to force a package manager

EONEXT



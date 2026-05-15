#!/usr/bin/env bash
set -euo pipefail

program_name="${0##*/}"

usage() {
  cat <<EOF
Usage:
  $program_name            Open the launcher UI.
  $program_name list       List discovered entries as TAB-separated display name and manifest path.
  $program_name run PATH   Run a specific .lawnrc manifest.

Config:
  \$XDG_CONFIG_HOME/lawn.sh/config
  or ~/.config/lawn.sh/config

Each non-empty, non-comment line in the config file must be an absolute path to a search root.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

show_config_help() {
  local config

  config="$(config_path)"
  cat >&2 <<EOF
No search roots configured yet.

Edit:
  $config

Add one absolute directory per line, for example:
  /mnt/games
  /home/alice/stuff

Then add a .lawnrc inside any launchable directory, for example:
  exec ./launch.sh
EOF
}

config_path() {
  if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    printf '%s\n' "$XDG_CONFIG_HOME/lawn.sh/config"
    return
  fi

  printf '%s/.config/lawn.sh/config\n' "$HOME"
}

read_roots() {
  local config line

  config="$(config_path)"
  if [[ ! -f "$config" ]]; then
    mkdir -p "$(dirname -- "$config")"
    : > "$config"
  fi

  ROOTS=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"

    if [[ "$line" =~ ^[[:space:]]*($|#) ]]; then
      continue
    fi

    [[ "$line" = /* ]] || die "config entry must be an absolute path: $line"
    ROOTS+=("$line")
  done < "$config"

  if ((${#ROOTS[@]} == 0)); then
    show_config_help
    exit 1
  fi
}

discover_manifests() {
  local root manifest
  local -a found=()

  for root in "${ROOTS[@]}"; do
    if [[ ! -d "$root" ]]; then
      printf 'warning: skipping missing root %s\n' "$root" >&2
      continue
    fi

    while IFS= read -r -d '' manifest; do
      found+=("$manifest")
    done < <(fd --hidden --absolute-path --glob '.lawnrc' "$root" -0)
  done

  if ((${#found[@]} == 0)); then
    MANIFESTS=()
    return
  fi

  mapfile -t MANIFESTS < <(printf '%s\n' "${found[@]}" | sort -u)
}

build_entries() {
  local manifest dir name display
  declare -A counts=()
  local -a unsorted=()

  ENTRIES=()
  for manifest in "${MANIFESTS[@]}"; do
    dir="$(dirname -- "$manifest")"
    name="$(basename -- "$dir")"
    ((counts["$name"] += 1))
  done

  for manifest in "${MANIFESTS[@]}"; do
    dir="$(dirname -- "$manifest")"
    name="$(basename -- "$dir")"
    display="$name"

    if ((counts["$name"] > 1)); then
      display="$name  [$dir]"
    fi

    unsorted+=("$display"$'\t'"$manifest")
  done

  mapfile -t ENTRIES < <(printf '%s\n' "${unsorted[@]}" | sort)
}

load_entries() {
  read_roots
  discover_manifests
  ((${#MANIFESTS[@]} > 0)) || die "no .lawnrc files found beneath configured roots"
  build_entries
}

list_entries() {
  local entry

  for entry in "${ENTRIES[@]}"; do
    printf '%s\n' "$entry"
  done
}

run_manifest() {
  local manifest dir base

  manifest="$1"
  [[ -f "$manifest" ]] || die "manifest not found: $manifest"

  dir="$(dirname -- "$manifest")"
  base="$(basename -- "$manifest")"

  (
    cd "$dir"
    exec bash "./$base"
  )
}

choose_and_run() {
  local selection manifest editor

  editor="${VISUAL:-${EDITOR:-xdg-open}}"

  selection="$(
    printf '%s\n' "${ENTRIES[@]}" | \
      fzf \
        --style=full \
        --delimiter=$'\t' \
        --with-nth=1 \
        --padding='1,2' \
        --prompt='lawn.sh> ' \
        --layout=reverse \
        --input-label=' Search ' \
        --list-label=' Targets ' \
        --header='enter: run • ctrl-e: edit .lawnrc • ctrl-r: refresh preview' \
        --bind='focus:transform-preview-label:printf " %s " {1}' \
        --bind='ctrl-r:refresh-preview' \
        --bind="ctrl-e:execute($editor {2})+refresh-preview" \
        --preview='sed -n "1,200p" {2}' \
        --preview-window='down,45%,wrap,border'
  )" || exit 130

  manifest="${selection#*$'\t'}"
  run_manifest "$manifest"
}

main() {
  case "${1:-}" in
    "")
      load_entries
      choose_and_run
      ;;
    -h|--help|help)
      usage
      ;;
    list)
      [[ $# -eq 1 ]] || die "list does not take any arguments"
      load_entries
      list_entries
      ;;
    run)
      [[ $# -eq 2 ]] || die "run requires a manifest path"
      run_manifest "$2"
      ;;
    *)
      die "unknown command: $1"
      ;;
  esac
}

main "$@"

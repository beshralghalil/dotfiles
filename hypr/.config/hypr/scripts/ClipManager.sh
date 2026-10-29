#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Clipboard Manager. This script uses cliphist, sumi-menu, and wl-copy.

# Variables
msg='👀 **note**  CTRL DEL = cliphist del (entry)   or   ALT DEL - cliphist wipe (all)'
# Actions:
# CTRL Del to delete an entry
# ALT Del to wipe clipboard contents

# Image entries get a thumbnail (cached by cliphist id, made with ImageMagick
# when available, the decoded image otherwise)
thumbs="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-thumbs"
mkdir -p "$thumbs"
img_re=$'^([0-9]+)\t\\[\\[ binary data (.+) (png|jpe?g|webp|bmp|gif) ([0-9]+x[0-9]+) \\]\\]$'

make_thumb() {   # $1 cliphist line  $2 output file
    if command -v magick >/dev/null 2>&1; then
        cliphist decode <<<"$1" | magick - -thumbnail '192x128>' "$2" 2>/dev/null
    else
        cliphist decode <<<"$1" >"$2"
    fi
}

# cliphist rows, image rows with an icon and a readable label; stale thumbnails
# (entries deleted or rotated out of the history) are removed
rows() {
    local line id f lines keep=()
    mapfile -t lines < <(cliphist list)
    for line in "${lines[@]}"; do
        [[ $line =~ $img_re ]] || continue
        id=${BASH_REMATCH[1]}
        keep+=("$id.png")
        [[ -s $thumbs/$id.png ]] || { make_thumb "$line" "$thumbs/$id.png" & }
    done
    wait
    for f in "$thumbs"/*.png; do
        [[ -e $f && " ${keep[*]} " != *" ${f##*/} "* ]] && rm -f -- "$f"
    done
    for line in "${lines[@]}"; do
        if [[ $line =~ $img_re && -s $thumbs/${BASH_REMATCH[1]}.png ]]; then
            printf '%s\0display\x1f%s\timage  ·  %s %s  ·  %s\x1ficon\x1f%s\n' "$line" \
                "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" \
                "${BASH_REMATCH[2]}" "$thumbs/${BASH_REMATCH[1]}.png"
        else
            printf '%s\n' "$line"
        fi
    done
}

# Close an open sumi-menu first
if pgrep -x sumi-menu >/dev/null; then
  pkill -x sumi-menu
fi

while true; do
    result=$(
        sumi-menu -i -dmenu \
            -kb-custom-1 "Control-Delete" \
            -kb-custom-2 "Alt-Delete" \
            -placeholder "Search Clipboard" \
            -mesg "$msg" < <(rows)
    )

    case "$?" in
        1)
            exit
            ;;
        0)
            case "$result" in
                "")
                    continue
                    ;;
                *)
                    cliphist decode <<<"$result" | wl-copy
                    exit
                    ;;
            esac
            ;;
        10)
            cliphist delete <<<"$result"
            ;;
        11)
            cliphist wipe
            ;;
    esac
done

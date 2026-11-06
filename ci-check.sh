#!/usr/bin/env bash
# Renders every variant of the shroud and fails on any OpenSCAD warning/error,
# a non-manifold result, or an empty/missing STL. Used by CI; run it locally too.
set -euo pipefail

SCAD=bmv080_shroud.scad
OUT=${OUT:-build}
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p "$OUT"

render() {  # name, extra openscad args...
  local name=$1; shift
  echo "== $name"
  "$OPENSCAD" -o "$OUT/$name.stl" "$@" "$SCAD" 2>&1 | tee "$OUT/$name.log"
  if grep -E -i 'warning|error' "$OUT/$name.log"; then
    echo "::error::$name: OpenSCAD reported warnings/errors"; exit 1
  fi
  if grep -q 'Simple: *no' "$OUT/$name.log"; then
    echo "::error::$name: geometry is not a simple (manifold) solid"; exit 1
  fi
  [ -s "$OUT/$name.stl" ] || { echo "::error::$name: empty STL"; exit 1; }
  grep -q '^ *facet normal' "$OUT/$name.stl" || { echo "::error::$name: STL has no facets"; exit 1; }
}

render screw
render peg   -D 'mount="peg"'
render ghost -D 'show_ghost=true'          # reference view still builds
render flip  -D 'lens_side=1'              # alternate lens side still builds
echo "All variants OK"

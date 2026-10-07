#!/usr/bin/env bash
# Evaluates every node of the flake, one nix process per node.
#
# `nix flake check` does the same in a single process and keeps all evaluated nodes in
# memory at once, which outgrows the runner VM. Evaluating them one by one keeps the peak
# at the size of the largest node.
set -uo pipefail
cd "$(dirname "$0")"

nodes=$(nix eval --raw .#nixosConfigurations --apply 'c: builtins.concatStringsSep " " (builtins.attrNames c)') || exit 1

failed=()
for node in $nodes; do
  echo "::group::$node"
  nix eval --raw ".#nixosConfigurations.$node.config.system.build.toplevel.drvPath" || failed+=("$node")
  echo
  echo "::endgroup::"
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "::error::Evaluation failed for: ${failed[*]}"
  exit 1
fi
echo "All nodes evaluate."

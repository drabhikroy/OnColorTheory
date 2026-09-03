#!/bin/bash
# Runs every standards check. Any failure stops the script.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Writing standards"
python3 "$here/writing_gate.py"
echo
echo "Palette audit"
python3 "$here/palette_audit.py"
echo
echo "Layout scale"
python3 "$here/metrics_gate.py"
echo
echo "Documentation coverage"
python3 "$here/doc_coverage.py"

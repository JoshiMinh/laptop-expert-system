#!/bin/bash
# Run Prolog Advisor
# This script starts SWI-Prolog and loads the advisor.pl file
# You will be in interactive mode and can run queries like:
#   ?- tu_van_top_k_giai_thich(gaming, 35000000, [mong_nhe], 3, TopK, CanhBao).

cd "$(dirname "$0")"

# Check if swipl is installed
if ! command -v swipl &> /dev/null; then
    echo ""
    echo "ERROR: SWI-Prolog is not installed or not in PATH"
    echo ""
    echo "Installation instructions:"
    echo "  macOS:  brew install swi-prolog"
    echo "  Ubuntu: sudo apt-get install swi-prolog"
    echo "  Fedora: sudo dnf install swi-prolog"
    echo "  Other:  https://www.swi-prolog.org/Download.html"
    echo ""
    echo "After installation, ensure 'swipl' is in your PATH"
    echo ""
    exit 1
fi

swipl -l advisor.pl

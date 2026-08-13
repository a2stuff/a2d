#!/usr/bin/env python3

# Like the `pybidi` utility included with python-bidi, but with
# explicit flushing so it can be used from a pipe on a line-by-line
# basis.

# Hardcoded to use 'R' base direction, because this is only used for
# non-LTR languages.

from bidi.algorithm import get_display
import sys

for line in sys.stdin:
  line = line.rstrip('\n')
  line = get_display(line, base_dir='R')
  sys.stdout.write(line + '\n')
  sys.stdout.flush()

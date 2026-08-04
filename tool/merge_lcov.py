#!/usr/bin/env python3
"""Union-merge lcov tracefiles that cover overlapping files.

The app report and packages/core's own report both carry core lines, so plain
concatenation would double-count them in the LF/LH summary. lcov's own `-a` is
version-sensitive about overlapping records; both of our tracefiles use only
SF/DA, which makes an explicit union trivial and stable.

Usage: merge_lcov.py OUT IN [IN ...]
"""

import collections
import posixpath
import sys


def read(path, hits):
    current = None
    with open(path, encoding='utf-8') as handle:
        for raw in handle:
            line = raw.strip()
            if line.startswith('SF:'):
                # Normalize separators so a Windows-produced report merges with
                # a Linux-produced one.
                current = posixpath.normpath(line[3:].replace('\\', '/'))
                if (posixpath.isabs(current) or ':' in current[:3]
                        or current.startswith('..')):
                    # A path outside the repo root would silently split one
                    # file into two records — fail loudly instead.
                    raise SystemExit(f'{path}: non-repo-relative SF: {current}')
                hits.setdefault(current, collections.Counter())
            elif line.startswith('DA:') and current is not None:
                number, _, count = line[3:].partition(',')
                hits[current][int(number)] += int(count.split(',')[0])
            elif line == 'end_of_record':
                current = None


def write(path, hits):
    with open(path, 'w', encoding='utf-8', newline='\n') as handle:
        for source in sorted(hits):
            counts = hits[source]
            handle.write(f'SF:{source}\n')
            for number in sorted(counts):
                handle.write(f'DA:{number},{counts[number]}\n')
            handle.write(f'LF:{len(counts)}\n')
            handle.write(f'LH:{sum(1 for c in counts.values() if c > 0)}\n')
            handle.write('end_of_record\n')


def main(argv):
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2
    hits = {}
    for path in argv[2:]:
        read(path, hits)
    write(argv[1], hits)
    total = sum(len(c) for c in hits.values())
    covered = sum(sum(1 for v in c.values() if v > 0) for c in hits.values())
    percent = 100 * covered / total if total else 0
    print(f'merged {len(argv) - 2} tracefiles: '
          f'{covered}/{total} lines ({percent:.1f}%) across {len(hits)} files')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

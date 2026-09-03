"""
Documentation coverage check.

Every top-level type in Sources carries a doc comment. This runs as a gate so
the next type added arrives with one rather than being caught in a later sweep.

A doc comment is a `///` line immediately above the declaration. Attribute lines
between the two are allowed, since `@MainActor` and similar sit there.

Exit status is non-zero when any type is undocumented.
"""

import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
SOURCES = os.path.join(ROOT, "Sources")

DECLARATION = re.compile(
    r"^(?:private |public |internal |fileprivate )?"
    r"(?:struct|enum|final class|class|actor|protocol) (\w+)"
)
ATTRIBUTE = re.compile(r"^@\w+")


def undocumented(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    found = []
    for index, line in enumerate(lines):
        match = DECLARATION.match(line)
        if not match:
            continue
        # Walk back over any attribute lines to reach the comment.
        cursor = index - 1
        while cursor >= 0 and ATTRIBUTE.match(lines[cursor].strip()):
            cursor -= 1
        if cursor < 0 or not lines[cursor].strip().startswith("///"):
            found.append((index + 1, match.group(1)))
    return found


def main():
    total = 0
    missing = []
    for root, _, names in os.walk(SOURCES):
        for name in names:
            if not name.endswith(".swift"):
                continue
            path = os.path.join(root, name)
            relative = os.path.relpath(path, ROOT)
            lines = open(path, encoding="utf-8").read().split("\n")
            total += sum(1 for line in lines if DECLARATION.match(line))
            for number, type_name in undocumented(path):
                missing.append((relative, number, type_name))

    for relative, number, type_name in missing:
        print("%s:%d  %s has no doc comment" % (relative, number, type_name))

    print()
    covered = total - len(missing)
    print("%d of %d types documented" % (covered, total))
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())

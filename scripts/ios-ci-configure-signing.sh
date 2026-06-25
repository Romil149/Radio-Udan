#!/usr/bin/env bash
# Apply manual code signing to Runner iOS target for GitHub Actions builds.
set -euo pipefail

TEAM_ID="${1:?Team ID required}"
PROFILE_NAME="${2:?Provisioning profile name required}"
PBX="${3:-ios/Runner.xcodeproj/project.pbxproj}"

python3 - "$TEAM_ID" "$PROFILE_NAME" "$PBX" <<'PY'
import pathlib
import sys

team, profile, pbx_path = sys.argv[1:4]
lines = pathlib.Path(pbx_path).read_text().splitlines()
bundle_line = "\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = org.reactjs.native.example.Radio;"
signing = {
    "\t\t\t\tDEVELOPMENT_TEAM": f"\t\t\t\tDEVELOPMENT_TEAM = {team};",
    "\t\t\t\tCODE_SIGN_STYLE": "\t\t\t\tCODE_SIGN_STYLE = Manual;",
    "\t\t\t\tPROVISIONING_PROFILE_SPECIFIER": f'\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "{profile}";',
    '\t\t\t\t"CODE_SIGN_IDENTITY[sdk=iphoneos*]"': '\t\t\t\t"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";',
}
out = []
i = 0
while i < len(lines):
    line = lines[i]
    out.append(line)
    if line == bundle_line:
        existing = set()
        j = i + 1
        while j < len(lines) and not lines[j].strip().startswith("PRODUCT_NAME"):
            for prefix in signing:
                if lines[j].startswith(prefix):
                    existing.add(prefix)
            j += 1
        for key in signing:
            if key not in existing:
                out.append(signing[key])
    i += 1
pathlib.Path(pbx_path).write_text("\n".join(out) + "\n")
print(f"Patched manual signing in {pbx_path}")
PY

#!/usr/bin/env python3
"""Design guardrail for Orion Finance.

Counts patterns that erode the design system and fails if any count rises above the recorded
baseline (scripts/design_lint_baseline.json). Counts may only go down.

    python3 scripts/design_lint.py             # check
    python3 scripts/design_lint.py --update    # record current counts as the new baseline
"""
import json, os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Equion for iOS")
BASELINE = os.path.join(ROOT, "scripts", "design_lint_baseline.json")
THEME = "Services/AppTheme.swift"   # tokens are defined here, so it's exempt

SCALE = {0, 1, 2, 4, 8, 12, 16, 20, 24, 32, 48, 64}
RULES = {
    # Fixed point sizes bypass Dynamic Type (large decorative glyphs ≥40pt are allowed).
    "fixed-font-size": (r"\.system\(size: ([0-9.]+)", lambda m: float(m.group(1)) < 40),
    # Perpetual animations compete for attention and ignore Reduce Motion.
    "repeat-forever": (r"repeatForever", None),
    # Resting content is flat; depth belongs to the navigation layer.
    "shadow": (r"\.shadow\(", None),
    # Fading text with opacity drops it below contrast minimums — use secondary/tertiary tokens.
    "faded-text": (r"foregroundColor\(AppTheme\.(secondaryText|primaryText)\.opacity\(", None),
    # Colours must come from the theme.
    "raw-color": (r"Color\(red:|UIColor\(red:|Color\.(orange|blue|purple|pink|yellow|teal|indigo|mint|cyan)\b", None),
    # Off-scale padding values.
    "off-scale-padding": (r"\.padding\((?:\.[a-zA-Z]+, )?(-?[0-9.]+)\)", lambda m: abs(float(m.group(1))) not in SCALE and abs(float(m.group(1))) < 64),
    # Manual haptics belong on state changes via .sensoryFeedback.
    "manual-haptic": (r"\bHaptic\.[a-z]+\(\)", None),
}

def count():
    files = [f for f in glob.glob(os.path.join(SRC, "**", "*.swift"), recursive=True)
             if not f.endswith(THEME) and not f.endswith("Localization.swift")]
    totals, where = {k: 0 for k in RULES}, {k: [] for k in RULES}
    for f in files:
        for i, line in enumerate(open(f, encoding="utf-8"), 1):
            if line.strip().startswith("//"): continue
            for name, (pat, pred) in RULES.items():
                for m in re.finditer(pat, line):
                    if pred is None or pred(m):
                        totals[name] += 1
                        where[name].append(f"{os.path.relpath(f, SRC)}:{i}")
    return totals, where

def main():
    totals, where = count()
    if "--update" in sys.argv:
        json.dump(totals, open(BASELINE, "w"), indent=2, sort_keys=True)
        print("Baseline updated:", totals); return 0
    base = json.load(open(BASELINE)) if os.path.exists(BASELINE) else {}
    failed = False
    for name, n in totals.items():
        b = base.get(name, 0)
        mark = "OK " if n <= b else "FAIL"
        print(f"{mark} {name:18} {n:4}  (baseline {b})")
        if n > b:
            failed = True
            for w in where[name][:10]: print("       ", w)
    if not failed and any(totals[k] < base.get(k, 0) for k in totals):
        print("Counts went down — run with --update to lock in the improvement.")
    return 1 if failed else 0

if __name__ == "__main__":
    sys.exit(main())

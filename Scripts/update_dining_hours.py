#!/usr/bin/env python3
"""Fetch UC Merced's official dining-hours page and update the bundled schedule."""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
import urllib.request
from pathlib import Path

SOURCE_URL = "https://dining.ucmerced.edu/dining-locations-hours/pavilion/dining-center-hours"
OUTPUT_PATH = Path(__file__).resolve().parents[1] / "Sources/ucm_dining_app/Resources/dining-hours.json"

MEAL_ICONS = {
    "Breakfast": "sunrise.fill",
    "Lunch": "sun.max.fill",
    "Dinner": "moon.stars.fill",
    "Late Night": "sparkles",
}


def visible_text(document: str) -> str:
    document = re.sub(r"<script.*?</script>|<style.*?</style>", " ", document, flags=re.I | re.S)
    document = re.sub(r"<[^>]+>", " ", document)
    return re.sub(r"\s+", " ", html.unescape(document)).strip()


def minutes(value: str) -> int:
    match = re.fullmatch(r"(\d{1,2})(?::(\d{2}))?\s*([ap])\.?m\.?", value.strip(), re.I)
    if not match:
        raise ValueError(f"Unsupported time: {value}")
    hour = int(match.group(1)) % 12
    minute = int(match.group(2) or 0)
    if match.group(3).lower() == "p":
        hour += 12
    total = hour * 60 + minute
    return 1_440 if total == 0 and value.lower().startswith("12") else total


def meal_window(block: str, meal: str) -> dict[str, object]:
    label_pattern = "Late\\s*night" if meal == "Late Night" else meal
    match = re.search(
        rf"{label_pattern}\s*:\s*(\d{{1,2}}(?::\d{{2}})?\s*[ap]\.??m\.?)\s*[-–]\s*(\d{{1,2}}(?::\d{{2}})?\s*[ap]\.??m\.?)",
        block,
        re.I,
    )
    if not match:
        raise ValueError(f"Could not find {meal} hours")
    return {
        "meal": meal,
        "startMinutes": minutes(match.group(1)),
        "endMinutes": minutes(match.group(2)),
        "icon": MEAL_ICONS[meal],
    }


def fetched_schedule() -> dict[str, object]:
    request = urllib.request.Request(SOURCE_URL, headers={"User-Agent": "UCMDiningHoursUpdater/1.0"})
    with urllib.request.urlopen(request, timeout=20) as response:
        text = visible_text(response.read().decode("utf-8"))

    pavilion_start = text.index("The Pavilion Monday - Friday")
    ywdc_start = text.index("Yablokoff-Wallace Dining Center", pavilion_start)
    pavilion = text[pavilion_start:ywdc_start]
    ywdc = text[ywdc_start:]

    weekday_start = pavilion.index("Monday - Friday")
    weekend_start = pavilion.index("Saturday & Sunday")
    pavilion_weekday = pavilion[weekday_start:weekend_start]
    pavilion_weekend = pavilion[weekend_start:]

    return {
        "sourceURL": SOURCE_URL,
        "pavilion": {
            "weekday": [meal_window(pavilion_weekday, meal) for meal in ("Breakfast", "Lunch", "Dinner")],
            "weekend": [meal_window(pavilion_weekend, meal) for meal in ("Breakfast", "Lunch", "Dinner")],
        },
        "ywdc": {
            "weekday": [meal_window(ywdc, meal) for meal in ("Lunch", "Dinner", "Late Night")],
            "weekend": [],
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Exit nonzero instead of writing when hours changed")
    args = parser.parse_args()

    updated = fetched_schedule()
    current = json.loads(OUTPUT_PATH.read_text()) if OUTPUT_PATH.exists() else None
    if current == updated:
        print("Dining hours are current.")
        return 0
    if args.check:
        print("Dining hours changed; run Scripts/update_dining_hours.py", file=sys.stderr)
        return 1

    OUTPUT_PATH.write_text(json.dumps(updated, indent=2) + "\n")
    print(f"Updated {OUTPUT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

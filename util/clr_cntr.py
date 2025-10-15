#!/usr/bin/env python3

"""
A command-line tool to find, categorize, and sort all unique hex color codes
from a given file and print them as CSS custom properties.
"""

import argparse
import colorsys
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

# A type hint for HSL values for clarity
HSLColor = Tuple[float, float, float]


def normalize_hex(hex_color: str) -> str:
    """
    Cleans and expands a hex color string.
    e.g., '#fff' -> 'ffffff', '#aabbccdd' -> 'aabbcc'
    """
    hex_color = hex_color.lstrip("#")
    if len(hex_color) == 3:
        return "".join(c * 2 for c in hex_color)
    # Ignore alpha channel for color calculations
    if len(hex_color) == 8:
        return hex_color[:6]
    return hex_color


def hex_to_hsl(hex_color: str) -> HSLColor:
    """Convert a hex color string to an HSL tuple."""
    normalized_hex = normalize_hex(hex_color)
    if len(normalized_hex) != 6:
        # Return a default value for invalid hex codes
        return 0.0, 0.0, 0.0

    try:
        r, g, b = (
            int(normalized_hex[0:2], 16) / 255.0,
            int(normalized_hex[2:4], 16) / 255.0,
            int(normalized_hex[4:6], 16) / 255.0,
        )
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        return h * 360, s * 100, l * 100
    except ValueError:
        # Handles cases with non-hex characters
        return 0.0, 0.0, 0.0


def hex_to_luminance(hex_color: str) -> float:
    """
    Calculate the perceived luminance of a hex color.
    Formula: 0.2126*R + 0.7152*G + 0.0722*B
    """
    normalized_hex = normalize_hex(hex_color)
    if len(normalized_hex) != 6:
        return 0.0

    try:
        r, g, b = (
            int(normalized_hex[0:2], 16),
            int(normalized_hex[2:4], 16),
            int(normalized_hex[4:6], 16),
        )
        return 0.2126 * (r / 255) + 0.7152 * (g / 255) + 0.0722 * (b / 255)
    except ValueError:
        return 0.0


def categorize_by_hue(h: float) -> str:
    """Determine the color category based on hue value."""
    if 0 <= h < 30 or 330 <= h <= 360:
        return "Reds"
    if 30 <= h < 90:
        return "Yellows"
    if 90 <= h < 150:
        return "Greens"
    if 150 <= h < 210:
        return "Cyans"
    if 210 <= h < 270:
        return "Blues"
    return "Magentas"


def is_shade(s: float, l: float) -> bool:
    """
    Determine if a color is a shade (grayscale) based on saturation and lightness.
    """
    # Mathematical boundaries for what is considered a 'color' vs a 'shade'
    l_min = lambda s: 0.15625 * s**2 - 6.375 * s + 94
    l_max = lambda s: 0.09375 * s**2 - 0.875 * s + 52

    if s > 21 or l < 15 or s < 12:
        return True
    # Relax boundaries slightly to catch near-colors
    if l_min(s) - 5 < l < l_max(s) + 5:
        return False
    return True


def process_colors(hex_colors: Set[str]) -> Tuple[List[str], Dict[str, List[str]]]:
    """Sort, categorize, and process a set of hex colors."""
    # Create a list of tuples with color and its calculated HSL for efficiency
    color_data = [
        (color, hex_to_hsl(color))
        for color in sorted(list(hex_colors), key=hex_to_luminance)
    ]

    shades: List[str] = []
    color_groups: Dict[str, List[str]] = {
        "Reds": [],
        "Yellows": [],
        "Greens": [],
        "Cyans": [],
        "Blues": [],
        "Magentas": [],
    }

    # Initial categorization
    for color, (h, s, l) in color_data:
        if is_shade(s, l):
            shades.append(color)
        else:
            category = categorize_by_hue(h)
            color_groups[category].append(color)

    # Re-evaluate shades to fill empty color categories if necessary
    shades_to_reassign = []
    for name, group in color_groups.items():
        if not group:
            # Find shades that could potentially fit in this empty color group
            for shade in shades:
                shade_h, shade_s, shade_l = hex_to_hsl(shade)
                if categorize_by_hue(shade_h) == name and shade_s > 9:
                    # Looser criteria to re-classify a shade as a color
                    if not is_shade(shade_s + 8, shade_l):
                        color_groups[name].append(shade)
                        shades_to_reassign.append(shade)
                        break  # Move to next empty group

    # Remove reassigned shades from the original shades list
    shades = [s for s in shades if s not in shades_to_reassign]

    return shades, color_groups


def print_results(shades: List[str], color_groups: Dict[str, List[str]]):
    """Format and print the categorized colors as CSS custom properties."""
    total_colors = len(shades) + sum(len(group) for group in color_groups.values())
    print(f"/* Total unique colors: {total_colors} */\n")

    print("Shades: {")
    for i, color in enumerate(shades, 1):
        print(f"    --shade-{i}: {color};")
    print("}\n")

    print("Colors {")
    for name, colors in color_groups.items():
        if not colors:
            continue
        print(f"  {name} {{")
        for i, color in enumerate(colors, 1):
            print(f"    --{name.lower()[:-1]}-{i}: {color};")  # e.g., --red-1
        print("  }\n")
    print("}")


def main():
    """Main function to run the script."""
    parser = argparse.ArgumentParser(
        description="Extract, sort, and categorize hex colors from a file."
    )
    parser.add_argument(
        "filepath",
        type=Path,
        help="Path to the file to scan for colors (e.g., a CSS, HTML, or text file).",
    )
    args = parser.parse_args()
    filepath: Path = args.filepath

    # --- Input Validation ---
    if not filepath.exists():
        print(f"Error: File not found at '{filepath}'", file=sys.stderr)
        sys.exit(1)
    if not filepath.is_file():
        print(f"Error: Path '{filepath}' is a directory, not a file.", file=sys.stderr)
        sys.exit(1)

    # --- File Processing ---
    try:
        content = filepath.read_text(encoding="utf-8")
    except PermissionError:
        print(f"Error: Permission denied to read file '{filepath}'", file=sys.stderr)
        sys.exit(1)
    except UnicodeDecodeError:
        print(
            f"Error: Could not decode file '{filepath}'. Is it a binary file?",
            file=sys.stderr,
        )
        sys.exit(1)

    hex_pattern = r"#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b"
    found_colors = {f"#{normalize_hex(c)}" for c in re.findall(hex_pattern, content)}

    if not found_colors:
        print("No hex color codes found in the file.")
        return

    shades, color_groups = process_colors(found_colors)
    print_results(shades, color_groups)


if __name__ == "__main__":
    main()

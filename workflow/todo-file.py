import argparse
import subprocess
import datetime
from datetime import timedelta
from pathlib import Path

# --- Constants ---
HOME = Path.home()
NOTE_PATH = HOME / "documents" / "notes" / "list.md"


# --- Argument Parsing ---
def get_args():
    """Parses command line actions, handling a default action and sub-arguments."""
    parser = argparse.ArgumentParser(
        description="A script to manage a markdown note file.",
        epilog="Default action is 'Launch' if no command is specified.",
    )

    subparsers = parser.add_subparsers(dest="action", help="Available actions")

    parser_add = subparsers.add_parser(
        "Add", help="Add a new message to the notes file."
    )
    # This is a REQUIRED POSITIONAL argument for 'Add'
    parser_add.add_argument(
        "message", type=str, help="The content of the message to add."
    )
    # This is an OPTIONAL flag for 'Add'
    parser_add.add_argument(
        "--pin",
        action="store_true",  # A simple flag that doesn't take a value
        help="Pin this message to the top (example flag).",
    )

    parser_display = subparsers.add_parser(
        "Display", help="Display the contents of the notes file."
    )
    # This is an OPTIONAL flag for 'Display'
    parser_display.add_argument(
        "-l", "--lines", type=int, help="Display only the last N lines of the file."
    )

    # Launch doesn't need its own arguments, but it needs to exist
    # so 'Launch' is a valid, recognized command.
    parser_launch = subparsers.add_parser(
        "Launch", help="Launch the note file in the editor (default action)."
    )

    args = parser.parse_args()

    # If no command was given, set the default.
    if args.action is None:
        args.action = "Launch"

    return args


# --- Core Logic Functions ---
def get_date_info():
    """Generates formatted date strings for the current day, week, and year."""
    now = datetime.datetime.now()
    year = now.strftime("%Y")
    week_num = now.isocalendar()[1]

    start_of_week = now - timedelta(days=now.weekday())
    end_of_week = start_of_week + timedelta(days=6)

    st_d = start_of_week.strftime("%d")
    month = start_of_week.strftime("%b")
    day_now = now.strftime("%a")

    if end_of_week.month != start_of_week.month:
        en_d = end_of_week.strftime("%d %b")
    else:
        en_d = end_of_week.strftime("%d")

    year_header = f"# {year}"
    week_header = f"## Week {week_num} ({month} {st_d}-{en_d})"
    day_header = f"### {day_now}"

    return year_header, week_header, day_header


def update_notes(path: Path, message: str = "", pinned: Bool = False):
    """
    Ensures headers are in the notes file and optionally adds a new message.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    year_header, week_header, day_header = get_date_info()
    status_messages = []

    if not path.is_file():
        print(f"File not found. Creating '{path}'...")
        with path.open("w", encoding="utf-8") as note_file:
            note_file.write(f"{year_header}\n")
            note_file.write(f"{week_header}\n")
            note_file.write(f"{day_header}\n")
        status_messages.append("File and headers created.")

    with path.open("r", encoding="utf-8") as note_file:
        lines = {line.strip() for line in note_file}

    to_append = []
    if year_header not in lines:
        to_append.append(year_header)
    if week_header not in lines:
        to_append.append(week_header)
    if day_header not in lines:
        to_append.append(day_header)

    if to_append:
        with path.open("a", encoding="utf-8") as note_file:
            note_file.write("\n")
            for item in to_append:
                note_file.write(f"{item}\n")
        status_messages.append("Headers updated.")

    if message:
        with path.open("a", encoding="utf-8") as note_file:
            note_file.write(f"- {message}\n")
        status_messages.append(f"Message '{message}' added.")

    if not status_messages:
        return "Notes are already up-to-date. No changes made."
    else:
        return " ".join(status_messages)


def display_notes(path: Path, last_lines: int = None):
    """Prints the content of the notes file to the console."""
    if not path.is_file():
        return f"Note file not found at '{path}'. Nothing to display."

    with path.open("r", encoding="utf-8") as f:
        lines = f.readlines()

    if not lines:
        return "Note file is empty."

    print("--- Displaying Notes ---")

    if last_lines and last_lines > 0:
        display_content = lines[-last_lines:]
        print(f"(Showing last {len(display_content)} of {len(lines)} lines)")
    else:
        display_content = lines

    print("".join(display_content).strip())
    print("------------------------")
    return "Display complete."


# --- Main Execution ---
def main():
    """Main function to orchestrate the script's actions."""
    args = get_args()

    if args.action == "Add":
        print("Action: Add")
        # The 'message' argument required
        # Check for the optional '--pin' flag.
        print(f"Message to add: '{args.message}'")
        if args.pin:
            print("Pin flag is set!")
        status = update_notes(NOTE_PATH, message=args.message, pinned=args.pin)
        print(f"Status: {status}")

    elif args.action == "Display":
        print("Action: Display")
        # Check for the optional '--lines' flag.
        if args.lines:
            print(f"Displaying last {args.lines} lines.")
        else:
            print("Displaying entire file.")
        status = display_notes(NOTE_PATH, last_lines=args.lines)
        print(f"Status: {status}")

    elif args.action == "Launch":
        print("Action: Launch (Default)")
        print("Opening notes in editor...")
        subprocess.run(["kitty", "-e", "nvim", NOTE_PATH])


if __name__ == "__main__":
    main()

import os
import shutil

# --- Configuration ---
# The directory where the archived files will be moved.
ARCHIVE_DIR = "docs_archive"

# List of historical and one-time setup files to be archived.
# These are generally not updated but are kept for project history and setup.
files_to_archive = [
    # Root Setup & Docs
    "insert_sample_data.sql",
    "DATABASE_REVIEW.md",
    "TIMETABLE_FIXES.md",
    "FIXES_AND_UPDATES.md",
    "ALGORITHM_IMPROVEMENTS_SUMMARY.md",

    # Backend Setup & Utility Scripts
    os.path.join("backend", "create_database.sql"),
    os.path.join("backend", "database_updates.sql"),
    os.path.join("backend", "setup_db.py"),
    os.path.join("backend", "insert_sample_data.py"),
    os.path.join("backend", "insert_large_data.py"),
    os.path.join("backend", "run_db_script.py"),
    os.path.join("backend", "verify_hashes.py"),
    os.path.join("backend", "hash_passwords.py"),
    os.path.join("backend", "fix_features.py"),
    os.path.join("backend", "verify_features.py"),
    os.path.join("backend", "update_database.py"),
    
    # Superseded Code
    os.path.join("backend", "generator.py")
]

script_dir = os.path.dirname(os.path.abspath(__file__))
archive_path = os.path.join(script_dir, ARCHIVE_DIR)

print(f"--- Archiving Project Files to '{archive_path}' ---")

# Create the archive directory if it doesn't exist
if not os.path.exists(archive_path):
    os.makedirs(archive_path)
    print(f"[CREATED] Directory: {archive_path}")

for relative_path in files_to_archive:
    source_path = os.path.join(script_dir, relative_path)
    # Flatten: store in archive root using just the filename
    filename = os.path.basename(relative_path)
    destination_path = os.path.join(archive_path, filename)

    if os.path.exists(source_path):
        try:
            shutil.move(source_path, destination_path)
            print(f"[MOVED] {relative_path} -> {ARCHIVE_DIR}/{filename}")
        except Exception as e:
            print(f"[ERROR] Could not move {relative_path}: {e}")
    else:
        print(f"[NOT FOUND] {relative_path}")

print("\nArchiving complete.")
"""
Database Update Script.

Updates the database schema with new features programmatically.
"""

import os
import sys

import mysql.connector

from db_config import get_db_connection

def execute_sql_file(file_path):
    """
    Execute SQL commands from a file
    """
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found!")
        return False
    
    try:
        # Read SQL file
        with open(file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Remove USE database statements (we're already connected)
        sql_content = sql_content.replace('USE timetable_db;', '')
        sql_content = sql_content.replace('USE timetable_db', '')
        
        # Split by semicolon to get individual statements
        # Handle multi-line statements properly
        statements = []
        current_statement = ""
        in_string = False
        string_char = None
        
        for char in sql_content:
            current_statement += char
            
            # Track string literals
            if char in ("'", '"') and (not current_statement or current_statement[-2] != '\\'):
                if not in_string:
                    in_string = True
                    string_char = char
                elif char == string_char:
                    in_string = False
                    string_char = None
            
            # If we hit a semicolon and we're not in a string, it's the end of a statement
            if char == ';' and not in_string:
                stmt = current_statement.strip()
                if stmt and not stmt.startswith('--'):
                    statements.append(stmt)
                current_statement = ""
        
        # Add any remaining statement
        if current_statement.strip() and not current_statement.strip().startswith('--'):
            statements.append(current_statement.strip())
        
        # Connect to database
        conn = get_db_connection()
        cursor = conn.cursor()
        
        print(f"Executing {len(statements)} SQL statements from {file_path}...")
        print("-" * 60)
        
        success_count = 0
        error_count = 0
        
        for i, statement in enumerate(statements, 1):
            if not statement or statement.strip() == '':
                continue
            
            try:
                # Execute statement
                cursor.execute(statement)
                conn.commit()
                success_count += 1
                
                # Print progress for important statements
                if any(keyword in statement.upper() for keyword in ['CREATE TABLE', 'ALTER TABLE', 'CREATE INDEX']):
                    # Extract table/index name for display
                    if 'CREATE TABLE' in statement.upper():
                        table_name = statement.split('CREATE TABLE')[1].split('(')[0].strip()
                        print(f"✓ [{i}/{len(statements)}] Created table: {table_name}")
                    elif 'ALTER TABLE' in statement.upper():
                        table_name = statement.split('ALTER TABLE')[1].split()[0].strip()
                        print(f"✓ [{i}/{len(statements)}] Altered table: {table_name}")
                    elif 'CREATE INDEX' in statement.upper():
                        index_name = statement.split('CREATE INDEX')[1].split()[0].strip()
                        print(f"✓ [{i}/{len(statements)}] Created index: {index_name}")
                
            except mysql.connector.Error as e:
                error_count += 1
                # Some errors are expected (like table already exists)
                if e.errno == 1050:  # Table already exists
                    print(f"⚠ [{i}/{len(statements)}] Table already exists (skipping)")
                elif e.errno == 1061:  # Duplicate key name
                    print(f"⚠ [{i}/{len(statements)}] Index already exists (skipping)")
                elif e.errno == 1062:  # Duplicate entry
                    print(f"⚠ [{i}/{len(statements)}] Duplicate entry (skipping)")
                elif e.errno == 1091:  # Can't DROP key
                    print(f"⚠ [{i}/{len(statements)}] Key doesn't exist (skipping)")
                else:
                    print(f"✗ [{i}/{len(statements)}] Error: {e.msg}")
                    print(f"   Statement: {statement[:100]}...")
        
        cursor.close()
        conn.close()
        
        print("-" * 60)
        print(f"✓ Successfully executed: {success_count} statements")
        if error_count > 0:
            print(f"⚠ Warnings/Errors: {error_count} statements")
        print("Database update completed!")
        
        return True
        
    except FileNotFoundError:
        print(f"Error: SQL file '{file_path}' not found!")
        return False
    except mysql.connector.Error as e:
        print(f"Database Error: {e}")
        return False
    except Exception as e:
        print(f"Unexpected Error: {e}")
        return False

def update_database():
    """
    Main function to update database
    """
    print("=" * 60)
    print("Timetable Generator - Database Update Script")
    print("=" * 60)
    print()
    
    # Check if database_updates.sql exists
    sql_file = "database_updates.sql"
    
    if not os.path.exists(sql_file):
        print(f"Error: '{sql_file}' file not found!")
        print("Please make sure database_updates.sql is in the current directory.")
        return False
    
    # Test database connection first
    print("Testing database connection...")
    try:
        conn = get_db_connection()
        conn.close()
        print("✓ Database connection successful!")
        print()
    except Exception as e:
        print(f"✗ Database connection failed: {e}")
        print("\nPlease check your database configuration in db_config.py")
        return False
    
    # Execute SQL file
    print(f"Reading SQL file: {sql_file}")
    print()
    
    success = execute_sql_file(sql_file)
    
    if success:
        print()
        print("=" * 60)
        print("Database update completed successfully!")
        print("=" * 60)
        return True
    else:
        print()
        print("=" * 60)
        print("Database update failed. Please check the errors above.")
        print("=" * 60)
        return False

def check_database_status():
    """
    Check which tables exist in the database
    """
    print("=" * 60)
    print("Database Status Check")
    print("=" * 60)
    print()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get list of tables
        cursor.execute("SHOW TABLES")
        tables = [table[0] for table in cursor.fetchall()]
        
        print(f"Total tables in database: {len(tables)}")
        print("-" * 60)
        print("\nAll tables:")
        for table in sorted(tables):
            # Get row count for each table
            try:
                cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
                count = cursor.fetchone()[0]
                print(f"  ✓ {table:<35} ({count:>6} rows)")
            except:
                print(f"  ✓ {table:<35} (error reading count)")
        
        # Check for new feature tables
        new_tables = {
            'teacher_preferences': 'Teacher Preferences',
            'timetable_versions': 'Timetable Versions',
            'timetable_version_slots': 'Version Slots',
            'conflicts': 'Conflicts',
            'timetable_comments': 'Comments',
            'change_requests': 'Change Requests',
            'academic_years': 'Academic Years',
            'semesters': 'Semesters',
            'timetable_templates': 'Templates',
            'notifications': 'Notifications',
            'timetable_quality_metrics': 'Quality Metrics',
            'room_preferences': 'Room Preferences',
            'scheduling_constraints': 'Scheduling Constraints',
            'export_history': 'Export History',
            'statistics_cache': 'Statistics Cache'
        }
        
        print("\n" + "=" * 60)
        print("New Feature Tables Status:")
        print("=" * 60)
        
        existing_count = 0
        missing_count = 0
        
        for table, description in new_tables.items():
            if table in tables:
                try:
                    cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
                    count = cursor.fetchone()[0]
                    print(f"  ✓ {description:<30} ({table:<25}) - {count:>4} rows")
                    existing_count += 1
                except:
                    print(f"  ✓ {description:<30} ({table:<25}) - exists (error reading count)")
                    existing_count += 1
            else:
                print(f"  ✗ {description:<30} ({table:<25}) - MISSING")
                missing_count += 1
        
        print("\n" + "-" * 60)
        print(f"Summary: {existing_count} tables exist, {missing_count} tables missing")
        
        if missing_count > 0:
            print("\n⚠ Some new feature tables are missing.")
            print("   Run 'python update_database.py' to create them.")
        else:
            print("\n✓ All new feature tables are present!")
        
        # Check for additional columns in existing tables
        print("\n" + "=" * 60)
        print("Enhanced Columns Check:")
        print("=" * 60)
        
        enhanced_tables = {
            'timetable_slots': ['notes', 'color', 'created_at', 'updated_at', 'created_by', 'updated_by'],
            'rooms': ['building', 'floor', 'location_description'],
            'users': ['email', 'notification_preferences']
        }
        
        for table_name, expected_columns in enhanced_tables.items():
            if table_name in tables:
                cursor.execute(f"SHOW COLUMNS FROM `{table_name}`")
                existing_columns = [col[0] for col in cursor.fetchall()]
                
                missing_cols = [col for col in expected_columns if col not in existing_columns]
                if missing_cols:
                    print(f"  ⚠ {table_name}: Missing columns - {', '.join(missing_cols)}")
                else:
                    print(f"  ✓ {table_name}: All enhanced columns present")
        
        cursor.close()
        conn.close()
        
        print("\n" + "=" * 60)
        
    except mysql.connector.Error as e:
        print(f"✗ Database Error: {e}")
        print("\nPlease check your database configuration in db_config.py")
    except Exception as e:
        print(f"✗ Error checking database: {e}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Update database schema')
    parser.add_argument('--check', action='store_true', help='Check database status only')
    parser.add_argument('--file', type=str, help='Custom SQL file to execute')
    
    args = parser.parse_args()
    
    if args.check:
        check_database_status()
    elif args.file:
        execute_sql_file(args.file)
    else:
        # Run normal update
        success = update_database()
        
        if success:
            # Optionally check status after update
            check_database_status()
        
        sys.exit(0 if success else 1)


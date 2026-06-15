"""
Feature Verification Script
Verifies that all new features are properly integrated and working
"""

import mysql.connector
from db_config import get_db_connection
import sys

def check_table_exists(table_name):
    """Check if a table exists in the database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(f"SHOW TABLES LIKE '{table_name}'")
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        return result is not None
    except:
        return False

def check_column_exists(table_name, column_name):
    """Check if a column exists in a table"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(f"SHOW COLUMNS FROM `{table_name}` LIKE '{column_name}'")
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        return result is not None
    except:
        return False

def verify_all_features():
    """Verify all new features are properly set up"""
    print("=" * 70)
    print("Timetable Generator - Feature Verification")
    print("=" * 70)
    print()
    
    issues = []
    warnings = []
    
    # Check new feature tables
    print("Checking new feature tables...")
    print("-" * 70)
    
    new_tables = {
        'teacher_preferences': 'Teacher Preferences',
        'timetable_versions': 'Timetable Versions',
        'timetable_version_slots': 'Version Slots',
        'conflicts': 'Conflict Detection',
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
    
    for table, description in new_tables.items():
        exists = check_table_exists(table)
        if exists:
            print(f"  ✓ {description:<30} - Table exists")
        else:
            print(f"  ✗ {description:<30} - Table MISSING")
            issues.append(f"Missing table: {table}")
    
    print()
    
    # Check enhanced columns
    print("Checking enhanced columns in existing tables...")
    print("-" * 70)
    
    enhanced_columns = {
        'timetable_slots': ['notes', 'color', 'created_at', 'updated_at', 'created_by', 'updated_by'],
        'rooms': ['building', 'floor', 'location_description'],
        'users': ['email', 'notification_preferences']
    }
    
    for table, columns in enhanced_columns.items():
        if not check_table_exists(table):
            warnings.append(f"Base table {table} doesn't exist")
            continue
            
        for column in columns:
            exists = check_column_exists(table, column)
            if exists:
                print(f"  ✓ {table}.{column:<25} - Column exists")
            else:
                print(f"  ✗ {table}.{column:<25} - Column MISSING")
                issues.append(f"Missing column: {table}.{column}")
    
    print()
    
    # Check Python modules
    print("Checking Python modules...")
    print("-" * 70)
    
    modules = {
        'conflict_detector': 'Conflict Detection Module',
        'export_manager': 'Export Manager Module',
        'quality_metrics': 'Quality Metrics Module',
        'bulk_operations': 'Bulk Operations Module'
    }
    
    for module_name, description in modules.items():
        try:
            __import__(module_name)
            print(f"  ✓ {description:<30} - Module found")
        except ImportError:
            print(f"  ✗ {description:<30} - Module MISSING")
            issues.append(f"Missing module: {module_name}.py")
    
    print()
    
    # Check required directories
    print("Checking required directories...")
    print("-" * 70)
    
    directories = ['../exports', '../uploads', '../frontend/js', '../frontend/css']
    
    import os
    for directory in directories:
        if os.path.exists(directory):
            print(f"  ✓ {directory:<30} - Directory exists")
        else:
            print(f"  ✗ {directory:<30} - Directory MISSING")
            issues.append(f"Missing directory: {directory}")
            # Try to create it
            try:
                os.makedirs(directory, exist_ok=True)
                print(f"    → Created {directory}")
            except:
                pass
    
    print()
    
    # Check API endpoints in app.py
    print("Checking API endpoints...")
    print("-" * 70)
    
    try:
        with open('../app.py', 'r', encoding='utf-8') as f:
            app_content = f.read()
        
        endpoints = {
            '/api/conflicts': 'Conflict Detection',
            '/api/export/': 'Export Functionality',
            '/api/quality-metrics': 'Quality Metrics',
            '/api/teacher-preferences': 'Teacher Preferences',
            '/api/timetable-versions': 'Timetable Versions',
            '/api/statistics/': 'Statistics',
            '/api/notifications': 'Notifications',
            '/api/change-requests': 'Change Requests',
            '/api/bulk/': 'Bulk Operations'
        }
        
        for endpoint, description in endpoints.items():
            if endpoint in app_content:
                print(f"  ✓ {description:<30} - Endpoint found")
            else:
                print(f"  ✗ {description:<30} - Endpoint MISSING")
                issues.append(f"Missing endpoint: {endpoint}")
    except FileNotFoundError:
        print("  ✗ app.py not found")
        issues.append("Missing file: app.py")
    except Exception as e:
        print(f"  ⚠ Error checking endpoints: {e}")
        warnings.append(f"Could not verify endpoints: {e}")
    
    print()
    
    # Summary
    print("=" * 70)
    print("Verification Summary")
    print("=" * 70)
    
    if not issues and not warnings:
        print("✓ All features are properly integrated!")
        print("\nYou can now use all the new features:")
        print("  - Conflict detection")
        print("  - Export functionality (PDF, Excel, CSV, iCal)")
        print("  - Quality metrics")
        print("  - Teacher preferences")
        print("  - Statistics dashboard")
        print("  - Notifications")
        print("  - Bulk operations")
        print("  - And more!")
        return True
    else:
        if issues:
            print(f"\n✗ Found {len(issues)} critical issue(s):")
            for issue in issues:
                print(f"  - {issue}")
        
        if warnings:
            print(f"\n⚠ Found {len(warnings)} warning(s):")
            for warning in warnings:
                print(f"  - {warning}")
        
        print("\nTo fix issues:")
        print("  1. Run: python update_database.py")
        print("  2. Check that all Python files are in the project directory")
        print("  3. Verify app.py contains all new endpoints")
        
        return False

def test_feature_modules():
    """Test that feature modules can be imported and basic functions work"""
    print("\n" + "=" * 70)
    print("Testing Feature Modules")
    print("=" * 70)
    print()
    
    tests = []
    
    # Test conflict detector
    try:
        from conflict_detector import ConflictDetector
        detector = ConflictDetector()
        tests.append(("Conflict Detector", True, "Module loads successfully"))
    except Exception as e:
        tests.append(("Conflict Detector", False, str(e)))
    
    # Test export manager
    try:
        from export_manager import ExportManager
        manager = ExportManager(export_dir='../exports')
        tests.append(("Export Manager", True, "Module loads successfully"))
    except Exception as e:
        tests.append(("Export Manager", False, str(e)))
    
    # Test quality metrics
    try:
        from quality_metrics import QualityMetricsCalculator
        calculator = QualityMetricsCalculator()
        tests.append(("Quality Metrics", True, "Module loads successfully"))
    except Exception as e:
        tests.append(("Quality Metrics", False, str(e)))
    
    # Test bulk operations
    try:
        from bulk_operations import BulkOperations
        bulk = BulkOperations()
        tests.append(("Bulk Operations", True, "Module loads successfully"))
    except Exception as e:
        tests.append(("Bulk Operations", False, str(e)))
    
    # Display results
    all_passed = True
    for name, passed, message in tests:
        if passed:
            print(f"  ✓ {name:<25} - {message}")
        else:
            print(f"  ✗ {name:<25} - Error: {message}")
            all_passed = False
    
    return all_passed

if __name__ == "__main__":
    print()
    
    # Run verification
    features_ok = verify_all_features()
    
    # Test modules
    modules_ok = test_feature_modules()
    
    print("\n" + "=" * 70)
    if features_ok and modules_ok:
        print("✓ All systems ready! Your timetable generator is fully updated.")
        sys.exit(0)
    else:
        print("⚠ Some issues found. Please review and fix them.")
        sys.exit(1)





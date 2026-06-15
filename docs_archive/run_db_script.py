import os
import mysql.connector
from db_config import get_db_connection

def run_sql_script():
    # Path to the SQL file relative to this script
    sql_file_path = os.path.join(os.path.dirname(__file__), 'bca_test_data.sql')
    
    if not os.path.exists(sql_file_path):
        print(f"Error: SQL file not found at {sql_file_path}")
        return

    print(f"Reading and executing SQL script: {sql_file_path}")
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        with open(sql_file_path, 'r', encoding='utf-8') as f:
            sql_script = f.read()
            
        # Execute the script with multi=True to handle multiple statements
        for result in cursor.execute(sql_script, multi=True):
            if result.with_rows:
                result.fetchall()  # Consume results if any
                
        conn.commit()
        print("Database updated successfully!")
        
    except mysql.connector.Error as err:
        print(f"Database Error: {err}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

if __name__ == "__main__":
    run_sql_script()
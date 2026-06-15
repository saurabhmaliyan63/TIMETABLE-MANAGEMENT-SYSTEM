import mysql.connector


def setup_database():
    """Setup database schema and data."""
    # Connect without database first
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="root"
    )
    cursor = conn.cursor()

    # Drop and recreate database
    cursor.execute("DROP DATABASE IF EXISTS timetable_db")
    cursor.execute("CREATE DATABASE timetable_db")
    cursor.execute("USE timetable_db")

    # Read and execute schema and data
    with open('timetable_db_fixed.sql', 'r') as f:
        sql = f.read()

    # Split by semicolon and execute each statement
    statements = [stmt.strip() for stmt in sql.split(';') if stmt.strip()]
    for statement in statements:
        if statement:
            cursor.execute(statement)
            # Consume any unread results
            try:
                cursor.fetchall()
            except Exception:
                pass

    conn.commit()
    cursor.close()
    conn.close()
    print("Database schema and data created successfully with hashed passwords")


if __name__ == "__main__":
    setup_database()

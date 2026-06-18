import mysql.connector


def get_db_connection():
    """Get database connection."""
    return mysql.connector.connect(
        host="localhost",
        user="Username",
        password="db_password",
        database="timetable_db"
    )


def create_database():
    """Create database if it doesn't exist."""
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="root"
    )
    cursor = connection.cursor()
    cursor.execute("CREATE DATABASE IF NOT EXISTS timetable_db")
    cursor.close()
    connection.close()
    print("Database 'timetable_db' created successfully.")

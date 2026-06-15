import mysql.connector
import bcrypt

# The original passwords from the task
ORIGINAL_PASSWORDS = {
    'admin': 'admin_pass123',
    'coordinator': 'coord_pass123',
    'prof_einstein': 'teacher_pass1',
    'prof_curie': 'teacher_pass2',
    'prof_turing': 'teacher_pass3',
    'prof_sharma': 'teacher_pass4',
    'prof_khan': 'teacher_pass5',
    'student_alice': 'student_pass1',
    'student_bob': 'student_pass2',
    'student_charlie': 'student_pass3',
    'student_dave': 'student_pass4',
    'student_eve': 'student_pass5',
    'student_frank': 'student_pass6',
    'student_grace': 'student_pass7',
    'student_heidi': 'student_pass8'
}


def verify_hashes():
    """Verify hashed passwords in database."""
    # Connect to database
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="root",
        database="timetable_db"
    )
    cursor = conn.cursor()

    # Get all users
    cursor.execute('SELECT username, password FROM users')
    results = cursor.fetchall()

    print('Verifying hashed passwords:')
    for username, hashed_password in results:
        original = ORIGINAL_PASSWORDS.get(username)
        if original and bcrypt.checkpw(
            original.encode('utf-8'),
            hashed_password.encode('utf-8')
        ):
            print(f'✓ {username}: Password hash verified')
        else:
            print(f'✗ {username}: Password hash verification failed')

    cursor.close()
    conn.close()


if __name__ == "__main__":
    verify_hashes()

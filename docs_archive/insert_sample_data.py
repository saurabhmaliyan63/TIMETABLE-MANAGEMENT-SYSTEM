import bcrypt
import mysql.connector

from db_config import get_db_connection


def insert_sample_data():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Hash passwords and insert Users
        users_data = [
            ('admin', 'admin_pass123', 'admin'),
            ('coordinator', 'coord_pass123', 'coordinator'),
            ('prof_einstein', 'teacher_pass1', 'teacher'),
            ('prof_curie', 'teacher_pass2', 'teacher'),
            ('prof_turing', 'teacher_pass3', 'teacher'),
            ('student_alice', 'student_pass1', 'student'),
            ('student_bob', 'student_pass2', 'student'),
            ('student_charlie', 'student_pass3', 'student'),
            ('student_dave', 'student_pass4', 'student')
        ]

        for username, password, role in users_data:
            hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            cursor.execute("""
                INSERT INTO users (username, `password`, role) VALUES (%s, %s, %s)
            """, (username, hashed_password, role))

        # Insert Programs
        cursor.execute("""
            INSERT INTO programs (name) VALUES
            ('Bachelor of Computer Applications'),
            ('Bachelor of Technology')
        """)

        # Insert Sections (BCA=1, B.Tech=2)
        cursor.execute("""
            INSERT INTO sections (program_id, year, section_name, size) VALUES
            (1, 1, 'A', 45),
            (1, 1, 'B', 50),
            (2, 2, 'A', 60)
        """)

        # Insert Students (alice=6, bob=7, charlie=8, dave=9 | bca_1a=1, bca_1b=2, btech_2a=3)
        cursor.execute("""
            INSERT INTO students (user_id, section_id, name) VALUES
            (6, 1, 'Alice Smith'),
            (7, 1, 'Bob Johnson'),
            (8, 2, 'Charlie Brown'),
            (9, 3, 'Dave Davis')
        """)

        # Insert Teachers (einstein=3, curie=4, turing=5)
        cursor.execute("""
            INSERT INTO teachers (user_id, name, email) VALUES
            (3, 'Albert Einstein', 'einstein@uni.com'),
            (4, 'Marie Curie', 'curie@uni.com'),
            (5, 'Alan Turing', 'turing@uni.com')
        """)

        # Insert Teacher Availability (einstein=1, curie=2, turing=3)
        cursor.execute("""
            INSERT INTO teacher_availability (teacher_id, day_of_week, start_time, end_time) VALUES
            (1, 'Monday', '09:00:00', '17:00:00'),
            (1, 'Tuesday', '09:00:00', '17:00:00'),
            (1, 'Wednesday', '09:00:00', '12:00:00'),
            (2, 'Wednesday', '13:00:00', '17:00:00'),
            (2, 'Thursday', '09:00:00', '17:00:00'),
            (2, 'Friday', '09:00:00', '17:00:00'),
            (3, 'Monday', '09:00:00', '17:00:00'),
            (3, 'Friday', '09:00:00', '17:00:00')
        """)

        # Insert Rooms
        cursor.execute("""
            INSERT INTO rooms (name, capacity, type) VALUES
            ('Main Hall (A-101)', 65, 'LECTURE'),
            ('West Wing (W-202)', 45, 'LECTURE'),
            ('Computer Lab (CS-01)', 50, 'LAB')
        """)

        # Insert Subjects
        cursor.execute("""
            INSERT INTO subjects (name, requires_room_type) VALUES
            ('Physics 101', NULL),
            ('History of Science', NULL),
            ('Calculus I', NULL),
            ('Data Structures', 'LAB')
        """)

        # Insert Timeslots
        cursor.execute("""
            INSERT INTO timeslots (day_of_week, start_time, end_time) VALUES
            ('Monday', '09:00:00', '10:00:00'),
            ('Monday', '10:00:00', '11:00:00'),
            ('Monday', '11:00:00', '12:00:00'),
            ('Monday', '13:00:00', '14:00:00'),
            ('Tuesday', '09:00:00', '10:00:00'),
            ('Tuesday', '10:00:00', '11:00:00'),
            ('Tuesday', '11:00:00', '12:00:00'),
            ('Tuesday', '13:00:00', '14:00:00'),
            ('Wednesday', '09:00:00', '10:00:00'),
            ('Wednesday', '10:00:00', '11:00:00'),
            ('Wednesday', '11:00:00', '12:00:00'),
            ('Wednesday', '13:00:00', '14:00:00'),
            ('Thursday', '09:00:00', '10:00:00'),
            ('Thursday', '10:00:00', '11:00:00'),
            ('Thursday', '11:00:00', '12:00:00'),
            ('Thursday', '13:00:00', '14:00:00'),
            ('Friday', '09:00:00', '10:00:00'),
            ('Friday', '10:00:00', '11:00:00'),
            ('Friday', '11:00:00', '12:00:00'),
            ('Friday', '13:00:00', '14:00:00')
        """)

        # Insert Subject Assignments
        # (einstein=1, curie=2, turing=3 | bca_1a=1, bca_1b=2, btech_2a=3 | physics=1, history=2, calculus=3, data_structures=4)
        cursor.execute("""
            INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week) VALUES
            (1, 1, 1, 3), -- Einstein teaches Physics to BCA 1A (3 hours)
            (4, 3, 1, 3), -- Turing teaches Data Structures to BCA 1A (3 hours)
            (3, 1, 2, 3), -- Einstein teaches Calculus to BCA 1B (3 hours)
            (4, 3, 2, 3), -- Turing teaches Data Structures to BCA 1B (3 hours)
            (2, 2, 3, 4)  -- Curie teaches History to B.Tech 2A (4 hours)
        """)

        conn.commit()
        print("Sample data inserted successfully!")

    except Exception as e:
        conn.rollback()
        print(f"Error inserting sample data: {e}")
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    insert_sample_data()

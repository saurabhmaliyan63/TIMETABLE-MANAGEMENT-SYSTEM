import bcrypt
import mysql.connector

from db_config import get_db_connection


def insert_large_data():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Clear existing data
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        cursor.execute("DELETE FROM generated_timetable")
        cursor.execute("DELETE FROM timetable_slots")
        cursor.execute("DELETE FROM subject_assignments")
        cursor.execute("DELETE FROM curriculum")
        cursor.execute("DELETE FROM teacher_qualifications")
        cursor.execute("DELETE FROM timeslots")
        cursor.execute("DELETE FROM subjects")
        cursor.execute("DELETE FROM rooms")
        cursor.execute("DELETE FROM teacher_availability")
        cursor.execute("DELETE FROM teachers")
        cursor.execute("DELETE FROM students")
        cursor.execute("DELETE FROM sections")
        cursor.execute("DELETE FROM programs")
        cursor.execute("DELETE FROM users")
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")

        # Hash passwords and insert Users (45 total)
        users_data = [
            # Admins/Coordinators (1-2)
            ('admin', 'admin_pass123', 'admin'),
            ('coordinator', 'coord_pass123', 'coordinator'),
            # Original Teachers (3-7)
            ('prof_einstein', 'teacher_pass1', 'teacher'),
            ('prof_curie', 'teacher_pass2', 'teacher'),
            ('prof_turing', 'teacher_pass3', 'teacher'),
            ('prof_sharma', 'teacher_pass4', 'teacher'),
            ('prof_khan', 'teacher_pass5', 'teacher'),
            # Original Students (8-15)
            ('student_alice', 'student_pass1', 'student'),
            ('student_bob', 'student_pass2', 'student'),
            ('student_charlie', 'student_pass3', 'student'),
            ('student_dave', 'student_pass4', 'student'),
            ('student_eve', 'student_pass5', 'student'),
            ('student_frank', 'student_pass6', 'student'),
            ('student_grace', 'student_pass7', 'student'),
            ('student_heidi', 'student_pass8', 'student'),
            # New Teachers (16-25)
            ('prof_davis', 'pass123', 'teacher'),
            ('prof_lee', 'pass123', 'teacher'),
            ('prof_chen', 'pass123', 'teacher'),
            ('prof_patel', 'pass123', 'teacher'),
            ('prof_bose', 'pass123', 'teacher'),
            ('prof_singh', 'pass123', 'teacher'),
            ('prof_murphy', 'pass123', 'teacher'),
            ('prof_gonzalez', 'pass123', 'teacher'),
            ('prof_smith', 'pass123', 'teacher'),
            ('prof_owens', 'pass123', 'teacher'),
            # New Students (26-45)
            ('student_ivan', 'pass123', 'student'),
            ('student_julia', 'pass123', 'student'),
            ('student_karl', 'pass123', 'student'),
            ('student_laura', 'pass123', 'student'),
            ('student_mike', 'pass123', 'student'),
            ('student_nina', 'pass123', 'student'),
            ('student_oscar', 'pass123', 'student'),
            ('student_paula', 'pass123', 'student'),
            ('student_quinn', 'pass123', 'student'),
            ('student_rachel', 'pass123', 'student'),
            ('student_sam', 'pass123', 'student'),
            ('student_tina', 'pass123', 'student'),
            ('student_umar', 'pass123', 'student'),
            ('student_vera', 'pass123', 'student'),
            ('student_will', 'pass123', 'student'),
            ('student_xena', 'pass123', 'student'),
            ('student_yara', 'pass123', 'student'),
            ('student_zack', 'pass123', 'student'),
            ('student_amy', 'pass123', 'student'),
            ('student_ben', 'pass123', 'student'),
            # Extra Teachers to solve constraints (46-50)
            ('prof_newton', 'pass123', 'teacher'),
            ('prof_galileo', 'pass123', 'teacher'),
            ('prof_faraday', 'pass123', 'teacher'),
            ('prof_maxwell', 'pass123', 'teacher'),
            ('prof_bohr', 'pass123', 'teacher'),
            # New Teachers for optimization (51-55)
            ('prof_tesla', 'pass123', 'teacher'),
            ('prof_edison', 'pass123', 'teacher'),
            ('prof_hawking', 'pass123', 'teacher'),
            ('prof_darwin', 'pass123', 'teacher'),
            ('prof_lovelace', 'pass123', 'teacher')
        ]

        for username, password, role in users_data:
            hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            cursor.execute("""
                INSERT INTO users (username, `password`, role) VALUES (%s, %s, %s)
            """, (username, hashed_password, role))

        # Insert Programs (6 total)
        cursor.execute("""
            INSERT INTO programs (name) VALUES
            ('Bachelor of Computer Applications'),
            ('Bachelor of Technology'),
            ('Bachelor of Business Administration'),
            ('Master of Technology'),
            ('B.Sc. Physics'),
            ('Master of Business Administration')
        """)

        # Insert Sections (18 total)
        # program_ids: BCA=1, B.Tech=2, BBA=3, M.Tech=4, BSc-PHY=5, MBA=6
        cursor.execute("""
            INSERT INTO sections (program_id, year, section_name, size) VALUES
            (1, 1, 'A', 45), -- 1: BCA 1A
            (1, 1, 'B', 50), -- 2: BCA 1B
            (1, 2, 'A', 40), -- 3: BCA 2A
            (2, 1, 'A', 60), -- 4: B.Tech 1A
            (2, 2, 'A', 55), -- 5: B.Tech 2A
            (3, 1, 'A', 70), -- 6: BBA 1A
            (1, 2, 'B', 42), -- 7: BCA 2B (New)
            (1, 3, 'A', 38), -- 8: BCA 3A (New)
            (2, 1, 'B', 60), -- 9: B.Tech 1B (New)
            (2, 2, 'B', 58), -- 10: B.Tech 2B (New)
            (2, 3, 'A', 50), -- 11: B.Tech 3A (New)
            (3, 1, 'B', 70), -- 12: BBA 1B (New)
            (3, 2, 'A', 65), -- 13: BBA 2A (New)
            (4, 1, 'A', 30), -- 14: M.Tech 1A (New)
            (5, 1, 'A', 40), -- 15: BSc-PHY 1A (New)
            (5, 2, 'A', 35), -- 16: BSc-PHY 2A (New)
            (6, 1, 'A', 60), -- 17: MBA 1A (New)
            (6, 1, 'B', 60)  -- 18: MBA 1B (New)
        """)

        # Insert Students (28 total)
        # user_ids: alice=8...heidi=15 (Original)
        # user_ids: ivan=26...ben=45 (New)
        cursor.execute("""
            INSERT INTO students (user_id, section_id, name) VALUES
            (8, 1, 'Alice Smith'),
            (9, 1, 'Bob Johnson'),
            (10, 2, 'Charlie Brown'),
            (11, 2, 'Dave Davis'),
            (12, 3, 'Eve Williams'),
            (13, 4, 'Frank Miller'),
            (14, 5, 'Grace Lee'),
            (15, 6, 'Heidi Wilson'),
            -- Populate new sections
            (26, 7, 'Ivan Ivanov'),
            (27, 7, 'Julia Kims'),
            (28, 8, 'Karl Marx'),
            (29, 8, 'Laura Moon'),
            (30, 9, 'Mike Ross'),
            (31, 9, 'Nina Simone'),
            (32, 10, 'Oscar Wilde'),
            (33, 10, 'Paula Ried'),
            (34, 11, 'Quinn Fabray'),
            (35, 11, 'Rachel Green'),
            (36, 12, 'Sam Tarly'),
            (37, 12, 'Tina Cohen'),
            (38, 13, 'Umar Akmal'),
            (39, 13, 'Vera Wang'),
            (40, 14, 'Will Turner'),
            (41, 14, 'Xena Warrior'),
            (42, 15, 'Yara Greyjoy'),
            (43, 16, 'Zack Snyder'),
            (44, 17, 'Amy Pond'),
            (45, 18, 'Ben Wyatt')
        """)

        # Insert Teachers (15 total)
        # user_ids: 3-7 (Original)
        # user_ids: 16-25 (New)
        cursor.execute("""
            INSERT INTO teachers (user_id, name, email) VALUES
            (3, 'Albert Einstein', 'einstein@uni.com'), -- 1
            (4, 'Marie Curie', 'curie@uni.com'), 	 -- 2
            (5, 'Alan Turing', 'turing@uni.com'), 	 -- 3
            (6, 'Rohan Sharma', 'sharma@uni.com'), 	 -- 4
            (7, 'Ayesha Khan', 'khan@uni.com'), 		 -- 5
            (16, 'Daniel Davis', 'davis@uni.com'), 	 -- 6
            (17, 'Emily Lee', 'lee@uni.com'), 		 -- 7
            (18, 'Frank Chen', 'chen@uni.com'), 		 -- 8
            (19, 'Grace Patel', 'patel@uni.com'), 	 -- 9
            (20, 'Henry Bose', 'bose@uni.com'), 		 -- 10
            (21, 'Ishaan Singh', 'singh@uni.com'), 	 -- 11
            (22, 'Jane Murphy', 'murphy@uni.com'), 	 -- 12
            (23, 'Ken Gonzalez', 'gonzalez@uni.com'),-- 13
            (24, 'Linda Smith', 'smith@uni.com'), 	 -- 14
            (25, 'Mike Owens', 'owens@uni.com'), 	 -- 15
            -- Extra Teachers
            (46, 'Isaac Newton', 'newton@uni.com'),    -- 16
            (47, 'Galileo Galilei', 'galileo@uni.com'), -- 17
            (48, 'Michael Faraday', 'faraday@uni.com'),-- 18
            (49, 'James Maxwell', 'maxwell@uni.com'),  -- 19
            (50, 'Niels Bohr', 'bohr@uni.com'),        -- 20
            # New Teachers for optimization
            (51, 'Nikola Tesla', 'tesla@uni.com'),      -- 21
            (52, 'Thomas Edison', 'edison@uni.com'),    -- 22
            (53, 'Stephen Hawking', 'hawking@uni.com'), -- 23
            (54, 'Charles Darwin', 'darwin@uni.com'),   -- 24
            (55, 'Ada Lovelace', 'lovelace@uni.com')    -- 25
        """)

        # Insert Teacher Availability
        cursor.execute("""
            INSERT INTO teacher_availability (teacher_id, day_of_week, start_time, end_time) VALUES
            -- Original 5
            (1, 'Monday', '09:00:00', '17:00:00'),
            (1, 'Tuesday', '09:00:00', '17:00:00'),
            (1, 'Wednesday', '09:00:00', '12:00:00'),
            (2, 'Wednesday', '13:00:00', '17:00:00'),
            (2, 'Thursday', '09:00:00', '17:00:00'),
            (2, 'Friday', '09:00:00', '17:00:00'),
            (3, 'Monday', '09:00:00', '17:00:00'),
            (3, 'Friday', '09:00:00', '17:00:00'),
            (4, 'Tuesday', '09:00:00', '12:00:00'),
            (4, 'Thursday', '09:00:00', '12:00:00'),
            (5, 'Monday', '13:00:00', '17:00:00'),
            (5, 'Tuesday', '13:00:00', '17:00:00'),
            (5, 'Wednesday', '09:00:00', '17:00:00'),
            -- New 10 (IDs 6-15)
            (6, 'Monday', '09:00:00', '11:00:00'),
            (6, 'Wednesday', '10:00:00', '12:00:00'),
            (7, 'Tuesday', '13:00:00', '17:00:00'),
            (7, 'Thursday', '13:00:00', '17:00:00'),
            (8, 'Monday', '09:00:00', '17:00:00'),
            (8, 'Tuesday', '09:00:00', '17:00:00'),
            (9, 'Wednesday', '09:00:00', '17:00:00'),
            (9, 'Thursday', '09:00:00', '17:00:00'),
            (10, 'Friday', '09:00:00', '14:00:00'),
            (11, 'Monday', '09:00:00', '12:00:00'),
            (11, 'Tuesday', '09:00:00', '12:00:00'),
            (12, 'Wednesday', '13:00:00', '16:00:00'),
            (12, 'Thursday', '10:00:00', '14:00:00'),
            (13, 'Friday', '09:00:00', '17:00:00'),
            (14, 'Monday', '10:00:00', '14:00:00'),
            (14, 'Tuesday', '10:00:00', '14:00:00'),
            (15, 'Wednesday', '09:00:00', '17:00:00'),
            (15, 'Thursday', '09:00:00', '17:00:00'),
            -- Extra Teachers (IDs 16-20)
            (16, 'Monday', '09:00:00', '17:00:00'), -- Newton
            (16, 'Tuesday', '09:00:00', '17:00:00'),
            (17, 'Wednesday', '09:00:00', '17:00:00'), -- Galileo
            (17, 'Thursday', '09:00:00', '17:00:00'),
            (18, 'Friday', '09:00:00', '17:00:00'), -- Faraday
            (18, 'Monday', '13:00:00', '17:00:00'),
            (19, 'Tuesday', '09:00:00', '12:00:00'), -- Maxwell
            (19, 'Wednesday', '09:00:00', '12:00:00'),
            (20, 'Thursday', '13:00:00', '17:00:00'), -- Bohr
            (20, 'Friday', '09:00:00', '12:00:00'),
            # New Teachers (Full availability to ease constraints)
            (21, 'Monday', '09:00:00', '17:00:00'), (21, 'Tuesday', '09:00:00', '17:00:00'), (21, 'Wednesday', '09:00:00', '17:00:00'), (21, 'Thursday', '09:00:00', '17:00:00'), (21, 'Friday', '09:00:00', '17:00:00'),
            (22, 'Monday', '09:00:00', '17:00:00'), (22, 'Tuesday', '09:00:00', '17:00:00'), (22, 'Wednesday', '09:00:00', '17:00:00'), (22, 'Thursday', '09:00:00', '17:00:00'), (22, 'Friday', '09:00:00', '17:00:00'),
            (23, 'Monday', '09:00:00', '17:00:00'), (23, 'Tuesday', '09:00:00', '17:00:00'), (23, 'Wednesday', '09:00:00', '17:00:00'), (23, 'Thursday', '09:00:00', '17:00:00'), (23, 'Friday', '09:00:00', '17:00:00'),
            (24, 'Monday', '09:00:00', '17:00:00'), (24, 'Tuesday', '09:00:00', '17:00:00'), (24, 'Wednesday', '09:00:00', '17:00:00'), (24, 'Thursday', '09:00:00', '17:00:00'), (24, 'Friday', '09:00:00', '17:00:00'),
            (25, 'Monday', '09:00:00', '17:00:00'), (25, 'Tuesday', '09:00:00', '17:00:00'), (25, 'Wednesday', '09:00:00', '17:00:00'), (25, 'Thursday', '09:00:00', '17:00:00'), (25, 'Friday', '09:00:00', '17:00:00')
        """)

        # Insert Rooms (15 total)
        cursor.execute("""
            INSERT INTO rooms (name, capacity, type) VALUES
            ('Main Hall (A-101)', 65, 'LECTURE'), -- 1
            ('West Wing (W-202)', 45, 'LECTURE'), -- 2
            ('Computer Lab (CS-01)', 50, 'LAB'), -- 3
            ('Auditorium', 150, 'AUDITORIUM'), -- 4
            ('Seminar Hall (S-101)', 75, 'SEMINAR'), -- 5
            ('Computer Lab (CS-02)', 50, 'LAB'), -- 6
            ('East Hall (E-101)', 70, 'LECTURE'), -- 7
            ('East Hall (E-102)', 70, 'LECTURE'), -- 8
            ('Main Hall (A-102)', 65, 'LECTURE'), -- 9
            ('West Wing (W-203)', 50, 'LECTURE'), -- 10
            ('Physics Lab (PHY-01)', 45, 'LAB'), -- 11
            ('Electronics Lab (EE-01)', 45, 'LAB'), -- 12
            ('Seminar Hall (S-102)', 75, 'SEMINAR'), -- 13
            ('Seminar Hall (S-201)', 80, 'SEMINAR'), -- 14
            ('M.Tech Lab (CS-M1)', 35, 'LAB'), -- 15
            # New Rooms to ease constraints
            ('Lecture Hall 101', 60, 'LECTURE'), -- 16
            ('Lecture Hall 102', 60, 'LECTURE'), -- 17
            ('Lecture Hall 103', 60, 'LECTURE'), -- 18
            ('Lab 201', 40, 'LAB'), -- 19
            ('Seminar Room 301', 50, 'SEMINAR') -- 20
        """)

        # Insert Subjects (22 total)
        cursor.execute("""
            INSERT INTO subjects (name, requires_room_type) VALUES
            ('Physics 101', NULL), -- 1
            ('History of Science', NULL), -- 2
            ('Calculus I', NULL), -- 3
            ('Data Structures', 'LAB'), -- 4
            ('Intro to Engineering', 'LECTURE'), -- 5
            ('Database Systems', 'LAB'), -- 6
            ('Business Management 101', 'SEMINAR'), -- 7
            ('Advanced Algorithms', 'SEMINAR'), -- 8
            -- New Subjects
            ('Software Engineering', 'LAB'), -- 9 (BCA 3)
            ('AI Concepts', 'SEMINAR'), -- 10 (BCA 3)
            ('Thermodynamics', 'LECTURE'), -- 11 (B.Tech 3)
            ('Digital Circuits', 'LAB'), -- 12 (B.Tech 3)
            ('Advanced DBMS', 'LAB'), -- 13 (M.Tech 1)
            ('Machine Learning', 'LAB'), -- 14 (M.Tech 1)
            ('Mechanics', 'LECTURE'), -- 15 (BSc-PHY 1)
            ('Optics Lab', 'LAB'), -- 16 (BSc-PHY 1)
            ('Quantum Mechanics', 'LECTURE'), -- 17 (BSc-PHY 2)
            ('Electronics Lab', 'LAB'), -- 18 (BSc-PHY 2)
            ('Marketing', 'SEMINAR'), -- 19 (BBA 2)
            ('Managerial Finance', 'SEMINAR'), -- 20 (BBA 2)
            ('Organizational Behavior', 'SEMINAR'), -- 21 (MBA 1)
            ('Financial Accounting', 'LECTURE') -- 22 (MBA 1)
        """)

        # Insert Teacher Qualifications
        # Teacher IDs: 1-15
        # Subject IDs: 1-22
        cursor.execute("""
            INSERT INTO teacher_qualifications (teacher_id, subject_id) VALUES
            -- Original
            (1, 1), (1, 3), -- Einstein: Physics, Calculus
            (2, 2), -- Curie: History
            (3, 4), (3, 8), -- Turing: Data Structures, Advanced Algorithms
            (4, 5), (4, 1), -- Sharma: Engineering, Physics
            (5, 6), (5, 7), -- Khan: DBMS, Business
            -- New
            (1, 15), (1, 17), -- Einstein also teaches Mechanics, Quantum Mechanics
            (3, 14), (3, 10), -- Turing also teaches ML, AI Concepts
            (5, 13), -- Khan also teaches Advanced DBMS
            (6, 9), (6, 12), -- Davis: Software Eng, Digital Circuits
            (7, 11), (7, 5), -- Lee: Thermodynamics, Intro to Eng
            (8, 13), (8, 6), -- Chen: Advanced DBMS, Database Systems
            (9, 15), (9, 16), -- Patel: Mechanics, Optics Lab
            (10, 17), (10, 18), -- Bose: Quantum Mechanics, Electronics Lab
            (11, 12), (11, 18), -- Singh: Digital Circuits, Electronics Lab
            (12, 19), (12, 21), -- Murphy: Marketing, Org. Behavior
            (13, 20), (13, 22), -- Gonzalez: Finance, Accounting
            (14, 7), (14, 19), -- Smith: Business Mgmt, Marketing
            (15, 21), (15, 20), -- Owens: Org. Behavior, Finance
            -- Extra Teachers (IDs 16-20)
            (16, 1), (16, 3), (16, 15), -- Newton: Physics 101, Calculus I, Mechanics
            (17, 1), (17, 15), -- Galileo: Physics 101, Mechanics
            (18, 12), (18, 18), -- Faraday: Digital Circuits, Electronics Lab
            (19, 11), (19, 17), -- Maxwell: Thermodynamics, Quantum Mechanics
            (20, 17), (20, 10), -- Bohr: Quantum Mechanics, AI Concepts
            # New Teachers Qualifications (Taking over some subjects)
            (21, 3), -- Tesla: Calculus I (Subject 3)
            (22, 4), -- Edison: Data Structures (Subject 4)
            (23, 6), -- Hawking: Database Systems (Subject 6)
            (24, 5), -- Darwin: Intro to Engineering (Subject 5)
            (25, 7)  -- Lovelace: Business Management 101 (Subject 7)
        """)

        # Insert Curriculum
        # Program IDs: BCA=1, B.Tech=2, BBA=3, M.Tech=4, BSc-PHY=5, MBA=6
        cursor.execute("""
            INSERT INTO curriculum (program_id, year, subject_id) VALUES
            -- Original
            (1, 1, 3), (1, 1, 4), -- BCA 1: Calculus, Data Structures
            (1, 2, 6), (1, 2, 8), -- BCA 2: DBMS, Advanced Algorithms
            (2, 1, 5), (2, 1, 3), -- B.Tech 1: Engineering, Calculus
            (2, 2, 1), (2, 2, 2), -- B.Tech 2: Physics, History
            (3, 1, 7), -- BBA 1: Business Management
            -- New
            (1, 3, 9), -- BCA 3: Software Eng (Removed AI Concepts 10 to ease load)
            (2, 3, 11), (2, 3, 12), -- B.Tech 3: Thermo, Digital Circuits
            (3, 2, 19), (3, 2, 20), -- BBA 2: Marketing, Finance
            (4, 1, 13), (4, 1, 14), -- M.Tech 1: Adv DBMS, ML
            (5, 1, 15), (5, 1, 16), -- BSc-PHY 1: Mechanics, Optics Lab
            (5, 2, 17), (5, 2, 18), -- BSc-PHY 2: Quantum, Electronics Lab
            (6, 1, 21), (6, 1, 22) -- MBA 1: Org. Behavior, Accounting
        """)

        # Insert Master Timeslots
        cursor.execute("""
            INSERT INTO timeslots (day_of_week, start_time, end_time) VALUES
            ('Monday', '09:00:00', '10:00:00'),
            ('Monday', '10:00:00', '11:00:00'),
            ('Monday', '11:00:00', '12:00:00'),
            ('Monday', '13:00:00', '14:00:00'),
            ('Monday', '14:00:00', '15:00:00'), -- Added afternoon slot
            ('Tuesday', '09:00:00', '10:00:00'),
            ('Tuesday', '10:00:00', '11:00:00'),
            ('Tuesday', '11:00:00', '12:00:00'),
            ('Tuesday', '13:00:00', '14:00:00'),
            ('Tuesday', '14:00:00', '15:00:00'), -- Added afternoon slot
            ('Wednesday', '09:00:00', '10:00:00'),
            ('Wednesday', '10:00:00', '11:00:00'),
            ('Wednesday', '11:00:00', '12:00:00'),
            ('Wednesday', '13:00:00', '14:00:00'),
            ('Wednesday', '14:00:00', '15:00:00'), -- Added afternoon slot
            ('Thursday', '09:00:00', '10:00:00'),
            ('Thursday', '10:00:00', '11:00:00'),
            ('Thursday', '11:00:00', '12:00:00'),
            ('Thursday', '13:00:00', '14:00:00'),
            ('Thursday', '14:00:00', '15:00:00'), -- Added afternoon slot
            ('Friday', '09:00:00', '10:00:00'),
            ('Friday', '10:00:00', '11:00:00'),
            ('Friday', '11:00:00', '12:00:00'),
            ('Friday', '13:00:00', '14:00:00'),
            ('Friday', '14:00:00', '15:00:00'), -- Added afternoon slot
            -- Saturday (Extra day for flexibility)
            ('Saturday', '09:00:00', '10:00:00'),
            ('Saturday', '10:00:00', '11:00:00'),
            ('Saturday', '11:00:00', '12:00:00')
        """)

        # Insert Subject Assignments (32 assignments total)
        # Original 10
        cursor.execute("""
            INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week) VALUES
            (3, 21, 1, 2), -- Tesla (21) teaches Calculus to BCA 1A (sec 1) [Was Einstein 1]
            (4, 22, 1, 3), -- Edison (22) teaches Data Structures to BCA 1A (sec 1) [Was Turing 3]
            (3, 1, 2, 2), -- Einstein teaches Calculus to BCA 1B (sec 2)
            (4, 3, 2, 3), -- Turing teaches Data Structures to BCA 1B (sec 2)
            (6, 23, 3, 3), -- Hawking (23) teaches DBMS to BCA 2A (sec 3) [Was Khan 5]
            (8, 3, 3, 2), -- Turing teaches Adv. Algorithms to BCA 2A (sec 3)
            (5, 24, 4, 3), -- Darwin (24) teaches Engineering to B.Tech 1A (sec 4) [Was Sharma 4]
            (1, 16, 5, 3), -- Newton (16) teaches Physics to B.Tech 2A (sec 5)
            (2, 2, 5, 2), -- Curie teaches History to B.Tech 2A (sec 5)
            (7, 25, 6, 3), -- Lovelace (25) teaches Business to BBA 1A (sec 6) [Was Khan 5]
            -- New 22
            (6, 8, 7, 3), -- Chen teaches DBMS to BCA 2B (sec 7)
            (8, 3, 7, 2), -- Turing teaches Adv. Algorithms to BCA 2B (sec 7)
            (9, 6, 8, 3), -- Davis teaches Software Eng to BCA 3A (sec 8)
            -- Removed Bohr (20) AI Concepts for BCA 3A (sec 8) to ease load (Subject 10)
            (5, 7, 9, 3), -- Lee teaches Engineering to B.Tech 1B (sec 9)
            (3, 1, 9, 2), -- Einstein teaches Calculus to B.Tech 1B (sec 9)
            (1, 4, 10, 3), -- Sharma teaches Physics to B.Tech 2B (sec 10)
            (2, 2, 10, 2), -- Curie teaches History to B.Tech 2B (sec 10)
            (11, 19, 11, 3), -- Maxwell (19) teaches Thermo to B.Tech 3A (sec 11)
            (12, 6, 11, 3), -- Davis teaches Digital Circuits to B.Tech 3A (sec 11)
            (7, 14, 12, 3), -- Smith teaches Business to BBA 1B (sec 12)
            (19, 12, 13, 3), -- Murphy teaches Marketing to BBA 2A (sec 13)
            (20, 13, 13, 3), -- Gonzalez teaches Finance to BBA 2A (sec 13)
            (13, 8, 14, 3), -- Chen teaches Adv DBMS to M.Tech 1A (sec 14)
            (14, 3, 14, 3), -- Turing teaches ML to M.Tech 1A (sec 14)
            (15, 9, 15, 3), -- Patel teaches Mechanics to BSc-PHY 1A (sec 15)
            (16, 9, 15, 2), -- Patel teaches Optics Lab to BSc-PHY 1A (sec 15)
            (17, 20, 16, 3), -- Bohr (20) teaches Quantum to BSc-PHY 2A (sec 16)
            (18, 11, 16, 2), -- Singh teaches Electronics Lab to BSc-PHY 2A (sec 16)
            (21, 15, 17, 3), -- Owens teaches Org. Behavior to MBA 1A (sec 17)
            (22, 13, 17, 2), -- Gonzalez teaches Accounting to MBA 1A (sec 17)
            (21, 12, 18, 3), -- Murphy teaches Org. Behavior to MBA 1B (sec 18)
            (22, 13, 18, 2) -- Gonzalez teaches Accounting to MBA 1B (sec 18)
        """)

        conn.commit()
        
        # Verification print
        cursor.execute("SELECT COUNT(*) FROM rooms")
        print(f"Rooms count: {cursor.fetchone()[0]}")
        print("Large dataset inserted successfully!")

    except Exception as e:
        conn.rollback()
        print(f"Error inserting large dataset: {e}")
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    insert_large_data()

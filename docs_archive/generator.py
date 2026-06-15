import copy

import mysql.connector

from db_config import get_db_connection


class TimetableGenerator:
    def __init__(self):
        self.teachers = []
        self.rooms = []
        self.subjects = []
        self.groups = []
        self.assignments = []
        self.timeslots = []
        self.timetable = {}  # {(day, timeslot, room): (teacher, subject, group)}

    def load_data(self):
        """Load all data from database"""
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        try:
            # Load teachers
            cursor.execute("SELECT * FROM teachers")
            self.teachers = cursor.fetchall()

            # Load rooms
            cursor.execute("SELECT * FROM rooms")
            self.rooms = cursor.fetchall()

            # Load subjects
            cursor.execute("SELECT * FROM subjects")
            self.subjects = cursor.fetchall()

            # Load sections
            cursor.execute("SELECT * FROM sections")
            self.groups = cursor.fetchall()

            # Load assignments
            cursor.execute("""
                SELECT sa.*, t.name as teacher_name, s.name as subject_name,
                       sec.section_name as group_name, sec.size as group_size,
                       p.name as program_name, sec.year
                FROM subject_assignments sa
                JOIN teachers t ON sa.teacher_id = t.teacher_id
                JOIN subjects s ON sa.subject_id = s.subject_id
                JOIN sections sec ON sa.section_id = sec.section_id
                JOIN programs p ON sec.program_id = p.program_id
            """)
            self.assignments = cursor.fetchall()

            # Load timeslots, excluding break/lunch timeslots (those with session_type_id)
            cursor.execute("""
                SELECT * FROM timeslots 
                WHERE session_type_id IS NULL 
                ORDER BY day_of_week, start_time
            """)
            self.timeslots = cursor.fetchall()

        finally:
            cursor.close()
            conn.close()

    def is_valid_placement(self, assignment, day, timeslot, room):
        """Check if placing this assignment at this time/room is valid"""
        key = (day, timeslot, room.room_id)

        # Check if room is already occupied
        if key in self.timetable:
            return False

        # Check teacher availability
        for existing_key, (existing_teacher, _, _) in self.timetable.items():
            if existing_key[0] == day and existing_key[1] == timeslot and existing_teacher['teacher_id'] == assignment['teacher_id']:
                return False

        # Check group availability
        for existing_key, (_, _, existing_group) in self.timetable.items():
            if existing_key[0] == day and existing_key[1] == timeslot and existing_group['section_id'] == assignment['section_id']:
                return False

        # Check room type compatibility
        if assignment.get('requires_room_type') and room['type'] != assignment['requires_room_type']:
            return False

        # Check room capacity
        if room['capacity'] < assignment['group_size']:
            return False

        return True

    def place_assignment(self, assignment, day, timeslot, room):
        """Place an assignment in the timetable"""
        key = (day, timeslot, room['room_id'])
        self.timetable[key] = (assignment, assignment, assignment)  # teacher, subject, group

    def unplace_assignment(self, assignment, day, timeslot, room):
        """Remove an assignment from the timetable"""
        key = (day, timeslot, room['room_id'])
        if key in self.timetable:
            del self.timetable[key]

    def get_available_slots(self, assignment):
        """Get all available time/room slots for an assignment"""
        available_slots = []

        for timeslot in self.timeslots:
            for room in self.rooms:
                if self.is_valid_placement(assignment, timeslot['day_of_week'], timeslot['timeslot_id'], room):
                    available_slots.append((timeslot, room))

        return available_slots

    def calculate_remaining_hours(self, assignment):
        """Calculate how many hours still need to be scheduled for this assignment"""
        scheduled_hours = 0

        for (day, timeslot_id, room_id), (teacher, subject, group) in self.timetable.items():
            if (teacher['teacher_id'] == assignment['teacher_id'] and
                subject['subject_id'] == assignment['subject_id'] and
                group['section_id'] == assignment['section_id']):
                scheduled_hours += 1

        return max(0, assignment['hours_per_week'] - scheduled_hours)

    def solve(self, assignments=None):
        """Backtracking algorithm to solve the timetable"""
        if assignments is None:
            assignments = self.assignments.copy()

        # Base case: all assignments are fully scheduled
        if not assignments:
            return True

        # Get the first assignment
        current_assignment = assignments[0]
        remaining_assignments = assignments[1:]

        # Check if this assignment still needs scheduling
        remaining_hours = self.calculate_remaining_hours(current_assignment)
        if remaining_hours == 0:
            # This assignment is done, move to next
            return self.solve(remaining_assignments)

        # Try to place this assignment
        available_slots = self.get_available_slots(current_assignment)

        for timeslot, room in available_slots:
            # Place the assignment
            self.place_assignment(current_assignment, timeslot['day_of_week'], timeslot['timeslot_id'], room)

            # Recurse to next assignment
            if self.solve(remaining_assignments):
                return True

            # Backtrack
            self.unplace_assignment(current_assignment, timeslot['day_of_week'], timeslot['timeslot_id'], room)

        # No valid placement found
        return False

    def generate_timetable(self):
        """Main method to generate the complete timetable"""
        self.load_data()

        if not self.assignments:
            return {"error": "No subject assignments found"}

        if not self.timeslots:
            return {"error": "No timeslots defined"}

        if not self.rooms:
            return {"error": "No rooms defined"}

        # Reset timetable
        self.timetable = {}

        # Try to solve
        if self.solve():
            # Convert timetable to readable format
            formatted_timetable = self.format_timetable()
            return {
                "success": True,
                "timetable": formatted_timetable,
                "message": "Timetable generated successfully"
            }
        else:
            return {
                "success": False,
                "error": "No valid timetable could be generated with current constraints"
            }

    def format_timetable(self):
        """Format the timetable for display"""
        formatted = {}

        # Group by day
        for (day, timeslot_id, room_id), (teacher, subject, group) in self.timetable.items():
            if day not in formatted:
                formatted[day] = {}

            # Get timeslot info
            timeslot = next((t for t in self.timeslots if t['timeslot_id'] == timeslot_id), None)
            room = next((r for r in self.rooms if r['room_id'] == room_id), None)

            if timeslot and room:
                slot_key = f"{timeslot['start_time']}-{timeslot['end_time']}"
                if slot_key not in formatted[day]:
                    formatted[day][slot_key] = {}

                formatted[day][slot_key][room['name']] = {
                    "teacher": teacher['teacher_name'],
                    "subject": subject['subject_name'],
                    "group": group['group_name'],
                    "room_type": room['type']
                }

        return formatted

    def save_timetable(self):
        """Save the generated timetable to database"""
        if not self.timetable:
            return False

        conn = get_db_connection()
        cursor = conn.cursor()

        try:
            # Clear existing timetable
            cursor.execute("DELETE FROM timetable_slots")

            # Insert new timetable
            for (day, timeslot_id, room_id), (teacher, subject, group) in self.timetable.items():
                cursor.execute("""
                    INSERT INTO timetable_slots
                    (day_of_week, timeslot_id, room_id, teacher_id, subject_id, section_id)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (day, timeslot_id, room_id, teacher['teacher_id'],
                      subject['subject_id'], group['section_id']))

            conn.commit()
            return True

        except Exception as e:
            conn.rollback()
            print(f"Error saving timetable: {e}")
            return False
        finally:
            cursor.close()
            conn.close()

import mysql.connector
from .db_config import get_db_connection
import random
import time
from datetime import timedelta

class Lecture:
    def __init__(self, assignment):
        self.teacher_id = assignment['teacher_id']
        self.subject_id = assignment['subject_id']
        self.section_id = assignment['section_id']
        self.teacher_name = assignment['teacher_name']
        self.subject_name = assignment['subject_name']
        self.group_name = assignment['group_name']
        self.group_size = assignment['group_size']
        self.program_name = assignment['program_name']
        self.year = assignment['year']
        self.requires_room_type = assignment.get('requires_room_type')


# Error codes and messages for detailed diagnostics
class TimetableError:
    """Error class for detailed timetable generation failures"""
    
    # Error codes
    NO_ASSIGNMENTS = 'NO_ASSIGNMENTS'
    NO_TIMESLOTS = 'NO_TIMESLOTS'
    NO_ROOMS = 'NO_ROOMS'
    NO_TEACHERS = 'NO_TEACHERS'
    NO_SECTIONS = 'NO_SECTIONS'
    INSUFFICIENT_ROOMS = 'INSUFFICIENT_ROOMS'
    INSUFFICIENT_TIMESLOTS = 'INSUFFICIENT_TIMESLOTS'
    ROOM_CAPACITY_ISSUE = 'ROOM_CAPACITY_ISSUE'
    ROOM_TYPE_ISSUE = 'ROOM_TYPE_ISSUE'
    TEACHER_UNAVAILABILITY = 'TEACHER_UNAVAILABILITY'
    GENERATION_FAILED = 'GENERATION_FAILED'
    
    @staticmethod
    def get_error_details(error_code, context=None):
        """Get detailed error information with suggestions"""
        
        errors = {
            TimetableError.NO_ASSIGNMENTS: {
                'title': 'No Subject Assignments Found',
                'message': 'There are no subject assignments in the system. You need to assign teachers to subjects for sections before generating a timetable.',
                'suggestion': 'Go to Subject Assignments and create assignments for each subject-teacher-section combination.',
                'severity': 'critical',
                'link': '#assignments'
            },
            TimetableError.NO_TIMESLOTS: {
                'title': 'No Timeslots Defined',
                'message': 'No timeslots have been created. The system needs time slots to schedule classes.',
                'suggestion': 'Go to Timeslots and either manually create timeslots or use "Generate Timeslot Structure" to auto-create them.',
                'severity': 'critical',
                'link': '#timeslots'
            },
            TimetableError.NO_ROOMS: {
                'title': 'No Rooms Defined',
                'message': 'No rooms have been added to the system. You need at least one room to schedule classes.',
                'suggestion': 'Go to Rooms and add at least one room with appropriate capacity.',
                'severity': 'critical',
                'link': '#rooms'
            },
            TimetableError.NO_TEACHERS: {
                'title': 'No Teachers Found',
                'message': 'No teachers have been added to the system.',
                'suggestion': 'Go to Teachers and add teachers to the system.',
                'severity': 'critical',
                'link': '#teachers'
            },
            TimetableError.NO_SECTIONS: {
                'title': 'No Sections/Groups Found',
                'message': 'No sections or groups have been created. You need at least one section to generate a timetable.',
                'suggestion': 'Go to Sections and create at least one section/group.',
                'severity': 'critical',
                'link': '#groups'
            },
            TimetableError.INSUFFICIENT_ROOMS: {
                'title': 'Insufficient Rooms',
                'message': f'There are not enough rooms to accommodate all classes. Only {context.get("room_count", "?")} room(s) available.',
                'suggestion': 'Add more rooms or reduce the number of concurrent classes.',
                'severity': 'critical',
                'link': '#rooms'
            },
            TimetableError.INSUFFICIENT_TIMESLOTS: {
                'title': 'Insufficient Timeslots',
                'message': 'There are not enough timeslots to schedule all lectures. The system needs more time slots.',
                'suggestion': 'Add more timeslots (longer school days or more days) or reduce subject hours per week.',
                'severity': 'critical',
                'link': '#timeslots'
            },
            TimetableError.ROOM_CAPACITY_ISSUE: {
                'title': 'Room Capacity Issue',
                'message': f"The section '{context.get('section_name', 'Unknown')}' has {context.get('section_size', '?')} students but no room is large enough.",
                'suggestion': f'Add rooms with capacity of at least {context.get("required_capacity", "?")} students, or split the section into smaller groups.',
                'severity': 'critical',
                'link': '#rooms'
            },
            TimetableError.ROOM_TYPE_ISSUE: {
                'title': 'Room Type Mismatch',
                'message': f"Subject '{context.get('subject_name', 'Unknown')}' requires a '{context.get('required_type', '?')}' type room, but none are available.",
                'suggestion': f'Add rooms with type "{context.get('required_type', '?')}" or change the subject requirements.',
                'severity': 'critical',
                'link': '#rooms'
            },
            TimetableError.TEACHER_UNAVAILABILITY: {
                'title': 'Teacher Availability Issue',
                'message': f"Teacher '{context.get('teacher_name', 'Unknown')}' is not available during any of the defined timeslots.",
                'suggestion': 'Update teacher availability preferences or add more timeslots that work with this teacher.',
                'severity': 'warning',
                'link': '#preferences'
            },
            TimetableError.GENERATION_FAILED: {
                'title': 'Timetable Generation Failed',
                'message': context.get('message', 'The algorithm could not find a valid schedule after multiple attempts.'),
                'suggestion': 'Possible solutions: (1) Add more timeslots, (2) Reduce subject hours per week, (3) Add more rooms, (4) Check for teacher availability conflicts.',
                'severity': 'critical',
                'link': None
            }
        }
        
        return errors.get(error_code, {
            'title': 'Unknown Error',
            'message': str(context) if context else 'An unknown error occurred.',
            'suggestion': 'Please check your data and try again.',
            'severity': 'critical',
            'link': None
        })

class AdvancedTimetableGenerator:
    def __init__(self):
        self.teachers = []
        self.rooms = []
        self.subjects = []
        self.groups = []
        self.assignments = []
        self.timeslots = []
        self.teacher_availability = []
        self.master_lecture_list = []
        self.teacher_schedule = {}  # teacher_id -> timeslot_id -> "FREE"/"BUSY"
        self.section_schedule = {}  # section_id -> timeslot_id -> "FREE"/"BUSY"
        self.room_schedule = {}     # room_id -> timeslot_id -> "FREE"/"BUSY"
        self.section_subject_day_count = {} # (section_id, day) -> {subject_id: count}
        self.max_subject_repeats_per_day = 1 # Default to strict
        self.solution = {}  # lecture_index -> (timeslot_id, room_id)
        self.stats = {
            'backtrack_count': 0,
            'placement_attempts': 0,
            'generation_time_seconds': 0,
            'max_backtracks': 100000,  # Safety limit
            'attempt_number': 0
        }

    def load_data(self):
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute('SELECT * FROM teachers')
            self.teachers = cursor.fetchall()
            cursor.execute('SELECT * FROM rooms')
            self.rooms = cursor.fetchall()
            cursor.execute('SELECT * FROM subjects')
            self.subjects = cursor.fetchall()
            cursor.execute('SELECT * FROM sections')
            self.groups = cursor.fetchall()
            cursor.execute('''
                SELECT sa.*, t.name as teacher_name, s.name as subject_name,
                       sec.section_name as group_name, sec.size as group_size,
                       p.name as program_name, sec.year, s.requires_room_type
                FROM subject_assignments sa
                JOIN teachers t ON sa.teacher_id = t.teacher_id
                JOIN subjects s ON sa.subject_id = s.subject_id
                JOIN sections sec ON sa.section_id = sec.section_id
                JOIN programs p ON sec.program_id = p.program_id
            ''')
            self.assignments = cursor.fetchall()
            # Load timeslots, excluding break/lunch timeslots
            cursor.execute('''
                SELECT ts.* FROM timeslots ts
                LEFT JOIN session_types st ON ts.session_type_id = st.session_type_id
                WHERE st.name NOT IN ('Break', 'Lunch') OR ts.session_type_id IS NULL
                ORDER BY ts.day_of_week, ts.start_time
            ''')
            self.timeslots = cursor.fetchall()
            try:
                cursor.execute('SELECT * FROM teacher_availability')
                self.teacher_availability = cursor.fetchall()
            except mysql.connector.Error as err:
                if err.errno == 1146: # Table doesn't exist
                    print("Warning: teacher_availability table not found. Assuming all teachers are available.")
                    self.teacher_availability = []
                else:
                    raise
        finally:
            cursor.close()
            conn.close()

    def create_master_lecture_list(self):
        self.master_lecture_list = []
        for assignment in self.assignments:
            for _ in range(assignment['hours_per_week']):
                lecture = Lecture(assignment)
                self.master_lecture_list.append(lecture)

    def initialize_hash_maps(self):
        # Initialize teacher_schedule
        for teacher in self.teachers:
            self.teacher_schedule[teacher['teacher_id']] = {}
            for timeslot in self.timeslots:
                self.teacher_schedule[teacher['teacher_id']][timeslot['timeslot_id']] = "FREE"

        # Initialize section_schedule
        for group in self.groups:
            self.section_schedule[group['section_id']] = {}
            for timeslot in self.timeslots:
                self.section_schedule[group['section_id']][timeslot['timeslot_id']] = "FREE"

        # Initialize room_schedule
        for room in self.rooms:
            self.room_schedule[room['room_id']] = {}
            for timeslot in self.timeslots:
                self.room_schedule[room['room_id']][timeslot['timeslot_id']] = "FREE"
        
        # Initialize for one-subject-per-day constraint
        self.section_subject_day_count = {}

    def difficulty_score(self, lecture):
        score = 0

        # Room constraint: harder if requires specific room type
        if lecture.requires_room_type:
            suitable_rooms = [r for r in self.rooms if r['type'] == lecture.requires_room_type]
            score += 10 / len(suitable_rooms) if suitable_rooms else 100

        # Section size: harder if large group
        suitable_rooms = [r for r in self.rooms if r['capacity'] >= lecture.group_size]
        score += 10 / len(suitable_rooms) if suitable_rooms else 100

        # Teacher availability: harder if less available
        teacher_avail = [a for a in self.teacher_availability if a['teacher_id'] == lecture.teacher_id]
        score += 10 / len(teacher_avail) if teacher_avail else 100

        return score

    def sort_lectures_by_difficulty(self):
        self.master_lecture_list.sort(key=self.difficulty_score, reverse=True)

    def is_teacher_free_at_time(self, teacher_id, timeslot):
        # If no availability records exist for this teacher, assume they are available
        teacher_avail_records = [a for a in self.teacher_availability if a['teacher_id'] == teacher_id]
        if not teacher_avail_records:
            return True

        # Helper to convert time/timedelta to seconds for comparison
        def to_seconds(t):
            if isinstance(t, timedelta):
                return int(t.total_seconds())
            if isinstance(t, str):
                h, m, s = map(int, t.split(':'))
                return h * 3600 + m * 60 + s
            return 0

        slot_start = to_seconds(timeslot['start_time'])
        slot_end = to_seconds(timeslot['end_time'])

        # Check if slot time is within any availability window for that day
        is_available = False
        for avail in teacher_avail_records:
            avail_start = to_seconds(avail['start_time'])
            avail_end = to_seconds(avail['end_time'])
            
            if (avail['day_of_week'] == timeslot['day_of_week'] and
                avail_start <= slot_start and
                avail_end >= slot_end):
                is_available = True
                break
        return is_available

    def is_valid(self, lecture, timeslot, room):
        # Teacher clash
        if self.teacher_schedule[lecture.teacher_id][timeslot['timeslot_id']] == "BUSY":
            return False

        # Section clash
        if self.section_schedule[lecture.section_id][timeslot['timeslot_id']] == "BUSY":
            return False

        # Room clash
        if self.room_schedule[room['room_id']][timeslot['timeslot_id']] == "BUSY":
            return False

        # Teacher availability
        if not self.is_teacher_free_at_time(lecture.teacher_id, timeslot):
            return False

        # Room capacity
        if room['capacity'] < lecture.group_size:
            return False

        # Room type
        if lecture.requires_room_type and lecture.requires_room_type != room['type']:
            return False

        # New check: Max subject repeats per day for a section
        day = timeslot['day_of_week']
        key = (lecture.section_id, day)
        
        subject_counts_for_day = self.section_subject_day_count.get(key, {})
        current_subject_count = subject_counts_for_day.get(lecture.subject_id, 0)
        if current_subject_count >= self.max_subject_repeats_per_day:
            return False

        return True

    def place_lecture(self, lecture_index, timeslot, room):
        lecture = self.master_lecture_list[lecture_index]
        self.teacher_schedule[lecture.teacher_id][timeslot['timeslot_id']] = "BUSY"
        self.section_schedule[lecture.section_id][timeslot['timeslot_id']] = "BUSY"
        self.room_schedule[room['room_id']][timeslot['timeslot_id']] = "BUSY"
        self.solution[lecture_index] = (timeslot['timeslot_id'], room['room_id'])
        
        # Add to subject-per-day count tracker
        day = timeslot['day_of_week']
        key = (lecture.section_id, day)
        if key not in self.section_subject_day_count:
            self.section_subject_day_count[key] = {}
        subject_counts = self.section_subject_day_count[key]
        subject_counts[lecture.subject_id] = subject_counts.get(lecture.subject_id, 0) + 1

    def unplace_lecture(self, lecture_index, timeslot, room):
        lecture = self.master_lecture_list[lecture_index]
        self.teacher_schedule[lecture.teacher_id][timeslot['timeslot_id']] = "FREE"
        self.section_schedule[lecture.section_id][timeslot['timeslot_id']] = "FREE"
        self.room_schedule[room['room_id']][timeslot['timeslot_id']] = "FREE"
        del self.solution[lecture_index]
        
        # Remove from subject-per-day count tracker
        day = timeslot['day_of_week']
        key = (lecture.section_id, day)
        if key in self.section_subject_day_count:
            subject_counts = self.section_subject_day_count[key]
            if lecture.subject_id in subject_counts:
                subject_counts[lecture.subject_id] -= 1
                if subject_counts[lecture.subject_id] == 0:
                    del subject_counts[lecture.subject_id]
            if not subject_counts: # if dict is empty
                del self.section_subject_day_count[key]

    def solve(self, lecture_index):
        self.stats['placement_attempts'] += 1
        if self.stats['backtrack_count'] > self.stats['max_backtracks']:
            return False # Safety break

        # Base case: all lectures placed
        if lecture_index == len(self.master_lecture_list):
            return True

        current_lecture = self.master_lecture_list[lecture_index]

        # Shuffle timeslots and rooms for randomness
        shuffled_timeslots = self.timeslots.copy()
        random.shuffle(shuffled_timeslots)
        
        # Heuristic: Sort rooms by capacity (Best Fit) to optimize room usage
        # Filter rooms that satisfy static constraints (capacity, type)
        candidate_rooms = [
            r for r in self.rooms 
            if r['capacity'] >= current_lecture.group_size 
            and (not current_lecture.requires_room_type or r['type'] == current_lecture.requires_room_type)
        ]
        # Sort by capacity (ascending) to use smallest suitable room first
        # Add random noise to sort order to prevent deterministic loops in retries
        candidate_rooms.sort(key=lambda r: (r['capacity'], random.random()))

        for timeslot in shuffled_timeslots:
            for room in candidate_rooms:
                if self.is_valid(current_lecture, timeslot, room):
                    # Place
                    self.place_lecture(lecture_index, timeslot, room)

                    # Recurse
                    if self.solve(lecture_index + 1):
                        return True

                    # Backtrack
                    self.stats['backtrack_count'] += 1
                    self.unplace_lecture(lecture_index, timeslot, room)

        return False

    def generate_timetable(self):
        self.load_data()

        # --- Pre-validation checks with detailed errors ---
        if not self.teachers:
            error_details = TimetableError.get_error_details(TimetableError.NO_TEACHERS)
            return {
                'success': False,
                'error': error_details['message'],
                'error_code': TimetableError.NO_TEACHERS,
                'error_details': error_details
            }
        
        if not self.groups:
            error_details = TimetableError.get_error_details(TimetableError.NO_SECTIONS)
            return {
                'success': False,
                'error': error_details['message'],
                'error_code': TimetableError.NO_SECTIONS,
                'error_details': error_details
            }
        
        if not self.assignments:
            error_details = TimetableError.get_error_details(TimetableError.NO_ASSIGNMENTS)
            return {
                'success': False,
                'error': error_details['message'],
                'error_code': TimetableError.NO_ASSIGNMENTS,
                'error_details': error_details
            }
        
        if not self.timeslots:
            error_details = TimetableError.get_error_details(TimetableError.NO_TIMESLOTS)
            return {
                'success': False,
                'error': error_details['message'],
                'error_code': TimetableError.NO_TIMESLOTS,
                'error_details': error_details
            }
        
        if not self.rooms:
            error_details = TimetableError.get_error_details(TimetableError.NO_ROOMS)
            return {
                'success': False,
                'error': error_details['message'],
                'error_code': TimetableError.NO_ROOMS,
                'error_details': error_details
            }

        # --- Resource Validation ---
        # Check if every lecture has at least one valid room
        self.create_master_lecture_list() # Create list temporarily for validation
        for lecture in self.master_lecture_list:
            # Check room capacity
            suitable_rooms_by_capacity = [r for r in self.rooms if r['capacity'] >= lecture.group_size]
            if not suitable_rooms_by_capacity:
                context = {
                    'section_name': lecture.group_name,
                    'section_size': lecture.group_size,
                    'required_capacity': lecture.group_size
                }
                error_details = TimetableError.get_error_details(TimetableError.ROOM_CAPACITY_ISSUE, context)
                return {
                    'success': False,
                    'error': error_details['message'],
                    'error_code': TimetableError.ROOM_CAPACITY_ISSUE,
                    'error_details': error_details,
                    'context': context
                }
            
            # Check room type if required
            if lecture.requires_room_type:
                suitable_rooms_by_type = [r for r in suitable_rooms_by_capacity if r['type'] == lecture.requires_room_type]
                if not suitable_rooms_by_type:
                    context = {
                        'subject_name': lecture.subject_name,
                        'required_type': lecture.requires_room_type
                    }
                    error_details = TimetableError.get_error_details(TimetableError.ROOM_TYPE_ISSUE, context)
                    return {
                        'success': False,
                        'error': error_details['message'],
                        'error_code': TimetableError.ROOM_TYPE_ISSUE,
                        'error_details': error_details,
                        'context': context
                    }

        # Define phases for generation with different levels of strictness
        phases = [
            {'attempts': 3, 'max_repeats': 1, 'desc': 'Strict (1 of same subject/day)'},
            {'attempts': 4, 'max_repeats': 2, 'desc': 'Relaxed (up to 2 of same subject/day)'}
        ]
        
        total_attempt = 0
        
        for phase in phases:
            self.max_subject_repeats_per_day = phase['max_repeats']

            # --- Pre-validation for this phase ---
            subject_days_needed = {}
            for assignment in self.assignments:
                key = (assignment['section_id'], assignment['subject_id'])
                days_needed = (assignment['hours_per_week'] + self.max_subject_repeats_per_day - 1) // self.max_subject_repeats_per_day
                subject_days_needed[key] = max(subject_days_needed.get(key, 0), days_needed)
            
            max_days_needed = max(subject_days_needed.values()) if subject_days_needed else 0
            unique_days = len(set(t['day_of_week'] for t in self.timeslots))

            if max_days_needed > unique_days:
                print(f"Skipping phase '{phase['desc']}' because it's impossible: needs {max_days_needed} days, but only {unique_days} are available.")
                continue # Skip to next phase if this one is impossible
            
            for i in range(phase['attempts']):
                total_attempt += 1
                print(f"Starting generation attempt {total_attempt} ({phase['desc']})...")
                
                # Reset state for new attempt
                self.create_master_lecture_list()
                self.initialize_hash_maps()
                self.sort_lectures_by_difficulty()
                self.stats = {**self.stats, 'backtrack_count': 0, 'placement_attempts': 0, 'attempt_number': total_attempt}
                random.seed(int(time.time() * 1000) + total_attempt)

                start_time = time.time()
                
                if self.solve(0):
                    end_time = time.time()
                    self.stats['generation_time_seconds'] = round(end_time - start_time, 2)
                    
                    msg = f"Timetable generated successfully on attempt {total_attempt}"
                    if self.max_subject_repeats_per_day > 1:
                        msg += f" (Note: Allowed up to {self.max_subject_repeats_per_day} lectures of the same subject per day)"

                    formatted_timetable = self.format_timetable()
                    return {
                        'success': True,
                        'timetable': formatted_timetable,
                        'message': msg,
                        'stats': self.stats
                    }
        
        # If all attempts fail
        unique_days = len(set(t['day_of_week'] for t in self.timeslots))
        diagnostics = (
            f"{len(self.master_lecture_list)} lectures to schedule, "
            f"{len(self.timeslots)} timeslots, {len(self.rooms)} rooms, "
            f"{unique_days} unique days. Possible issues: (1) Subject repetition constraints are too strict, "
            "(2) Teacher availability conflicts, (3) Room capacity/type constraints, or "
            "(4) Insufficient timeslots for the number of lectures."
        )
        
        # Get detailed error information
        error_context = {
            'total_lectures': len(self.master_lecture_list),
            'total_timeslots': len(self.timeslots),
            'total_rooms': len(self.rooms),
            'unique_days': unique_days,
            'message': diagnostics
        }
        error_details = TimetableError.get_error_details(TimetableError.GENERATION_FAILED, error_context)
        
        return {
            'success': False,
            'error': f'No valid timetable could be generated after {total_attempt} attempts. {diagnostics}',
            'error_code': TimetableError.GENERATION_FAILED,
            'error_details': error_details,
            'context': error_context,
            'stats': self.stats
        }

    def format_timetable(self):
        formatted = {}

        for lecture_index, (timeslot_id, room_id) in self.solution.items():
            lecture = self.master_lecture_list[lecture_index]
            timeslot = next((t for t in self.timeslots if t['timeslot_id'] == timeslot_id), None)
            room = next((r for r in self.rooms if r['room_id'] == room_id), None)

            if timeslot and room:
                day = timeslot['day_of_week']
                if day not in formatted:
                    formatted[day] = {}

                slot_key = f"{timeslot['start_time']}-{timeslot['end_time']}"
                if slot_key not in formatted[day]:
                    formatted[day][slot_key] = {}

                formatted[day][slot_key][room['name']] = {
                    'teacher': lecture.teacher_name,
                    'subject': lecture.subject_name,
                    'group': lecture.group_name,
                    'room_type': room['type']
                }

        return formatted

    def save_timetable(self):
        if not self.solution:
            return False

        conn = get_db_connection()
        cursor = conn.cursor()

        try:
            # Clear existing timetable
            cursor.execute("DELETE FROM timetable_slots")

            # Insert new timetable
            for lecture_index, (timeslot_id, room_id) in self.solution.items():
                lecture = self.master_lecture_list[lecture_index]
                cursor.execute("""
                    INSERT INTO timetable_slots
                    (timeslot_id, room_id, teacher_id, subject_id, section_id)
                    VALUES (%s, %s, %s, %s, %s)
                """, (timeslot_id, room_id, lecture.teacher_id,
                      lecture.subject_id, lecture.section_id))

            conn.commit()
            return True

        except Exception as e:
            conn.rollback()
            print(f"Error saving timetable: {e}")
            return False
        finally:
            cursor.close()
            conn.close()

# Backward compatibility
class FixedTimetableGenerator(AdvancedTimetableGenerator):
    pass

# Test the advanced generator
if __name__ == "__main__":
    g = AdvancedTimetableGenerator()
    result = g.generate_timetable()
    print('Success:', result.get('success'))
    if not result.get('success'):
        print('Error:', result.get('error'))
    else:
        print('Timetable generated successfully!')
        print('Number of scheduled lectures:', len(g.solution))
        # Save to database
        if g.save_timetable():
            print('Timetable saved to database successfully!')
        else:
            print('Failed to save timetable to database.')

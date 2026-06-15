import os
from functools import wraps

import bcrypt
from flask import (
    Flask, jsonify, redirect, request, send_from_directory, session, url_for
)
from werkzeug.utils import secure_filename
from flask_cors import CORS

from backend.db_config import get_db_connection

app = Flask(__name__, static_folder='frontend', static_url_path='')
app.secret_key = os.environ.get('SECRET_KEY', 'your-secret-key-change-in-production')
CORS(app)  # Enable CORS for all routes

# Helper function to execute queries
def execute_query(query, params=None, fetch=False):
    """Execute database query."""
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query, params or ())
        if fetch:
            result = cursor.fetchall()
        else:
            conn.commit()
            result = cursor.lastrowid
        return result
    except Exception as e:
        if conn:
            conn.rollback()
        raise e
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# Role-based access decorator
def role_required(*allowed_roles):
    """Decorator for role-based access control."""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'role' not in session:
                return jsonify({'error': 'Authentication required'}), 401
            if session['role'] not in allowed_roles:
                return jsonify({'error': 'Access denied'}), 403
            return f(*args, **kwargs)
        return decorated_function
    return decorator

# TEACHERS ENDPOINTS
@app.route('/api/teachers', methods=['GET'])
@role_required('coordinator', 'admin')
def get_teachers():
    """Get all teachers."""
    try:
        teachers = execute_query("SELECT * FROM teachers", fetch=True)
        return jsonify(teachers)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/teachers/<int:teacher_id>', methods=['GET'])
@role_required('coordinator', 'admin')
def get_teacher(teacher_id):
    try:
        teacher = execute_query("SELECT * FROM teachers WHERE teacher_id = %s", (teacher_id,), fetch=True)
        if teacher:
            return jsonify(teacher[0])
        return jsonify({'error': 'Teacher not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/teachers', methods=['POST'])
@role_required('admin')
def create_teacher():
    data = request.get_json()
    try:
        teacher_id = execute_query(
            "INSERT INTO teachers (user_id, name, email) VALUES (%s, %s, %s)",
            (data.get('user_id'), data['name'], data['email'])
        )
        return jsonify({'teacher_id': teacher_id, 'message': 'Teacher created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/teachers/<int:teacher_id>', methods=['PUT'])
@role_required('admin')
def update_teacher(teacher_id):
    data = request.get_json()
    try:
        execute_query(
            "UPDATE teachers SET user_id = %s, name = %s, email = %s WHERE teacher_id = %s",
            (data.get('user_id'), data['name'], data['email'], teacher_id)
        )
        return jsonify({'message': 'Teacher updated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/teachers/<int:teacher_id>', methods=['DELETE'])
@role_required('admin')
def delete_teacher(teacher_id):
    try:
        execute_query("DELETE FROM teachers WHERE teacher_id = %s", (teacher_id,))
        return jsonify({'message': 'Teacher deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ROOMS ENDPOINTS
@app.route('/api/rooms', methods=['GET'])
@role_required('coordinator', 'admin')
def get_rooms():
    try:
        rooms = execute_query("SELECT * FROM rooms", fetch=True)
        return jsonify(rooms)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/rooms/<int:room_id>', methods=['GET'])
@role_required('coordinator', 'admin')
def get_room(room_id):
    try:
        room = execute_query("SELECT * FROM rooms WHERE room_id = %s", (room_id,), fetch=True)
        if room:
            return jsonify(room[0])
        return jsonify({'error': 'Room not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/rooms', methods=['POST'])
@role_required('admin')
def create_room():
    data = request.get_json()
    try:
        room_id = execute_query(
            "INSERT INTO rooms (name, capacity, type) VALUES (%s, %s, %s)",
            (data['name'], data['capacity'], data['type'])
        )
        return jsonify({'room_id': room_id, 'message': 'Room created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/rooms/<int:room_id>', methods=['PUT'])
@role_required('admin')
def update_room(room_id):
    data = request.get_json()
    try:
        execute_query(
            "UPDATE rooms SET name = %s, capacity = %s, type = %s WHERE room_id = %s",
            (data['name'], data['capacity'], data['type'], room_id)
        )
        return jsonify({'message': 'Room updated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/rooms/<int:room_id>', methods=['DELETE'])
@role_required('admin')
def delete_room(room_id):
    try:
        execute_query("DELETE FROM rooms WHERE room_id = %s", (room_id,))
        return jsonify({'message': 'Room deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# SUBJECTS ENDPOINTS
@app.route('/api/subjects', methods=['GET'])
@role_required('coordinator', 'admin')
def get_subjects():
    try:
        subjects = execute_query("SELECT * FROM subjects", fetch=True)
        return jsonify(subjects)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/subjects/<int:subject_id>', methods=['GET'])
@role_required('coordinator', 'admin')
def get_subject(subject_id):
    try:
        subject = execute_query("SELECT * FROM subjects WHERE subject_id = %s", (subject_id,), fetch=True)
        if subject:
            return jsonify(subject[0])
        return jsonify({'error': 'Subject not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/subjects', methods=['POST'])
@role_required('admin')
def create_subject():
    data = request.get_json()
    try:
        subject_id = execute_query(
            "INSERT INTO subjects (name, requires_room_type) VALUES (%s, %s)",
            (data['name'], data.get('requires_room_type'))
        )
        return jsonify({'subject_id': subject_id, 'message': 'Subject created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/subjects/<int:subject_id>', methods=['PUT'])
@role_required('admin')
def update_subject(subject_id):
    data = request.get_json()
    try:
        execute_query(
            "UPDATE subjects SET name = %s, requires_room_type = %s WHERE subject_id = %s",
            (data['name'], data.get('requires_room_type'), subject_id)
        )
        return jsonify({'message': 'Subject updated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/subjects/<int:subject_id>', methods=['DELETE'])
@role_required('admin')
def delete_subject(subject_id):
    try:
        execute_query("DELETE FROM subjects WHERE subject_id = %s", (subject_id,))
        return jsonify({'message': 'Subject deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# PROGRAMS ENDPOINTS
@app.route('/api/programs', methods=['GET'])
@role_required('coordinator', 'admin')
def get_programs():
    try:
        programs = execute_query("SELECT * FROM programs", fetch=True)
        return jsonify(programs)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/programs/<int:program_id>', methods=['GET'])
@role_required('coordinator', 'admin')
def get_program(program_id):
    try:
        program = execute_query("SELECT * FROM programs WHERE program_id = %s", (program_id,), fetch=True)
        if program:
            return jsonify(program[0])
        return jsonify({'error': 'Program not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/programs', methods=['POST'])
@role_required('admin')
def create_program():
    data = request.get_json()
    try:
        program_id = execute_query(
            "INSERT INTO programs (name) VALUES (%s)",
            (data['name'],)
        )
        return jsonify({'program_id': program_id, 'message': 'Program created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/programs/<int:program_id>', methods=['PUT'])
@role_required('admin')
def update_program(program_id):
    data = request.get_json()
    try:
        execute_query(
            "UPDATE programs SET name = %s WHERE program_id = %s",
            (data['name'], program_id)
        )
        return jsonify({'message': 'Program updated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/programs/<int:program_id>', methods=['DELETE'])
@role_required('admin')
def delete_program(program_id):
    try:
        execute_query("DELETE FROM programs WHERE program_id = %s", (program_id,))
        return jsonify({'message': 'Program deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# SECTIONS ENDPOINTS
@app.route('/api/sections', methods=['GET'])
@role_required('coordinator', 'admin')
def get_sections():
    try:
        sections = execute_query("""
            SELECT s.*, p.name as program_name
            FROM sections s
            JOIN programs p ON s.program_id = p.program_id
        """, fetch=True)
        return jsonify(sections)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/sections/<int:section_id>', methods=['GET'])
@role_required('coordinator', 'admin')
def get_section(section_id):
    try:
        section = execute_query("""
            SELECT s.*, p.name as program_name
            FROM sections s
            JOIN programs p ON s.program_id = p.program_id
            WHERE s.section_id = %s
        """, (section_id,), fetch=True)
        if section:
            return jsonify(section[0])
        return jsonify({'error': 'Section not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/sections', methods=['POST'])
@role_required('admin')
def create_section():
    data = request.get_json()
    try:
        # Check for duplicate section: same program_id, year, and section_name
        existing = execute_query(
            "SELECT section_id FROM sections WHERE program_id = %s AND year = %s AND section_name = %s",
            (data['program_id'], data['year'], data['section_name']), fetch=True
        )
        if existing:
            return jsonify({'error': 'A section with this name already exists for the selected program and year'}), 400

        section_id = execute_query(
            "INSERT INTO sections (program_id, year, section_name, size) VALUES (%s, %s, %s, %s)",
            (data['program_id'], data['year'], data['section_name'], data['size'])
        )
        return jsonify({'section_id': section_id, 'message': 'Section created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/sections/<int:section_id>', methods=['PUT'])
@role_required('admin')
def update_section(section_id):
    data = request.get_json()
    try:
        execute_query(
            "UPDATE sections SET program_id = %s, year = %s, section_name = %s, size = %s WHERE section_id = %s",
            (data['program_id'], data['year'], data['section_name'], data['size'], section_id)
        )
        return jsonify({'message': 'Section updated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/sections/<int:section_id>', methods=['DELETE'])
@role_required('admin')
def delete_section(section_id):
    try:
        execute_query("DELETE FROM sections WHERE section_id = %s", (section_id,))
        return jsonify({'message': 'Section deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500



# SESSION TYPES ENDPOINTS
@app.route('/api/session_types', methods=['GET'])
@role_required('coordinator', 'admin')
def get_session_types():
    try:
        session_types = execute_query("SELECT * FROM session_types ORDER BY name", fetch=True)
        return jsonify(session_types)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/session_types/<int:session_type_id>', methods=['GET'])
@role_required('coordinator', 'admin')
def get_session_type(session_type_id):
    try:
        session_type = execute_query("SELECT * FROM session_types WHERE session_type_id = %s", (session_type_id,), fetch=True)
        if session_type:
            return jsonify(session_type[0])
        return jsonify({'error': 'Session type not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/session_types', methods=['POST'])
@role_required('admin')
def create_session_type():
    data = request.get_json()
    try:
        # Check for duplicate session type name
        existing = execute_query(
            "SELECT session_type_id FROM session_types WHERE name = %s",
            (data['name'],), fetch=True
        )
        if existing:
            return jsonify({'error': 'A session type with this name already exists'}), 400

        session_type_id = execute_query(
            "INSERT INTO session_types (name, description, color) VALUES (%s, %s, %s)",
            (data['name'], data.get('description'), data.get('color', '#007bff'))
        )
        return jsonify({'session_type_id': session_type_id, 'message': 'Session type created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/session_types/<int:session_type_id>', methods=['PUT'])
@role_required('admin')
def update_session_type(session_type_id):
    data = request.get_json()
    try:
        execute_query(
            "UPDATE session_types SET name = %s, description = %s, color = %s WHERE session_type_id = %s",
            (data['name'], data.get('description'), data.get('color', '#007bff'), session_type_id)
        )
        return jsonify({'message': 'Session type updated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/session_types/<int:session_type_id>', methods=['DELETE'])
@role_required('admin')
def delete_session_type(session_type_id):
    try:
        execute_query("DELETE FROM session_types WHERE session_type_id = %s", (session_type_id,))
        return jsonify({'message': 'Session type deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# TIMESLOTS ENDPOINTS
@app.route('/api/timeslots', methods=['GET'])
@role_required('coordinator', 'admin')
def get_timeslots():
    try:
        timeslots = execute_query("""
            SELECT t.timeslot_id, t.day_of_week, TIME_FORMAT(t.start_time, '%H:%i') as start_time,
                   TIME_FORMAT(t.end_time, '%H:%i') as end_time, t.session_type_id,
                   st.name as session_type_name, st.color as session_type_color
            FROM timeslots t
            LEFT JOIN session_types st ON t.session_type_id = st.session_type_id
            ORDER BY FIELD(t.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), 
                     t.start_time, t.end_time
        """, fetch=True)
        return jsonify(timeslots)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timeslots/<int:timeslot_id>', methods=['GET'])
@role_required('coordinator', 'admin')
def get_timeslot(timeslot_id):
    try:
        timeslot = execute_query("SELECT * FROM timeslots WHERE timeslot_id = %s", (timeslot_id,), fetch=True)
        if timeslot:
            return jsonify(timeslot[0])
        return jsonify({'error': 'Timeslot not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timeslots', methods=['POST'])
@role_required('admin')
def create_timeslot():
    data = request.get_json()
    try:
        # Check for duplicate timeslot: same day_of_week, start_time, and end_time
        existing = execute_query(
            "SELECT timeslot_id FROM timeslots WHERE day_of_week = %s AND start_time = %s AND end_time = %s",
            (data['day_of_week'], data['start_time'], data['end_time']), fetch=True
        )
        if existing:
            return jsonify({'error': 'A timeslot with this day, start time, and end time already exists'}), 400

        timeslot_id = execute_query(
            "INSERT INTO timeslots (day_of_week, start_time, end_time, session_type_id) VALUES (%s, %s, %s, %s)",
            (data['day_of_week'], data['start_time'], data['end_time'], data.get('session_type_id'))
        )
        return jsonify({'timeslot_id': timeslot_id, 'message': 'Timeslot created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timeslots/<int:timeslot_id>', methods=['PUT'])
@role_required('admin')
def update_timeslot(timeslot_id):
    data = request.get_json()
    try:
        execute_query(
            "UPDATE timeslots SET day_of_week = %s, start_time = %s, end_time = %s, session_type_id = %s WHERE timeslot_id = %s",
            (data['day_of_week'], data['start_time'], data['end_time'], data.get('session_type_id'), timeslot_id)
        )
        return jsonify({'message': 'Timeslot updated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timeslots/<int:timeslot_id>', methods=['DELETE'])
@role_required('admin', 'coordinator')
def delete_timeslot(timeslot_id):
    try:
        # Check if timeslot is used in timetable
        used = execute_query(
            "SELECT COUNT(*) as count FROM timetable_slots WHERE timeslot_id = %s",
            (timeslot_id,), fetch=True
        )
        
        if used and used[0]['count'] > 0:
            return jsonify({
                'error': f'Cannot delete timeslot: It is used in {used[0]["count"]} timetable slot(s). Delete timetable slots first.'
            }), 400
        
        execute_query("DELETE FROM timeslots WHERE timeslot_id = %s", (timeslot_id,))
        return jsonify({'message': 'Timeslot deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Bulk delete timeslots
@app.route('/api/timeslots/bulk-delete', methods=['POST'])
@role_required('admin', 'coordinator')
def bulk_delete_timeslots():
    try:
        data = request.get_json()
        timeslot_ids = data.get('timeslot_ids', [])
        
        if not timeslot_ids:
            return jsonify({'error': 'No timeslot IDs provided'}), 400
        
        # Check which timeslots are in use
        placeholders = ','.join(['%s'] * len(timeslot_ids))
        used_query = f"""
            SELECT timeslot_id, COUNT(*) as count 
            FROM timetable_slots 
            WHERE timeslot_id IN ({placeholders})
            GROUP BY timeslot_id
        """
        used = execute_query(used_query, tuple(timeslot_ids), fetch=True)
        
        if used:
            used_ids = [str(u['timeslot_id']) for u in used]
            return jsonify({
                'error': f'Cannot delete timeslots: Some are in use',
                'used_timeslots': used_ids,
                'details': used
            }), 400
        
        # Delete timeslots
        delete_query = f"DELETE FROM timeslots WHERE timeslot_id IN ({placeholders})"
        execute_query(delete_query, tuple(timeslot_ids))
        
        return jsonify({
            'message': f'Successfully deleted {len(timeslot_ids)} timeslot(s)',
            'deleted_count': len(timeslot_ids)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Delete timeslots by day
@app.route('/api/timeslots/delete-by-day', methods=['POST'])
@role_required('admin', 'coordinator')
def delete_timeslots_by_day():
    try:
        data = request.get_json()
        day_of_week = data.get('day_of_week')
        
        if not day_of_week:
            return jsonify({'error': 'Day of week is required'}), 400
        
        # Check if any timeslots for this day are in use
        used = execute_query(
            """SELECT COUNT(*) as count 
               FROM timetable_slots ts
               JOIN timeslots t ON ts.timeslot_id = t.timeslot_id
               WHERE t.day_of_week = %s""",
            (day_of_week,), fetch=True
        )
        
        if used and used[0]['count'] > 0:
            return jsonify({
                'error': f'Cannot delete timeslots: {used[0]["count"]} timetable slot(s) use timeslots for {day_of_week}. Delete timetable slots first.'
            }), 400
        
        # Get count before deletion
        count_res = execute_query("SELECT COUNT(*) as count FROM timeslots WHERE day_of_week = %s", (day_of_week,), fetch=True)
        count = count_res[0]['count'] if count_res else 0

        # Delete timeslots for the day
        execute_query(
            "DELETE FROM timeslots WHERE day_of_week = %s",
            (day_of_week,)
        )
        
        return jsonify({
            'message': f'Successfully deleted all timeslots for {day_of_week}',
            'deleted_count': count
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Delete all timeslots (with confirmation)
@app.route('/api/timeslots/delete-all', methods=['POST'])
@role_required('admin', 'coordinator')
def delete_all_timeslots():
    try:
        data = request.get_json()
        confirm = data.get('confirm', False)
        
        if not confirm:
            return jsonify({'error': 'Confirmation required. Set confirm=true'}), 400
        
        # Check if any timeslots are in use
        used = execute_query(
            "SELECT COUNT(*) as count FROM timetable_slots",
            fetch=True
        )
        
        if used and used[0]['count'] > 0:
            return jsonify({
                'error': f'Cannot delete all timeslots: {used[0]["count"]} timetable slot(s) exist. Delete timetable first.'
            }), 400
        
        # Delete all timeslots
        execute_query("DELETE FROM timeslots")
        
        return jsonify({
            'message': 'All timeslots deleted successfully'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timeslots/generate-structure', methods=['POST'])
@role_required('admin', 'coordinator')
def generate_timeslot_structure():
    data = request.get_json()
    try:
        # Extract parameters
        day_start_time = data.get('day_start_time')  # e.g., '09:00'
        day_end_time = data.get('day_end_time')  # e.g., '17:00'
        lecture_duration = int(data.get('lecture_duration', 60))  # in minutes
        break_duration = int(data.get('break_duration', 10))  # in minutes
        
        if lecture_duration <= 0:
            return jsonify({'error': 'Lecture duration must be positive'}), 400
            
        lunch_start = data.get('lunch_start')  # e.g., '12:00'
        lunch_end = data.get('lunch_end')  # e.g., '13:00'
        clear_existing = data.get('clear_existing', False)  # Whether to clear existing timeslots
        # Allow user to specify days, default to Mon-Fri
        days = data.get('days', ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'])
        
        # Ensure times are in HH:MM format
        def normalize_time(time_str):
            """Normalize time string to HH:MM format"""
            if ':' in time_str:
                parts = time_str.split(':')
                return f"{parts[0].zfill(2)}:{parts[1].zfill(2)}"
            return time_str
        
        day_start_time = normalize_time(day_start_time)
        day_end_time = normalize_time(day_end_time)
        lunch_start = normalize_time(lunch_start)
        lunch_end = normalize_time(lunch_end)
        
        # Validate inputs
        if not all([day_start_time, day_end_time, lunch_start, lunch_end]):
            return jsonify({'error': 'All time fields are required'}), 400
        
        # Parse times
        def time_to_minutes(time_str):
            """Convert HH:MM to minutes since midnight"""
            parts = time_str.split(':')
            return int(parts[0]) * 60 + int(parts[1])
        
        def minutes_to_time(minutes):
            """Convert minutes since midnight to HH:MM"""
            hours = minutes // 60
            mins = minutes % 60
            return f"{hours:02d}:{mins:02d}"
        
        start_minutes = time_to_minutes(day_start_time)
        end_minutes = time_to_minutes(day_end_time)
        lunch_start_minutes = time_to_minutes(lunch_start)
        lunch_end_minutes = time_to_minutes(lunch_end)
        
        # Validate lunch break is within day
        if lunch_start_minutes < start_minutes or lunch_end_minutes > end_minutes:
            return jsonify({'error': 'Lunch break must be within the day time range'}), 400
        
        if lunch_start_minutes >= lunch_end_minutes:
            return jsonify({'error': 'Lunch break end time must be after start time'}), 400
        
        # Clear existing timeslots if requested
        if clear_existing:
            execute_query("DELETE FROM timeslots")
        
        # Get lunch break session type ID if it exists
        lunch_session_type = execute_query(
            "SELECT session_type_id FROM session_types WHERE LOWER(name) LIKE '%lunch%' OR LOWER(name) LIKE '%break%' LIMIT 1",
            fetch=True
        )
        lunch_session_type_id = lunch_session_type[0]['session_type_id'] if lunch_session_type else None
        
        # Generate timeslots for each day
        timeslots_created = 0
        for day in days:
            current_time = start_minutes
            lunch_created = False  # Track if lunch break has been created for this day
            
            while current_time < end_minutes:
                # Check if we need to create lunch break
                if not lunch_created and current_time >= lunch_start_minutes:
                    # Create lunch break timeslot
                    # Ensure lunch times are in proper format
                    lunch_start_formatted = lunch_start if len(lunch_start) >= 8 else lunch_start + ':00'
                    lunch_end_formatted = lunch_end if len(lunch_end) >= 8 else lunch_end + ':00'
                    
                    existing_lunch = execute_query(
                        "SELECT timeslot_id FROM timeslots WHERE day_of_week = %s AND start_time = %s AND end_time = %s",
                        (day, lunch_start_formatted, lunch_end_formatted), fetch=True
                    )
                    if not existing_lunch:
                        execute_query(
                            "INSERT INTO timeslots (day_of_week, start_time, end_time, session_type_id) VALUES (%s, %s, %s, %s)",
                            (day, lunch_start_formatted, lunch_end_formatted, lunch_session_type_id)
                        )
                        timeslots_created += 1
                    lunch_created = True
                    current_time = lunch_end_minutes
                    continue
                
                # Skip if we're in lunch break period
                if lunch_start_minutes <= current_time < lunch_end_minutes:
                    current_time = lunch_end_minutes
                    continue
                
                # Create lecture timeslot
                slot_end_time = current_time + lecture_duration
                
                # Don't create slot if it would extend beyond end time
                if slot_end_time > end_minutes:
                    break
                
                # Don't create slot if it would overlap with lunch
                if current_time < lunch_start_minutes and slot_end_time > lunch_start_minutes:
                    # Adjust to end before lunch
                    slot_end_time = lunch_start_minutes
                
                if slot_end_time <= current_time:
                    break
                
                start_time_str = minutes_to_time(current_time)
                end_time_str = minutes_to_time(slot_end_time)
                
                # Ensure times are in proper format (HH:MM:SS)
                if len(start_time_str) == 5:  # HH:MM
                    start_time_str += ':00'
                if len(end_time_str) == 5:  # HH:MM
                    end_time_str += ':00'
                
                # Check if timeslot already exists
                existing = execute_query(
                    "SELECT timeslot_id FROM timeslots WHERE day_of_week = %s AND start_time = %s AND end_time = %s",
                    (day, start_time_str, end_time_str), fetch=True
                )
                
                if not existing:
                    execute_query(
                        "INSERT INTO timeslots (day_of_week, start_time, end_time) VALUES (%s, %s, %s)",
                        (day, start_time_str, end_time_str)
                    )
                    timeslots_created += 1
                
                # Move to next slot (add break duration after lecture)
                current_time = slot_end_time + break_duration
        
        return jsonify({
            'message': f'Timeslot structure generated successfully',
            'timeslots_created': timeslots_created,
            'days_processed': len(days)
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# SUBJECT ASSIGNMENTS ENDPOINTS
@app.route('/api/subject_assignments', methods=['GET'])
@role_required('coordinator', 'admin')
def get_subject_assignments():
    try:
        # Get filter parameters from request arguments
        program_id = request.args.get('program_id')
        teacher_id = request.args.get('teacher_id')
        year = request.args.get('year')

        query = """
            SELECT sa.*, t.name as teacher_name, 
                   s.name as subject_name, s.code as subject_code,
                   sec.section_name as group_name, sec.size as group_size, sec.year,
                   p.name as program_name, p.short_code as program_code
            FROM subject_assignments sa
            JOIN teachers t ON sa.teacher_id = t.teacher_id
            JOIN subjects s ON sa.subject_id = s.subject_id
            JOIN sections sec ON sa.section_id = sec.section_id
            JOIN programs p ON sec.program_id = p.program_id
        """
        
        conditions = []
        params = []

        if program_id:
            conditions.append("p.program_id = %s")
            params.append(program_id)
        
        if year:
            conditions.append("sec.year = %s")
            params.append(year)
        
        if teacher_id:
            conditions.append("sa.teacher_id = %s")
            params.append(teacher_id)

        if conditions:
            query += " WHERE " + " AND ".join(conditions)

        query += " ORDER BY p.name, sec.year, sec.section_name, s.name"

        assignments = execute_query(query, tuple(params), fetch=True)
        return jsonify(assignments)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/subject_assignments/<int:assign_id>', methods=['GET'])
@role_required('coordinator', 'admin')
def get_subject_assignment(assign_id):
    try:
        assignment = execute_query("""
            SELECT sa.*, t.name as teacher_name, 
                   s.name as subject_name, s.code as subject_code,
                   sec.section_name as group_name, sec.size as group_size, sec.year,
                   p.name as program_name, p.short_code as program_code
            FROM subject_assignments sa
            JOIN teachers t ON sa.teacher_id = t.teacher_id
            JOIN subjects s ON sa.subject_id = s.subject_id
            JOIN sections sec ON sa.section_id = sec.section_id
            JOIN programs p ON sec.program_id = p.program_id
            WHERE sa.assign_id = %s
        """, (assign_id,), fetch=True)
        if assignment:
            return jsonify(assignment[0])
        return jsonify({'error': 'Subject assignment not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/subject_assignments', methods=['POST'])
@role_required('coordinator', 'admin')
def create_subject_assignment():
    data = request.get_json()
    try:
        # Check for duplicate assignment: same subject_id, teacher_id, and section_id
        existing = execute_query(
            "SELECT assign_id FROM subject_assignments WHERE subject_id = %s AND teacher_id = %s AND section_id = %s",
            (data['subject_id'], data['teacher_id'], data['section_id']), fetch=True
        )
        if existing:
            return jsonify({'error': 'This subject is already assigned to the selected teacher and section'}), 400

        assign_id = execute_query(
            "INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week) VALUES (%s, %s, %s, %s)",
            (data['subject_id'], data['teacher_id'], data['section_id'], data['hours_per_week'])
        )
        return jsonify({'assign_id': assign_id, 'message': 'Subject assignment created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/subject_assignments/<int:assign_id>', methods=['PUT'])
@role_required('coordinator', 'admin')
def update_subject_assignment(assign_id):
    data = request.get_json()
    try:
        execute_query(
            "UPDATE subject_assignments SET subject_id = %s, teacher_id = %s, section_id = %s, hours_per_week = %s WHERE assign_id = %s",
            (data['subject_id'], data['teacher_id'], data['section_id'], data['hours_per_week'], assign_id)
        )
        return jsonify({'message': 'Subject assignment updated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/subject_assignments/<int:assign_id>', methods=['DELETE'])
@role_required('coordinator', 'admin')
def delete_subject_assignment(assign_id):
    try:
        execute_query("DELETE FROM subject_assignments WHERE assign_id = %s", (assign_id,))
        return jsonify({'message': 'Subject assignment deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Authentication routes
@app.route('/login')
def login_page():
    return send_from_directory('frontend', 'login.html')

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    role = data.get('role')

    try:
        # Get user from database
        user = execute_query(
            "SELECT user_id, username, password, role FROM users WHERE username = %s AND role = %s",
            (username, role), fetch=True
        )

        if not user:
            return jsonify({'error': 'Invalid credentials'}), 401

        user = user[0]

        # Check password using bcrypt
        if not bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
            return jsonify({'error': 'Invalid credentials'}), 401

        # Set session
        session['user_id'] = user['user_id']
        session['username'] = user['username']
        session['role'] = user['role']

        return jsonify({
            'message': 'Login successful',
            'role': user['role'],
            'username': user['username']
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/check-session')
def check_session():
    if 'role' in session:
        return jsonify({
            'authenticated': True,
            'role': session['role'],
            'username': session['username']
        })
    return jsonify({'authenticated': False}), 401

@app.route('/logout')
def logout():
    session.clear()
    return redirect('/login')

# Static file serving
@app.route('/')
def index():
    if 'role' not in session:
        return redirect('/login')
    return send_from_directory('frontend', 'index.html')

@app.route('/<path:path>')
def static_files(path):
    return send_from_directory('frontend', path)

# Timetable generation endpoint
@app.route('/api/generate', methods=['POST'])
@role_required('coordinator', 'admin')
def generate_timetable():
    try:
        from backend.test_generator import AdvancedTimetableGenerator

        # Check for existing timetable
        existing_slots = execute_query("SELECT COUNT(*) as count FROM timetable_slots", fetch=True)
        
        # Get overwrite flag from request body
        data = request.get_json() or {}
        overwrite = data.get('overwrite', False)

        if existing_slots and existing_slots[0]['count'] > 0 and not overwrite:
            return jsonify({
                'error': 'A timetable already exists. Overwrite?',
                'conflict': 'existing_timetable'
            }), 409

        generator = AdvancedTimetableGenerator()
        result = generator.generate_timetable()

        if result.get('success'):
            # Save to database
            if generator.save_timetable():
                return jsonify({
                    'message': result.get('message', 'Timetable generated and saved successfully'),
                    'stats': result.get('stats', {})
                }), 200
            else:
                return jsonify({
                    'error': 'Timetable generated but failed to save',
                    'stats': result.get('stats', {})
                }), 500
        else:
            # Return detailed error information
            response_data = {
                'error': result.get('error', 'Generation failed'),
                'stats': result.get('stats', {}),
                'success': False
            }
            
            # Include detailed error information if available
            if result.get('error_code'):
                response_data['error_code'] = result.get('error_code')
            
            if result.get('error_details'):
                response_data['error_details'] = result.get('error_details')
            
            if result.get('context'):
                response_data['context'] = result.get('context')
            
            return jsonify(response_data), 400

    except Exception as e:
        import traceback
        return jsonify({'error': f'Generation error: {str(e)}', 'traceback': traceback.format_exc()}), 500

# Get generated timetable
@app.route('/api/timetable', methods=['GET'])
def get_timetable():
    """
    DEPRECATED: This endpoint mixes data and presentation logic. 
    A modern frontend should use /api/timetable-view to get raw data 
    and handle rendering on the client-side.
    """
    section_id = request.args.get('section_id')
    teacher_id = request.args.get('teacher_id')
    room_id = request.args.get('room_id')
    try:
        # Get all timeslots for the days (including breaks) - properly ordered
        all_timeslots_query = """
            SELECT ts.timeslot_id, ts.day_of_week, TIME_FORMAT(ts.start_time, '%H:%i') as start_time, 
                   TIME_FORMAT(ts.end_time, '%H:%i') as end_time, 
                   ts.session_type_id, st.name as session_type_name
            FROM timeslots ts
            LEFT JOIN session_types st ON ts.session_type_id = st.session_type_id
            ORDER BY FIELD(ts.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), 
                     ts.start_time, ts.end_time
        """
        all_timeslots = execute_query(all_timeslots_query, fetch=True)
        
        # Get scheduled timetable entries
        query = """
            SELECT gt.*, t.name as teacher_name, s.name as subject_name,
                   sec.section_name as group_name, r.name as room_name,
                   ts.start_time, ts.end_time, ts.day_of_week,
                   p.name as program_name, sec.year
            FROM timetable_slots gt
            JOIN teachers t ON gt.teacher_id = t.teacher_id
            JOIN subjects s ON gt.subject_id = s.subject_id
            JOIN sections sec ON gt.section_id = sec.section_id
            JOIN programs p ON sec.program_id = p.program_id
            JOIN rooms r ON gt.room_id = r.room_id
            JOIN timeslots ts ON gt.timeslot_id = ts.timeslot_id
        """
        conditions = []
        params = []
        
        if section_id:
            conditions.append("gt.section_id = %s")
            params.append(section_id)
        if teacher_id:
            conditions.append("gt.teacher_id = %s")
            params.append(teacher_id)
        if room_id:
            conditions.append("gt.room_id = %s")
            params.append(room_id)
            
        if conditions:
            query += " WHERE " + " AND ".join(conditions)

        query += " ORDER BY FIELD(ts.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), ts.start_time, r.name"

        scheduled_entries = execute_query(query, tuple(params), fetch=True)

        # Create a map of scheduled entries by timeslot_id and section_id
        scheduled_map = {}
        for entry in scheduled_entries:
            # Map by timeslot_id. Since we are filtering by a specific entity (section, teacher, or room),
            # that entity can only be in one place at a time, so timeslot_id is unique.
            scheduled_map[entry['timeslot_id']] = entry

        # Format for frontend - include all timeslots (scheduled and breaks)
        # Always show the structure, even if no class is selected or no timetable exists
        formatted = {}
        
        # Initialize all days with empty arrays to ensure structure is always shown
        days_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        for day in days_order:
            formatted[day] = []
        
        for timeslot in all_timeslots:
            day = timeslot['day_of_week']
            if day not in formatted:
                formatted[day] = []

            slot_key = f"{timeslot['start_time']}-{timeslot['end_time']}"
            
            # Check if this is a break/lunch timeslot
            is_break = False
            if timeslot['session_type_id'] and timeslot.get('session_type_name'):
                name = timeslot['session_type_name'].lower()
                if 'break' in name or 'lunch' in name:
                    is_break = True
            
            if is_break:
                # This is a break timeslot - always show it
                formatted[day].append({
                    'timeslot': slot_key,
                    'is_break': True,
                    'break_type': timeslot.get('session_type_name', 'Break')
                })
            else:
                # This is a regular timeslot - check if it has scheduled entries
                entry = scheduled_map.get(timeslot['timeslot_id'])
                
                if (section_id or teacher_id or room_id) and entry:
                    formatted[day].append({
                        'timeslot': slot_key,
                        'room': entry['room_name'],
                        'teacher': entry['teacher_name'],
                        'subject': entry['subject_name'],
                        'group': f"{entry['program_name']} - {entry['group_name']} (Year {entry['year']})"
                    })
                else:
                    # Empty slot or no filter selected - show structure
                    formatted[day].append({
                        'timeslot': slot_key,
                        'is_empty': True
                    })

        return jsonify(formatted)

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timetable-view', methods=['GET'])
@role_required('coordinator', 'admin', 'teacher', 'student')
def get_timetable_view():
    """
    Provides raw data for rendering the timetable on the frontend.
    This is preferred over the deprecated /api/timetable endpoint.
    """
    section_id = request.args.get('section_id')
    teacher_id = request.args.get('teacher_id')
    room_id = request.args.get('room_id')
    try:
        # 1. Get all timeslots (the grid structure)
        all_timeslots = execute_query("""
            SELECT ts.timeslot_id, ts.day_of_week, TIME_FORMAT(ts.start_time, '%H:%i') as start_time, 
                   TIME_FORMAT(ts.end_time, '%H:%i') as end_time, 
                   ts.session_type_id, st.name as session_type_name, st.color as session_type_color
            FROM timeslots ts
            LEFT JOIN session_types st ON ts.session_type_id = st.session_type_id
            ORDER BY FIELD(ts.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), 
                     ts.start_time, ts.end_time
        """, fetch=True)

        # 2. Get scheduled events based on filter
        query = """
            SELECT gt.slot_id, gt.timeslot_id, gt.room_id, gt.teacher_id, gt.section_id,
                   t.name as teacher_name, s.name as subject_name,
                   sec.section_name as group_name, r.name as room_name,
                   p.name as program_name, sec.year
            FROM timetable_slots gt
            JOIN teachers t ON gt.teacher_id = t.teacher_id
            JOIN subjects s ON gt.subject_id = s.subject_id
            JOIN sections sec ON gt.section_id = sec.section_id
            JOIN programs p ON sec.program_id = p.program_id
            JOIN rooms r ON gt.room_id = r.room_id
        """
        conditions = []
        params = []
        
        if section_id:
            conditions.append("gt.section_id = %s")
            params.append(section_id)
        if teacher_id:
            conditions.append("gt.teacher_id = %s")
            params.append(teacher_id)
        if room_id:
            conditions.append("gt.room_id = %s")
            params.append(room_id)
            
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        scheduled_slots = execute_query(query, tuple(params), fetch=True)

        return jsonify({
            'timeslots': all_timeslots,
            'scheduled_slots': scheduled_slots or [] # Ensure it's always a list
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Delete timetable endpoint
@app.route('/api/timetable', methods=['DELETE'])
@role_required('coordinator', 'admin')
def delete_timetable():
    try:
        # Get filter parameters
        section_id = request.args.get('section_id', type=int)
        teacher_id = request.args.get('teacher_id', type=int)
        room_id = request.args.get('room_id', type=int)
        day_of_week = request.args.get('day_of_week')
        
        # Build query based on filters
        if section_id or teacher_id or room_id or day_of_week:
            # Delete filtered timetable slots
            query = "DELETE ts FROM timetable_slots ts"
            conditions = []
            params = []
            
            if section_id:
                conditions.append("ts.section_id = %s")
                params.append(section_id)
            
            if teacher_id:
                conditions.append("ts.teacher_id = %s")
                params.append(teacher_id)
            
            if room_id:
                conditions.append("ts.room_id = %s")
                params.append(room_id)
            
            if day_of_week:
                query += " JOIN timeslots t ON ts.timeslot_id = t.timeslot_id"
                conditions.append("t.day_of_week = %s")
                params.append(day_of_week)
            
            if conditions:
                query += " WHERE " + " AND ".join(conditions)
                execute_query(query, tuple(params))
                
                message = "Filtered timetable slots deleted successfully"
                if section_id:
                    message += f" (Section ID: {section_id})"
                if teacher_id:
                    message += f" (Teacher ID: {teacher_id})"
                if room_id:
                    message += f" (Room ID: {room_id})"
                if day_of_week:
                    message += f" (Day: {day_of_week})"
                
                return jsonify({'message': message}), 200
        else:
            # Delete all records from timetable_slots table
            execute_query("DELETE FROM timetable_slots")
            return jsonify({'message': 'All timetable slots deleted successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Delete timetable by section
@app.route('/api/timetable/section/<int:section_id>', methods=['DELETE'])
@role_required('coordinator', 'admin')
def delete_timetable_by_section(section_id):
    try:
        # Get count before deletion
        count = execute_query(
            "SELECT COUNT(*) as count FROM timetable_slots WHERE section_id = %s",
            (section_id,), fetch=True
        )
        slot_count = count[0]['count'] if count else 0
        
        if slot_count == 0:
            return jsonify({'message': 'No timetable slots found for this section'}), 200
        
        # Delete timetable slots for this section
        execute_query("DELETE FROM timetable_slots WHERE section_id = %s", (section_id,))
        
        return jsonify({
            'message': f'Successfully deleted {slot_count} timetable slot(s) for section {section_id}',
            'deleted_count': slot_count
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Delete timetable by teacher
@app.route('/api/timetable/teacher/<int:teacher_id>', methods=['DELETE'])
@role_required('coordinator', 'admin')
def delete_timetable_by_teacher(teacher_id):
    try:
        # Get count before deletion
        count = execute_query(
            "SELECT COUNT(*) as count FROM timetable_slots WHERE teacher_id = %s",
            (teacher_id,), fetch=True
        )
        slot_count = count[0]['count'] if count else 0
        
        if slot_count == 0:
            return jsonify({'message': 'No timetable slots found for this teacher'}), 200
        
        # Delete timetable slots for this teacher
        execute_query("DELETE FROM timetable_slots WHERE teacher_id = %s", (teacher_id,))
        
        return jsonify({
            'message': f'Successfully deleted {slot_count} timetable slot(s) for teacher {teacher_id}',
            'deleted_count': slot_count
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Delete timetable by room
@app.route('/api/timetable/room/<int:room_id>', methods=['DELETE'])
@role_required('coordinator', 'admin')
def delete_timetable_by_room(room_id):
    try:
        # Get count before deletion
        count = execute_query(
            "SELECT COUNT(*) as count FROM timetable_slots WHERE room_id = %s",
            (room_id,), fetch=True
        )
        slot_count = count[0]['count'] if count else 0
        
        if slot_count == 0:
            return jsonify({'message': 'No timetable slots found for this room'}), 200
        
        # Delete timetable slots for this room
        execute_query("DELETE FROM timetable_slots WHERE room_id = %s", (room_id,))
        
        return jsonify({
            'message': f'Successfully deleted {slot_count} timetable slot(s) for room {room_id}',
            'deleted_count': slot_count
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Delete timetable by day
@app.route('/api/timetable/day/<day_of_week>', methods=['DELETE'])
@role_required('coordinator', 'admin')
def delete_timetable_by_day(day_of_week):
    try:
        # Get count before deletion
        count = execute_query(
            """SELECT COUNT(*) as count 
               FROM timetable_slots ts
               JOIN timeslots t ON ts.timeslot_id = t.timeslot_id
               WHERE t.day_of_week = %s""",
            (day_of_week,), fetch=True
        )
        slot_count = count[0]['count'] if count else 0
        
        if slot_count == 0:
            return jsonify({'message': f'No timetable slots found for {day_of_week}'}), 200
        
        # Delete timetable slots for this day
        execute_query(
            """DELETE ts FROM timetable_slots ts
               JOIN timeslots t ON ts.timeslot_id = t.timeslot_id
               WHERE t.day_of_week = %s""",
            (day_of_week,)
        )
        
        return jsonify({
            'message': f'Successfully deleted {slot_count} timetable slot(s) for {day_of_week}',
            'deleted_count': slot_count
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Bulk delete timetable slots
@app.route('/api/timetable/bulk-delete', methods=['POST'])
@role_required('coordinator', 'admin')
def bulk_delete_timetable_slots():
    try:
        data = request.get_json()
        slot_ids = data.get('slot_ids', [])
        
        if not slot_ids:
            return jsonify({'error': 'No slot IDs provided'}), 400
        
        # Delete slots
        placeholders = ','.join(['%s'] * len(slot_ids))
        delete_query = f"DELETE FROM timetable_slots WHERE slot_id IN ({placeholders})"
        execute_query(delete_query, tuple(slot_ids))
        
        return jsonify({
            'message': f'Successfully deleted {len(slot_ids)} timetable slot(s)',
            'deleted_count': len(slot_ids)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Get timetable statistics before deletion
@app.route('/api/timetable/stats', methods=['GET'])
@role_required('coordinator', 'admin')
def get_timetable_stats():
    try:
        stats = {}
        
        # Total slots
        total = execute_query("SELECT COUNT(*) as count FROM timetable_slots", fetch=True)
        stats['total_slots'] = total[0]['count'] if total else 0
        
        # By section
        by_section = execute_query(
            """SELECT s.section_id, s.section_name, p.name as program_name, 
                      COUNT(ts.slot_id) as slot_count
               FROM sections s
               LEFT JOIN timetable_slots ts ON s.section_id = ts.section_id
               LEFT JOIN programs p ON s.program_id = p.program_id
               GROUP BY s.section_id, s.section_name, p.name
               HAVING slot_count > 0
               ORDER BY slot_count DESC""",
            fetch=True
        )
        stats['by_section'] = by_section
        
        # By teacher
        by_teacher = execute_query(
            """SELECT t.teacher_id, t.name, COUNT(ts.slot_id) as slot_count
               FROM teachers t
               LEFT JOIN timetable_slots ts ON t.teacher_id = ts.teacher_id
               GROUP BY t.teacher_id, t.name
               HAVING slot_count > 0
               ORDER BY slot_count DESC""",
            fetch=True
        )
        stats['by_teacher'] = by_teacher
        
        # By day
        by_day = execute_query(
            """SELECT t.day_of_week, COUNT(ts.slot_id) as slot_count
               FROM timeslots t
               LEFT JOIN timetable_slots ts ON t.timeslot_id = ts.timeslot_id
               WHERE t.session_type_id IS NULL
               GROUP BY t.day_of_week
               HAVING slot_count > 0
               ORDER BY FIELD(t.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')""",
            fetch=True
        )
        stats['by_day'] = by_day
        
        # By room
        by_room = execute_query(
            """SELECT r.room_id, r.name, COUNT(ts.slot_id) as slot_count
               FROM rooms r
               LEFT JOIN timetable_slots ts ON r.room_id = ts.room_id
               GROUP BY r.room_id, r.name
               HAVING slot_count > 0
               ORDER BY slot_count DESC""",
            fetch=True
        )
        stats['by_room'] = by_room
        
        return jsonify(stats), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== NEW FEATURES ENDPOINTS ==========

# Conflict Detection Endpoints
@app.route('/api/conflicts', methods=['GET'])
@role_required('coordinator', 'admin')
def get_conflicts():
    try:
        from backend.conflict_detector import ConflictDetector
        
        version_id = request.args.get('version_id', type=int)
        detector = ConflictDetector()
        conflicts = detector.detect_all_conflicts(version_id)
        summary = detector.get_conflicts_summary()
        
        return jsonify({
            'conflicts': conflicts,
            'summary': summary
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/conflicts/<int:conflict_id>/resolve', methods=['POST'])
@role_required('coordinator', 'admin')
def resolve_conflict(conflict_id):
    try:
        execute_query(
            "UPDATE conflicts SET resolved = TRUE, resolved_at = NOW(), resolved_by = %s WHERE conflict_id = %s",
            (session.get('user_id'), conflict_id)
        )
        return jsonify({'message': 'Conflict resolved successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Export Endpoints
@app.route('/api/export/<format_type>', methods=['GET'])
@role_required('coordinator', 'admin', 'teacher', 'student')
def export_timetable(format_type):
    try:
        from backend.export_manager import ExportManager
        
        section_id = request.args.get('section_id', type=int)
        teacher_id = request.args.get('teacher_id', type=int)
        room_id = request.args.get('room_id', type=int)
        version_id = request.args.get('version_id', type=int)
        
        manager = ExportManager(export_dir='exports')
        
        if format_type.lower() == 'csv':
            filepath = manager.export_to_csv(section_id, teacher_id, room_id, version_id)
        elif format_type.lower() in ['excel', 'xlsx']:
            filepath = manager.export_to_excel(section_id, teacher_id, room_id, version_id)
        elif format_type.lower() in ['pdf']:
            filepath = manager.export_to_pdf(section_id, teacher_id, room_id, version_id)
        elif format_type.lower() in ['ical', 'ics']:
            filepath = manager.export_to_ical(section_id, teacher_id, room_id, version_id)
        else:
            return jsonify({'error': 'Invalid format type'}), 400
        
        # Return file for download
        filename = os.path.basename(filepath)
        return send_from_directory(manager.export_dir, filename, as_attachment=True)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Quality Metrics Endpoints
@app.route('/api/quality-metrics', methods=['GET'])
@role_required('coordinator', 'admin')
def get_quality_metrics():
    try:
        from backend.quality_metrics import QualityMetricsCalculator
        
        version_id = request.args.get('version_id', type=int)
        calculator = QualityMetricsCalculator()
        metrics = calculator.calculate_all_metrics(version_id)
        
        return jsonify(metrics)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Teacher Preferences Endpoints
@app.route('/api/teacher-preferences', methods=['GET'])
@role_required('coordinator', 'admin', 'teacher')
def get_teacher_preferences():
    teacher_id = request.args.get('teacher_id')
    try:
        query = "SELECT * FROM teacher_preferences"
        params = ()
        if teacher_id:
            query += " WHERE teacher_id = %s"
            params = (teacher_id,)
        preferences = execute_query(query, params, fetch=True)
        return jsonify(preferences)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/teacher-preferences', methods=['POST'])
@role_required('coordinator', 'admin', 'teacher')
def create_teacher_preference():
    data = request.get_json()
    try:
        pref_id = execute_query(
            "INSERT INTO teacher_preferences (teacher_id, day_of_week, start_time, end_time, preference_type, weight) VALUES (%s, %s, %s, %s, %s, %s)",
            (data['teacher_id'], data['day_of_week'], data['start_time'], data['end_time'], 
             data.get('preference_type', 'PREFERRED'), data.get('weight', 1))
        )
        return jsonify({'pref_id': pref_id, 'message': 'Preference created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/teacher-preferences/<int:pref_id>', methods=['DELETE'])
@role_required('coordinator', 'admin', 'teacher')
def delete_teacher_preference(pref_id):
    try:
        execute_query("DELETE FROM teacher_preferences WHERE pref_id = %s", (pref_id,))
        return jsonify({'message': 'Preference deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Timetable Versions Endpoints
@app.route('/api/timetable-versions', methods=['GET'])
@role_required('coordinator', 'admin')
def get_timetable_versions():
    try:
        versions = execute_query("SELECT * FROM timetable_versions ORDER BY created_at DESC", fetch=True)
        return jsonify(versions)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timetable-versions', methods=['POST'])
@role_required('coordinator', 'admin')
def create_timetable_version():
    data = request.get_json()
    try:
        version_id = execute_query(
            "INSERT INTO timetable_versions (name, description, created_by, semester_id) VALUES (%s, %s, %s, %s)",
            (data['name'], data.get('description'), session.get('user_id'), data.get('semester_id'))
        )
        return jsonify({'version_id': version_id, 'message': 'Version created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timetable-versions/<int:version_id>/activate', methods=['POST'])
@role_required('coordinator', 'admin')
def activate_timetable_version(version_id):
    try:
        # Deactivate all versions
        execute_query("UPDATE timetable_versions SET is_active = FALSE")
        # Activate selected version
        execute_query("UPDATE timetable_versions SET is_active = TRUE WHERE version_id = %s", (version_id,))
        return jsonify({'message': 'Version activated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Manual Timetable Editing Endpoints
@app.route('/api/timetable/slots/<int:slot_id>', methods=['PUT'])
@role_required('coordinator', 'admin')
def update_timetable_slot(slot_id):
    data = request.get_json()
    try:
        execute_query(
            "UPDATE timetable_slots SET timeslot_id = %s, room_id = %s, updated_by = %s, updated_at = NOW() WHERE slot_id = %s",
            (data.get('timeslot_id'), data.get('room_id'), session.get('user_id'), slot_id)
        )
        return jsonify({'message': 'Slot updated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timetable/slots', methods=['POST'])
@role_required('coordinator', 'admin')
def create_timetable_slot():
    data = request.get_json()
    try:
        slot_id = execute_query(
            "INSERT INTO timetable_slots (timeslot_id, subject_id, teacher_id, section_id, room_id, created_by) VALUES (%s, %s, %s, %s, %s, %s)",
            (data['timeslot_id'], data['subject_id'], data['teacher_id'], data['section_id'], data['room_id'], session.get('user_id'))
        )
        return jsonify({'slot_id': slot_id, 'message': 'Slot created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timetable/slots/<int:slot_id>', methods=['DELETE'])
@role_required('coordinator', 'admin')
def delete_timetable_slot(slot_id):
    try:
        execute_query("DELETE FROM timetable_slots WHERE slot_id = %s", (slot_id,))
        return jsonify({'message': 'Slot deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/timetable/swap', methods=['POST'])
@role_required('coordinator', 'admin')
def swap_timetable_slots():
    data = request.get_json()
    slot1_id = data.get('slot1_id')
    slot2_id = data.get('slot2_id')
    try:
        # Get current values
        slot1 = execute_query("SELECT timeslot_id, room_id FROM timetable_slots WHERE slot_id = %s", (slot1_id,), fetch=True)
        slot2 = execute_query("SELECT timeslot_id, room_id FROM timetable_slots WHERE slot_id = %s", (slot2_id,), fetch=True)
        
        if not slot1 or not slot2:
            return jsonify({'error': 'One or both slots not found'}), 404
        
        # Swap
        execute_query(
            "UPDATE timetable_slots SET timeslot_id = %s, room_id = %s, updated_by = %s, updated_at = NOW() WHERE slot_id = %s",
            (slot2[0]['timeslot_id'], slot2[0]['room_id'], session.get('user_id'), slot1_id)
        )
        execute_query(
            "UPDATE timetable_slots SET timeslot_id = %s, room_id = %s, updated_by = %s, updated_at = NOW() WHERE slot_id = %s",
            (slot1[0]['timeslot_id'], slot1[0]['room_id'], session.get('user_id'), slot2_id)
        )
        
        return jsonify({'message': 'Slots swapped successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Statistics and Analytics Endpoints
@app.route('/api/statistics/workload', methods=['GET'])
@role_required('coordinator', 'admin')
def get_workload_statistics():
    try:
        query = """
            SELECT t.teacher_id, t.name, COUNT(ts.slot_id) as total_classes,
                   COUNT(DISTINCT ts.subject_id) as subjects_count,
                   COUNT(DISTINCT ts.section_id) as sections_count
            FROM teachers t
            LEFT JOIN timetable_slots ts ON t.teacher_id = ts.teacher_id
            GROUP BY t.teacher_id, t.name
            ORDER BY total_classes DESC
        """
        stats = execute_query(query, fetch=True)
        return jsonify(stats)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/statistics/room-utilization', methods=['GET'])
@role_required('coordinator', 'admin')
def get_room_utilization():
    try:
        query = """
            SELECT r.room_id, r.name, r.capacity, r.type,
                   COUNT(ts.slot_id) as usage_count,
                   COUNT(DISTINCT ts.timeslot_id) as timeslots_used
            FROM rooms r
            LEFT JOIN timetable_slots ts ON r.room_id = ts.room_id
            GROUP BY r.room_id, r.name, r.capacity, r.type
            ORDER BY usage_count DESC
        """
        stats = execute_query(query, fetch=True)
        return jsonify(stats)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Change Requests Endpoints
@app.route('/api/change-requests', methods=['GET'])
@role_required('coordinator', 'admin', 'teacher')
def get_change_requests():
    try:
        user_id = session.get('user_id')
        role = session.get('role')
        
        if role in ['coordinator', 'admin']:
            requests = execute_query("SELECT * FROM change_requests ORDER BY created_at DESC", fetch=True)
        else:
            requests = execute_query(
                "SELECT * FROM change_requests WHERE requested_by = %s ORDER BY created_at DESC",
                (user_id,), fetch=True
            )
        return jsonify(requests)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/change-requests', methods=['POST'])
@role_required('teacher', 'coordinator', 'admin')
def create_change_request():
    data = request.get_json()
    try:
        request_id = execute_query(
            "INSERT INTO change_requests (requested_by, slot_id, requested_timeslot_id, requested_room_id, reason) VALUES (%s, %s, %s, %s, %s)",
            (session.get('user_id'), data['slot_id'], data.get('requested_timeslot_id'), 
             data.get('requested_room_id'), data.get('reason'))
        )
        return jsonify({'request_id': request_id, 'message': 'Change request created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/change-requests/<int:request_id>/approve', methods=['POST'])
@role_required('coordinator', 'admin')
def approve_change_request(request_id):
    try:
        # Get request details
        req = execute_query("SELECT * FROM change_requests WHERE request_id = %s", (request_id,), fetch=True)
        if not req:
            return jsonify({'error': 'Request not found'}), 404
        
        req = req[0]
        if req['status'] != 'PENDING':
            return jsonify({'error': 'Request is not pending'}), 400
        
        # Update slot
        if req['requested_timeslot_id'] or req['requested_room_id']:
            update_fields = []
            params = []
            
            if req['requested_timeslot_id']:
                update_fields.append("timeslot_id = %s")
                params.append(req['requested_timeslot_id'])
            
            if req['requested_room_id']:
                update_fields.append("room_id = %s")
                params.append(req['requested_room_id'])
            
            params.append(session.get('user_id'))
            params.append(req['slot_id'])
            
            execute_query(
                f"UPDATE timetable_slots SET {', '.join(update_fields)}, updated_by = %s, updated_at = NOW() WHERE slot_id = %s",
                tuple(params)
            )
        
        # Update request status
        execute_query(
            "UPDATE change_requests SET status = 'APPROVED', reviewed_by = %s, reviewed_at = NOW() WHERE request_id = %s",
            (session.get('user_id'), request_id)
        )
        
        return jsonify({'message': 'Change request approved successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Notifications Endpoints
@app.route('/api/notifications', methods=['GET'])
def get_notifications():
    try:
        user_id = session.get('user_id')
        if not user_id:
            return jsonify([]), 200
        
        unread_only = request.args.get('unread_only', 'false').lower() == 'true'
        
        query = "SELECT * FROM notifications WHERE user_id = %s"
        params = [user_id]
        
        if unread_only:
            query += " AND read = FALSE"
        
        query += " ORDER BY created_at DESC LIMIT 50"
        
        notifications = execute_query(query, tuple(params), fetch=True)
        # Ensure we always return a list
        if notifications is None:
            notifications = []
        return jsonify(notifications)
    except Exception as e:
        # Return empty array on error instead of error object
        return jsonify([]), 200

@app.route('/api/notifications/<int:notification_id>/read', methods=['POST'])
def mark_notification_read(notification_id):
    try:
        execute_query("UPDATE notifications SET read = TRUE WHERE notification_id = %s", (notification_id,))
        return jsonify({'message': 'Notification marked as read'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Academic Years/Semesters Endpoints
@app.route('/api/academic-years', methods=['GET'])
def get_academic_years():
    try:
        years = execute_query("SELECT * FROM academic_years ORDER BY start_date DESC", fetch=True)
        return jsonify(years)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/semesters', methods=['GET'])
def get_semesters():
    try:
        year_id = request.args.get('year_id', type=int)
        query = "SELECT * FROM semesters"
        params = ()
        if year_id:
            query += " WHERE year_id = %s"
            params = (year_id,)
        query += " ORDER BY start_date DESC"
        semesters = execute_query(query, params, fetch=True)
        return jsonify(semesters)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Bulk Operations Endpoints
@app.route('/api/bulk/import-teachers', methods=['POST'])
@role_required('admin', 'coordinator')
def bulk_import_teachers():
    try:
        from backend.bulk_operations import BulkOperations
        
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Save uploaded file
        upload_dir = 'uploads'
        if not os.path.exists(upload_dir):
            os.makedirs(upload_dir)
        
        filename = secure_filename(file.filename)
        filepath = os.path.join(upload_dir, filename)
        file.save(filepath)
        
        # Process import
        bulk_ops = BulkOperations()
        result = bulk_ops.bulk_import_teachers(filepath)
        
        # Clean up
        os.remove(filepath)
        
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/bulk/import-rooms', methods=['POST'])
@role_required('admin', 'coordinator')
def bulk_import_rooms():
    try:
        from backend.bulk_operations import BulkOperations
        
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        upload_dir = 'uploads'
        if not os.path.exists(upload_dir):
            os.makedirs(upload_dir)
        
        filename = secure_filename(file.filename)
        filepath = os.path.join(upload_dir, filename)
        file.save(filepath)
        
        bulk_ops = BulkOperations()
        result = bulk_ops.bulk_import_rooms(filepath)
        
        os.remove(filepath)
        
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/bulk/create-assignments', methods=['POST'])
@role_required('admin', 'coordinator')
def bulk_create_assignments():
    try:
        from backend.bulk_operations import BulkOperations
        
        data = request.get_json()
        assignments = data.get('assignments', [])
        
        if not assignments:
            return jsonify({'error': 'No assignments provided'}), 400
        
        bulk_ops = BulkOperations()
        result = bulk_ops.bulk_create_assignments(assignments)
        
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/bulk/update-slots', methods=['POST'])
@role_required('admin', 'coordinator')
def bulk_update_slots():
    try:
        from backend.bulk_operations import BulkOperations
        
        data = request.get_json()
        updates = data.get('updates', [])
        
        if not updates:
            return jsonify({'error': 'No updates provided'}), 400
        
        bulk_ops = BulkOperations()
        result = bulk_ops.bulk_update_timeslots(updates)
        
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/bulk/template/<template_type>', methods=['GET'])
@role_required('admin', 'coordinator')
def get_bulk_template(template_type):
    try:
        from backend.bulk_operations import BulkOperations
        
        bulk_ops = BulkOperations()
        filepath = bulk_ops.export_template(template_type, export_dir='exports')
        
        filename = os.path.basename(filepath)
        return send_from_directory('exports', filename, as_attachment=True)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)






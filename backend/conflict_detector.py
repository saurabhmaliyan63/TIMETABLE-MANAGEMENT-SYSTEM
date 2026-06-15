"""
Conflict Detection System for Timetable Generator.

Detects and reports various types of conflicts in the timetable.
"""

from datetime import datetime
from typing import Dict, List, Optional

from .db_config import get_db_connection

class ConflictDetector:
    def __init__(self):
        self.conflicts = []
    
    def detect_all_conflicts(self, version_id: Optional[int] = None) -> List[Dict]:
        """
        Detect all types of conflicts in the timetable
        Returns list of conflict dictionaries
        """
        self.conflicts = []
        
        # Load timetable data
        timetable_slots = self._load_timetable_slots(version_id)
        
        if not timetable_slots:
            return []
        
        # Detect different types of conflicts
        self._detect_teacher_conflicts(timetable_slots)
        self._detect_room_conflicts(timetable_slots)
        self._detect_section_conflicts(timetable_slots)
        self._detect_capacity_conflicts(timetable_slots)
        self._detect_availability_conflicts(timetable_slots)
        self._detect_preference_violations(timetable_slots)
        
        # Save conflicts to database
        self._save_conflicts_to_db()
        
        return self.conflicts
    
    def _load_timetable_slots(self, version_id: Optional[int] = None) -> List[Dict]:
        """Load timetable slots from database"""
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            if version_id:
                query = """
                    SELECT ts.*, t.timeslot_id, t.day_of_week, t.start_time, t.end_time,
                           r.capacity, r.type as room_type,
                           sec.size as section_size
                    FROM timetable_version_slots ts
                    JOIN timeslots t ON ts.timeslot_id = t.timeslot_id
                    JOIN rooms r ON ts.room_id = r.room_id
                    JOIN sections sec ON ts.section_id = sec.section_id
                    WHERE ts.version_id = %s
                """
                cursor.execute(query, (version_id,))
            else:
                query = """
                    SELECT ts.*, t.timeslot_id, t.day_of_week, t.start_time, t.end_time,
                           r.capacity, r.type as room_type,
                           sec.size as section_size
                    FROM timetable_slots ts
                    JOIN timeslots t ON ts.timeslot_id = t.timeslot_id
                    JOIN rooms r ON ts.room_id = r.room_id
                    JOIN sections sec ON ts.section_id = sec.section_id
                """
                cursor.execute(query)
            
            return cursor.fetchall()
        finally:
            cursor.close()
            conn.close()
    
    def _detect_teacher_conflicts(self, slots: List[Dict]):
        """Detect if a teacher is scheduled in multiple places at the same time"""
        teacher_schedule = {}  # {teacher_id: {timeslot_id: [slots]}}
        
        for slot in slots:
            teacher_id = slot['teacher_id']
            timeslot_id = slot['timeslot_id']
            
            if teacher_id not in teacher_schedule:
                teacher_schedule[teacher_id] = {}
            
            if timeslot_id not in teacher_schedule[teacher_id]:
                teacher_schedule[teacher_id][timeslot_id] = []
            
            teacher_schedule[teacher_id][timeslot_id].append(slot)
        
        # Find conflicts
        for teacher_id, timeslots in teacher_schedule.items():
            for timeslot_id, conflicting_slots in timeslots.items():
                if len(conflicting_slots) > 1:
                    for slot in conflicting_slots:
                        self.conflicts.append({
                            'type': 'TEACHER',
                            'severity': 'ERROR',
                            'slot_id': slot['slot_id'],
                            'description': f"Teacher scheduled in {len(conflicting_slots)} places at the same time ({slot['day_of_week']} {slot['start_time']})",
                            'details': {
                                'teacher_id': teacher_id,
                                'timeslot_id': timeslot_id,
                                'conflicting_slots': [s['slot_id'] for s in conflicting_slots]
                            }
                        })
    
    def _detect_room_conflicts(self, slots: List[Dict]):
        """Detect if a room is double-booked"""
        room_schedule = {}  # {room_id: {timeslot_id: [slots]}}
        
        for slot in slots:
            room_id = slot['room_id']
            timeslot_id = slot['timeslot_id']
            
            if room_id not in room_schedule:
                room_schedule[room_id] = {}
            
            if timeslot_id not in room_schedule[room_id]:
                room_schedule[room_id][timeslot_id] = []
            
            room_schedule[room_id][timeslot_id].append(slot)
        
        # Find conflicts
        for room_id, timeslots in room_schedule.items():
            for timeslot_id, conflicting_slots in timeslots.items():
                if len(conflicting_slots) > 1:
                    for slot in conflicting_slots:
                        self.conflicts.append({
                            'type': 'ROOM',
                            'severity': 'ERROR',
                            'slot_id': slot['slot_id'],
                            'description': f"Room double-booked: {len(conflicting_slots)} classes scheduled at the same time",
                            'details': {
                                'room_id': room_id,
                                'timeslot_id': timeslot_id,
                                'conflicting_slots': [s['slot_id'] for s in conflicting_slots]
                            }
                        })
    
    def _detect_section_conflicts(self, slots: List[Dict]):
        """Detect if a section is scheduled in multiple places at the same time"""
        section_schedule = {}  # {section_id: {timeslot_id: [slots]}}
        
        for slot in slots:
            section_id = slot['section_id']
            timeslot_id = slot['timeslot_id']
            
            if section_id not in section_schedule:
                section_schedule[section_id] = {}
            
            if timeslot_id not in section_schedule[section_id]:
                section_schedule[section_id][timeslot_id] = []
            
            section_schedule[section_id][timeslot_id].append(slot)
        
        # Find conflicts
        for section_id, timeslots in section_schedule.items():
            for timeslot_id, conflicting_slots in timeslots.items():
                if len(conflicting_slots) > 1:
                    for slot in conflicting_slots:
                        self.conflicts.append({
                            'type': 'SECTION',
                            'severity': 'ERROR',
                            'slot_id': slot['slot_id'],
                            'description': f"Section scheduled in {len(conflicting_slots)} places at the same time",
                            'details': {
                                'section_id': section_id,
                                'timeslot_id': timeslot_id,
                                'conflicting_slots': [s['slot_id'] for s in conflicting_slots]
                            }
                        })
    
    def _detect_capacity_conflicts(self, slots: List[Dict]):
        """Detect if room capacity is insufficient"""
        for slot in slots:
            if slot.get('capacity') and slot.get('section_size'):
                if slot['capacity'] < slot['section_size']:
                    self.conflicts.append({
                        'type': 'CAPACITY',
                        'severity': 'ERROR',
                        'slot_id': slot['slot_id'],
                        'description': f"Room capacity ({slot['capacity']}) is less than section size ({slot['section_size']})",
                        'details': {
                            'room_id': slot['room_id'],
                            'section_id': slot['section_id'],
                            'capacity': slot['capacity'],
                            'section_size': slot['section_size']
                        }
                    })
    
    def _detect_availability_conflicts(self, slots: List[Dict]):
        """Detect if teacher is scheduled outside their availability"""
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            # Get all teacher availability
            cursor.execute("SELECT * FROM teacher_availability")
            availability = cursor.fetchall()
            
            # Group by teacher
            teacher_availability = {}
            for avail in availability:
                teacher_id = avail['teacher_id']
                if teacher_id not in teacher_availability:
                    teacher_availability[teacher_id] = []
                teacher_availability[teacher_id].append(avail)
            
            # Check each slot
            for slot in slots:
                teacher_id = slot['teacher_id']
                if teacher_id in teacher_availability:
                    # Check if slot time is within any availability window
                    slot_day = slot['day_of_week']
                    slot_start = slot['start_time']
                    slot_end = slot['end_time']
                    
                    is_available = False
                    for avail in teacher_availability[teacher_id]:
                        if (avail['day_of_week'] == slot_day and
                            avail['start_time'] <= slot_start and
                            avail['end_time'] >= slot_end):
                            is_available = True
                            break
                    
                    if not is_available:
                        self.conflicts.append({
                            'type': 'AVAILABILITY',
                            'severity': 'WARNING',
                            'slot_id': slot['slot_id'],
                            'description': f"Teacher scheduled outside their availability window",
                            'details': {
                                'teacher_id': teacher_id,
                                'day': slot_day,
                                'time': f"{slot_start}-{slot_end}"
                            }
                        })
        finally:
            cursor.close()
            conn.close()
    
    def _detect_preference_violations(self, slots: List[Dict]):
        """Detect violations of teacher preferences"""
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            # Get all teacher preferences
            cursor.execute("""
                SELECT * FROM teacher_preferences 
                WHERE preference_type = 'AVOID' OR preference_type = 'BLOCKED'
            """)
            preferences = cursor.fetchall()
            
            # Group by teacher
            teacher_preferences = {}
            for pref in preferences:
                teacher_id = pref['teacher_id']
                if teacher_id not in teacher_preferences:
                    teacher_preferences[teacher_id] = []
                teacher_preferences[teacher_id].append(pref)
            
            # Check each slot
            for slot in slots:
                teacher_id = slot['teacher_id']
                if teacher_id in teacher_preferences:
                    slot_day = slot['day_of_week']
                    slot_start = slot['start_time']
                    slot_end = slot['end_time']
                    
                    for pref in teacher_preferences[teacher_id]:
                        if (pref['day_of_week'] == slot_day and
                            pref['start_time'] <= slot_start and
                            pref['end_time'] >= slot_end):
                            severity = 'ERROR' if pref['preference_type'] == 'BLOCKED' else 'WARNING'
                            self.conflicts.append({
                                'type': 'PREFERENCE',
                                'severity': severity,
                                'slot_id': slot['slot_id'],
                                'description': f"Teacher scheduled during {pref['preference_type'].lower()} time",
                                'details': {
                                    'teacher_id': teacher_id,
                                    'preference_id': pref['pref_id'],
                                    'preference_type': pref['preference_type']
                                }
                            })
        finally:
            cursor.close()
            conn.close()
    
    def _save_conflicts_to_db(self):
        """Save detected conflicts to database"""
        if not self.conflicts:
            return
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            # Clear existing unresolved conflicts
            cursor.execute("DELETE FROM conflicts WHERE resolved = FALSE")
            
            # Insert new conflicts
            for conflict in self.conflicts:
                cursor.execute("""
                    INSERT INTO conflicts 
                    (conflict_type, severity, slot_id, description, resolved)
                    VALUES (%s, %s, %s, %s, %s)
                """, (
                    conflict['type'],
                    conflict['severity'],
                    conflict['slot_id'],
                    conflict['description'],
                    False
                ))
            
            conn.commit()
        except Exception as e:
            conn.rollback()
            print(f"Error saving conflicts: {e}")
        finally:
            cursor.close()
            conn.close()
    
    def get_conflicts_summary(self) -> Dict:
        """Get summary of conflicts"""
        summary = {
            'total': len(self.conflicts),
            'by_type': {},
            'by_severity': {'ERROR': 0, 'WARNING': 0, 'INFO': 0}
        }
        
        for conflict in self.conflicts:
            # Count by type
            conflict_type = conflict['type']
            summary['by_type'][conflict_type] = summary['by_type'].get(conflict_type, 0) + 1
            
            # Count by severity
            severity = conflict['severity']
            summary['by_severity'][severity] = summary['by_severity'].get(severity, 0) + 1
        
        return summary


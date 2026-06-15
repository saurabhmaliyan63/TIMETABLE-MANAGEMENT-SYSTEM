"""
Bulk Operations Module for Timetable Generator.

Handles bulk imports, bulk assignments, and mass updates.
"""

import csv
import json
import os
from typing import Dict, List

from .db_config import get_db_connection

class BulkOperations:
    def __init__(self):
        self.errors = []
        self.success_count = 0
    
    def bulk_import_teachers(self, file_path: str) -> Dict:
        """
        Import teachers from CSV file
        Expected format: name,email
        """
        self.errors = []
        self.success_count = 0
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                
                conn = get_db_connection()
                cursor = conn.cursor()
                
                try:
                    for row_num, row in enumerate(reader, start=2):  # Start at 2 (header is row 1)
                        try:
                            name = row.get('name', '').strip()
                            email = row.get('email', '').strip()
                            
                            if not name or not email:
                                self.errors.append(f"Row {row_num}: Missing name or email")
                                continue
                            
                            # Insert teacher
                            cursor.execute(
                                "INSERT INTO teachers (name, email) VALUES (%s, %s)",
                                (name, email)
                            )
                            self.success_count += 1
                        except Exception as e:
                            self.errors.append(f"Row {row_num}: {str(e)}")
                    
                    conn.commit()
                except Exception as e:
                    conn.rollback()
                    raise e
                finally:
                    cursor.close()
                    conn.close()
            
            return {
                'success': len(self.errors) == 0,
                'success_count': self.success_count,
                'error_count': len(self.errors),
                'errors': self.errors
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'errors': self.errors
            }
    
    def bulk_import_rooms(self, file_path: str) -> Dict:
        """
        Import rooms from CSV file
        Expected format: name,capacity,type
        """
        self.errors = []
        self.success_count = 0
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                
                conn = get_db_connection()
                cursor = conn.cursor()
                
                try:
                    for row_num, row in enumerate(reader, start=2):
                        try:
                            name = row.get('name', '').strip()
                            capacity = int(row.get('capacity', 0))
                            room_type = row.get('type', 'LECTURE').strip().upper()
                            
                            if not name or capacity <= 0:
                                self.errors.append(f"Row {row_num}: Invalid data")
                                continue
                            
                            if room_type not in ['LECTURE', 'LAB']:
                                room_type = 'LECTURE'
                            
                            cursor.execute(
                                "INSERT INTO rooms (name, capacity, type) VALUES (%s, %s, %s)",
                                (name, capacity, room_type)
                            )
                            self.success_count += 1
                        except Exception as e:
                            self.errors.append(f"Row {row_num}: {str(e)}")
                    
                    conn.commit()
                except Exception as e:
                    conn.rollback()
                    raise e
                finally:
                    cursor.close()
                    conn.close()
            
            return {
                'success': len(self.errors) == 0,
                'success_count': self.success_count,
                'error_count': len(self.errors),
                'errors': self.errors
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'errors': self.errors
            }
    
    def bulk_create_assignments(self, assignments: List[Dict]) -> Dict:
        """
        Create multiple subject assignments at once
        assignments: List of dicts with keys: subject_id, teacher_id, section_id, hours_per_week
        """
        self.errors = []
        self.success_count = 0
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            for idx, assignment in enumerate(assignments):
                try:
                    subject_id = assignment.get('subject_id')
                    teacher_id = assignment.get('teacher_id')
                    section_id = assignment.get('section_id')
                    hours_per_week = assignment.get('hours_per_week')
                    
                    if not all([subject_id, teacher_id, section_id, hours_per_week]):
                        self.errors.append(f"Assignment {idx + 1}: Missing required fields")
                        continue
                    
                    # Check for duplicates
                    cursor.execute(
                        "SELECT assign_id FROM subject_assignments WHERE subject_id = %s AND teacher_id = %s AND section_id = %s",
                        (subject_id, teacher_id, section_id)
                    )
                    if cursor.fetchone():
                        self.errors.append(f"Assignment {idx + 1}: Duplicate assignment")
                        continue
                    
                    cursor.execute(
                        "INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week) VALUES (%s, %s, %s, %s)",
                        (subject_id, teacher_id, section_id, hours_per_week)
                    )
                    self.success_count += 1
                except Exception as e:
                    self.errors.append(f"Assignment {idx + 1}: {str(e)}")
            
            conn.commit()
        except Exception as e:
            conn.rollback()
            return {
                'success': False,
                'error': str(e),
                'errors': self.errors
            }
        finally:
            cursor.close()
            conn.close()
        
        return {
            'success': len(self.errors) == 0,
            'success_count': self.success_count,
            'error_count': len(self.errors),
            'errors': self.errors
        }
    
    def bulk_update_timeslots(self, updates: List[Dict]) -> Dict:
        """
        Update multiple timetable slots at once
        updates: List of dicts with keys: slot_id, timeslot_id (optional), room_id (optional)
        """
        self.errors = []
        self.success_count = 0
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            for idx, update in enumerate(updates):
                try:
                    slot_id = update.get('slot_id')
                    if not slot_id:
                        self.errors.append(f"Update {idx + 1}: Missing slot_id")
                        continue
                    
                    updates_list = []
                    params = []
                    
                    if 'timeslot_id' in update:
                        updates_list.append("timeslot_id = %s")
                        params.append(update['timeslot_id'])
                    
                    if 'room_id' in update:
                        updates_list.append("room_id = %s")
                        params.append(update['room_id'])
                    
                    if not updates_list:
                        self.errors.append(f"Update {idx + 1}: No fields to update")
                        continue
                    
                    params.append(slot_id)
                    
                    cursor.execute(
                        f"UPDATE timetable_slots SET {', '.join(updates_list)}, updated_at = NOW() WHERE slot_id = %s",
                        tuple(params)
                    )
                    self.success_count += 1
                except Exception as e:
                    self.errors.append(f"Update {idx + 1}: {str(e)}")
            
            conn.commit()
        except Exception as e:
            conn.rollback()
            return {
                'success': False,
                'error': str(e),
                'errors': self.errors
            }
        finally:
            cursor.close()
            conn.close()
        
        return {
            'success': len(self.errors) == 0,
            'success_count': self.success_count,
            'error_count': len(self.errors),
            'errors': self.errors
        }
    
    def export_template(self, template_type: str, export_dir: str = "../exports") -> str:
        """
        Export CSV template for bulk import
        template_type: 'teachers', 'rooms', 'assignments'
        export_dir: Directory to save the template (default: ../exports for backend, exports for root)
        """
        templates = {
            'teachers': ['name', 'email'],
            'rooms': ['name', 'capacity', 'type'],
            'assignments': ['subject_id', 'teacher_id', 'section_id', 'hours_per_week']
        }
        
        if template_type not in templates:
            raise ValueError(f"Unknown template type: {template_type}")
        
        filename = f"template_{template_type}.csv"
        filepath = os.path.join(export_dir, filename)
        
        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(templates[template_type])
            # Add example row
            if template_type == 'teachers':
                writer.writerow(['John Doe', 'john.doe@example.com'])
            elif template_type == 'rooms':
                writer.writerow(['Room 101', '50', 'LECTURE'])
            elif template_type == 'assignments':
                writer.writerow(['1', '1', '1', '3'])
        
        return filepath


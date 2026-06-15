"""
Quality Metrics Calculator for Timetable Generator.

Calculates various quality metrics for generated timetables.
"""

from collections import defaultdict
from typing import Dict, List, Optional

from .db_config import get_db_connection

class QualityMetricsCalculator:
    def __init__(self):
        self.metrics = {}
    
    def calculate_all_metrics(self, version_id: Optional[int] = None) -> Dict:
        """Calculate all quality metrics for a timetable"""
        slots = self._load_timetable_slots(version_id)
        
        if not slots:
            return {}
        
        self.metrics = {
            'load_balancing': self._calculate_load_balancing(slots),
            'teacher_workload': self._calculate_teacher_workload(slots),
            'room_utilization': self._calculate_room_utilization(slots),
            'gap_minimization': self._calculate_gap_minimization(slots),
            'preference_satisfaction': self._calculate_preference_satisfaction(slots),
            'overall_score': 0.0
        }
        
        # Calculate overall score (weighted average)
        weights = {
            'load_balancing': 0.2,
            'teacher_workload': 0.2,
            'room_utilization': 0.15,
            'gap_minimization': 0.15,
            'preference_satisfaction': 0.3
        }
        
        self.metrics['overall_score'] = sum(
            self.metrics[key] * weights[key] 
            for key in weights.keys()
        )
        
        # Save metrics to database
        self._save_metrics_to_db(version_id)
        
        return self.metrics
    
    def _load_timetable_slots(self, version_id: Optional[int] = None) -> List[Dict]:
        """Load timetable slots"""
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            if version_id:
                query = """
                    SELECT ts.*, t.day_of_week, t.start_time, t.end_time
                    FROM timetable_version_slots ts
                    JOIN timeslots t ON ts.timeslot_id = t.timeslot_id
                    WHERE ts.version_id = %s
                """
                cursor.execute(query, (version_id,))
            else:
                query = """
                    SELECT ts.*, t.day_of_week, t.start_time, t.end_time
                    FROM timetable_slots ts
                    JOIN timeslots t ON ts.timeslot_id = t.timeslot_id
                """
                cursor.execute(query)
            
            return cursor.fetchall()
        finally:
            cursor.close()
            conn.close()
    
    def _calculate_load_balancing(self, slots: List[Dict]) -> float:
        """
        Calculate how evenly classes are distributed across days
        Returns score 0-1 (1 = perfectly balanced)
        """
        # Count classes per day
        day_counts = defaultdict(int)
        for slot in slots:
            day_counts[slot['day_of_week']] += 1
        
        if not day_counts:
            return 0.0
        
        # Calculate variance
        counts = list(day_counts.values())
        mean = sum(counts) / len(counts)
        variance = sum((x - mean) ** 2 for x in counts) / len(counts)
        
        # Normalize to 0-1 (lower variance = better balance)
        max_variance = mean * len(counts)  # Theoretical maximum
        if max_variance == 0:
            return 1.0
        
        score = 1.0 - (variance / max_variance)
        return max(0.0, min(1.0, score))
    
    def _calculate_teacher_workload(self, slots: List[Dict]) -> float:
        """
        Calculate how evenly workload is distributed among teachers
        Returns score 0-1 (1 = perfectly balanced)
        """
        # Count classes per teacher
        teacher_counts = defaultdict(int)
        for slot in slots:
            if slot.get('teacher_id'):
                teacher_counts[slot['teacher_id']] += 1
        
        if not teacher_counts:
            return 0.0
        
        # Calculate variance
        counts = list(teacher_counts.values())
        mean = sum(counts) / len(counts)
        variance = sum((x - mean) ** 2 for x in counts) / len(counts)
        
        # Normalize to 0-1
        max_variance = mean * len(counts)
        if max_variance == 0:
            return 1.0
        
        score = 1.0 - (variance / max_variance)
        return max(0.0, min(1.0, score))
    
    def _calculate_room_utilization(self, slots: List[Dict]) -> float:
        """
        Calculate room utilization efficiency
        Returns score 0-1 (1 = optimal utilization)
        """
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            # Get all timeslots count
            cursor.execute("SELECT COUNT(*) as total FROM timeslots WHERE session_type_id IS NULL")
            total_slots = cursor.fetchone()['total']
            
            if total_slots == 0:
                return 0.0
            
            # Get all rooms
            cursor.execute("SELECT room_id FROM rooms")
            rooms = cursor.fetchall()
            total_rooms = len(rooms)
            
            if total_rooms == 0:
                return 0.0
            
            # Count used room-timeslot combinations
            used_combinations = set()
            for slot in slots:
                if slot.get('room_id') and slot.get('timeslot_id'):
                    used_combinations.add((slot['room_id'], slot['timeslot_id']))
            
            # Calculate utilization
            total_possible = total_slots * total_rooms
            utilization = len(used_combinations) / total_possible if total_possible > 0 else 0.0
            
            # Normalize (optimal utilization is around 60-80%, not 100%)
            # Score peaks at 70% utilization
            if utilization <= 0.7:
                score = utilization / 0.7
            else:
                score = 1.0 - ((utilization - 0.7) / 0.3)
            
            return max(0.0, min(1.0, score))
        finally:
            cursor.close()
            conn.close()
    
    def _calculate_gap_minimization(self, slots: List[Dict]) -> float:
        """
        Calculate how well gaps between classes are minimized
        Returns score 0-1 (1 = no gaps)
        """
        # Group slots by section and day
        section_day_slots = defaultdict(list)
        for slot in slots:
            if slot.get('section_id'):
                key = (slot['section_id'], slot['day_of_week'])
                section_day_slots[key].append(slot)
        
        if not section_day_slots:
            return 0.0
        
        total_gaps = 0
        total_days = 0
        
        for (section_id, day), day_slots in section_day_slots.items():
            if len(day_slots) < 2:
                continue
            
            # Sort by start time
            sorted_slots = sorted(day_slots, key=lambda x: x['start_time'])
            
            # Calculate gaps between consecutive classes
            for i in range(len(sorted_slots) - 1):
                current_end = sorted_slots[i]['end_time']
                next_start = sorted_slots[i + 1]['start_time']
                
                # Calculate gap in minutes
                gap_minutes = self._time_diff_minutes(current_end, next_start)
                if gap_minutes > 0:
                    total_gaps += gap_minutes
            
            total_days += 1
        
        if total_days == 0:
            return 1.0
        
        # Average gap per day
        avg_gap = total_gaps / total_days if total_days > 0 else 0
        
        # Score: smaller gaps = higher score
        # Optimal: 0-15 minutes gap (score = 1.0)
        # Penalize larger gaps
        if avg_gap <= 15:
            score = 1.0
        elif avg_gap <= 60:
            score = 1.0 - ((avg_gap - 15) / 45) * 0.5  # 0.5 to 1.0
        else:
            score = 0.5 - min(0.5, (avg_gap - 60) / 120)  # 0.0 to 0.5
        
        return max(0.0, min(1.0, score))
    
    def _calculate_preference_satisfaction(self, slots: List[Dict]) -> float:
        """
        Calculate how well teacher preferences are satisfied
        Returns score 0-1 (1 = all preferences satisfied)
        """
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            # Get all teacher preferences
            cursor.execute("SELECT * FROM teacher_preferences")
            preferences = cursor.fetchall()
            
            if not preferences:
                return 1.0  # No preferences = perfect score
            
            # Group preferences by teacher
            teacher_prefs = defaultdict(list)
            for pref in preferences:
                teacher_prefs[pref['teacher_id']].append(pref)
            
            total_score = 0.0
            total_weight = 0.0
            
            # Check each slot against preferences
            for slot in slots:
                teacher_id = slot.get('teacher_id')
                if not teacher_id or teacher_id not in teacher_prefs:
                    continue
                
                for pref in teacher_prefs[teacher_id]:
                    weight = pref.get('weight', 1)
                    total_weight += weight
                    
                    # Check if slot matches preference
                    if (pref['day_of_week'] == slot['day_of_week'] and
                        pref['start_time'] <= slot['start_time'] and
                        pref['end_time'] >= slot['end_time']):
                        
                        if pref['preference_type'] == 'PREFERRED':
                            total_score += weight  # Positive
                        elif pref['preference_type'] == 'AVOID':
                            total_score += weight * 0.3  # Partial penalty
                        elif pref['preference_type'] == 'BLOCKED':
                            total_score += 0  # Full penalty
            
            if total_weight == 0:
                return 1.0
            
            return max(0.0, min(1.0, total_score / total_weight))
        finally:
            cursor.close()
            conn.close()
    
    def _time_diff_minutes(self, time1, time2) -> int:
        """Calculate difference between two times in minutes"""
        t1 = int(str(time1).replace(':', ''))
        t2 = int(str(time2).replace(':', ''))
        
        h1, m1 = divmod(t1, 100)
        h2, m2 = divmod(t2, 100)
        
        minutes1 = h1 * 60 + m1
        minutes2 = h2 * 60 + m2
        
        return minutes2 - minutes1
    
    def _save_metrics_to_db(self, version_id: Optional[int]):
        """Save calculated metrics to database"""
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            for metric_name, metric_value in self.metrics.items():
                if metric_name == 'overall_score':
                    metric_type = 'OVERALL'
                else:
                    metric_type = metric_name.upper()
                
                # Determine status
                if metric_value >= 0.8:
                    status = 'PASS'
                elif metric_value >= 0.5:
                    status = 'WARNING'
                else:
                    status = 'FAIL'
                
                cursor.execute("""
                    INSERT INTO timetable_quality_metrics
                    (version_id, metric_type, metric_name, metric_value, status)
                    VALUES (%s, %s, %s, %s, %s)
                """, (version_id, metric_type, metric_name, metric_value, status))
            
            # Update version quality score
            if version_id:
                cursor.execute("""
                    UPDATE timetable_versions
                    SET quality_score = %s
                    WHERE version_id = %s
                """, (self.metrics['overall_score'], version_id))
            
            conn.commit()
        except Exception as e:
            conn.rollback()
            print(f"Error saving metrics: {e}")
        finally:
            cursor.close()
            conn.close()


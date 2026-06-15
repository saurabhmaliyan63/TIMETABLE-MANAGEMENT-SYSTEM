# Quick Start Guide - New Features

## ✅ All Features Are Ready!

Your database has been updated and all new features are integrated. Here's how to use them:

## 🚀 Quick Access

### 1. Conflict Detection
- **URL**: Navigate to "Conflicts" in the sidebar
- **API**: `GET /api/conflicts`
- **Features**:
  - Real-time conflict detection
  - Visual conflict indicators
  - Conflict resolution

### 2. Export Timetable
- **URL**: Go to "View Timetable" → Click export buttons
- **API**: `GET /api/export/{format}` (pdf, excel, csv, ical)
- **Formats Available**:
  - PDF - For printing
  - Excel - For editing
  - CSV - For data analysis
  - iCal - For calendar apps

### 3. Quality Metrics
- **URL**: Navigate to "Statistics" → "Quality Metrics" tab
- **API**: `GET /api/quality-metrics`
- **Metrics**:
  - Load Balancing
  - Teacher Workload
  - Room Utilization
  - Gap Minimization
  - Preference Satisfaction
  - Overall Score

### 4. Teacher Preferences
- **URL**: Navigate to "Preferences" in sidebar
- **API**: 
  - `GET /api/teacher-preferences`
  - `POST /api/teacher-preferences`
- **Features**:
  - Set preferred times
  - Set avoid times
  - Set blocked times
  - Weighted preferences

### 5. Statistics Dashboard
- **URL**: Navigate to "Statistics" in sidebar
- **API**: 
  - `GET /api/statistics/workload`
  - `GET /api/statistics/room-utilization`
- **Reports**:
  - Teacher workload analysis
  - Room utilization reports
  - Quality metrics

### 6. Manual Timetable Editing
- **URL**: Go to "View Timetable" → Click "Enable Editing"
- **Features**:
  - Click to select slots
  - Move slots
  - Swap slots
  - Delete slots

### 7. Notifications
- **URL**: Navigate to "Notifications" in sidebar
- **API**: `GET /api/notifications`
- **Features**:
  - View all notifications
  - Mark as read
  - Filter unread

### 8. Change Requests
- **URL**: Teachers can request changes
- **API**: 
  - `POST /api/change-requests`
  - `POST /api/change-requests/{id}/approve`
- **Workflow**:
  1. Teacher creates request
  2. Coordinator/Admin reviews
  3. Approve/Reject

### 9. Bulk Operations
- **API**: `/api/bulk/*`
- **Features**:
  - Bulk import teachers (CSV)
  - Bulk import rooms (CSV)
  - Bulk create assignments
  - Bulk update slots
  - Download CSV templates

## 📝 Example Usage

### Export Timetable as PDF
```javascript
// In browser console or JavaScript
fetch('/api/export/pdf?section_id=1')
  .then(response => response.blob())
  .then(blob => {
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'timetable.pdf';
    a.click();
  });
```

### Check Conflicts
```javascript
fetch('/api/conflicts')
  .then(response => response.json())
  .then(data => {
    console.log('Conflicts:', data.conflicts);
    console.log('Summary:', data.summary);
  });
```

### Get Quality Metrics
```javascript
fetch('/api/quality-metrics')
  .then(response => response.json())
  .then(metrics => {
    console.log('Overall Score:', metrics.overall_score);
    console.log('Load Balancing:', metrics.load_balancing);
  });
```

### Add Teacher Preference
```javascript
fetch('/api/teacher-preferences', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    teacher_id: 1,
    day_of_week: 'Monday',
    start_time: '09:00',
    end_time: '12:00',
    preference_type: 'PREFERRED',
    weight: 5
  })
});
```

## 🎯 Next Steps

1. **Test the Features**:
   - Generate a timetable
   - Check for conflicts
   - Export in different formats
   - View statistics

2. **Set Up Preferences**:
   - Add teacher preferences
   - Configure scheduling constraints

3. **Use Bulk Operations**:
   - Download CSV templates
   - Import teachers/rooms in bulk

4. **Monitor Quality**:
   - Check quality metrics after generation
   - Optimize based on scores

## 🔧 Troubleshooting

### If features don't appear:
1. Clear browser cache
2. Refresh the page
3. Check browser console for errors

### If API calls fail:
1. Check database connection
2. Verify user has proper role (admin/coordinator)
3. Check server logs

### If exports fail:
1. Ensure `exports/` directory exists and is writable
2. Check required libraries are installed:
   ```bash
   pip install openpyxl reportlab
   ```

## 📚 Documentation

- `FEATURES.md` - Complete feature list
- `SETUP_GUIDE.md` - Setup instructions
- `IMPLEMENTATION_SUMMARY.md` - What's implemented

## ✨ Enjoy Your Enhanced Timetable Generator!

All features are ready to use. Start by generating a timetable and exploring the new capabilities!





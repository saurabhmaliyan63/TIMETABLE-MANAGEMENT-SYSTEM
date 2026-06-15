- [x] Add Flask session management and bcrypt imports to app.py
- [x] Configure Flask app for sessions and secret key
- [x] Create /login route to serve login.html
- [x] Create /api/login POST endpoint for authentication
- [x] Create /logout route to clear session
- [x] Add role_required decorator for route protection
- [x] Protect existing API routes with role_required decorator
- [x] Modify / route to redirect to login if not authenticated

## Phase 2: Login UI
- [x] Create static/login.html with login form and role dropdown
- [x] Create static/js/login.js for login form handling
- [x] Update static/css/styles.css with login page styles

## Phase 3: Role-Based Dashboard
- [ ] Update static/index.html to check session and show role-specific content
- [ ] Add role-based navigation menu items
- [ ] Restrict UI elements based on user role
- [ ] Add logout button to dashboard

## Phase 4: Database Updates
- [ ] Update sample_data.sql to hash passwords with bcrypt
- [ ] Test login with sample users (admin, coordinator, teacher, student)

## Phase 5: Role-Specific Features (Future)
- [ ] Create teacher dashboard view
- [ ] Create student dashboard view
- [ ] Create admin panel
- [ ] Add profile management

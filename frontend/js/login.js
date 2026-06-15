document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.getElementById('login-form');
    const loginMessage = document.getElementById('login-message');
    const togglePasswordBtn = document.getElementById('toggle-password');
    const passwordInput = document.getElementById('password');

    // Toggle password visibility
    togglePasswordBtn.addEventListener('click', function() {
        const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
        passwordInput.setAttribute('type', type);

        // Update icon (eye open/closed)
        const svg = this.querySelector('svg');
        if (type === 'password') {
            // Show eye icon (visible)
            svg.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle>';
        } else {
            // Show eye-off icon (hidden)
            svg.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line>';
        }
    });

    loginForm.addEventListener('submit', async function(e) {
        e.preventDefault();

        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;
        const role = document.getElementById('role').value;

        // Clear previous messages
        loginMessage.textContent = '';
        loginMessage.className = 'login-message';

        try {
            const response = await fetch('/api/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    username: username,
                    password: password,
                    role: role
                })
            });

            const data = await response.json();

            if (response.ok) {
                loginMessage.textContent = 'Login successful! Redirecting...';
                loginMessage.className = 'login-message success';

                // Redirect to dashboard after successful login
                setTimeout(() => {
                    window.location.href = '/';
                }, 1000);
            } else {
                loginMessage.textContent = data.error || 'Login failed';
                loginMessage.className = 'login-message error';
            }
        } catch (error) {
            loginMessage.textContent = 'Network error. Please try again.';
            loginMessage.className = 'login-message error';
            console.error('Login error:', error);
        }
    });
});

import bcrypt

# Passwords from the task
passwords = {
    'admin': 'admin_pass123',
    'coordinator': 'coord_pass123',
    'prof_einstein': 'teacher_pass1',
    'prof_curie': 'teacher_pass2',
    'prof_turing': 'teacher_pass3',
    'prof_sharma': 'teacher_pass4',
    'prof_khan': 'teacher_pass5',
    'student_alice': 'student_pass1',
    'student_bob': 'student_pass2',
    'student_charlie': 'student_pass3',
    'student_dave': 'student_pass4',
    'student_eve': 'student_pass5',
    'student_frank': 'student_pass6',
    'student_grace': 'student_pass7',
    'student_heidi': 'student_pass8'
}


def hash_passwords():
    """Hash all passwords and return dictionary."""
    hashed_passwords = {}
    for username, password in passwords.items():
        hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        hashed_passwords[username] = hashed.decode('utf-8')
    return hashed_passwords


if __name__ == "__main__":
    # Hash each password
    hashed_passwords = hash_passwords()

    # Print the hashed passwords
    for username, hashed in hashed_passwords.items():
        print(f"'{username}': '{hashed}',")

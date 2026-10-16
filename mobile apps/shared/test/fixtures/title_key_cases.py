"""
Job titles and the search key each must give. Both implementations are checked on this list:
search_title_key() in SQL (supabase/migrations/step6g_titles_from_users.sql, what the collector searches)
and title_key() in backend/cv_ai.py (how the CV analysis avoids suggesting the same search twice).
None = not a job title: never searched.
"""

CASES = [
    ("Network Engineer", "network engineer"),
    ("  Senior   Network  Engineer ", "network engineer"),
    ("Sr. Accountant", "accountant"),
    ("Junior Senior Developer", "developer"),
    ("Entry Level Data Analyst", "data analyst"),
    ("Mid-Level QA Engineer", "qa engineer"),
    ("Network Engineer (CCNP)", "network engineer"),
    ("Data Analyst [Remote]", "data analyst"),
    ("Software Engineer - Backend", "software engineer"),
    ("IT Support | Help Desk", "it support"),
    ("Front-End Developer", "front-end developer"),
    ("Senior-Accountant", "senior-accountant"),
    (".NET Developer", ".net developer"),
    ("C++ Developer", "c++ developer"),
    ("UI/UX Designer", "ui/ux designer"),
    ("Accountant.", "accountant"),
    ("Staff Nurse", "staff nurse"),
    ("Ｎｅｔｗｏｒｋ Engineer", "network engineer"),
    ("محاسب", "محاسب"),
    ("مهندس شبكات", "مهندس شبكات"),
    ("Ingénieur réseau", "ingénieur réseau"),
    ("x", None),
    ("", None),
    ("   ", None),
    ("Senior", None),
    ("123", None),
    ("one two three four five six seven", None),
    ("a" * 61, None),
    ("buy followers at www.example.com", None),
    ("mail me: a@b.com", None),
    ("see https://example.com", None),
]

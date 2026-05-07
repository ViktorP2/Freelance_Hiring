BEGIN;

SET search_path TO freelancehub, public;

-- Optional if you want bcrypt-style hashing inside PostgreSQL later
-- CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- USERS
-- Using the same pre-hashed passwords from your old seed
-- =========================================================
INSERT INTO users (email, password_hash, role)
VALUES
    ('admin@freelancehub.com', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'admin'),
    ('company1@test.com',      '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'company'),
    ('freelancer1@test.com',   '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'freelancer')
ON CONFLICT (email) DO NOTHING;

-- =========================================================
-- COMPANY PROFILE
-- =========================================================
INSERT INTO company_profiles (user_id, company_name, website, description)
SELECT
    u.id,
    'TechCorp',
    'https://techcorp.com/careers',
    'Software company'
FROM users u
WHERE u.email = 'company1@test.com'
ON CONFLICT (user_id) DO NOTHING;

-- =========================================================
-- FREELANCER PROFILE
-- =========================================================
INSERT INTO freelancer_profiles (user_id, full_name, bio, skills_summary, portfolio_url)
SELECT
    u.id,
    'John Freelancer',
    'Frontend developer',
    'HTML, CSS, JavaScript, React',
    'https://portfolio.example.com/john-freelancer'
FROM users u
WHERE u.email = 'freelancer1@test.com'
ON CONFLICT (user_id) DO NOTHING;

-- =========================================================
-- JOBS
-- =========================================================
INSERT INTO jobs (company_user_id, title, description, salary_min, salary_max, category, website, status)
SELECT
    u.id,
    v.title,
    v.description,
    v.salary_min,
    v.salary_max,
    v.category,
    v.website,
    'open'
FROM users u
CROSS JOIN (
    VALUES
        ('Software Engineer', 'Build web apps and APIs.', 900.00::numeric, 1700.00::numeric, 'Web development', 'https://techcorp.com/careers'),
        ('Graphic Designer', 'Create stunning visuals for our brand.', 500.00::numeric, 1200.00::numeric, 'Design', 'https://designpro.com'),
        ('Digital Marketer', 'Drive online campaigns and growth.', 600.00::numeric, 1500.00::numeric, 'Marketing', 'https://marketgurus.com')
) AS v(title, description, salary_min, salary_max, category, website)
WHERE u.email = 'company1@test.com'
  AND NOT EXISTS (
      SELECT 1
      FROM jobs j
      WHERE j.company_user_id = u.id
        AND j.title = v.title
  );

-- =========================================================
-- JOB SKILLS
-- =========================================================
INSERT INTO job_skills (job_id, skill_name)
SELECT j.id, s.skill_name
FROM jobs j
JOIN users u
  ON u.id = j.company_user_id
JOIN (
    VALUES
        ('Software Engineer', 'JavaScript'),
        ('Software Engineer', 'Node.js'),
        ('Software Engineer', 'React'),
        ('Graphic Designer', 'Adobe Photoshop'),
        ('Graphic Designer', 'Illustrator'),
        ('Graphic Designer', 'Creativity'),
        ('Digital Marketer', 'SEO'),
        ('Digital Marketer', 'Google Ads'),
        ('Digital Marketer', 'Analytics')
) AS s(job_title, skill_name)
  ON s.job_title = j.title
WHERE u.email = 'company1@test.com'
ON CONFLICT (job_id, skill_name) DO NOTHING;

COMMIT;
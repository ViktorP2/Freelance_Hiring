USE freelancehub;

INSERT INTO users (email, password_hash, role) VALUES
('admin@freelancehub.com', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'admin'),
('company1@test.com', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'company'),
('freelancer1@test.com', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'freelancer');

INSERT INTO company_profiles (user_id, company_name, website, description) VALUES
(2, 'TechCorp', 'https://techcorp.com/careers', 'Software company');

INSERT INTO freelancer_profiles (user_id, full_name, bio) VALUES
(3, 'John Freelancer', 'Frontend developer');

INSERT INTO jobs (company_user_id, title, description, salary_min, salary_max, category, website) VALUES
(2, 'Software Engineer', 'Build web apps and APIs.', 900, 1700, 'Web development', 'https://techcorp.com/careers'),
(2, 'Graphic Designer', 'Create stunning visuals for our brand.', 500, 1200, 'Design', 'https://designpro.com'),
(2, 'Digital Marketer', 'Drive online campaigns and growth.', 600, 1500, 'Marketing', 'https://marketgurus.com');

INSERT INTO job_skills (job_id, skill_name) VALUES
(1, 'JavaScript'),
(1, 'Node.js'),
(1, 'React'),
(2, 'Adobe Photoshop'),
(2, 'Illustrator'),
(2, 'Creativity'),
(3, 'SEO'),
(3, 'Google Ads'),
(3, 'Analytics');
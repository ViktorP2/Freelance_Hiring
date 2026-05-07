BEGIN;

-- =========================================================
-- FREELANCEHUB - secure PostgreSQL schema
-- =========================================================

CREATE SCHEMA IF NOT EXISTS freelancehub;
SET search_path TO freelancehub, public;

CREATE EXTENSION IF NOT EXISTS citext;

-- ---------------------------------------------------------
-- Tables
-- ---------------------------------------------------------

CREATE TABLE IF NOT EXISTS users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email CITEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT users_role_check
        CHECK (role IN ('freelancer', 'company', 'admin')),
    CONSTRAINT users_email_format_check
        CHECK (email ~* '^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$'),
    CONSTRAINT users_password_hash_not_empty
        CHECK (length(trim(password_hash)) > 0)
);

CREATE TABLE IF NOT EXISTS freelancer_profiles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    bio TEXT,
    skills_summary TEXT,
    portfolio_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT freelancer_profiles_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT freelancer_profiles_full_name_not_empty
        CHECK (length(trim(full_name)) > 0),

    CONSTRAINT freelancer_profiles_portfolio_url_check
        CHECK (
            portfolio_url IS NULL
            OR portfolio_url ~* '^https?://'
        )
);

CREATE TABLE IF NOT EXISTS company_profiles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    company_name VARCHAR(150) NOT NULL,
    website TEXT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT company_profiles_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT company_profiles_company_name_not_empty
        CHECK (length(trim(company_name)) > 0),

    CONSTRAINT company_profiles_website_check
        CHECK (
            website IS NULL
            OR website ~* '^https?://'
        )
);

CREATE TABLE IF NOT EXISTS jobs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_user_id BIGINT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    salary_min NUMERIC(10,2),
    salary_max NUMERIC(10,2),
    category VARCHAR(100) NOT NULL,
    website TEXT,
    status TEXT NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT jobs_company_user_fk
        FOREIGN KEY (company_user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT jobs_status_check
        CHECK (status IN ('open', 'closed')),

    CONSTRAINT jobs_title_not_empty
        CHECK (length(trim(title)) > 0),

    CONSTRAINT jobs_description_not_empty
        CHECK (length(trim(description)) > 0),

    CONSTRAINT jobs_category_not_empty
        CHECK (length(trim(category)) > 0),

    CONSTRAINT jobs_salary_nonnegative_check
        CHECK (
            (salary_min IS NULL OR salary_min >= 0) AND
            (salary_max IS NULL OR salary_max >= 0)
        ),

    CONSTRAINT jobs_salary_range_check
        CHECK (
            salary_min IS NULL
            OR salary_max IS NULL
            OR salary_min <= salary_max
        ),

    CONSTRAINT jobs_website_check
        CHECK (
            website IS NULL
            OR website ~* '^https?://'
        )
);

CREATE TABLE IF NOT EXISTS job_skills (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_id BIGINT NOT NULL,
    skill_name VARCHAR(100) NOT NULL,

    CONSTRAINT job_skills_job_fk
        FOREIGN KEY (job_id)
        REFERENCES jobs(id)
        ON DELETE CASCADE,

    CONSTRAINT job_skills_skill_name_not_empty
        CHECK (length(trim(skill_name)) > 0),

    CONSTRAINT job_skills_unique_per_job
        UNIQUE (job_id, skill_name)
);

CREATE TABLE IF NOT EXISTS applications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_id BIGINT NOT NULL,
    freelancer_user_id BIGINT NOT NULL,
    cover_letter TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT applications_job_fk
        FOREIGN KEY (job_id)
        REFERENCES jobs(id)
        ON DELETE CASCADE,

    CONSTRAINT applications_freelancer_user_fk
        FOREIGN KEY (freelancer_user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT applications_status_check
        CHECK (status IN ('pending', 'reviewed', 'accepted', 'rejected')),

    CONSTRAINT applications_unique_job_freelancer
        UNIQUE (job_id, freelancer_user_id)
);

-- ---------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_users_role
    ON users(role);

CREATE INDEX IF NOT EXISTS idx_jobs_company_user_id
    ON jobs(company_user_id);

CREATE INDEX IF NOT EXISTS idx_jobs_status
    ON jobs(status);

CREATE INDEX IF NOT EXISTS idx_jobs_category
    ON jobs(category);

CREATE INDEX IF NOT EXISTS idx_jobs_created_at
    ON jobs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_skills_job_id
    ON job_skills(job_id);

CREATE INDEX IF NOT EXISTS idx_job_skills_skill_name
    ON job_skills(skill_name);

CREATE INDEX IF NOT EXISTS idx_applications_job_id
    ON applications(job_id);

CREATE INDEX IF NOT EXISTS idx_applications_freelancer_user_id
    ON applications(freelancer_user_id);

CREATE INDEX IF NOT EXISTS idx_applications_status
    ON applications(status);

CREATE INDEX IF NOT EXISTS idx_applications_applied_at
    ON applications(applied_at DESC);

-- ---------------------------------------------------------
-- Trigger functions to enforce role correctness
-- PostgreSQL CHECK constraints should not depend on other tables,
-- so cross-table role validation is done with triggers
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION enforce_job_company_role()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE id = NEW.company_user_id
          AND role = 'company'
    ) THEN
        RAISE EXCEPTION 'company_user_id must reference a user with role=company';
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION enforce_application_freelancer_role()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE id = NEW.freelancer_user_id
          AND role = 'freelancer'
    ) THEN
        RAISE EXCEPTION 'freelancer_user_id must reference a user with role=freelancer';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_job_company_role ON jobs;
CREATE TRIGGER trg_enforce_job_company_role
BEFORE INSERT OR UPDATE ON jobs
FOR EACH ROW
EXECUTE FUNCTION enforce_job_company_role();

DROP TRIGGER IF EXISTS trg_enforce_application_freelancer_role ON applications;
CREATE TRIGGER trg_enforce_application_freelancer_role
BEFORE INSERT OR UPDATE ON applications
FOR EACH ROW
EXECUTE FUNCTION enforce_application_freelancer_role();

-- ---------------------------------------------------------
-- Optional row-level security setup
-- If you do not want RLS yet, comment this block out
-- App can set:
-- SET app.current_user_id = '123';
-- ---------------------------------------------------------

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE freelancer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_select_self ON users;
CREATE POLICY users_select_self
ON users
FOR SELECT
USING (id = current_setting('app.current_user_id', true)::BIGINT);

DROP POLICY IF EXISTS users_update_self ON users;
CREATE POLICY users_update_self
ON users
FOR UPDATE
USING (id = current_setting('app.current_user_id', true)::BIGINT)
WITH CHECK (id = current_setting('app.current_user_id', true)::BIGINT);

DROP POLICY IF EXISTS freelancer_profiles_select_public ON freelancer_profiles;
CREATE POLICY freelancer_profiles_select_public
ON freelancer_profiles
FOR SELECT
USING (true);

DROP POLICY IF EXISTS freelancer_profiles_modify_self ON freelancer_profiles;
CREATE POLICY freelancer_profiles_modify_self
ON freelancer_profiles
FOR ALL
USING (user_id = current_setting('app.current_user_id', true)::BIGINT)
WITH CHECK (user_id = current_setting('app.current_user_id', true)::BIGINT);

DROP POLICY IF EXISTS company_profiles_select_public ON company_profiles;
CREATE POLICY company_profiles_select_public
ON company_profiles
FOR SELECT
USING (true);

DROP POLICY IF EXISTS company_profiles_modify_self ON company_profiles;
CREATE POLICY company_profiles_modify_self
ON company_profiles
FOR ALL
USING (user_id = current_setting('app.current_user_id', true)::BIGINT)
WITH CHECK (user_id = current_setting('app.current_user_id', true)::BIGINT);

DROP POLICY IF EXISTS jobs_select_public ON jobs;
CREATE POLICY jobs_select_public
ON jobs
FOR SELECT
USING (true);

DROP POLICY IF EXISTS jobs_insert_company_self ON jobs;
CREATE POLICY jobs_insert_company_self
ON jobs
FOR INSERT
WITH CHECK (company_user_id = current_setting('app.current_user_id', true)::BIGINT);

DROP POLICY IF EXISTS jobs_update_company_self ON jobs;
CREATE POLICY jobs_update_company_self
ON jobs
FOR UPDATE
USING (company_user_id = current_setting('app.current_user_id', true)::BIGINT)
WITH CHECK (company_user_id = current_setting('app.current_user_id', true)::BIGINT);

DROP POLICY IF EXISTS jobs_delete_company_self ON jobs;
CREATE POLICY jobs_delete_company_self
ON jobs
FOR DELETE
USING (company_user_id = current_setting('app.current_user_id', true)::BIGINT);

DROP POLICY IF EXISTS job_skills_select_public ON job_skills;
CREATE POLICY job_skills_select_public
ON job_skills
FOR SELECT
USING (true);

DROP POLICY IF EXISTS job_skills_modify_owner ON job_skills;
CREATE POLICY job_skills_modify_owner
ON job_skills
FOR ALL
USING (
    EXISTS (
        SELECT 1
        FROM jobs j
        WHERE j.id = job_skills.job_id
          AND j.company_user_id = current_setting('app.current_user_id', true)::BIGINT
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM jobs j
        WHERE j.id = job_skills.job_id
          AND j.company_user_id = current_setting('app.current_user_id', true)::BIGINT
    )
);

DROP POLICY IF EXISTS applications_insert_self ON applications;
CREATE POLICY applications_insert_self
ON applications
FOR INSERT
WITH CHECK (freelancer_user_id = current_setting('app.current_user_id', true)::BIGINT);

DROP POLICY IF EXISTS applications_select_related ON applications;
CREATE POLICY applications_select_related
ON applications
FOR SELECT
USING (
    freelancer_user_id = current_setting('app.current_user_id', true)::BIGINT
    OR EXISTS (
        SELECT 1
        FROM jobs j
        WHERE j.id = applications.job_id
          AND j.company_user_id = current_setting('app.current_user_id', true)::BIGINT
    )
);

DROP POLICY IF EXISTS applications_update_related ON applications;
CREATE POLICY applications_update_related
ON applications
FOR UPDATE
USING (
    freelancer_user_id = current_setting('app.current_user_id', true)::BIGINT
    OR EXISTS (
        SELECT 1
        FROM jobs j
        WHERE j.id = applications.job_id
          AND j.company_user_id = current_setting('app.current_user_id', true)::BIGINT
    )
)
WITH CHECK (
    freelancer_user_id = current_setting('app.current_user_id', true)::BIGINT
    OR EXISTS (
        SELECT 1
        FROM jobs j
        WHERE j.id = applications.job_id
          AND j.company_user_id = current_setting('app.current_user_id', true)::BIGINT
    )
);

DROP POLICY IF EXISTS applications_delete_self ON applications;
CREATE POLICY applications_delete_self
ON applications
FOR DELETE
USING (freelancer_user_id = current_setting('app.current_user_id', true)::BIGINT);

COMMIT;
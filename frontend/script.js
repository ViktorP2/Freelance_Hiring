let jobs = [
    {
        id: 1,
        company: "TechCorp",
        title: "Software Engineer",
        desc: "Build web apps and APIs.",
        skills: ["JavaScript", "Node.js", "React"],
        salary: "$900 - $1700",
        category: "Web development",
        website: "https://techcorp.com/careers"
    },
    {
        id: 2,
        company: "DesignPro",
        title: "Graphic Designer",
        desc: "Create stunning visuals for our brand.",
        skills: ["Adobe Photoshop", "Illustrator", "Creativity"],
        salary: "$500 - $1200",
        category: "Design",
        website: "https://designpro.com"
    },
    {
        id: 3,
        company: "MarketGurus",
        title: "Digital Marketer",
        desc: "Drive online campaigns and growth.",
        skills: ["SEO", "Google Ads", "Analytics"],
        salary: "$600 - $1500",
        category: "Marketing",
        website: "https://marketgurus.com"
    }
];

let loginRole = "freelancer";
let registerRole = "freelancer";
let currentUser = null;
let nextJobId = 4;

function renderJobs(jobsToShow) {
    const grid = document.getElementById("jobsGrid");

    if (jobsToShow.length === 0) {
        grid.innerHTML = `<p>No jobs found.</p>`;
        return;
    }

    grid.innerHTML = jobsToShow.map(job => `
        <div class="job-card">
            <div class="job-company">${job.company}</div>
            <h3 class="job-title">${job.title}</h3>
            <p class="job-desc">${job.desc}</p>
            <div class="job-meta">
                <span><strong>Skills:</strong> ${job.skills.join(", ")}</span>
                <p><strong>Salary:</strong> ${job.salary}</p>
                <p><strong>Category:</strong> ${job.category}</p>
            </div>
            <p class="website">${job.website || "No website available"}</p>
            <button class="apply-btn" onclick="apply(${job.id})">Apply Now</button>
        </div>
    `).join("");
}

function filterJobs() {
    const search = document.getElementById("search-input").value.toLowerCase().trim();
    const category = document.getElementById("category-filter").value;

    let filtered = jobs.filter(job =>
        job.title.toLowerCase().includes(search) ||
        job.company.toLowerCase().includes(search) ||
        job.desc.toLowerCase().includes(search) ||
        job.skills.join(" ").toLowerCase().includes(search)
    );

    if (category !== "All Categories") {
        filtered = filtered.filter(job => job.category === category);
    }

    renderJobs(filtered);
}

function apply(jobId) {
    const job = jobs.find(j => j.id === jobId);

    if (!currentUser) {
        alert("Please log in first.");
        return;
    }

    if (currentUser.role !== "freelancer") {
        alert("Only freelancers can apply for jobs.");
        return;
    }

    alert(`Application sent for "${job.title}" at ${job.company}`);
}

function openLoginModal() {
    document.getElementById("login-modal-overlay").classList.add("active");
}

function closeLoginModal() {
    document.getElementById("login-modal-overlay").classList.remove("active");
}

function openRegisterModal() {
    document.getElementById("register-modal-overlay").classList.add("active");
}

function closeRegisterModal() {
    document.getElementById("register-modal-overlay").classList.remove("active");
}

function switchToRegister() {
    closeLoginModal();
    openRegisterModal();
}

function switchToLogin() {
    closeRegisterModal();
    openLoginModal();
}

function setLoginRole(role) {
    loginRole = role;
    document.getElementById("loginFreelancerBtn").classList.toggle("active", role === "freelancer");
    document.getElementById("loginCompanyBtn").classList.toggle("active", role === "company");
    document.getElementById("loginAdminBtn").classList.toggle("active", role === "admin");
}

function setRegisterRole(role) {
    registerRole = role;
    document.getElementById("registerFreelancerBtn").classList.toggle("active", role === "freelancer");
    document.getElementById("registerCompanyBtn").classList.toggle("active", role === "company");
}

function handleLogin(event) {
    event.preventDefault();

    const email = document.getElementById("loginEmailInput").value.trim();
    const password = document.getElementById("loginPasswordInput").value.trim();

    if (!email || !password) {
        alert("Please fill in all fields.");
        return;
    }

    currentUser = {
        email,
        role: loginRole
    };

    alert(`Logged in as ${loginRole}: ${email}`);
    closeLoginModal();
    updateAdminPanel();
}

function handleRegister(event) {
    event.preventDefault();

    const name = document.getElementById("registerNameInput").value.trim();
    const email = document.getElementById("registerEmailInput").value.trim();
    const password = document.getElementById("registerPasswordInput").value.trim();

    if (!name || !email || !password) {
        alert("Please fill in all fields.");
        return;
    }

    alert(`${registerRole} account created successfully for ${name}`);
    closeRegisterModal();
    openLoginModal();
}

function updateAdminPanel() {
    const adminPanel = document.getElementById("admin-panel");

    if (currentUser && currentUser.role === "admin") {
        adminPanel.classList.remove("hidden");
    } else {
        adminPanel.classList.add("hidden");
    }
}

function handleAddJob(event) {
    event.preventDefault();

    if (!currentUser || currentUser.role !== "admin") {
        alert("Only admins can add job listings.");
        return;
    }

    const company = document.getElementById("adminCompany").value.trim();
    const title = document.getElementById("adminTitle").value.trim();
    const desc = document.getElementById("adminDesc").value.trim();
    const skillsInput = document.getElementById("adminSkills").value.trim();
    const salary = document.getElementById("adminSalary").value.trim();
    const category = document.getElementById("adminCategory").value;
    const website = document.getElementById("adminWebsite").value.trim();

    if (!company || !title || !desc || !skillsInput || !salary || !category) {
        alert("Please fill in all required fields.");
        return;
    }

    const newJob = {
        id: nextJobId++,
        company,
        title,
        desc,
        skills: skillsInput.split(",").map(skill => skill.trim()).filter(Boolean),
        salary,
        category,
        website: website || "No website available"
    };

    jobs.unshift(newJob);
    renderJobs(jobs);
    document.querySelector(".admin-job-form").reset();

    alert("Job listing added successfully.");
}

document.addEventListener("DOMContentLoaded", function () {
    renderJobs(jobs);
    document.getElementById("search-input").addEventListener("input", filterJobs);
});
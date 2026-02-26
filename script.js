const jobs = [{
    id: 1,
    company: "TechCorp", 
    title: "Software Engineer", 
    desc: "Build web apps and APIs.",
    skills: ["JavaScript", "Node.js", "React"],
    salary: "$900 - $1700",
    category: "Software Development"
    },
    {
    id: 2,
    company: "DesignPro",
    title: "Graphic Designer",
    desc: "Create stunning visuals for our brand.",
    skills: ["Adobe Photoshop", "Illustrator", "Creativity"],
    salary: "$500 - $1200",
    category: "Design"},
    {
    id: 3,
    company: "MarketGurus",
    title: "Digital Marketer",
    desc: "Drive online campaigns and growth.",
    skills: ["SEO", "Google Ads", "Analytics"],
    salary: "$600 - $1500",
    category: "Marketing"
    }
];

function renderJobs() {
    const grid = document.getElementById('jobsGrid');
    grid.innerHTML = jobs.map(job => `
        <div class="job-card">
            <div class="job-company">${job.company}</div>
            <h3 class="job-title">${job.title}</h3>
            <p class="job-desc">${job.desc}</p>
            <div class="job-meta">
                <span>Skills: ${job.skills.join(', ')}</span>
                <p>Salary: ${job.salary}</p>
            </div>
            <button class="apply-btn">Apply Now</button>
        </div>
    `).join('');
}

renderJobs(jobs);
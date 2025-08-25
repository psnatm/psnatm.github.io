#!/bin/bash

# This script creates a self-contained directory with a static webpage
# to generate emails to New Zealand MPs about the situation in Palestine.
# Version 3: Fixed the CSV parsing to correctly handle commas in names.

# Create the main directory
mkdir -p psna-email-app/data

# --- Create the HTML file (No changes here) ---
cat > psna-email-app/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Palestine Solidarity Network Aotearoa - Email Your MP</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header>
        <div class="logo">
             <img src="https://i.postimg.cc/9F0Y8z4R/palestine-solidarity-network-aotearoa-logo.png" alt="Palestine Solidarity Network Aotearoa Logo" style="max-height: 80px;">
        </div>
        <nav>
            <a href="#">HOME</a>
            <a href="#">BDS</a>
            <a href="#">PETITION</a>
            <a href="#">NEWSLETTERS</a>
            <a href="#">RESOURCES</a>
            <a href="#">PRESS RELEASES</a>
            <a href="#">SHOP</a>
            <a href="#">DONATE</a>
            <a href="#">CONTACT</a>
        </nav>
    </header>

    <main>
        <div class="hero">
            <h1>Committed to building and strengthening campaigns for a free Palestine.</h1>
        </div>

        <div class="email-generator">
            <h2>Email Your Electorate MP</h2>
            <p>Select your MP, fill in the details, and click "Generate Email" to open the email in your default mail client.</p>

            <div class="form-container">
                <div class="form-section" id="user-input-section">
                    <h3>Step 1: Your Details</h3>
                    <label for="mp-select">Select Your MP:</label>
                    <select id="mp-select" name="mp">
                        <option value="" disabled selected>Loading MPs...</option>
                    </select>

                    <!-- Dynamic form fields will be injected here -->
                    <div id="dynamic-form-fields"></div>
                </div>

                <div class="form-section">
                    <h3>Step 2: Edit the Template (Optional)</h3>
                    <label for="email-template">Email Template:</label>
                    <textarea id="email-template" name="email-template" rows="20">
Dear {mp.Contact},

My name is {Your Full Name?} and I am a constituent writing to you from {Your Suburb or Town?}.

I am writing to you today to express my profound distress regarding the ongoing humanitarian crisis in Palestine. The loss of innocent lives, the destruction of homes, and the denial of basic human rights are unacceptable and demand immediate action from the international community.

New Zealand has a proud history of standing up for justice and human rights on the global stage. I urge you, as my elected representative, to advocate within Parliament for the New Zealand government to take a stronger, more decisive stance.

Specifically, I ask that you please push for the following actions:
1.  Publicly call for an immediate and permanent ceasefire.
2.  Increase humanitarian aid to Gaza and the West Bank.
3.  Support international efforts to investigate all credible reports of war crimes and hold perpetrators accountable.
4.  Recognise the State of Palestine.

The people of Palestine have endured decades of occupation and hardship. It is our moral obligation to speak out and act in solidarity with them.

Thank you for your time and attention to this urgent matter. I look forward to your response outlining the steps you will take.

Sincerely,
{Your Full Name?}
                    </textarea>
                </div>
            </div>

            <button id="generate-email">Generate Email</button>
        </div>
    </main>

    <script src="script.js"></script>
</body>
</html>
EOF

# --- Create the CSS file (No changes here) ---
cat > psna-email-app/style.css << 'EOF'
body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    margin: 0;
    background-color: #f8f9fa;
    color: #343a40;
}

header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 2rem;
    background-color: #fff;
    border-bottom: 1px solid #dee2e6;
}

header nav a {
    margin-left: 1.5rem;
    text-decoration: none;
    color: #004b23;
    font-weight: bold;
    font-size: 0.9rem;
}

.hero {
    background-image: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url('https://i.postimg.cc/YCXB3B9T/psna-background.jpg');
    background-size: cover;
    background-position: center;
    color: white;
    text-align: center;
    padding: 5rem 1rem;
}

.hero h1 {
    font-size: 2.8rem;
    font-weight: 700;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.7);
}

.email-generator {
    padding: 2rem;
    max-width: 1200px;
    margin: 2rem auto;
    background-color: #fff;
    border-radius: 8px;
    box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.email-generator h2, .email-generator h3 {
    text-align: center;
    color: #d82c2c;
}

.form-container {
    display: flex;
    flex-wrap: wrap;
    gap: 2rem;
    margin-top: 2rem;
}

.form-section {
    flex: 1;
    min-width: 300px;
}

label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: bold;
    color: #495057;
}

input[type="text"],
select,
textarea {
    width: 100%;
    padding: 0.8rem;
    margin-bottom: 1rem;
    border-radius: 4px;
    border: 1px solid #ced4da;
    box-sizing: border-box;
    font-size: 1rem;
}

textarea {
    min-height: 300px;
    font-family: inherit;
}

button {
    display: block;
    width: 100%;
    padding: 1rem;
    background-color: #004b23;
    color: white;
    border: none;
    border-radius: 4px;
    font-size: 1.2rem;
    cursor: pointer;
    margin-top: 1rem;
    font-weight: bold;
    transition: background-color 0.2s;
}

button:hover {
    background-color: #003318;
}
EOF

# --- Create the JavaScript file (UPDATED) ---
cat > psna-email-app/script.js << 'EOF'
document.addEventListener('DOMContentLoaded', () => {
    const mpSelect = document.getElementById('mp-select');
    const generateEmailButton = document.getElementById('generate-email');
    const emailTemplateTextarea = document.getElementById('email-template');
    const dynamicFormFieldsContainer = document.getElementById('dynamic-form-fields');

    let mps = [];
    const placeholderRegex = /\{([^{}?\n]+)\?\}/g;

    /**
     * A robust CSV parser that handles commas inside quoted fields.
     * @param {string} text The raw CSV text.
     * @returns {Array<Object>} An array of objects representing the CSV rows.
     */
    const parseCSV = (text) => {
        const lines = text.trim().split('\n');
        const headers = lines[0].split(',').map(h => h.trim().replace(/"/g, ''));
        const data = [];
        const valueRegex = /,(?=(?:(?:[^"]*"){2})*[^"]*$)/;

        for (let i = 1; i < lines.length; i++) {
            if (lines[i].trim() === '') continue;

            const values = lines[i].split(valueRegex);

            if (values.length === headers.length) {
                let entry = {};
                headers.forEach((header, index) => {
                    entry[header] = values[index] ? values[index].trim().replace(/^"|"$/g, '') : '';
                });
                data.push(entry);
            } else {
                console.warn(`Skipping malformed CSV line ${i + 1}:`, lines[i]);
            }
        }
        return data;
    };
    
    const populateMPDropdown = () => {
        mpSelect.innerHTML = ''; // Clear "Loading..."
        const placeholderOption = document.createElement('option');
        placeholderOption.value = "";
        placeholderOption.textContent = "Select your electorate MP...";
        placeholderOption.disabled = true;
        placeholderOption.selected = true;
        mpSelect.appendChild(placeholderOption);

        const electorateMPs = mps.filter(mp => mp['Job Title'] && !mp['Job Title'].includes('List Member') && mp['Electorate']);
        electorateMPs.sort((a, b) => a.Contact.localeCompare(b.Contact));

        electorateMPs.forEach(mp => {
            const option = document.createElement('option');
            option.value = mp['Parliament Email'];
            option.textContent = `${mp['Contact']} (${mp['Electorate']} - ${mp['Party']})`;
            option.dataset.mpData = JSON.stringify(mp);
            mpSelect.appendChild(option);
        });
    };

    const generateFormFromTemplate = () => {
        const template = emailTemplateTextarea.value;
        const placeholders = [...template.matchAll(placeholderRegex)];
        const uniqueLabels = [...new Set(placeholders.map(match => match[1]))];

        dynamicFormFieldsContainer.innerHTML = '';

        uniqueLabels.forEach(label => {
            const formGroup = document.createElement('div');
            
            const labelEl = document.createElement('label');
            labelEl.htmlFor = `input-${label.replace(/\s+/g, '-')}`;
            labelEl.textContent = `${label}:`;
            
            const inputEl = document.createElement('input');
            inputEl.type = 'text';
            inputEl.id = `input-${label.replace(/\s+/g, '-')}`;
            inputEl.dataset.placeholder = `{${label}?}`;
            inputEl.setAttribute('aria-label', label);


            formGroup.appendChild(labelEl);
            formGroup.appendChild(inputEl);
            dynamicFormFieldsContainer.appendChild(formGroup);
        });
    };

    const generateEmail = () => {
        const selectedOption = mpSelect.options[mpSelect.selectedIndex];
        if (!selectedOption || selectedOption.disabled) {
            alert('Please select an MP.');
            return;
        }

        const mpEmail = selectedOption.value;
        const mpData = JSON.parse(selectedOption.dataset.mpData);
        let emailBody = emailTemplateTextarea.value;
        const subject = "Urgent Action Required for Palestine";

        // Replace {mp.Property} placeholders
        for (const key in mpData) {
            const regex = new RegExp(`{mp.${key}}`, 'g');
            emailBody = emailBody.replace(regex, mpData[key]);
        }

        // Replace dynamic {Question?} placeholders
        let allFieldsFilled = true;
        const dynamicInputs = dynamicFormFieldsContainer.querySelectorAll('input');
        dynamicInputs.forEach(input => {
            const placeholder = input.dataset.placeholder;
            const value = input.value;
            if (!value) {
                alert(`Please fill out the "${placeholder.slice(1, -2)}" field.`);
                allFieldsFilled = false;
            }
            const regex = new RegExp(placeholder.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g');
            emailBody = emailBody.replace(regex, value);
        });

        if (!allFieldsFilled) {
             return; // Stop if a field was empty
        }

        window.location.href = `mailto:${mpEmail}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(emailBody)}`;
    };

    // --- Main Execution ---
    fetch('data/mps.csv')
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.text();
        })
        .then(csvText => {
            mps = parseCSV(csvText);
            populateMPDropdown();
        })
        .catch(error => {
            console.error('Error fetching or parsing CSV:', error);
            mpSelect.innerHTML = '<option value="">Could not load MP data</option>';
        });

    emailTemplateTextarea.addEventListener('input', generateFormFromTemplate);
    generateEmailButton.addEventListener('click', generateEmail);

    // Initial form generation
    generateFormFromTemplate();
});
EOF

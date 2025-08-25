document.addEventListener('DOMContentLoaded', () => {
    const mpSelect = document.getElementById('mp-select');
    const generateEmailButton = document.getElementById('generate-email');
    const emailTemplateTextarea = document.getElementById('email-template');
    const dynamicFormFieldsContainer = document.getElementById('dynamic-form-fields');

    let mps = [];
    const placeholderRegex = /\{([^{}?\n]+)\?\}/g;

    const parseCSV = (text) => {
        const lines = text.trim().split('\n');
        const headers = lines[0].split(',').map(h => h.trim());
        const data = [];
        for (let i = 1; i < lines.length; i++) {
            const values = lines[i].split(',').map(v => v.trim().replace(/"/g, ''));
            if (values.length === headers.length) {
                let entry = {};
                headers.forEach((header, index) => {
                    entry[header] = values[index];
                });
                data.push(entry);
            }
        }
        return data;
    };
    
    const populateMPDropdown = () => {
        const electorateMPs = mps.filter(mp => mp['Job Title'] !== 'List Member' && mp['Electorate']);
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

            formGroup.appendChild(labelEl);
            formGroup.appendChild(inputEl);
            dynamicFormFieldsContainer.appendChild(formGroup);
        });
    };

    const generateEmail = () => {
        const selectedOption = mpSelect.options[mpSelect.selectedIndex];
        if (!selectedOption) {
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
        const dynamicInputs = dynamicFormFieldsContainer.querySelectorAll('input');
        dynamicInputs.forEach(input => {
            const placeholder = input.dataset.placeholder;
            const value = input.value;
            if (!value) {
                alert(`Please fill out the "${placeholder.slice(1, -2)}" field.`);
                throw new Error('Field is empty'); // Stop execution
            }
            // Use a regex with a global flag to replace all occurrences
            const regex = new RegExp(placeholder.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g');
            emailBody = emailBody.replace(regex, value);
        });

        window.location.href = `mailto:${mpEmail}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(emailBody)}`;
    };

    // --- Event Listeners ---
    fetch('data/mps.csv')
        .then(response => response.text())
        .then(csvText => {
            mps = parseCSV(csvText);
            populateMPDropdown();
        });

    emailTemplateTextarea.addEventListener('input', generateFormFromTemplate);
    generateEmailButton.addEventListener('click', () => {
        try {
            generateEmail();
        } catch (error) {
            console.warn(error.message);
        }
    });

    // Initial setup
    generateFormFromTemplate();
});

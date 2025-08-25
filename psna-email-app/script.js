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

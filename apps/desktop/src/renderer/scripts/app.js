'use strict';

/* ==========================================================================
   DOM references
   ========================================================================== */
const el = {
    backupAssets: document.getElementById('backup-assets'),
    startBtn: document.getElementById('start-btn'),
    progressCard: document.getElementById('progress-card'),
    progressBar: document.getElementById('progress-bar'),
    progressTrack: document.getElementById('progress-track'),
    statusText: document.getElementById('status-text'),
    log: document.getElementById('log'),
    submitCard: document.getElementById('submit-card'),
    summary: document.getElementById('summary'),
    submitBtn: document.getElementById('submit-btn'),
    resultCard: document.getElementById('result-card'),
    resultText: document.getElementById('result-text'),
    dialog: document.getElementById('confirm-dialog'),
    confirmCheck: document.getElementById('confirm-check'),
    confirmBtn: document.getElementById('confirm-btn'),
    cancelBtn: document.getElementById('cancel-btn'),
};

/* ==========================================================================
   Backend bridge
   In Electron, preload.js exposes window.electronAPI through contextBridge.
   Expected contract:
     startBackup({ backupAssets })  -> Promise<{ profile, filesCount, assetsIncluded }>
     onProgress(callback)           -> callback receives { percent, message }
     submitBackup()                 -> Promise<{ success, url?, error? }>
   Outside Electron, a simulated backend is used so the page can be previewed.
   ========================================================================== */
const backend = window.electronAPI ?? createMockBackend();

/* ==========================================================================
   UI helpers
   ========================================================================== */
function showSection(section, visible) {
    section.hidden = !visible;
}

function setRunning(isRunning) {
    el.startBtn.disabled = isRunning;
    el.backupAssets.disabled = isRunning;
}

function setProgress(percent, message) {
    const value = Math.max(0, Math.min(100, Math.round(percent)));
    el.progressBar.style.width = `${value}%`;
    el.progressTrack.setAttribute('aria-valuenow', String(value));
    if (message) {
        el.statusText.textContent = message;
    }
}

function logMessage(text, type = 'info') {
    const item = document.createElement('li');
    item.className = type;

    const time = document.createElement('span');
    time.className = 'time';
    time.textContent = new Date().toLocaleTimeString('en-GB');

    item.append(time, text);
    el.log.append(item);
    item.scrollIntoView({ block: 'nearest' });
}

function renderSummary({ profile, filesCount, assetsIncluded }) {
    const rows = [
        ['Profile', profile],
        ['Files backed up', String(filesCount)],
        ['Game assets', assetsIncluded ? 'Included (kept local, never submitted)' : 'Not included'],
    ];

    el.summary.textContent = '';
    for (const [label, value] of rows) {
        const term = document.createElement('dt');
        term.textContent = label;
        const detail = document.createElement('dd');
        detail.textContent = value;
        el.summary.append(term, detail);
    }
}

function isSafeUrl(value) {
    try {
        return new URL(value).protocol === 'https:';
    } catch {
        return false;
    }
}

function showResult(url) {
    el.resultText.textContent = 'Your data was submitted successfully. ';

    if (isSafeUrl(url)) {
        const link = document.createElement('a');
        link.href = url;
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        link.textContent = 'View your file in the repository';
        el.resultText.append(link);
    }

    showSection(el.resultCard, true);
}

function resetUi() {
    el.log.textContent = '';
    setProgress(0, 'Starting…');
    showSection(el.submitCard, false);
    showSection(el.resultCard, false);
    el.submitBtn.disabled = false;
}

/* ==========================================================================
   Step 1 & 2: backup
   ========================================================================== */
async function startProcess() {
    resetUi();
    showSection(el.progressCard, true);
    setRunning(true);
    logMessage('Starting backup…');

    try {
        const summary = await backend.startBackup({
            backupAssets: el.backupAssets.checked,
        });

        renderSummary(summary);
        setProgress(100, 'Backup complete.');
        logMessage('Backup complete. You can now review and optionally submit your data.', 'success');
        showSection(el.submitCard, true);
    } catch (err) {
        setProgress(0, 'Backup failed.');
        logMessage(`Error: ${err?.message ?? err}`, 'error');
    } finally {
        setRunning(false);
    }
}

function handleProgress({ percent, message }) {
    setProgress(percent, message);
    logMessage(message);
}

/* ==========================================================================
   Step 3: submission (always requires explicit confirmation)
   ========================================================================== */
function openConfirmation() {
    el.confirmCheck.checked = false;
    el.confirmBtn.disabled = true;
    el.dialog.showModal();
}

async function submitBackup() {
    el.submitBtn.disabled = true;
    logMessage('Submitting data to the community repository…');

    try {
        const result = await backend.submitBackup();
        if (!result?.success) {
            throw new Error(result?.error ?? 'Unknown error');
        }

        showResult(result.url);
        logMessage('Submission successful.', 'success');
    } catch (err) {
        logMessage(`Submission failed: ${err?.message ?? err}`, 'error');
        el.submitBtn.disabled = false;
    }
}

/* ==========================================================================
   Event wiring
   ========================================================================== */
backend.onProgress(handleProgress);

el.startBtn.addEventListener('click', startProcess);
el.submitBtn.addEventListener('click', openConfirmation);

el.confirmCheck.addEventListener('change', () => {
    el.confirmBtn.disabled = !el.confirmCheck.checked;
});

el.cancelBtn.addEventListener('click', () => el.dialog.close());

el.confirmBtn.addEventListener('click', () => {
    el.dialog.close();
    submitBackup();
});

/* ==========================================================================
   Mock backend (browser preview only)
   ========================================================================== */
function createMockBackend() {
    let progressListener = () => { };
    const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

    const baseSteps = [
        'Checking ADB connection…',
        'Verifying Developer Mode…',
        'Extracting account profile…',
        'Reading player progress…',
    ];

    return {
        onProgress(callback) {
            progressListener = callback;
        },

        async startBackup({ backupAssets }) {
            const steps = backupAssets
                ? [...baseSteps, 'Copying game assets…']
                : baseSteps;

            for (const [index, message] of steps.entries()) {
                await delay(700);
                progressListener({ percent: ((index + 1) / steps.length) * 100, message });
            }

            return { profile: 'Preview Player', filesCount: 42, assetsIncluded: backupAssets };
        },

        async submitBackup() {
            await delay(1200);
            return { success: true, url: 'https://github.com/' };
        },
    };
}
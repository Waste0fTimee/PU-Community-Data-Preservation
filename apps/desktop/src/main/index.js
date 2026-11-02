const { app, BrowserWindow } = require('electron');
const path = require('node:path');

if (!app.isPackaged) {
    // Reload open windows when src files change and restart the app when the
    // main-process file changes. electron-reload spawns its own Electron
    // process, so a restart must repeat the Chromium flags used by
    // .devcontainer/electron.sh (the container runs as root).
    const electronArgs = ['--disable-gpu', '--disable-dev-shm-usage'];
    if (process.getuid?.() === 0) {
        electronArgs.push('--no-sandbox');
    }

    // The .bin shim is POSIX-only; Windows needs the executable itself.
    const electronBinary = process.platform === 'win32'
        ? path.join(__dirname, '../../node_modules/electron/dist/electron.exe')
        : path.join(__dirname, '../../node_modules/.bin/electron');

    require('electron-reload')(path.join(__dirname, '..'), {
        electron: electronBinary,
        electronArgv: electronArgs,
    });
}

function createWindow() {
    const mainWindow = new BrowserWindow({
        width: 1100,
        height: 750,
        webPreferences: {
            preload: path.join(__dirname, '../preload/index.js'),
            contextIsolation: true,
            nodeIntegration: false,
        },
    });

    mainWindow.loadFile(
        path.join(__dirname, '../renderer/index.html')
    );
}

app.whenReady().then(() => {
    createWindow();

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});
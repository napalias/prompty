// sidecar.js
// AITextTool
//
// Claude Agent SDK wrapper for OAuth subscription mode.
// Communicates with Swift host via stdin/stdout newline-delimited JSON.

// Orphan prevention: exit if parent process dies (21H)
setInterval(() => {
    try {
        process.kill(process.ppid, 0);
    } catch (e) {
        process.exit(0);
    }
}, 5000);

process.on('disconnect', () => {
    process.exit(0);
});

// TODO: Implement Claude Agent SDK integration

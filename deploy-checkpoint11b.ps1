$ErrorActionPreference = "Stop"

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object {
    $_.id -notmatch "^checkpoint11b-" -and
    $_.z -ne "checkpoint11b-tab"
})

$exportCode = @'
const now = new Date().toISOString();
function compactDelivery(item) {
    return {
        id: item.id,
        status: item.status,
        source: item.source,
        subject: item.subject,
        recipients: item.recipients || [],
        attempts: item.attempts || 0,
        duplicateCount: item.duplicateCount || 0,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        sentAt: item.sentAt,
        failedAt: item.failedAt,
        lastError: item.lastError
    };
}
const data = {
    birthdayContacts: global.get('birthdayContacts') || [],
    birthdayDeliveries: global.get('birthdayDeliveries') || {},
    recipientGroups: global.get('recipientGroups') || [],
    meetingReminders: global.get('meetingReminders') || [],
    appSettings: global.get('appSettings') || {},
    scheduleSettings: global.get('scheduleSettings') || {},
    scheduleRunLog: global.get('scheduleRunLog') || [],
    deliveryHistory: (global.get('deliveryHistory') || []).map(compactDelivery).slice(0, 250),
    deliveryIdempotency: global.get('deliveryIdempotency') || {}
};
const counts = {
    birthdayContacts: data.birthdayContacts.length,
    recipientGroups: data.recipientGroups.length,
    meetingReminders: data.meetingReminders.length,
    scheduleRunLog: data.scheduleRunLog.length,
    deliveryHistory: data.deliveryHistory.length
};
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = {
    ok: true,
    kind: 'parman-automation-backup',
    version: 1,
    exportedAt: now,
    safeModeNotice: 'Live email is not enabled by backup export or restore.',
    counts,
    data
};
return msg;
'@

$restoreCode = @'
const backup = msg.payload || {};
const errors = [];
if (backup.kind !== 'parman-automation-backup') errors.push('Backup kind must be parman-automation-backup.');
if (Number(backup.version) !== 1) errors.push('Backup version must be 1.');
const data = backup.data || {};
function mustArray(key) {
    if (data[key] !== undefined && !Array.isArray(data[key])) errors.push(`${key} must be an array.`);
}
function mustObject(key) {
    if (data[key] !== undefined && (typeof data[key] !== 'object' || data[key] === null || Array.isArray(data[key]))) errors.push(`${key} must be an object.`);
}
mustArray('birthdayContacts');
mustObject('birthdayDeliveries');
mustArray('recipientGroups');
mustArray('meetingReminders');
mustObject('appSettings');
mustObject('scheduleSettings');
mustArray('scheduleRunLog');
mustArray('deliveryHistory');
mustObject('deliveryIdempotency');
if (errors.length) {
    msg.statusCode = 400;
    msg.headers = { 'content-type': 'application/json; charset=utf-8' };
    msg.payload = { ok: false, errors };
    return msg;
}
const restored = {};
function restore(key, globalKey) {
    if (data[key] !== undefined) {
        global.set(globalKey || key, data[key]);
        restored[key] = Array.isArray(data[key]) ? data[key].length : Object.keys(data[key]).length;
    }
}
restore('birthdayContacts');
restore('birthdayDeliveries');
restore('recipientGroups');
restore('meetingReminders');
restore('scheduleSettings');
restore('scheduleRunLog');
restore('deliveryHistory');
restore('deliveryIdempotency');
if (data.appSettings !== undefined) {
    const safeSettings = {
        ...data.appSettings,
        safeMode: true,
        liveEmailEnabled: false,
        smtpConfigured: false,
        emailTransport: 'Mailpit',
        restoredAt: new Date().toISOString()
    };
    global.set('appSettings', safeSettings);
    restored.appSettings = Object.keys(safeSettings).length;
}
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = {
    ok: true,
    message: 'Backup restored. Live email remains disabled.',
    restored
};
return msg;
'@

$nodes = @(
    @{
        id = "checkpoint11b-tab"
        type = "tab"
        label = "Checkpoint 11B - Backup Restore"
        disabled = $false
        info = "Exports and restores POC data. Restore keeps live email disabled."
    },
    @{
        id = "checkpoint11b-comment"
        type = "comment"
        z = "checkpoint11b-tab"
        name = "GET /api/backups/export | POST /api/backups/restore"
        info = "Backup includes contacts, groups, reminders, settings, schedule state, run logs, and delivery metadata."
        x = 410
        y = 55
        wires = @()
    },
    @{
        id = "checkpoint11b-export-in"
        type = "http in"
        z = "checkpoint11b-tab"
        name = "Export backup"
        url = "/api/backups/export"
        method = "get"
        upload = $false
        swaggerDoc = ""
        x = 145
        y = 130
        wires = @(, @("checkpoint11b-export"))
    },
    @{
        id = "checkpoint11b-export"
        type = "function"
        z = "checkpoint11b-tab"
        name = "Build backup JSON"
        func = $exportCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 405
        y = 130
        wires = @(, @("checkpoint11b-export-response"))
    },
    @{
        id = "checkpoint11b-export-response"
        type = "http response"
        z = "checkpoint11b-tab"
        name = "Return backup"
        statusCode = ""
        headers = @{}
        x = 680
        y = 130
        wires = @()
    },
    @{
        id = "checkpoint11b-restore-in"
        type = "http in"
        z = "checkpoint11b-tab"
        name = "Restore backup"
        url = "/api/backups/restore"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 150
        y = 205
        wires = @(, @("checkpoint11b-restore"))
    },
    @{
        id = "checkpoint11b-restore"
        type = "function"
        z = "checkpoint11b-tab"
        name = "Validate and restore backup"
        func = $restoreCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 430
        y = 205
        wires = @(, @("checkpoint11b-restore-response"))
    },
    @{
        id = "checkpoint11b-restore-response"
        type = "http response"
        z = "checkpoint11b-tab"
        name = "Return restore result"
        statusCode = ""
        headers = @{}
        x = 725
        y = 205
        wires = @()
    }
)

$allFlows = @($flows) + $nodes
$json = $allFlows | ConvertTo-Json -Depth 50 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Checkpoint 11B backup and restore deployed."

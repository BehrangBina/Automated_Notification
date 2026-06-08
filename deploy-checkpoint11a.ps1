$ErrorActionPreference = "Stop"

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object {
    $_.id -notmatch "^checkpoint11a-" -and
    $_.z -ne "checkpoint11a-tab"
})

$getCode = @'
const defaults = {
    safeMode: true,
    liveEmailEnabled: false,
    smtpConfigured: false,
    environmentName: 'Local POC',
    emailTransport: 'Mailpit',
    defaultFromName: 'Parman Automation',
    defaultFromEmail: 'notifications@parman.local',
    replyToEmail: 'reply@parman.local',
    approvalPhrase: 'APPROVE LIVE SEND',
    smtpProvider: '',
    smtpHost: '',
    smtpPort: '',
    smtpUsername: '',
    senderDomain: '',
    smtpSecretSource: 'Docker environment variable',
    lastUpdatedAt: null
};
const saved = global.get('appSettings') || {};
const settings = { ...defaults, ...saved, safeMode: true, liveEmailEnabled: false, smtpConfigured: false, emailTransport: 'Mailpit' };
const smtpPlanReady = Boolean(settings.smtpProvider && settings.smtpHost && settings.smtpPort && settings.smtpUsername && settings.senderDomain);
const readiness = [
    { id: 'safe-mode', label: 'Safe mode is locked on', ok: settings.safeMode, detail: 'All email continues to route to local Mailpit.' },
    { id: 'smtp', label: 'Real SMTP is not configured', ok: !settings.smtpConfigured, detail: 'No live SMTP credentials are stored in this POC.' },
    { id: 'smtp-plan', label: 'SMTP plan documented', ok: smtpPlanReady, detail: smtpPlanReady ? 'Provider, host, port, username, and sender domain are documented.' : 'Document provider, host, port, username, and sender domain before a future pilot.' },
    { id: 'secrets', label: 'SMTP password is not stored in UI', ok: true, detail: 'Future SMTP secrets must be injected through Docker or Node-RED environment variables.' },
    { id: 'approval', label: 'Live-send approval phrase exists', ok: Boolean(settings.approvalPhrase), detail: 'This phrase will be required before any future live-send switch.' },
    { id: 'history', label: 'Delivery history is available', ok: true, detail: 'Sent, failed, duplicate, and retry records can be reviewed.' },
    { id: 'run-log', label: 'Schedule run log is available', ok: true, detail: 'Birthday and meeting reminder checks record compact run summaries.' }
];
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = {
    ok: true,
    settings,
    readiness,
    message: 'Checkpoint 11A keeps live email disabled. This is a safe configuration screen only.'
};
return msg;
'@

$postCode = @'
const body = msg.payload || {};
const current = global.get('appSettings') || {};
const errors = [];
function text(value) {
    return String(value || '').trim();
}
const next = {
    ...current,
    environmentName: text(body.environmentName) || 'Local POC',
    defaultFromName: text(body.defaultFromName) || 'Parman Automation',
    defaultFromEmail: text(body.defaultFromEmail) || 'notifications@parman.local',
    replyToEmail: text(body.replyToEmail) || 'reply@parman.local',
    approvalPhrase: text(body.approvalPhrase) || 'APPROVE LIVE SEND',
    smtpProvider: text(body.smtpProvider),
    smtpHost: text(body.smtpHost),
    smtpPort: text(body.smtpPort),
    smtpUsername: text(body.smtpUsername),
    senderDomain: text(body.senderDomain),
    smtpSecretSource: 'Docker environment variable',
    safeMode: true,
    liveEmailEnabled: false,
    smtpConfigured: false,
    emailTransport: 'Mailpit',
    lastUpdatedAt: new Date().toISOString()
};
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
if (!emailPattern.test(next.defaultFromEmail)) errors.push('Default from email must look like an email address.');
if (!emailPattern.test(next.replyToEmail)) errors.push('Reply-to email must look like an email address.');
if (next.approvalPhrase.length < 8) errors.push('Approval phrase must be at least 8 characters.');
if (next.smtpPort && (!/^\d+$/.test(next.smtpPort) || Number(next.smtpPort) < 1 || Number(next.smtpPort) > 65535)) errors.push('SMTP port must be a number between 1 and 65535.');
if (body.liveEmailEnabled === true || body.safeMode === false || body.smtpConfigured === true) {
    errors.push('Live email cannot be enabled in Checkpoint 11A.');
}
if (errors.length) {
    msg.statusCode = 400;
    msg.headers = { 'content-type': 'application/json; charset=utf-8' };
    msg.payload = { ok: false, errors };
    return msg;
}
global.set('appSettings', next);
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = {
    ok: true,
    settings: next,
    message: 'Safety settings saved. Live email remains disabled.'
};
return msg;
'@

$nodes = @(
    @{
        id = "checkpoint11a-tab"
        type = "tab"
        label = "Checkpoint 11A - Safety Settings"
        disabled = $false
        info = "Safe-mode settings and production-readiness checklist. Live email remains disabled."
    },
    @{
        id = "checkpoint11a-comment"
        type = "comment"
        z = "checkpoint11a-tab"
        name = "GET /api/settings | POST /api/settings"
        info = "Stores safe operator-facing settings only. This checkpoint does not enable real SMTP or live sending."
        x = 355
        y = 55
        wires = @()
    },
    @{
        id = "checkpoint11a-get-in"
        type = "http in"
        z = "checkpoint11a-tab"
        name = "Get safety settings"
        url = "/api/settings"
        method = "get"
        upload = $false
        swaggerDoc = ""
        x = 155
        y = 130
        wires = @(, @("checkpoint11a-get"))
    },
    @{
        id = "checkpoint11a-get"
        type = "function"
        z = "checkpoint11a-tab"
        name = "Read safety settings"
        func = $getCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 420
        y = 130
        wires = @(, @("checkpoint11a-get-response"))
    },
    @{
        id = "checkpoint11a-get-response"
        type = "http response"
        z = "checkpoint11a-tab"
        name = "Return safety settings"
        statusCode = ""
        headers = @{}
        x = 705
        y = 130
        wires = @()
    },
    @{
        id = "checkpoint11a-post-in"
        type = "http in"
        z = "checkpoint11a-tab"
        name = "Save safety settings"
        url = "/api/settings"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 160
        y = 205
        wires = @(, @("checkpoint11a-post"))
    },
    @{
        id = "checkpoint11a-post"
        type = "function"
        z = "checkpoint11a-tab"
        name = "Validate and save safety settings"
        func = $postCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 450
        y = 205
        wires = @(, @("checkpoint11a-post-response"))
    },
    @{
        id = "checkpoint11a-post-response"
        type = "http response"
        z = "checkpoint11a-tab"
        name = "Return save result"
        statusCode = ""
        headers = @{}
        x = 745
        y = 205
        wires = @()
    }
)

$allFlows = @($flows) + $nodes
$json = $allFlows | ConvertTo-Json -Depth 50 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Checkpoint 11A safety settings deployed."

$ErrorActionPreference = "Stop"

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object {
    $_.id -notmatch "^checkpoint10c-" -and
    $_.z -ne "checkpoint10c-tab"
})

function Add-LogHelper {
    param(
        [object]$Node,
        [string]$Anchor,
        [string]$Helper
    )
    if ($Node.func -notmatch "scheduleRunLog") {
        if (-not $Node.func.Contains($Anchor)) {
            throw "Could not find log helper anchor in $($Node.id)"
        }
        $Node.func = $Node.func.Replace($Anchor, "$Anchor$Helper`n")
    }
}

$birthday = $flows | Where-Object id -eq "checkpoint6b-check"
if (-not $birthday) { throw "Could not find checkpoint6b-check" }

$birthdayHelper = @'
function logScheduleRun(status, summary) {
    const log = global.get('scheduleRunLog') || [];
    log.unshift({
        id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
        job: 'birthday-check',
        name: 'Birthday check',
        trigger: isHttp ? 'manual' : 'automatic',
        status,
        summary,
        ranAt: now.toISOString()
    });
    if (log.length > 250) log.length = 250;
    global.set('scheduleRunLog', log);
}
'@
Add-LogHelper $birthday "const selectedIds = Array.isArray(options.contactIds) ? new Set(options.contactIds) : null;`n" $birthdayHelper

if ($birthday.func -notmatch "logScheduleRun\('skipped', \{ reason: 'disabled'") {
    $birthday.func = $birthday.func.Replace(
        "node.status({ fill: 'grey', shape: 'ring', text: 'birthday schedule disabled' });`n    return [null, null];",
        "node.status({ fill: 'grey', shape: 'ring', text: 'birthday schedule disabled' });`n    logScheduleRun('skipped', { reason: 'disabled' });`n    return [null, null];"
    )
}
if ($birthday.func -notmatch "logScheduleRun\('failed', \{ errors: \['now must be") {
    $birthday.func = $birthday.func.Replace(
        "return [null, respond(400, { ok: false, errors: ['now must be a valid ISO date/time'] })];",
        "logScheduleRun('failed', { errors: ['now must be a valid ISO date/time'] });`n    return [null, respond(400, { ok: false, errors: ['now must be a valid ISO date/time'] })];"
    )
}
if ($birthday.func -notmatch "logScheduleRun\('success', \{ checkedContacts: 0") {
    $birthday.func = $birthday.func.Replace(
        "return [null, respond(200, { ok: true, queued: 0, skipped: 0, message: 'No active birthday contacts saved' })];",
        "logScheduleRun('success', { checkedContacts: 0, queued: 0, skipped: 0, message: 'No active birthday contacts saved' });`n    return [null, respond(200, { ok: true, queued: 0, skipped: 0, message: 'No active birthday contacts saved' })];"
    )
}
if ($birthday.func -notmatch "checkedContacts: contacts.length,\s*queued: emails.length,\s*queuedContacts: queuedContacts.length") {
    $birthday.func = $birthday.func.Replace(
        "const response = respond(202, {",
        "logScheduleRun('success', { checkedContacts: contacts.length, queued: emails.length, queuedContacts: queuedContacts.length, skipped: skipped.length, force });`nconst response = respond(202, {"
    )
}

$reminder = $flows | Where-Object id -eq "checkpoint10b-check"
if (-not $reminder) { throw "Could not find checkpoint10b-check. Deploy Checkpoint 10B first." }

$reminderHelper = @'
function logScheduleRun(status, summary) {
    const log = global.get('scheduleRunLog') || [];
    log.unshift({
        id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
        job: 'meeting-reminders',
        name: 'Meeting reminders',
        trigger: isHttp ? 'manual' : 'automatic',
        status,
        summary,
        ranAt: now.toISOString()
    });
    if (log.length > 250) log.length = 250;
    global.set('scheduleRunLog', log);
}
'@
Add-LogHelper $reminder "const emails = [];`n" $reminderHelper

if ($reminder.func -notmatch "logScheduleRun\('failed', \{ errors: \['now must be") {
    $reminder.func = $reminder.func.Replace(
        "return [null, respond(400, { ok: false, errors: ['now must be a valid date/time'] })];",
        "logScheduleRun('failed', { errors: ['now must be a valid date/time'] });`n    return [null, respond(400, { ok: false, errors: ['now must be a valid date/time'] })];"
    )
}
if ($reminder.func -notmatch "sentCount: emails.length,\s*sent: sent.length") {
    $reminder.func = $reminder.func.Replace(
        "global.set('meetingReminders', reminders);`nreturn [emails.length ? emails : null, respond(202, { ok: true, sentCount: emails.length, sent, skipped, checkedAt: now.toISOString() })];",
        "global.set('meetingReminders', reminders);`nlogScheduleRun('success', { checkedReminders: reminders.length, sentCount: emails.length, sent: sent.length, skipped: skipped.length });`nreturn [emails.length ? emails : null, respond(202, { ok: true, sentCount: emails.length, sent, skipped, checkedAt: now.toISOString() })];"
    )
}

$listCode = @'
const log = global.get('scheduleRunLog') || [];
const query = msg.req && msg.req.query ? msg.req.query : {};
let records = log;
if (query.job) {
    records = records.filter(item => item.job === query.job);
}
const limit = Math.min(Math.max(Number(query.limit) || 50, 1), 250);
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = {
    ok: true,
    count: records.length,
    runs: records.slice(0, limit)
};
return msg;
'@

$clearCode = @'
global.set('scheduleRunLog', []);
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = { ok: true, message: 'Schedule run log cleared' };
return msg;
'@

$nodes = @(
    @{
        id = "checkpoint10c-tab"
        type = "tab"
        label = "Checkpoint 10C - Schedule Run Logs"
        disabled = $false
        info = "Persistent lightweight run logs for scheduled automation checks."
    },
    @{
        id = "checkpoint10c-comment"
        type = "comment"
        z = "checkpoint10c-tab"
        name = "GET /api/schedule-runs | DELETE /api/schedule-runs"
        info = "Logs check runs and summaries only; email bodies stay in delivery history records."
        x = 365
        y = 55
        wires = @()
    },
    @{
        id = "checkpoint10c-list-in"
        type = "http in"
        z = "checkpoint10c-tab"
        name = "List schedule runs"
        url = "/api/schedule-runs"
        method = "get"
        upload = $false
        swaggerDoc = ""
        x = 155
        y = 130
        wires = @(, @("checkpoint10c-list"))
    },
    @{
        id = "checkpoint10c-list"
        type = "function"
        z = "checkpoint10c-tab"
        name = "Read schedule run log"
        func = $listCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 425
        y = 130
        wires = @(, @("checkpoint10c-list-response"))
    },
    @{
        id = "checkpoint10c-list-response"
        type = "http response"
        z = "checkpoint10c-tab"
        name = "Return schedule runs"
        statusCode = ""
        headers = @{}
        x = 705
        y = 130
        wires = @()
    },
    @{
        id = "checkpoint10c-clear-in"
        type = "http in"
        z = "checkpoint10c-tab"
        name = "Clear schedule run log"
        url = "/api/schedule-runs"
        method = "delete"
        upload = $false
        swaggerDoc = ""
        x = 165
        y = 205
        wires = @(, @("checkpoint10c-clear"))
    },
    @{
        id = "checkpoint10c-clear"
        type = "function"
        z = "checkpoint10c-tab"
        name = "Clear schedule run log"
        func = $clearCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 430
        y = 205
        wires = @(, @("checkpoint10c-clear-response"))
    },
    @{
        id = "checkpoint10c-clear-response"
        type = "http response"
        z = "checkpoint10c-tab"
        name = "Return clear result"
        statusCode = ""
        headers = @{}
        x = 705
        y = 205
        wires = @()
    }
)

$allFlows = @($flows) + $nodes
$json = $allFlows | ConvertTo-Json -Depth 50 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Checkpoint 10C schedule run logs deployed."

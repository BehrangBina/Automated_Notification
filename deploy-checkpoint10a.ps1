$ErrorActionPreference = "Stop"

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object {
    $_.id -notmatch "^checkpoint10a-" -and
    $_.z -ne "checkpoint10a-tab"
})

$birthdayCheck = $flows | Where-Object id -eq "checkpoint6b-check"
if (-not $birthdayCheck) {
    throw "Could not find checkpoint6b-check birthday function"
}

$guard = @'
const scheduleSettings = global.get('scheduleSettings') || {};
const birthdaySchedule = {
    enabled: true,
    intervalMinutes: 15,
    ...(scheduleSettings.birthdayCheck || {})
};
if (!isHttp && birthdaySchedule.enabled === false) {
    node.status({ fill: 'grey', shape: 'ring', text: 'birthday schedule disabled' });
    return [null, null];
}
'@

if ($birthdayCheck.func -notmatch "birthday schedule disabled") {
    $anchor = "const force = options.force === true;`n"
    if (-not $birthdayCheck.func.Contains($anchor)) {
        throw "Could not find birthday schedule insertion point"
    }
    $birthdayCheck.func = $birthdayCheck.func.Replace($anchor, "$anchor$guard`n")
}

$defaultCode = @'
function defaultSettings() {
    return {
        birthdayCheck: {
            id: 'birthday-check',
            name: 'Birthday check',
            description: 'Checks active birthday contacts every 15 minutes in their local timezone.',
            enabled: true,
            intervalMinutes: 15,
            safeMode: true,
            updatedAt: null
        }
    };
}

const stored = global.get('scheduleSettings');
const existing = stored && typeof stored === 'object' && !Array.isArray(stored) ? stored : {};
const defaults = defaultSettings();
for (const [key, value] of Object.entries(defaults)) {
    existing[key] = { ...value, ...(existing[key] || {}) };
}
global.set('scheduleSettings', existing);
return existing;
'@

$listCode = @'
function defaults() {
    return {
        birthdayCheck: {
            id: 'birthday-check',
            name: 'Birthday check',
            description: 'Checks active birthday contacts every 15 minutes in their local timezone.',
            enabled: true,
            intervalMinutes: 15,
            safeMode: true,
            updatedAt: null
        }
    };
}

const stored = global.get('scheduleSettings');
const settings = stored && typeof stored === 'object' && !Array.isArray(stored) ? stored : {};
const merged = defaults();
if (settings.birthdayCheck && typeof settings.birthdayCheck === 'object' && !Array.isArray(settings.birthdayCheck)) {
    merged.birthdayCheck = { ...merged.birthdayCheck, ...settings.birthdayCheck };
}
global.set('scheduleSettings', merged);

const now = Date.now();
const schedules = [merged.birthdayCheck].map(item => ({
    ...item,
    status: item.enabled ? 'enabled' : 'disabled',
    nextRunEstimate: item.enabled ? new Date(now + item.intervalMinutes * 60000).toISOString() : null
}));

msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = { ok: true, count: schedules.length, schedules };
return msg;
'@

$saveCode = @'
const input = msg.payload || {};
const errors = [];
const id = msg.req && msg.req.params ? msg.req.params.id : input.id;

if (id !== 'birthday-check') {
    errors.push('unknown schedule id');
}
if (input.enabled !== undefined && typeof input.enabled !== 'boolean') {
    errors.push('enabled must be true or false');
}
if (
    input.intervalMinutes !== undefined &&
    (!Number.isInteger(input.intervalMinutes) || input.intervalMinutes < 5 || input.intervalMinutes > 1440)
) {
    errors.push('intervalMinutes must be an integer from 5 to 1440');
}

msg.headers = { 'content-type': 'application/json; charset=utf-8' };
if (errors.length) {
    msg.statusCode = 400;
    msg.payload = { ok: false, errors };
    return msg;
}

const stored = global.get('scheduleSettings');
const settings = stored && typeof stored === 'object' && !Array.isArray(stored) ? stored : {};
const current = settings.birthdayCheck || {
    id: 'birthday-check',
    name: 'Birthday check',
    description: 'Checks active birthday contacts every 15 minutes in their local timezone.',
    enabled: true,
    intervalMinutes: 15,
    safeMode: true
};

settings.birthdayCheck = {
    ...current,
    enabled: input.enabled !== undefined ? input.enabled : current.enabled,
    intervalMinutes: input.intervalMinutes || current.intervalMinutes || 15,
    updatedAt: new Date().toISOString()
};
global.set('scheduleSettings', settings);

msg.statusCode = 200;
msg.payload = { ok: true, schedule: settings.birthdayCheck };
return msg;
'@

$nodes = @(
    @{
        id = "checkpoint10a-tab"
        type = "tab"
        label = "Checkpoint 10A - Schedules"
        disabled = $false
        info = "Local schedule controls for safe automation."
    },
    @{
        id = "checkpoint10a-comment"
        type = "comment"
        z = "checkpoint10a-tab"
        name = "GET /api/schedules | POST /api/schedules/:id"
        info = "The birthday automatic check runs every 15 minutes but respects the enabled/disabled schedule setting."
        x = 360
        y = 50
        wires = @()
    },
    @{
        id = "checkpoint10a-init"
        type = "inject"
        z = "checkpoint10a-tab"
        name = "Initialize schedule defaults"
        props = @(@{ p = "payload" })
        repeat = ""
        crontab = ""
        once = $true
        onceDelay = 1
        topic = ""
        payload = ""
        payloadType = "date"
        x = 170
        y = 115
        wires = @(, @("checkpoint10a-defaults"))
    },
    @{
        id = "checkpoint10a-defaults"
        type = "function"
        z = "checkpoint10a-tab"
        name = "Ensure schedule defaults"
        func = $defaultCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 440
        y = 115
        wires = @(, @())
    },
    @{
        id = "checkpoint10a-list-in"
        type = "http in"
        z = "checkpoint10a-tab"
        name = "List schedules"
        url = "/api/schedules"
        method = "get"
        upload = $false
        swaggerDoc = ""
        x = 145
        y = 185
        wires = @(, @("checkpoint10a-list"))
    },
    @{
        id = "checkpoint10a-list"
        type = "function"
        z = "checkpoint10a-tab"
        name = "Read schedules"
        func = $listCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 400
        y = 185
        wires = @(, @("checkpoint10a-list-response"))
    },
    @{
        id = "checkpoint10a-list-response"
        type = "http response"
        z = "checkpoint10a-tab"
        name = "Return schedules"
        statusCode = ""
        headers = @{}
        x = 665
        y = 185
        wires = @()
    },
    @{
        id = "checkpoint10a-save-in"
        type = "http in"
        z = "checkpoint10a-tab"
        name = "Update schedule"
        url = "/api/schedules/:id"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 150
        y = 255
        wires = @(, @("checkpoint10a-save"))
    },
    @{
        id = "checkpoint10a-save"
        type = "function"
        z = "checkpoint10a-tab"
        name = "Persist schedule setting"
        func = $saveCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 420
        y = 255
        wires = @(, @("checkpoint10a-save-response"))
    },
    @{
        id = "checkpoint10a-save-response"
        type = "http response"
        z = "checkpoint10a-tab"
        name = "Return schedule setting"
        statusCode = ""
        headers = @{}
        x = 700
        y = 255
        wires = @()
    }
)

$allFlows = @($flows) + $nodes
$json = $allFlows | ConvertTo-Json -Depth 50 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Checkpoint 10A schedules API deployed."

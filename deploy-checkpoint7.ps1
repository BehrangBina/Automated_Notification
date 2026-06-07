$ErrorActionPreference = "Stop"

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object {
    $_.z -ne "checkpoint7-tab" -and
    $_.id -ne "checkpoint7-tab" -and
    $_.id -notmatch "^checkpoint7-(meeting|birthday|notification)-"
})

function Add-DeliveryMetadata {
    param(
        [object]$Node,
        [string]$Anchor,
        [string]$Replacement
    )
    if ($Node.func -notmatch "_deliverySource") {
        if (-not $Node.func.Contains($Anchor)) {
            throw "Could not find metadata anchor in $($Node.id)"
        }
        $Node.func = $Node.func.Replace($Anchor, $Replacement)
    }
}

$meetingBuilder = $flows | Where-Object id -eq "checkpoint6a-build"
Add-DeliveryMetadata $meetingBuilder `
    "topic: subject," `
    "topic: subject,`n    _deliverySource: 'meeting',`n    _idempotencyKey: input.idempotencyKey || null,"

$notificationBuilder = $flows | Where-Object id -eq "checkpoint6c-build"
Add-DeliveryMetadata $notificationBuilder `
    "topic: input.subject.trim()," `
    "topic: input.subject.trim(),`n    _deliverySource: 'notification',`n    _idempotencyKey: input.idempotencyKey || null,"

$birthdayBuilder = $flows | Where-Object id -eq "checkpoint6b-check"
Add-DeliveryMetadata $birthdayBuilder `
    "topic: subject," `
    "topic: subject,`n        _deliverySource: 'birthday',`n        _idempotencyKey: options.idempotencyKey || null,"

$queueCode = @'
const source = '__SOURCE__';
const history = global.get('deliveryHistory') || [];
const idempotency = global.get('deliveryIdempotency') || {};
const now = new Date().toISOString();
const requestedKey = msg._idempotencyKey ? `${source}:${msg._idempotencyKey}` : null;

if (requestedKey && idempotency[requestedKey]) {
    const existing = history.find(item => item.id === idempotency[requestedKey]);
    if (existing && ['queued', 'sent'].includes(existing.status)) {
        existing.duplicateCount = (existing.duplicateCount || 0) + 1;
        existing.lastDuplicateAt = now;
        global.set('deliveryHistory', history);
        node.status({ fill: 'blue', shape: 'ring', text: `duplicate ${existing.id}` });
        return null;
    }
}

const id = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
msg._msgid = id;
msg._deliveryId = id;
msg._deliverySource = msg._deliverySource || source;

const storedMessage = RED.util.cloneMessage(msg);
delete storedMessage.req;
delete storedMessage.res;

const record = {
    id,
    source: msg._deliverySource,
    status: 'queued',
    subject: msg.topic || '',
    recipients: String(msg.to || '').split(',').map(value => value.trim()).filter(Boolean),
    idempotencyKey: requestedKey,
    attempts: 1,
    duplicateCount: 0,
    createdAt: now,
    updatedAt: now,
    queuedAt: now,
    sentAt: null,
    failedAt: null,
    lastError: null,
    response: null,
    message: storedMessage
};
history.unshift(record);
if (history.length > 500) {
    history.length = 500;
}
if (requestedKey) {
    idempotency[requestedKey] = id;
}
global.set('deliveryHistory', history);
global.set('deliveryIdempotency', idempotency);
node.status({ fill: 'blue', shape: 'dot', text: `queued ${id}` });
return msg;
'@

$statusCode = @'
const history = global.get('deliveryHistory') || [];
const statusMessage = msg.status && msg.status.msg;
if (!statusMessage) {
    return null;
}
const deliveryId = statusMessage.id;
let record = history.find(item => item.id === deliveryId);
if (!record) {
    const statusRecipients = String(statusMessage.to || '')
        .split(',')
        .map(value => value.trim())
        .filter(Boolean)
        .sort()
        .join(',');
    record = history.find(item =>
        item.status === 'queued' &&
        item.subject === (statusMessage.topic || '') &&
        item.recipients.slice().sort().join(',') === statusRecipients
    );
}
if (!record) {
    return null;
}
const now = new Date().toISOString();
const failed = msg.status.fill === 'red';
record.status = failed ? 'failed' : 'sent';
record.updatedAt = now;
record.response = msg.status.response || null;
if (failed) {
    record.failedAt = now;
    record.lastError = msg.status.response || msg.status.text || 'Email delivery failed';
} else {
    record.sentAt = now;
    record.failedAt = null;
    record.lastError = null;
}
global.set('deliveryHistory', history);
return null;
'@

$catchCode = @'
const history = global.get('deliveryHistory') || [];
const deliveryId = msg._deliveryId || msg._msgid;
const record = history.find(item => item.id === deliveryId);
if (!record) {
    return null;
}
const now = new Date().toISOString();
record.status = 'failed';
record.updatedAt = now;
record.failedAt = now;
record.lastError = msg.error && msg.error.message ? msg.error.message : 'Email node error';
global.set('deliveryHistory', history);
return null;
'@

$sources = @(
    @{ Tab = "checkpoint6a-tab"; Email = "checkpoint6a-email"; Prefix = "checkpoint7-meeting"; Source = "meeting" },
    @{ Tab = "checkpoint6b-tab"; Email = "checkpoint6b-email"; Prefix = "checkpoint7-birthday"; Source = "birthday" },
    @{ Tab = "checkpoint6c-tab"; Email = "checkpoint6c-email"; Prefix = "checkpoint7-notification"; Source = "notification" }
)

$helperNodes = @()
foreach ($source in $sources) {
    $queueId = "$($source.Prefix)-queue"
    foreach ($node in $flows) {
        if ($node.wires) {
            for ($i = 0; $i -lt $node.wires.Count; $i++) {
                if ($node.wires[$i] -contains $source.Email) {
                    $node.wires[$i] = @($node.wires[$i] | ForEach-Object {
                        if ($_ -eq $source.Email) { $queueId } else { $_ }
                    })
                }
            }
        }
    }
    $sourceQueueCode = $queueCode.Replace("__SOURCE__", $source.Source)
    $helperNodes += @(
        @{
            id = $queueId
            type = "function"
            z = $source.Tab
            name = "Queue and prevent duplicates"
            func = $sourceQueueCode
            outputs = 1
            timeout = 0
            noerr = 0
            initialize = ""
            finalize = ""
            libs = @()
            x = 720
            y = 250
            wires = @(, @($source.Email))
        },
        @{
            id = "$($source.Prefix)-status"
            type = "status"
            z = $source.Tab
            name = "Track email result"
            scope = @($source.Email)
            x = 160
            y = 430
            wires = @(, @("$($source.Prefix)-status-update"))
        },
        @{
            id = "$($source.Prefix)-status-update"
            type = "function"
            z = $source.Tab
            name = "Mark sent or failed"
            func = $statusCode
            outputs = 1
            timeout = 0
            noerr = 0
            initialize = ""
            finalize = ""
            libs = @()
            x = 410
            y = 430
            wires = @(, @())
        },
        @{
            id = "$($source.Prefix)-catch"
            type = "catch"
            z = $source.Tab
            name = "Capture email error"
            scope = @($source.Email)
            uncaught = $false
            x = 160
            y = 480
            wires = @(, @("$($source.Prefix)-catch-update"))
        },
        @{
            id = "$($source.Prefix)-catch-update"
            type = "function"
            z = $source.Tab
            name = "Mark delivery failed"
            func = $catchCode
            outputs = 1
            timeout = 0
            noerr = 0
            initialize = ""
            finalize = ""
            libs = @()
            x = 410
            y = 480
            wires = @(, @())
        }
    )
}

$historyCode = @'
const history = global.get('deliveryHistory') || [];
const query = msg.req && msg.req.query ? msg.req.query : {};
let records = history;
if (query.status) {
    records = records.filter(item => item.status === query.status);
}
if (query.source) {
    records = records.filter(item => item.source === query.source);
}
const limit = Math.min(Math.max(Number(query.limit) || 50, 1), 200);
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = {
    ok: true,
    count: records.length,
    deliveries: records.slice(0, limit).map(({ message, ...record }) => record)
};
return msg;
'@

$dashboardCode = @'
const history = global.get('deliveryHistory') || [];
const escapeHtml = value => String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
const colors = {
    queued: '#c88a14',
    sent: '#198754',
    failed: '#c83b3b'
};
const rows = history.slice(0, 100).map(item => `
    <tr>
      <td><span class="status" style="background:${colors[item.status] || '#687386'}">${escapeHtml(item.status)}</span></td>
      <td>${escapeHtml(item.source)}</td>
      <td>${escapeHtml(item.subject)}</td>
      <td>${escapeHtml(item.recipients.join(', '))}</td>
      <td>${escapeHtml(item.attempts)}</td>
      <td>${escapeHtml(item.duplicateCount || 0)}</td>
      <td>${escapeHtml(item.updatedAt)}</td>
      <td>${escapeHtml(item.lastError || '')}</td>
    </tr>`).join('');
const summary = ['sent', 'failed', 'queued'].map(status => {
    const count = history.filter(item => item.status === status).length;
    return `<div class="card"><strong>${count}</strong><span>${status}</span></div>`;
}).join('');
msg.statusCode = 200;
msg.headers = { 'content-type': 'text/html; charset=utf-8' };
msg.payload = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Parman Delivery History</title>
<style>
body{margin:0;background:#eef2f7;color:#202938;font-family:Arial,sans-serif}
.wrap{max-width:1180px;margin:0 auto;padding:28px 16px}
h1{margin:0 0 8px;color:#173b57}.sub{color:#687386;margin-bottom:24px}
.summary{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:22px}.card{background:#fff;border-radius:12px;padding:16px 24px;box-shadow:0 4px 16px rgba(20,40,60,.08);min-width:110px}.card strong{display:block;font-size:28px;color:#173b57}.card span{color:#687386;text-transform:capitalize}
.table-wrap{overflow:auto;background:#fff;border-radius:14px;box-shadow:0 5px 20px rgba(20,40,60,.09)}
table{width:100%;border-collapse:collapse;min-width:950px}th,td{padding:13px 14px;border-bottom:1px solid #e8edf1;text-align:left;font-size:13px}th{background:#173b57;color:#fff;position:sticky;top:0}.status{display:inline-block;color:#fff;border-radius:20px;padding:5px 10px;font-weight:bold;text-transform:capitalize}
.note{margin-top:16px;color:#687386;font-size:13px}
</style></head><body><div class="wrap">
<h1>Parman Delivery History</h1>
<div class="sub">Persistent email delivery status, duplicate prevention, and retry attempts</div>
<div class="summary">${summary}</div>
<div class="table-wrap"><table><thead><tr><th>Status</th><th>Source</th><th>Subject</th><th>Recipients</th><th>Attempts</th><th>Duplicates</th><th>Updated</th><th>Last error</th></tr></thead><tbody>${rows || '<tr><td colspan="8">No deliveries recorded yet.</td></tr>'}</tbody></table></div>
<div class="note">Refresh this page to see the latest delivery state.</div>
</div></body></html>`;
return msg;
'@

$reconcileCode = @'
const history = global.get('deliveryHistory') || [];
const now = Date.now();
let changed = 0;
for (const record of history) {
    if (record.status === 'queued' && now - Date.parse(record.updatedAt) > 60000) {
        record.status = 'failed';
        record.updatedAt = new Date(now).toISOString();
        record.failedAt = record.updatedAt;
        record.lastError = 'Delivery was not confirmed before the service restarted';
        changed += 1;
    }
}
if (changed) {
    global.set('deliveryHistory', history);
}
node.status({ fill: changed ? 'yellow' : 'green', shape: 'dot', text: `${changed} stale queued reconciled` });
return null;
'@

$retryCode = @'
const history = global.get('deliveryHistory') || [];
const id = msg.req && msg.req.params ? msg.req.params.id : null;
const record = history.find(item => item.id === id);
if (!record) {
    const response = {
        ...msg,
        statusCode: 404,
        headers: { 'content-type': 'application/json; charset=utf-8' },
        payload: { ok: false, errors: ['delivery not found'] }
    };
    return [null, response];
}
if (record.status !== 'failed') {
    const response = {
        ...msg,
        statusCode: 409,
        headers: { 'content-type': 'application/json; charset=utf-8' },
        payload: { ok: false, errors: ['only failed deliveries can be retried'], delivery: { id: record.id, status: record.status } }
    };
    return [null, response];
}
const now = new Date().toISOString();
record.status = 'queued';
record.updatedAt = now;
record.queuedAt = now;
record.attempts += 1;
record.lastError = null;
const retryMessage = RED.util.cloneMessage(record.message);
retryMessage._msgid = record.id;
retryMessage._deliveryId = record.id;
retryMessage._retry = true;
global.set('deliveryHistory', history);
const response = {
    ...msg,
    statusCode: 202,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    payload: { ok: true, message: 'Retry accepted', delivery: { id: record.id, status: record.status, attempts: record.attempts } }
};
return [retryMessage, response];
'@

$failedTestCode = @'
const input = msg.payload || {};
const subject = input.subject || 'Checkpoint 7 simulated failure';
const to = input.to || 'failure-test@parman.local';
const delivery = {
    ...msg,
    to,
    from: 'reliability@parman.local',
    topic: subject,
    payload: '<h2>Checkpoint 7</h2><p>This message intentionally uses an unavailable SMTP port to test failure tracking and retry.</p>',
    _deliverySource: 'reliability-test',
    _idempotencyKey: input.idempotencyKey || null
};
delete delivery.req;
delete delivery.res;
const response = {
    ...msg,
    statusCode: 202,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    payload: { ok: true, message: 'Failure simulation accepted' }
};
return [delivery, response];
'@

$checkpoint7Nodes = @(
    @{
        id = "checkpoint7-tab"
        type = "tab"
        label = "Checkpoint 7 - Delivery Reliability"
        disabled = $false
        info = "Persistent delivery history, duplicate prevention, failure tracking, and retry."
    },
    @{
        id = "checkpoint7-comment"
        type = "comment"
        z = "checkpoint7-tab"
        name = "GET /api/deliveries | POST /api/deliveries/:id/retry | POST /api/deliveries/test-failure"
        info = "History excludes stored email bodies. Retry is allowed only for failed deliveries."
        x = 430
        y = 50
        wires = @()
    },
    @{
        id = "checkpoint7-history-in"
        type = "http in"
        z = "checkpoint7-tab"
        name = "List delivery history"
        url = "/api/deliveries"
        method = "get"
        upload = $false
        swaggerDoc = ""
        x = 160
        y = 120
        wires = @(, @("checkpoint7-history"))
    },
    @{
        id = "checkpoint7-history"
        type = "function"
        z = "checkpoint7-tab"
        name = "Filter delivery history"
        func = $historyCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 430
        y = 120
        wires = @(, @("checkpoint7-history-response"))
    },
    @{
        id = "checkpoint7-history-response"
        type = "http response"
        z = "checkpoint7-tab"
        name = "Return delivery history"
        statusCode = ""
        headers = @{}
        x = 730
        y = 120
        wires = @()
    },
    @{
        id = "checkpoint7-dashboard-in"
        type = "http in"
        z = "checkpoint7-tab"
        name = "Delivery history page"
        url = "/delivery-history"
        method = "get"
        upload = $false
        swaggerDoc = ""
        x = 160
        y = 165
        wires = @(, @("checkpoint7-dashboard"))
    },
    @{
        id = "checkpoint7-dashboard"
        type = "function"
        z = "checkpoint7-tab"
        name = "Render delivery dashboard"
        func = $dashboardCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 430
        y = 165
        wires = @(, @("checkpoint7-dashboard-response"))
    },
    @{
        id = "checkpoint7-dashboard-response"
        type = "http response"
        z = "checkpoint7-tab"
        name = "Return delivery dashboard"
        statusCode = ""
        headers = @{}
        x = 730
        y = 165
        wires = @()
    },
    @{
        id = "checkpoint7-retry-in"
        type = "http in"
        z = "checkpoint7-tab"
        name = "Retry failed delivery"
        url = "/api/deliveries/:id/retry"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 160
        y = 210
        wires = @(, @("checkpoint7-retry"))
    },
    @{
        id = "checkpoint7-retry"
        type = "function"
        z = "checkpoint7-tab"
        name = "Validate and queue retry"
        func = $retryCode
        outputs = 2
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 430
        y = 210
        wires = @(
            @("checkpoint7-retry-email"),
            @("checkpoint7-retry-response")
        )
    },
    @{
        id = "checkpoint7-retry-email"
        type = "e-mail"
        z = "checkpoint7-tab"
        server = "parman-mailpit"
        port = "1025"
        authtype = "NONE"
        saslformat = $false
        token = "oauth2Response.access_token"
        secure = $false
        tls = $false
        name = ""
        dname = "Retry through Mailpit"
        x = 740
        y = 185
        wires = @()
    },
    @{
        id = "checkpoint7-retry-response"
        type = "http response"
        z = "checkpoint7-tab"
        name = "Return retry result"
        statusCode = ""
        headers = @{}
        x = 730
        y = 235
        wires = @()
    },
    @{
        id = "checkpoint7-failure-in"
        type = "http in"
        z = "checkpoint7-tab"
        name = "Simulate delivery failure"
        url = "/api/deliveries/test-failure"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 170
        y = 320
        wires = @(, @("checkpoint7-failure-build"))
    },
    @{
        id = "checkpoint7-failure-build"
        type = "function"
        z = "checkpoint7-tab"
        name = "Build failure test"
        func = $failedTestCode
        outputs = 2
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 420
        y = 320
        wires = @(
            @("checkpoint7-failure-queue"),
            @("checkpoint7-failure-response")
        )
    },
    @{
        id = "checkpoint7-failure-queue"
        type = "function"
        z = "checkpoint7-tab"
        name = "Queue failure test"
        func = $queueCode.Replace("__SOURCE__", "reliability-test")
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 680
        y = 295
        wires = @(, @("checkpoint7-failure-email"))
    },
    @{
        id = "checkpoint7-failure-email"
        type = "e-mail"
        z = "checkpoint7-tab"
        server = "parman-mailpit"
        port = "9999"
        authtype = "NONE"
        saslformat = $false
        token = "oauth2Response.access_token"
        secure = $false
        tls = $false
        name = ""
        dname = "Intentionally unavailable SMTP"
        x = 950
        y = 295
        wires = @()
    },
    @{
        id = "checkpoint7-failure-response"
        type = "http response"
        z = "checkpoint7-tab"
        name = "Return failure-test result"
        statusCode = ""
        headers = @{}
        x = 700
        y = 350
        wires = @()
    },
    @{
        id = "checkpoint7-status"
        type = "status"
        z = "checkpoint7-tab"
        name = "Track retry and failure tests"
        scope = @("checkpoint7-retry-email", "checkpoint7-failure-email")
        x = 180
        y = 430
        wires = @(, @("checkpoint7-status-update"))
    },
    @{
        id = "checkpoint7-status-update"
        type = "function"
        z = "checkpoint7-tab"
        name = "Mark sent or failed"
        func = $statusCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 460
        y = 430
        wires = @(, @())
    },
    @{
        id = "checkpoint7-catch"
        type = "catch"
        z = "checkpoint7-tab"
        name = "Capture retry errors"
        scope = @("checkpoint7-retry-email", "checkpoint7-failure-email")
        uncaught = $false
        x = 170
        y = 480
        wires = @(, @("checkpoint7-catch-update"))
    },
    @{
        id = "checkpoint7-catch-update"
        type = "function"
        z = "checkpoint7-tab"
        name = "Mark delivery failed"
        func = $catchCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 450
        y = 480
        wires = @(, @())
    },
    @{
        id = "checkpoint7-reconcile-start"
        type = "inject"
        z = "checkpoint7-tab"
        name = "Reconcile stale queued on startup"
        props = @(@{ p = "payload" })
        repeat = ""
        crontab = ""
        once = $true
        onceDelay = 2
        topic = ""
        payload = ""
        payloadType = "date"
        x = 190
        y = 550
        wires = @(, @("checkpoint7-reconcile"))
    },
    @{
        id = "checkpoint7-reconcile"
        type = "function"
        z = "checkpoint7-tab"
        name = "Mark unconfirmed deliveries failed"
        func = $reconcileCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 490
        y = 550
        wires = @(, @())
    }
)

$allFlows = @($flows) + $helperNodes + $checkpoint7Nodes
$json = $allFlows | ConvertTo-Json -Depth 50 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Checkpoint 7 delivery reliability deployed."

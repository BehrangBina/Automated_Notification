$ErrorActionPreference = "Stop"

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object {
    $_.id -notmatch "^checkpoint9b-" -and
    $_.z -ne "checkpoint9b-tab"
})

$saveCode = @'
const input = msg.payload || {};
const errors = [];
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

if (typeof input.name !== 'string' || !input.name.trim()) {
    errors.push('name is required');
}
if (
    !Array.isArray(input.emails) ||
    input.emails.length === 0 ||
    input.emails.some(email => typeof email !== 'string' || !emailPattern.test(email.trim()))
) {
    errors.push('emails must contain at least one valid email address');
}
if (input.description !== undefined && typeof input.description !== 'string') {
    errors.push('description must be text');
}

msg.headers = { 'content-type': 'application/json; charset=utf-8' };
if (errors.length) {
    msg.statusCode = 400;
    msg.payload = { ok: false, errors };
    return msg;
}

const groups = global.get('recipientGroups') || [];
const id = typeof input.id === 'string' && input.id.trim()
    ? input.id.trim()
    : `${Date.now()}-${Math.random().toString(16).slice(2)}`;
const duplicateName = groups.find(group =>
    group.id !== id &&
    group.name.toLocaleLowerCase() === input.name.trim().toLocaleLowerCase()
);
if (duplicateName) {
    msg.statusCode = 409;
    msg.payload = { ok: false, errors: ['a recipient group with this name already exists'] };
    return msg;
}

const now = new Date().toISOString();
const index = groups.findIndex(group => group.id === id);
const created = index === -1;
const group = {
    id,
    name: input.name.trim(),
    description: (input.description || '').trim(),
    emails: [...new Set(input.emails.map(email => email.trim().toLowerCase()))],
    createdAt: created ? now : groups[index].createdAt,
    updatedAt: now
};
if (created) {
    groups.push(group);
} else {
    groups[index] = group;
}
global.set('recipientGroups', groups);

msg.statusCode = created ? 201 : 200;
msg.payload = {
    ok: true,
    created,
    message: created ? 'Recipient group created' : 'Recipient group updated',
    group
};
return msg;
'@

$listCode = @'
const groups = global.get('recipientGroups') || [];
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = {
    ok: true,
    count: groups.length,
    groups: groups.slice().sort((a, b) => a.name.localeCompare(b.name))
};
return msg;
'@

$deleteCode = @'
const groups = global.get('recipientGroups') || [];
const id = msg.req && msg.req.params ? msg.req.params.id : null;
const index = groups.findIndex(group => group.id === id);
msg.headers = { 'content-type': 'application/json; charset=utf-8' };

if (index === -1) {
    msg.statusCode = 404;
    msg.payload = { ok: false, errors: ['recipient group not found'] };
    return msg;
}

const [deleted] = groups.splice(index, 1);
global.set('recipientGroups', groups);
msg.statusCode = 200;
msg.payload = {
    ok: true,
    message: 'Recipient group deleted',
    group: deleted,
    remainingCount: groups.length
};
return msg;
'@

$nodes = @(
    @{
        id = "checkpoint9b-tab"
        type = "tab"
        label = "Checkpoint 9B - Recipient Groups"
        disabled = $false
        info = "Persistent reusable email groups for meetings, birthdays, and notifications."
    },
    @{
        id = "checkpoint9b-comment"
        type = "comment"
        z = "checkpoint9b-tab"
        name = "GET/POST /api/recipient-groups | DELETE /api/recipient-groups/:id"
        info = "Groups store validated unique email addresses in Node-RED persistent context."
        x = 390
        y = 50
        wires = @()
    },
    @{
        id = "checkpoint9b-save-in"
        type = "http in"
        z = "checkpoint9b-tab"
        name = "Save recipient group"
        url = "/api/recipient-groups"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 150
        y = 120
        wires = @(, @("checkpoint9b-save"))
    },
    @{
        id = "checkpoint9b-save"
        type = "function"
        z = "checkpoint9b-tab"
        name = "Validate and persist group"
        func = $saveCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 430
        y = 120
        wires = @(, @("checkpoint9b-save-response"))
    },
    @{
        id = "checkpoint9b-save-response"
        type = "http response"
        z = "checkpoint9b-tab"
        name = "Return saved group"
        statusCode = ""
        headers = @{}
        x = 720
        y = 120
        wires = @()
    },
    @{
        id = "checkpoint9b-list-in"
        type = "http in"
        z = "checkpoint9b-tab"
        name = "List recipient groups"
        url = "/api/recipient-groups"
        method = "get"
        upload = $false
        swaggerDoc = ""
        x = 150
        y = 190
        wires = @(, @("checkpoint9b-list"))
    },
    @{
        id = "checkpoint9b-list"
        type = "function"
        z = "checkpoint9b-tab"
        name = "Read persistent groups"
        func = $listCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 430
        y = 190
        wires = @(, @("checkpoint9b-list-response"))
    },
    @{
        id = "checkpoint9b-list-response"
        type = "http response"
        z = "checkpoint9b-tab"
        name = "Return group list"
        statusCode = ""
        headers = @{}
        x = 720
        y = 190
        wires = @()
    },
    @{
        id = "checkpoint9b-delete-in"
        type = "http in"
        z = "checkpoint9b-tab"
        name = "Delete recipient group"
        url = "/api/recipient-groups/:id"
        method = "delete"
        upload = $false
        swaggerDoc = ""
        x = 160
        y = 260
        wires = @(, @("checkpoint9b-delete"))
    },
    @{
        id = "checkpoint9b-delete"
        type = "function"
        z = "checkpoint9b-tab"
        name = "Delete persistent group"
        func = $deleteCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 440
        y = 260
        wires = @(, @("checkpoint9b-delete-response"))
    },
    @{
        id = "checkpoint9b-delete-response"
        type = "http response"
        z = "checkpoint9b-tab"
        name = "Return delete result"
        statusCode = ""
        headers = @{}
        x = 720
        y = 260
        wires = @()
    }
)

$allFlows = @($flows) + $nodes
$json = $allFlows | ConvertTo-Json -Depth 50 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Checkpoint 9B recipient groups API deployed."

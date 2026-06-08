$ErrorActionPreference = "Stop"

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object {
    $_.id -notmatch "^checkpoint9a-" -and
    $_.z -ne "checkpoint9a-tab"
})

$deleteCode = @'
const contacts = global.get('birthdayContacts') || [];
const id = msg.req && msg.req.params ? msg.req.params.id : null;
const index = contacts.findIndex(contact => contact.id === id);

msg.headers = { 'content-type': 'application/json; charset=utf-8' };
if (index === -1) {
    msg.statusCode = 404;
    msg.payload = { ok: false, errors: ['birthday contact not found'] };
    return msg;
}

const [deleted] = contacts.splice(index, 1);
global.set('birthdayContacts', contacts);

const deliveries = global.get('birthdayDeliveries') || {};
let deliveriesChanged = false;
for (const key of Object.keys(deliveries)) {
    if (key.startsWith(`${id}:`)) {
        delete deliveries[key];
        deliveriesChanged = true;
    }
}
if (deliveriesChanged) {
    global.set('birthdayDeliveries', deliveries);
}

msg.statusCode = 200;
msg.payload = {
    ok: true,
    message: 'Birthday contact deleted',
    contact: deleted,
    remainingCount: contacts.length
};
return msg;
'@

$nodes = @(
    @{
        id = "checkpoint9a-tab"
        type = "tab"
        label = "Checkpoint 9A - Birthday Management"
        disabled = $false
        info = "Delete birthday contacts safely while retaining the existing create, list, edit, and test APIs."
    },
    @{
        id = "checkpoint9a-comment"
        type = "comment"
        z = "checkpoint9a-tab"
        name = "DELETE /api/birthdays/contacts/:id"
        info = "Removes one birthday contact and its per-contact sent markers. The UI asks for confirmation first."
        x = 310
        y = 60
        wires = @()
    },
    @{
        id = "checkpoint9a-delete-in"
        type = "http in"
        z = "checkpoint9a-tab"
        name = "Delete birthday contact"
        url = "/api/birthdays/contacts/:id"
        method = "delete"
        upload = $false
        swaggerDoc = ""
        x = 170
        y = 130
        wires = @(, @("checkpoint9a-delete"))
    },
    @{
        id = "checkpoint9a-delete"
        type = "function"
        z = "checkpoint9a-tab"
        name = "Delete persistent contact"
        func = $deleteCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 450
        y = 130
        wires = @(, @("checkpoint9a-delete-response"))
    },
    @{
        id = "checkpoint9a-delete-response"
        type = "http response"
        z = "checkpoint9a-tab"
        name = "Return delete result"
        statusCode = ""
        headers = @{}
        x = 730
        y = 130
        wires = @()
    }
)

$allFlows = @($flows) + $nodes
$json = $allFlows | ConvertTo-Json -Depth 50 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Checkpoint 9A birthday delete API deployed."

const state = { contacts: [], deliveries: [] };

const $ = (selector, parent = document) => parent.querySelector(selector);
const $$ = (selector, parent = document) => [...parent.querySelectorAll(selector)];

function splitLines(value) {
  return value.split(/\r?\n/).map(item => item.trim()).filter(Boolean);
}

function uniqueKey(prefix) {
  return `${prefix}-${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}`;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

async function api(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: { "content-type": "application/json; charset=utf-8", ...(options.headers || {}) }
  });
  const type = response.headers.get("content-type") || "";
  const data = type.includes("application/json") ? await response.json() : await response.text();
  if (!response.ok) {
    const message = data?.errors?.join(", ") || data?.message || `Request failed (${response.status})`;
    throw new Error(message);
  }
  return data;
}

function toast(message, isError = false) {
  const element = $("#toast");
  element.textContent = message;
  element.className = `toast show${isError ? " error" : ""}`;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => element.className = "toast", 4200);
}

function setBusy(form, busy) {
  const button = form.querySelector('button[type="submit"]');
  if (!button) return;
  button.disabled = busy;
  if (!button.dataset.label) button.dataset.label = button.textContent;
  button.textContent = busy ? "Working..." : button.dataset.label;
}

function showView(name) {
  $$(".view").forEach(view => view.classList.toggle("active", view.id === `view-${name}`));
  $$(".nav-item").forEach(button => button.classList.toggle("active", button.dataset.view === name));
  const labels = { overview: "Overview", meetings: "Meetings", birthdays: "Birthdays", notifications: "Notifications", history: "Delivery history" };
  $("#page-title").textContent = labels[name] || "Parman Automation";
  $(".sidebar").classList.remove("open");
  if (name === "overview") loadOverview();
  if (name === "birthdays") loadContacts();
  if (name === "history") loadHistory();
  history.replaceState(null, "", `#${name}`);
}

async function loadOverview() {
  try {
    const [contacts, historyData] = await Promise.all([
      api("/api/birthdays/contacts"),
      api("/api/deliveries?limit=200")
    ]);
    const deliveries = historyData.deliveries || [];
    $("#stat-contacts").textContent = contacts.count;
    $("#stat-sent").textContent = deliveries.filter(item => item.status === "sent").length;
    $("#stat-failed").textContent = deliveries.filter(item => item.status === "failed").length;
    $("#stat-duplicates").textContent = deliveries.reduce((sum, item) => sum + (item.duplicateCount || 0), 0);
    $("#health-pill").innerHTML = "<i></i>Node-RED connected";
    $("#health-pill").classList.remove("error");
  } catch (error) {
    $("#health-pill").innerHTML = "<i></i>Service unavailable";
    $("#health-pill").classList.add("error");
  }
}

async function loadContacts() {
  const container = $("#contacts-list");
  try {
    const data = await api("/api/birthdays/contacts");
    state.contacts = data.contacts || [];
    if (!state.contacts.length) {
      container.innerHTML = '<div class="empty-state">No contacts saved yet.</div>';
      return;
    }
    container.innerHTML = state.contacts.map(contact => `
      <div class="contact-card">
        <input class="contact-select" type="checkbox" value="${escapeHtml(contact.id)}" aria-label="Select ${escapeHtml(contact.name)}">
        <div><strong>${escapeHtml(contact.name)}</strong><span>${escapeHtml(contact.birthday)} · ${escapeHtml(contact.timezone)} · ${escapeHtml(contact.sendHour)}:00 · ${contact.active ? "Active" : "Inactive"}</span></div>
        <button type="button" data-edit-contact="${escapeHtml(contact.id)}">Edit</button>
      </div>`).join("");
  } catch (error) {
    container.innerHTML = `<div class="empty-state">${escapeHtml(error.message)}</div>`;
  }
}

function editContact(id) {
  const contact = state.contacts.find(item => item.id === id);
  if (!contact) return;
  const form = $("#birthday-form");
  form.elements.id.value = contact.id;
  form.elements.name.value = contact.name;
  form.elements.birthday.value = contact.birthday;
  form.elements.timezone.value = contact.timezone;
  form.elements.sendHour.value = contact.sendHour;
  form.elements.recipientEmails.value = contact.recipientEmails.join("\n");
  form.elements.active.checked = contact.active;
  $("#birthday-form-title").textContent = "Edit birthday contact";
  $("#cancel-birthday-edit").classList.remove("hidden");
  form.scrollIntoView({ behavior: "smooth", block: "start" });
}

function resetBirthdayForm() {
  const form = $("#birthday-form");
  form.reset();
  form.elements.id.value = "";
  form.elements.sendHour.value = "9";
  form.elements.timezone.value = "Australia/Melbourne";
  form.elements.recipientEmails.value = "members@parman.local";
  form.elements.active.checked = true;
  $("#birthday-form-title").textContent = "Add a birthday contact";
  $("#cancel-birthday-edit").classList.add("hidden");
}

async function loadHistory() {
  const body = $("#history-body");
  body.innerHTML = '<tr><td colspan="8">Loading delivery history...</td></tr>';
  const status = $("#history-status").value;
  const source = $("#history-source").value;
  const query = new URLSearchParams({ limit: "100" });
  if (status) query.set("status", status);
  if (source) query.set("source", source);
  try {
    const data = await api(`/api/deliveries?${query}`);
    state.deliveries = data.deliveries || [];
    if (!state.deliveries.length) {
      body.innerHTML = '<tr><td colspan="8">No deliveries match these filters.</td></tr>';
      return;
    }
    body.innerHTML = state.deliveries.map(item => `
      <tr>
        <td><span class="status ${escapeHtml(item.status)}">${escapeHtml(item.status)}</span></td>
        <td>${escapeHtml(item.source)}</td>
        <td>${escapeHtml(item.subject)}</td>
        <td>${escapeHtml(item.recipients.join(", "))}</td>
        <td>${escapeHtml(item.attempts)}</td>
        <td>${escapeHtml(item.duplicateCount || 0)}</td>
        <td>${escapeHtml(new Date(item.updatedAt).toLocaleString())}</td>
        <td>${item.status === "failed" ? `<button class="retry-button" data-retry="${escapeHtml(item.id)}">Retry</button>` : ""}</td>
      </tr>`).join("");
  } catch (error) {
    body.innerHTML = `<tr><td colspan="8">${escapeHtml(error.message)}</td></tr>`;
  }
}

$("#meeting-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  const values = Object.fromEntries(new FormData(form));
  const payload = {
    title: values.title,
    date: values.date,
    time: values.time,
    timezone: values.timezone,
    durationMinutes: Number(values.durationMinutes),
    greeting: values.greeting,
    agenda: splitLines(values.agenda),
    zoomUrl: values.zoomUrl,
    meetingId: values.meetingId,
    passcode: values.passcode,
    idempotencyKey: uniqueKey("meeting"),
    organizer: { name: values.organizerName, email: values.organizerEmail },
    recipients: splitLines(values.recipients),
    displayTimezones: [
      { label: "اروپای مرکزی", timezone: "Europe/Paris" },
      { label: "ملبورن", timezone: "Australia/Melbourne" },
      { label: "لندن", timezone: "Europe/London" },
      { label: "نیویورک", timezone: "America/New_York" }
    ]
  };
  try {
    await api("/api/meetings/send", { method: "POST", body: JSON.stringify(payload) });
    toast("Meeting invitation sent to Mailpit successfully.");
  } catch (error) {
    toast(error.message, true);
  } finally {
    setBusy(form, false);
  }
});

$("#birthday-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  const values = Object.fromEntries(new FormData(form));
  const payload = {
    id: values.id || undefined,
    name: values.name,
    birthday: values.birthday,
    timezone: values.timezone,
    sendHour: Number(values.sendHour),
    recipientEmails: splitLines(values.recipientEmails),
    active: form.elements.active.checked
  };
  try {
    await api("/api/birthdays/contacts", { method: "POST", body: JSON.stringify(payload) });
    toast(values.id ? "Birthday contact updated." : "Birthday contact saved.");
    resetBirthdayForm();
    await loadContacts();
    await loadOverview();
  } catch (error) {
    toast(error.message, true);
  } finally {
    setBusy(form, false);
  }
});

$("#run-birthday-test").addEventListener("click", async event => {
  const selected = $$(".contact-select:checked").map(input => input.value);
  if (!selected.length) {
    toast("Select at least one birthday contact first.", true);
    return;
  }
  const button = event.currentTarget;
  button.disabled = true;
  try {
    const result = await api("/api/birthdays/check", {
      method: "POST",
      body: JSON.stringify({ force: true, contactIds: selected, idempotencyKey: uniqueKey("birthday-test") })
    });
    toast(`${result.queuedContacts?.length || 0} birthday contact(s) sent to Mailpit.`);
  } catch (error) {
    toast(error.message, true);
  } finally {
    button.disabled = false;
  }
});

$("#notification-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  const values = Object.fromEntries(new FormData(form));
  const action = values.actionLabel && values.actionUrl ? { label: values.actionLabel, url: values.actionUrl } : undefined;
  const payload = {
    language: values.language,
    type: values.type,
    subject: values.subject,
    title: values.title,
    message: values.message,
    recipients: splitLines(values.recipients),
    channels: ["email"],
    idempotencyKey: uniqueKey("notification"),
    action
  };
  try {
    await api("/api/notifications/send", { method: "POST", body: JSON.stringify(payload) });
    toast("Notification sent to Mailpit successfully.");
  } catch (error) {
    toast(error.message, true);
  } finally {
    setBusy(form, false);
  }
});

$("#history-body").addEventListener("click", async event => {
  const button = event.target.closest("[data-retry]");
  if (!button) return;
  button.disabled = true;
  try {
    await api(`/api/deliveries/${encodeURIComponent(button.dataset.retry)}/retry`, { method: "POST", body: "{}" });
    toast("Retry accepted.");
    setTimeout(loadHistory, 1600);
  } catch (error) {
    toast(error.message, true);
    button.disabled = false;
  }
});

$("#contacts-list").addEventListener("click", event => {
  const button = event.target.closest("[data-edit-contact]");
  if (button) editContact(button.dataset.editContact);
});

$$(".nav-item").forEach(button => button.addEventListener("click", () => showView(button.dataset.view)));
$$("[data-go]").forEach(button => button.addEventListener("click", () => showView(button.dataset.go)));
$("#mobile-menu").addEventListener("click", () => $(".sidebar").classList.toggle("open"));
$("#refresh-contacts").addEventListener("click", loadContacts);
$("#cancel-birthday-edit").addEventListener("click", resetBirthdayForm);
$("#refresh-history").addEventListener("click", loadHistory);
$("#history-status").addEventListener("change", loadHistory);
$("#history-source").addEventListener("change", loadHistory);

const initialView = location.hash.replace("#", "");
showView(["overview", "meetings", "birthdays", "notifications", "history"].includes(initialView) ? initialView : "overview");

import { Buffer } from "buffer";

if (typeof globalThis.global === "undefined") {
  globalThis.global = globalThis;
}
if (typeof globalThis.Buffer === "undefined") {
  globalThis.Buffer = Buffer;
}

import {
  CognitoUserPool,
  CognitoUser,
  AuthenticationDetails
} from "amazon-cognito-identity-js";

const config = window.APP_CONFIG;
const $ = (id) => document.getElementById(id);

let pool = null;
let employees = [];
let currentPage = 1;
let selectedEmployee = null;
let isSaving = false;

function showMessage(message) {
  const el = $("statusMessage");
  if (el) el.textContent = message;
}

function showFormMessage(message, success = false) {
  const el = $("formMessage");
  if (!el) return;
  el.textContent = message;
  el.classList.toggle("success", success);
}

function setPage(page) {
  const dashboard = page === "dashboard";
  $("dashboard").hidden = !dashboard;
  $("employees").hidden = dashboard;
  $("employeeEditor").hidden = true;

  $("pageTitle").textContent = dashboard
    ? "Welcome to HR Dashboard"
    : "Employees";

  document.querySelectorAll(".nav-link").forEach((link) => {
    const active = link.getAttribute("href") === `#${page}`;
    link.classList.toggle("active", active);
    if (active) link.setAttribute("aria-current", "page");
    else link.removeAttribute("aria-current");
  });

  if (dashboard) {
    history.replaceState(null, "", "#dashboard");
  } else {
    history.replaceState(null, "", "#employees");
  }
}

function showLoggedIn() {
  document.body.classList.remove("logged-out");
  $("loginSection").hidden = true;
  $("employeeSection").hidden = false;
  $("logoutBtn").hidden = false;

  const requestedPage = location.hash === "#employees"
    ? "employees"
    : "dashboard";

  setPage(requestedPage);
}

function showLoggedOut() {
  document.body.classList.add("logged-out");
  $("loginSection").hidden = false;
  $("employeeSection").hidden = true;
  $("logoutBtn").hidden = true;
  $("employeeEditor").hidden = true;
  closeProfile();
  $("pageTitle").textContent = "Welcome to HR Dashboard";
}

function getSession() {
  return new Promise((resolve, reject) => {
    const user = pool?.getCurrentUser();

    if (!user) {
      reject(new Error("Please log in."));
      return;
    }

    user.getSession((error, session) => {
      if (error || !session || !session.isValid()) {
        reject(error || new Error("Session expired. Please log in again."));
        return;
      }

      resolve({
        user,
        accessToken: session.getAccessToken().getJwtToken()
      });
    });
  });
}

function login(email, password) {
  return new Promise((resolve, reject) => {
    const user = new CognitoUser({ Username: email, Pool: pool });
    const auth = new AuthenticationDetails({
      Username: email,
      Password: password
    });

    user.authenticateUser(auth, {
      onSuccess: resolve,
      onFailure: reject,
      newPasswordRequired: () => reject(new Error(
        "Cognito requires a new password. Complete the first-login password setup before continuing."
      )),
      mfaRequired: () => reject(new Error(
        "MFA is enabled, but this login page does not yet support MFA verification."
      ))
    });
  });
}

async function apiRequest(path, options = {}) {
  const { accessToken } = await getSession();

  const response = await fetch(`${config.apiBaseUrl}${path}`, {
    ...options,
    headers: {
      ...(options.body ? { "Content-Type": "application/json" } : {}),
      Authorization: `Bearer ${accessToken}`,
      ...options.headers
    }
  });

  if (response.status === 401) {
    throw new Error("Your session expired or your login is invalid.");
  }

  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || "The request failed.");
  return data;
}

function employeeName(e) {
  return String(e.name || "");
}

function employeeDepartment(e) {
  return String(e.department || "");
}

function employeeEmail(e) {
  return String(e.email || "");
}

function employeeJobTitle(e) {
  return String(e.job_title || e.jobTitle || "");
}

function employeeJoiningDate(e) {
  return String(e.joining_date || e.joiningDate || "").slice(0, 10);
}

function employeeEmploymentStatus(e) {
  const value = e.employment_status || e.employmentStatus || "Active";
  return value === "Inactive" ? "Inactive" : "Active";
}

function formatDate(value) {
  if (!value) return "—";
  const match = String(value).match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (match) return `${match[3]}/${match[2]}/${match[1]}`;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? "—" : date.toLocaleDateString();
}

function initials(name) {
  return String(name || "E").trim().split(/\s+/).slice(0, 2)
    .map((part) => part.charAt(0).toUpperCase()).join("") || "E";
}

function createCell(text, className = "") {
  const cell = document.createElement("td");
  cell.textContent = text || "—";
  if (className) cell.className = className;
  return cell;
}

function createButton(label, className, action) {
  const button = document.createElement("button");
  button.type = "button";
  button.textContent = label;
  button.className = className;
  button.addEventListener("click", action);
  return button;
}

function populateDepartmentFilters() {
  const select = $("departmentFilter");
  const currentValue = select.value;

  const departments = [...new Set(
    employees.map(employeeDepartment).map((v) => v.trim()).filter(Boolean)
  )].sort((a, b) => a.localeCompare(b));

  select.replaceChildren();
  const all = document.createElement("option");
  all.value = "";
  all.textContent = "All departments";
  select.appendChild(all);

  const suggestions = $("departmentSuggestions");
  if (suggestions) suggestions.replaceChildren();

  departments.forEach((department) => {
    const option = document.createElement("option");
    option.value = department;
    option.textContent = department;
    select.appendChild(option);

    if (suggestions) {
      const suggestion = document.createElement("option");
      suggestion.value = department;
      suggestions.appendChild(suggestion);
    }
  });

  if (departments.includes(currentValue)) select.value = currentValue;
}

function getFilteredEmployees() {
  const search = $("searchInput").value.trim().toLowerCase();
  const department = $("departmentFilter").value;
  const sort = $("sortSelect").value;

  const filtered = employees.filter((employee) => {
    const matchesSearch = [
      employeeName(employee),
      employeeEmail(employee),
      employeeDepartment(employee),
      employeeJobTitle(employee),
      employeeJoiningDate(employee),
      employeeEmploymentStatus(employee)
    ].some((value) => value.toLowerCase().includes(search));

    return matchesSearch &&
      (!department || employeeDepartment(employee) === department);
  });

  const sorters = {
    "name-asc": (a, b) => employeeName(a).localeCompare(employeeName(b)),
    "name-desc": (a, b) => employeeName(b).localeCompare(employeeName(a)),
    "department-asc": (a, b) =>
      employeeDepartment(a).localeCompare(employeeDepartment(b)),
    "email-asc": (a, b) => employeeEmail(a).localeCompare(employeeEmail(b))
  };

  filtered.sort(sorters[sort] || sorters["name-asc"]);
  return filtered;
}

/*
 * DASHBOARD METRICS
 *
 * Total employees: all employee records.
 * Departments: unique departments.
 * New joiners: employees whose joining date is within the last 30 days.
 * Active employees: employees with Active employment status.
 */
function renderDashboard() {
  $("totalEmployees").textContent = employees.length;

  const departments = new Set(
    employees.map(employeeDepartment)
      .map((v) => v.trim().toLowerCase()).filter(Boolean)
  );

  $("totalDepartments").textContent = departments.size;

  // Count employees whose joining date falls within the last 30 days.
  const now = new Date();
  const today = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate()
  );

  const cutoff = new Date(today);
  cutoff.setDate(cutoff.getDate() - 1);

  const recentCount = employees.filter((employee) => {
    const raw = employeeJoiningDate(employee);
    if (!raw) return false;

    const match = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (!match) return false;

    const joiningDate = new Date(
      Number(match[1]),
      Number(match[2]) - 1,
      Number(match[3])
    );

    return !Number.isNaN(joiningDate.getTime()) &&
      joiningDate >= cutoff &&
      joiningDate <= today;
  }).length;

  $("recentEmployees").textContent = recentCount;

  // Count active employees from the employment status field.
  const activeCount = employees.filter(
    (employee) => employeeEmploymentStatus(employee) === "Active"
  ).length;

  $("activeEmployees").textContent = activeCount;
}

function openProfile(employee) {
  selectedEmployee = employee;
  $("profileAvatar").textContent = initials(employeeName(employee));
  $("profileName").textContent = employeeName(employee) || "Employee";
  $("profileJobTitle").textContent =
    employeeJobTitle(employee) || "Job title not provided";
  $("profileId").textContent = employee.id ?? "—";
  $("profileEmail").textContent = employeeEmail(employee) || "—";
  $("profileDepartment").textContent = employeeDepartment(employee) || "—";
  $("profileJoiningDate").textContent = formatDate(employeeJoiningDate(employee));
  $("profileEmploymentStatus").textContent = employeeEmploymentStatus(employee);
  $("profileOverlay").hidden = false;
  $("closeProfileBtn").focus();
}

function closeProfile() {
  const overlay = $("profileOverlay");
  if (overlay) overlay.hidden = true;
  selectedEmployee = null;
}

function renderEmployees() {
  const filtered = getFilteredEmployees();
  const pageSize = Number($("pageSize").value) || 10;
  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));

  currentPage = Math.min(Math.max(1, currentPage), totalPages);
  const start = (currentPage - 1) * pageSize;
  const visible = filtered.slice(start, start + pageSize);
  const table = $("employeeTable");
  table.replaceChildren();

  visible.forEach((employee) => {
    const row = document.createElement("tr");

    const nameCell = document.createElement("td");
    const employeeBox = document.createElement("div");
    employeeBox.className = "employee-cell";

    const avatar = document.createElement("span");
    avatar.className = "employee-avatar";
    avatar.textContent = initials(employeeName(employee));

    const identity = document.createElement("div");
    const name = document.createElement("span");
    name.className = "employee-name";
    name.textContent = employeeName(employee) || "Unnamed employee";

    const idText = document.createElement("span");
    idText.className = "employee-subtitle";
    idText.textContent = `ID: ${employee.id ?? "—"}`;

    identity.append(name, idText);
    employeeBox.append(avatar, identity);
    nameCell.appendChild(employeeBox);
    row.appendChild(nameCell);

    const departmentCell = document.createElement("td");
    const departmentPill = document.createElement("span");
    departmentPill.className = "department-pill";
    departmentPill.textContent = employeeDepartment(employee) || "—";
    departmentCell.appendChild(departmentPill);
    row.appendChild(departmentCell);

    row.appendChild(createCell(employeeJobTitle(employee)));
    row.appendChild(createCell(employeeEmail(employee)));
    row.appendChild(createCell(formatDate(employeeJoiningDate(employee))));

    const statusCell = document.createElement("td");
    const statusPill = document.createElement("span");
    const status = employeeEmploymentStatus(employee);
    statusPill.className = `status-pill ${status.toLowerCase()}`;
    statusPill.textContent = status;
    statusCell.appendChild(statusPill);
    row.appendChild(statusCell);

    const actionsCell = document.createElement("td");
    const actions = document.createElement("div");
    actions.className = "row-actions";
    actions.append(
      createButton("View", "row-action", () => openProfile(employee)),
      createButton("Edit", "row-action", () => startEdit(employee)),
      createButton("Delete", "row-action delete", () => removeEmployee(employee.id))
    );
    actionsCell.appendChild(actions);
    row.appendChild(actionsCell);
    table.appendChild(row);
  });

  $("emptyState").hidden = filtered.length !== 0;
  table.parentElement.hidden = filtered.length === 0;

  const from = filtered.length ? start + 1 : 0;
  const to = Math.min(start + pageSize, filtered.length);
  $("paginationInfo").textContent =
    `Showing ${from}–${to} of ${filtered.length} employees`;
  $("pageInfo").textContent = `${currentPage} / ${totalPages}`;
  $("prevPageBtn").disabled = currentPage <= 1;
  $("nextPageBtn").disabled = currentPage >= totalPages;

  // Dashboard counts are based on all employees, not filtered results.
  renderDashboard();
}

async function loadEmployees() {
  showMessage("Loading employee records…");
  const data = await apiRequest("/api/employees");
  employees = Array.isArray(data.employees) ? data.employees : [];
  populateDepartmentFilters();
  renderEmployees();
  showMessage(`${employees.length} employee record(s) loaded.`);
}

function openEditor(employee = null) {
  $("employeeEditor").hidden = false;
  $("employeeForm").reset();
  $("employeeId").value = "";

  if (employee) {
    $("formTitle").textContent = "Edit employee";
    $("employeeId").value = employee.id;
    $("name").value = employeeName(employee);
    $("employeeEmail").value = employeeEmail(employee);
    $("department").value = employeeDepartment(employee);
    $("jobTitle").value = employeeJobTitle(employee);
    $("joiningDate").value = employeeJoiningDate(employee);
    $("employmentStatus").value = employeeEmploymentStatus(employee);
    $("saveBtn").textContent = "Update employee";
  } else {
    $("formTitle").textContent = "Add employee";
    $("saveBtn").textContent = "Save employee";
    $("joiningDate").value = "";
    $("employmentStatus").value = "Active";
  }

  showFormMessage("");
  $("employeeEditor").scrollIntoView({ behavior: "smooth", block: "start" });
  $("name").focus();
}

function startEdit(employee) {
  closeProfile();
  setPage("employees");
  openEditor(employee);
}

function closeEditor() {
  $("employeeEditor").hidden = true;
  $("employeeForm").reset();
  $("employeeId").value = "";
  showFormMessage("");
}

async function saveEmployee(event) {
  event.preventDefault();
  if (isSaving) return;

  const id = $("employeeId").value;
  const employee = {
    name: $("name").value.trim(),
    email: $("employeeEmail").value.trim(),
    department: $("department").value.trim(),
    job_title: $("jobTitle").value.trim(),
    joining_date: $("joiningDate").value,
    employment_status: $("employmentStatus").value
  };

  if (Object.values(employee).some((value) => !value)) {
    showFormMessage("Please complete all required fields.");
    return;
  }

  if (employee.name.length > 100 ||
      employee.department.length > 100 ||
      employee.job_title.length > 100 ||
      employee.email.length > 254) {
    showFormMessage("One or more fields exceed the allowed length.");
    return;
  }

  if (!$("employeeEmail").checkValidity()) {
    showFormMessage("Enter a valid email address.");
    $("employeeEmail").focus();
    return;
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(employee.joining_date) ||
      Number.isNaN(Date.parse(`${employee.joining_date}T00:00:00`))) {
    showFormMessage("Please enter a valid joining date.");
    $("joiningDate").focus();
    return;
  }

  if (!["Active", "Inactive"].includes(employee.employment_status)) {
    showFormMessage("Choose Active or Inactive for employment status.");
    return;
  }

  isSaving = true;
  $("saveBtn").disabled = true;
  $("saveBtn").textContent = "Saving…";

  try {
    await apiRequest(
      id ? `/api/employees/${encodeURIComponent(id)}` : "/api/employees",
      { method: id ? "PUT" : "POST", body: JSON.stringify(employee) }
    );

    closeEditor();
    await loadEmployees();
    showMessage(id ? "Employee updated successfully." : "Employee added successfully.");
    $("employees").scrollIntoView({ behavior: "smooth" });
  } catch (error) {
    showFormMessage(error.message || "Could not save the employee.");
  } finally {
    isSaving = false;
    $("saveBtn").disabled = false;
    $("saveBtn").textContent = $("employeeId").value
      ? "Update employee" : "Save employee";
  }
}

async function removeEmployee(id) {
  const employee = employees.find((item) => String(item.id) === String(id));
  const name = employee ? employeeName(employee) : "this employee";

  if (!confirm(`Delete ${name}? This action cannot be undone.`)) return;

  try {
    await apiRequest(`/api/employees/${encodeURIComponent(id)}`, {
      method: "DELETE"
    });
    await loadEmployees();
    showMessage(`${name} was deleted successfully.`);
  } catch (error) {
    alert(error.message || "Could not delete the employee.");
  }
}

function exportCSV() {
  const filtered = getFilteredEmployees();
  if (!filtered.length) {
    showMessage("There are no employees to export.");
    return;
  }

  const headers = [
    "Employee ID", "Full name", "Email", "Department",
    "Job title", "Joining date", "Employment status"
  ];

  const rows = filtered.map((e) => [
    e.id ?? "", employeeName(e), employeeEmail(e),
    employeeDepartment(e), employeeJobTitle(e),
    employeeJoiningDate(e), employeeEmploymentStatus(e)
  ]);

  const csv = [headers, ...rows].map((row) =>
    row.map((value) => {
      let text = String(value ?? "");
      if (/^[\s]*[=+\-@]/.test(text)) text = "'" + text;
      return `"${text.replace(/"/g, '""')}"`;
    }).join(",")
  ).join("\r\n");

  const blob = new Blob(["\uFEFF", csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `employees-${new Date().toISOString().slice(0, 10)}.csv`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
  showMessage(`${filtered.length} employee record(s) exported.`);
}

// Login
$("loginForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = event.currentTarget.querySelector("button[type='submit']");
  button.disabled = true;
  button.textContent = "Signing in…";

  try {
    await login($("email").value.trim(), $("password").value);
    $("loginForm").reset();
    showLoggedIn();
    await loadEmployees();
  } catch (error) {
    alert(error.message || "Login failed.");
    showLoggedOut();
  } finally {
    button.disabled = false;
    button.textContent = "Sign in";
  }
});

$("employeeForm").addEventListener("submit", saveEmployee);

$("searchInput").addEventListener("input", () => {
  currentPage = 1;
  renderEmployees();
});
$("departmentFilter").addEventListener("change", () => {
  currentPage = 1;
  renderEmployees();
});
$("sortSelect").addEventListener("change", () => {
  currentPage = 1;
  renderEmployees();
});
$("pageSize").addEventListener("change", () => {
  currentPage = 1;
  renderEmployees();
});

$("prevPageBtn").addEventListener("click", () => {
  if (currentPage > 1) {
    currentPage--;
    renderEmployees();
  }
});
$("nextPageBtn").addEventListener("click", () => {
  currentPage++;
  renderEmployees();
});

$("clearFiltersBtn").addEventListener("click", () => {
  $("searchInput").value = "";
  $("departmentFilter").value = "";
  $("sortSelect").value = "name-asc";
  currentPage = 1;
  renderEmployees();
});

$("addEmployeeBtn").addEventListener("click", () => {
  setPage("employees");
  openEditor();
});
$("emptyAddBtn").addEventListener("click", () => openEditor());
$("closeEditorBtn").addEventListener("click", closeEditor);
$("cancelEditBtn").addEventListener("click", closeEditor);
$("exportBtn").addEventListener("click", exportCSV);

$("closeProfileBtn").addEventListener("click", closeProfile);
$("profileDoneBtn").addEventListener("click", closeProfile);
$("profileEditBtn").addEventListener("click", () => {
  if (selectedEmployee) startEdit(selectedEmployee);
});
$("profileOverlay").addEventListener("click", (event) => {
  if (event.target === $("profileOverlay")) closeProfile();
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeProfile();
});

// Navigation: switch pages without showing the directory on the dashboard.
document.querySelectorAll(".nav-link").forEach((link) => {
  link.addEventListener("click", (event) => {
    event.preventDefault();
    const page = link.getAttribute("href") === "#employees"
      ? "employees"
      : "dashboard";
    setPage(page);
  });
});

// Brand link returns to the dashboard.
document.querySelector(".brand").addEventListener("click", (event) => {
  event.preventDefault();
  if (!$("employeeSection").hidden) setPage("dashboard");
});

// Logout
$("logoutBtn").addEventListener("click", () => {
  const user = pool?.getCurrentUser();
  if (user) user.signOut();

  employees = [];
  currentPage = 1;
  $("loginForm").reset();
  closeEditor();
  showLoggedOut();
  history.replaceState(null, "", location.pathname);
});

// Startup
if (!config || !config.userPoolId || !config.clientId || typeof config.apiBaseUrl !== "string") {
  console.error("Check your Cognito and API values in config.js.");
  showLoggedOut();
} else {
  pool = new CognitoUserPool({
    UserPoolId: config.userPoolId,
    ClientId: config.clientId
  });
  restoreSession();
}

async function restoreSession() {
  try {
    await getSession();
    showLoggedIn();
    await loadEmployees();
  } catch {
    showLoggedOut();
  }
}

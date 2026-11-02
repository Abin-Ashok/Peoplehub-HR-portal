const express = require("express");
const { pool } = require("./db");
const { queueEmployeeCreated } = require("./notifications");

const router = express.Router();

function validEmployee(body) {
  const {
    name,
    email,
    department,
    job_title,
    joining_date,
    employment_status
  } = body || {};

  const validDate =
    typeof joining_date === "string" &&
    /^\d{4}-\d{2}-\d{2}$/.test(joining_date) &&
    (() => {
      const date = new Date(`${joining_date}T00:00:00Z`);
      return (
        !Number.isNaN(date.getTime()) &&
        date.toISOString().slice(0, 10) === joining_date
      );
    })();

  return (
    typeof name === "string" &&
    name.trim().length > 0 &&
    name.trim().length <= 100 &&
    typeof email === "string" &&
    email.trim().length > 0 &&
    email.trim().length <= 254 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim()) &&
    typeof department === "string" &&
    department.trim().length > 0 &&
    department.trim().length <= 100 &&
    typeof job_title === "string" &&
    job_title.trim().length > 0 &&
    job_title.trim().length <= 100 &&
    validDate &&
    ["Active", "Inactive"].includes(employment_status)
  );
}

function employeeValues(body) {
  return [
    body.name.trim(),
    body.email.trim().toLowerCase(),
    body.department.trim(),
    body.job_title.trim(),
    body.joining_date,
    body.employment_status
  ];
}

const employeeColumns = `
  id, name, email, department, job_title,
  joining_date, employment_status, created_at
`;

// GET /api/employees
router.get("/employees", async (req, res) => {
  try {
    const [employees] = await pool.query(
      `SELECT ${employeeColumns}
       FROM employees
       ORDER BY id DESC`
    );

    res.json({ employees });
  } catch (error) {
    console.error("List employees failed:", error.message);
    res.status(500).json({ error: "Could not load employees." });
  }
});

// POST /api/employees
router.post("/employees", async (req, res) => {
  if (!validEmployee(req.body)) {
    return res.status(400).json({
      error:
        "Enter a valid name, email, department, job title, joining date and status."
    });
  }

  try {
    const [result] = await pool.execute(
      `INSERT INTO employees
       (name, email, department, job_title, joining_date, employment_status)
       VALUES (?, ?, ?, ?, ?, ?)`,
      employeeValues(req.body)
    );

    const [rows] = await pool.execute(
      `SELECT ${employeeColumns}
       FROM employees WHERE id = ?`,
      [result.insertId]
    );

    const employee = rows[0];
    let notificationQueued = false;

    try {
      notificationQueued = await queueEmployeeCreated(employee);
    } catch (error) {
      console.error("Could not queue employee email:", error.message);
    }

    res.status(201).json({ employee, notificationQueued });
  } catch (error) {
    if (error.code === "ER_DUP_ENTRY") {
      return res.status(409).json({
        error: "An employee with this email already exists."
      });
    }

    console.error("Create employee failed:", error.message);
    res.status(500).json({ error: "Could not create employee." });
  }
});

// PUT /api/employees/:id
router.put("/employees/:id", async (req, res) => {
  const id = Number(req.params.id);

  if (!Number.isSafeInteger(id) || id < 1 || !validEmployee(req.body)) {
    return res.status(400).json({
      error: "Invalid employee ID or employee details."
    });
  }

  try {
    const [result] = await pool.execute(
      `UPDATE employees
       SET name = ?, email = ?, department = ?, job_title = ?,
           joining_date = ?, employment_status = ?
       WHERE id = ?`,
      [...employeeValues(req.body), id]
    );

    if (result.affectedRows === 0) {
      const [existing] = await pool.execute(
        "SELECT id FROM employees WHERE id = ?",
        [id]
      );

      if (existing.length === 0) {
        return res.status(404).json({ error: "Employee not found." });
      }
    }

    const [rows] = await pool.execute(
      `SELECT ${employeeColumns}
       FROM employees WHERE id = ?`,
      [id]
    );

    res.json({ employee: rows[0] });
  } catch (error) {
    if (error.code === "ER_DUP_ENTRY") {
      return res.status(409).json({
        error: "An employee with this email already exists."
      });
    }

    console.error("Update employee failed:", error.message);
    res.status(500).json({ error: "Could not update employee." });
  }
});

// DELETE /api/employees/:id
router.delete("/employees/:id", async (req, res) => {
  const id = Number(req.params.id);

  if (!Number.isSafeInteger(id) || id < 1) {
    return res.status(400).json({ error: "Invalid employee ID." });
  }

  try {
    const [result] = await pool.execute(
      "DELETE FROM employees WHERE id = ?",
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Employee not found." });
    }

    res.json({ message: "Employee deleted." });
  } catch (error) {
    console.error("Delete employee failed:", error.message);
    res.status(500).json({ error: "Could not delete employee." });
  }
});

module.exports = router;

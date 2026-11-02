require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const { initializeDatabase } = require("./db");
const { requireAuth } = require("./auth");
const employeeRoutes = require("./employees");

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(helmet());

app.use(cors({
  origin: process.env.FRONTEND_ORIGIN || "http://localhost:8080"
}));

app.use(express.json({ limit: "20kb" }));

// Public health check for the load balancer.
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

// All employee API operations require a valid Cognito access token.
app.use("/api", requireAuth, employeeRoutes);

async function start() {
  try {
    await initializeDatabase();

    app.listen(port, "0.0.0.0", () => {
      console.log(`Employee API listening on port ${port}`);
    });
  } catch (error) {
    console.error("Application startup failed:", error.message);
    process.exit(1);
  }
}

start();
// webhook test

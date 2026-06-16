const path = require("path");

require("dotenv").config({
  path: path.resolve(__dirname, "../.env"),
  quiet: true,
});

const express = require("express");
const cors = require("cors");
const authRoute = require("./routes/auth.route");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoute);

module.exports = app;

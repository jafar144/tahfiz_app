const mysql = require("mysql2/promise");
const { DB_HOST, DB_PORT, DB_USER, DB_NAME, DB_PASSWORD } = require("./config");

async function createConnection(options = {}) {
  return mysql.createConnection({
    host: DB_HOST.value(),
    port: Number(DB_PORT.value()),
    user: DB_USER.value(),
    password: DB_PASSWORD.value(),
    database: DB_NAME.value(),
    connectTimeout: 30000,
    ...options,
  });
}

module.exports = { createConnection };

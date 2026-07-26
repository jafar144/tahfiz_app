const { defineSecret } = require("firebase-functions/params");

const WABLAS_TOKEN = defineSecret("WABLAS_TOKEN");
const WABLAS_SECRET_KEY = defineSecret("WABLAS_SECRET_KEY");

module.exports = { WABLAS_TOKEN, WABLAS_SECRET_KEY };

const {
  ADMIN_HTTP_TOKEN,
  LEGACY_ADMIN_HTTP_ENABLED,
  secureCompare,
} = require("./legacyConfig");

function suppliedAdminHttpToken(req) {
  const headerToken = req.get("x-admin-token") || "";
  const authorization = req.get("authorization") || "";
  const bearer = authorization.match(/^Bearer\s+(.+)$/i);
  return headerToken || (bearer ? bearer[1] : "");
}

function authorizeLegacyAdminHttp(req, res) {
  if (LEGACY_ADMIN_HTTP_ENABLED.value().toLowerCase() !== "true") {
    res.status(404).json({ error: "not_found" });
    return false;
  }

  let expected = "";
  try {
    expected = ADMIN_HTTP_TOKEN.value();
  } catch (_) {
    expected = "";
  }

  if (!expected) {
    console.error("ADMIN_HTTP_TOKEN belum dikonfigurasi.");
    res.status(503).json({ error: "admin_endpoint_unavailable" });
    return false;
  }

  if (!secureCompare(suppliedAdminHttpToken(req), expected)) {
    res.status(401).json({ error: "unauthorized" });
    return false;
  }

  return true;
}

module.exports = {
  authorizeLegacyAdminHttp,
  suppliedAdminHttpToken,
};

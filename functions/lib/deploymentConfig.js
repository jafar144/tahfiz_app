const projects = require("../config/deployment.json");

// GCLOUD_PROJECT tersedia saat discovery Firebase CLI maupun di runtime.
// Project lama yang belum tercantum mempertahankan tiga scheduler existing.
function shouldDeployScheduledFunctions(
  projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
) {
  return projects[projectId]?.scheduledFunctions !== false;
}

// Firebase discovers exported functions before it reads a project's .env file.
// Use this checked-in per-project setting for temporary legacy HTTP exports.
function shouldDeployLegacyHttpFunctions(
  projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
) {
  return projects[projectId]?.legacyHttpFunctions === true;
}

function shouldBindWablasSecrets(
  projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
) {
  return projects[projectId]?.wablasSecrets !== false;
}

function shouldDeployNotificationFunctions(
  projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
) {
  return projects[projectId]?.notificationFunctions !== false;
}

function shouldDeployTranscriptionFunction(
  projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
) {
  return projects[projectId]?.transcriptionFunction !== false;
}

module.exports = {
  shouldDeployScheduledFunctions,
  shouldDeployLegacyHttpFunctions,
  shouldDeployNotificationFunctions,
  shouldBindWablasSecrets,
  shouldDeployTranscriptionFunction,
};

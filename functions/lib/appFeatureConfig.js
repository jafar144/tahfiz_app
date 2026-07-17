const APP_FEATURE_KEYS = Object.freeze(["tahfiz_arena"]);

function isSupportedAppFeature(value) {
  return APP_FEATURE_KEYS.includes(value);
}

module.exports = { APP_FEATURE_KEYS, isSupportedAppFeature };

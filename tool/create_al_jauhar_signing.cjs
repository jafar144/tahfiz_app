// One-time, non-overwriting generator. Secrets stay in ignored Android files.
const fs = require('node:fs');
const path = require('node:path');
const { randomBytes } = require('node:crypto');
const { spawnSync } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const keyStore = path.join(root, 'android/app/al-jauhar-upload.jks');
const properties = path.join(root, 'android/key.al_jauhar.properties');
if (fs.existsSync(keyStore) || fs.existsSync(properties)) {
  throw new Error('Signing Al-Jauhar already exists; refusing to replace it.');
}
const keytool = process.env.AL_JAUHAR_KEYTOOL ||
  'C:/Program Files/Android/Android Studio/jbr/bin/keytool.exe';
const password = randomBytes(32).toString('hex');
const result = spawnSync(keytool, [
  '-genkeypair', '-noprompt', '-keystore', keyStore,
  '-alias', 'al-jauhar-upload', '-keyalg', 'RSA', '-keysize', '2048',
  '-validity', '10000', '-storetype', 'JKS',
  '-storepass:env', 'AL_JAUHAR_SIGNING_PASSWORD',
  '-keypass:env', 'AL_JAUHAR_SIGNING_PASSWORD',
  '-dname', 'CN=Tahfiz Al-Jauhar, O=Al-Jauhar, C=ID',
], { env: { ...process.env, AL_JAUHAR_SIGNING_PASSWORD: password }, encoding: 'utf8' });
if (result.error || result.status !== 0) {
  throw new Error(result.error?.message || result.stderr || 'Key generation failed');
}
fs.writeFileSync(properties, [
  `storePassword=${password}`, `keyPassword=${password}`,
  'keyAlias=al-jauhar-upload', 'storeFile=al-jauhar-upload.jks', '',
].join('\n'), { flag: 'wx', mode: 0o600 });
console.log('Created separate Al-Jauhar upload key and ignored signing properties.');

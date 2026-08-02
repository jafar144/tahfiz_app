const assert = require("node:assert/strict");
const test = require("node:test");

const {
  wasEnrolledInPeriod,
  computeIncompleteAsatidz,
} = require("../lib/assessmentStatus");

function fakeFirestore(collections) {
  return {
    collection(name) {
      const filters = [];
      const query = {
        where(field, operator, value) {
          assert.equal(operator, "==");
          filters.push({ field, value });
          return query;
        },
        async get() {
          const docs = (collections[name] || [])
            .filter(({ data }) =>
              filters.every(({ field, value }) => data[field] === value),
            )
            .map(({ id, data }) => ({ id, data: () => data }));
          return {
            docs,
            forEach(callback) {
              docs.forEach(callback);
            },
          };
        },
      };
      return query;
    },
  };
}

function timestamp(iso) {
  return { toDate: () => new Date(iso) };
}

test("eligibility tanggal masuk dibandingkan pada bulan penilaian dalam WIB", () => {
  assert.equal(wasEnrolledInPeriod(null, 7, 2026), true);
  assert.equal(
    wasEnrolledInPeriod(timestamp("2026-07-01T00:00:00.000Z"), 7, 2026),
    true,
  );
  assert.equal(
    wasEnrolledInPeriod(timestamp("2026-07-31T17:00:00.000Z"), 7, 2026),
    false,
  );
  assert.equal(
    wasEnrolledInPeriod(timestamp("2027-01-01T00:00:00.000Z"), 12, 2026),
    false,
  );
});

test("status tunggakan mengecualikan santri baru dan asatidz yang lengkap", async () => {
  const firestore = fakeFirestore({
    halaqahs: [
      { id: "halaqah-a", data: { asatidz: { id: "a", name: "Ahmad" } } },
      { id: "halaqah-b", data: { asatidz: { id: "b", name: "Fatimah" } } },
    ],
    asatidz_profiles: [
      { id: "a", data: { is_active: true } },
      { id: "b", data: { is_active: true } },
      { id: "inactive", data: { is_active: false } },
    ],
    santri_profiles: [
      {
        id: "a-reported",
        data: {
          is_active: true,
          halaqah_id: "halaqah-a",
          tanggal_masuk: timestamp("2026-06-01T00:00:00.000Z"),
        },
      },
      {
        id: "a-missing",
        data: {
          is_active: true,
          halaqah_id: "halaqah-a",
          tanggal_masuk: timestamp("2026-07-01T00:00:00.000Z"),
        },
      },
      {
        id: "a-joined-august",
        data: {
          is_active: true,
          halaqah_id: "halaqah-a",
          tanggal_masuk: timestamp("2026-07-31T17:00:00.000Z"),
        },
      },
      {
        id: "b-reported",
        data: {
          is_active: true,
          halaqah_id: "halaqah-b",
          tanggal_masuk: null,
        },
      },
      {
        id: "inactive-santri",
        data: { is_active: false, halaqah_id: "halaqah-a" },
      },
    ],
    monthly_reports: [
      {
        id: "report-a",
        data: {
          bulan: 7,
          tahun: 2026,
          santri_id: "a-reported",
        },
      },
      {
        id: "report-b",
        data: {
          bulan: 7,
          tahun: 2026,
          santri_id: "b-reported",
        },
      },
    ],
  });

  const result = await computeIncompleteAsatidz(7, 2026, firestore);

  assert.deepEqual(result, [
    { uid: "a", name: "Ahmad", total: 2, count: 1 },
  ]);
});

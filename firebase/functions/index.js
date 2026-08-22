"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const seed = require("./seed.json");
const coolavListings = require("./coolavListings.json");

initializeApp();
const db = getFirestore();

function ownerAllowlist() {
  const raw = [process.env.OWNER_UIDS, process.env.OWNER_EMAILS].filter(Boolean).join(",");
  return raw.split(",").map((s) => s.trim().toLowerCase()).filter(Boolean);
}

function assertOwner(auth) {
  const owners = ownerAllowlist();
  const uid = (auth && auth.uid ? String(auth.uid) : "").toLowerCase();
  const email = (auth && auth.token && auth.token.email ? String(auth.token.email) : "").toLowerCase();
  if (!uid || owners.length === 0 || (!owners.includes(uid) && !owners.includes(email))) {
    throw new HttpsError("permission-denied", "owner only");
  }
}

async function ownerUid() {
  const uids = String(process.env.OWNER_UIDS || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (uids[0]) return uids[0];
  const emails = String(process.env.OWNER_EMAILS || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (emails[0]) {
    const user = await getAuth().getUserByEmail(emails[0]);
    return user.uid;
  }
  throw new HttpsError("failed-precondition", "OWNER_UIDS or OWNER_EMAILS required");
}

function valuateFromComps(comps) {
  const prices = comps.map((item) => Number(item.priceBYN) || 0).filter((price) => price > 0).sort((a, b) => a - b);
  if (prices.length < 2) return { ok: false, reason: "not_enough_comps" };
  const mid = Math.floor(prices.length / 2);
  const median = prices.length % 2 === 0 ? Math.round((prices[mid - 1] + prices[mid]) / 2) : prices[mid];
  return { ok: true, medianBYN: median, count: prices.length };
}

exports.autoraSeedDemo = onCall(async (request) => {
  assertOwner(request.auth);
  const sellerId = await ownerUid();
  const now = Date.now() / 1000;
  const batch = db.batch();
  for (const listing of seed.listings) {
    batch.set(db.collection("autora_listings").doc(listing.id), {
      ...listing,
      sellerId,
      isDemo: true,
      status: listing.status || "active",
    });
  }
  for (const listing of coolavListings) {
    const image = listing.image && listing.image.startsWith("http")
      ? listing.image
      : listing.image
        ? `https://firebasestorage.googleapis.com/v0/b/serzhanovich-ecosystem-ce700.firebasestorage.app/o/${encodeURIComponent(`autora/${sellerId}/listings/demo/${String(listing.image).split("/").pop()}`)}?alt=media`
        : "";
    batch.set(db.collection("autora_listings").doc(listing.id), {
      ...listing,
      sellerId,
      image,
      isDemo: true,
      status: "active",
      verified: false,
      historyCheck: false,
      photoURLs: image ? [image] : [],
      createdAt: now,
      bumpedAt: now,
    });
  }
  batch.set(db.collection("autora_fx").doc("nbrb"), seed.fx || { usdBYN: 3.28, at: now, source: "seed" });
  for (const chat of seed.chats || []) {
    batch.set(db.collection("autora_chats").doc(chat.id), chat);
  }
  await batch.commit();
  return { ok: true, listings: seed.listings.length + coolavListings.length, sellerId };
});

exports.autoraWipeDemo = onCall(async (request) => {
  assertOwner(request.auth);
  const snap = await db.collection("autora_listings").where("isDemo", "==", true).get();
  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  for (const chat of seed.chats || []) {
    batch.delete(db.collection("autora_chats").doc(chat.id));
  }
  const messages = await db.collection("autora_messages").limit(400).get();
  messages.docs.forEach((doc) => {
    const chatId = String(doc.data().chatId || "");
    if ((seed.chats || []).some((chat) => chat.id === chatId)) {
      batch.delete(doc.ref);
    }
  });
  await batch.commit();
  return { ok: true, deleted: snap.size };
});

async function take(collectionName, limit) {
  const snap = await db.collection(collectionName).limit(limit).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

exports.autoraAdminOverview = onCall(async (request) => {
  assertOwner(request.auth);
  const [users, listings, chats, messages, reports] = await Promise.all([
    take("autora_users", 80),
    take("autora_listings", 80),
    take("autora_chats", 80),
    take("autora_messages", 120),
    take("autora_reports", 80),
  ]);
  return {
    ok: true,
    counts: {
      users: users.length,
      listings: listings.length,
      chats: chats.length,
      messages: messages.length,
      reports: reports.length,
    },
    users,
    listings,
    chats,
    messages,
    reports,
  };
});

exports.autoraModerateListing = onCall(async (request) => {
  assertOwner(request.auth);
  const listingId = String((request.data && request.data.listingId) || "");
  const status = String((request.data && request.data.status) || "");
  if (!listingId || (status !== "active" && status !== "inactive")) {
    throw new HttpsError("invalid-argument", "listingId and status required");
  }
  const ref = db.collection("autora_listings").doc(listingId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "listing");
  await ref.update({ status });
  return { ok: true };
});

exports.autoraVinCheck = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "sign in");
  const vin = String((request.data && request.data.vin) || "").trim().toUpperCase();
  if (vin.length !== 17) throw new HttpsError("invalid-argument", "VIN must be 17 chars");
  const payload = { ok: false, reason: "unavailable", vin, at: Date.now() / 1000 };
  await db.collection("autora_vin_reports").doc(vin).set(payload, { merge: true });
  return payload;
});

exports.autoraValuate = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "sign in");
  const make = String((request.data && request.data.make) || "").trim();
  const model = String((request.data && request.data.model) || "").trim();
  const year = Number((request.data && request.data.year) || 0);
  if (!make) throw new HttpsError("invalid-argument", "make required");
  const snap = await db.collection("autora_listings").where("make", "==", make).limit(80).get();
  const comps = snap.docs
    .map((doc) => doc.data())
    .filter((row) => {
      if (row.status && row.status !== "active") return false;
      if (model && String(row.model) !== model) return false;
      if (year && Math.abs(Number(row.year) - year) > 1) return false;
      return true;
    });
  return valuateFromComps(comps);
});

exports.autoraRefreshFx = onSchedule("every 6 hours", async () => {
  const res = await fetch("https://api.nbrb.by/exrates/rates/431");
  if (!res.ok) return;
  const json = await res.json();
  const usdBYN = Number(json.Cur_OfficialRate);
  if (!usdBYN) return;
  await db.collection("autora_fx").doc("nbrb").set({
    usdBYN,
    at: Date.now() / 1000,
    source: "nbrb",
  });
});

exports.autoraOnListingWrite = onDocumentWritten("autora_listings/{id}", async (event) => {
  const after = event.data && event.data.after;
  if (!after || !after.exists) return null;
  const data = after.data() || {};
  const patch = {};
  if (data.verified === true && data.isDemo !== true) patch.verified = false;
  if (data.historyCheck === true && data.isDemo !== true) patch.historyCheck = false;
  if (!data.bumpedAt) patch.bumpedAt = Date.now() / 1000;
  if (Object.keys(patch).length === 0) return null;
  await after.ref.update(patch);
  return null;
});

exports.autoraNotifySavedSearch = onDocumentWritten("autora_listings/{id}", async (event) => {
  const after = event.data && event.data.after && event.data.after.data();
  if (!after || after.status === "inactive") return null;
  const searches = await db.collection("autora_saved_searches").limit(40).get();
  const hits = [];
  searches.docs.forEach((doc) => {
    const criteria = doc.data() || {};
    if (criteria.make && criteria.make !== after.make) return;
    hits.push({ searchId: doc.id, userId: criteria.userId, listingId: after.id });
  });
  if (hits.length === 0) return null;
  const batch = db.batch();
  hits.forEach((hit) => {
    const id = `hit_${hit.searchId}_${hit.listingId}`;
    batch.set(db.collection("autora_search_hits").doc(id), { ...hit, at: Date.now() / 1000 }, { merge: true });
  });
  await batch.commit();
  return { hits: hits.length };
});

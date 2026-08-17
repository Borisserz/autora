"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const seed = require("./seed.json");

initializeApp();
const db = getFirestore();

function assertOwner(uid) {
  const owners = (process.env.OWNER_UIDS || "").split(",").map((s) => s.trim()).filter(Boolean);
  if (!uid || !owners.includes(uid)) {
    throw new HttpsError("permission-denied", "owner only");
  }
}

exports.autoraSeedDemo = onCall(async (request) => {
  assertOwner(request.auth && request.auth.uid);
  const batch = db.batch();
  for (const listing of seed.listings) {
    batch.set(db.collection("autora_listings").doc(listing.id), listing);
  }
  batch.set(db.collection("autora_fx").doc("nbrb"), seed.fx);
  for (const chat of seed.chats) {
    batch.set(db.collection("autora_chats").doc(chat.id), chat);
  }
  await batch.commit();
  return { ok: true, listings: seed.listings.length };
});

exports.autoraWipeDemo = onCall(async (request) => {
  assertOwner(request.auth && request.auth.uid);
  const snap = await db.collection("autora_listings").where("isDemo", "==", true).get();
  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  for (const chat of seed.chats || []) {
    batch.delete(db.collection("autora_chats").doc(chat.id));
  }
  for (const search of seed.savedSearches || []) {
    batch.delete(db.collection("autora_saved_searches").doc(search.id));
  }
  await batch.commit();
  return { ok: true, deleted: snap.size };
});

exports.autoraOnListingWrite = onDocumentWritten("autora_listings/{id}", async () => {
  return null;
});

exports.autoraNotifySavedSearch = onDocumentWritten("autora_listings/{id}", async () => {
  return null;
});

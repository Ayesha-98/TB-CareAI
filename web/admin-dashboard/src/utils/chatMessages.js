// src/utils/chatMessages.js
import { db } from "../firebaseConfig";
import {
  addDoc,
  collection,
  serverTimestamp,
  setDoc,
  doc,
  query,
  orderBy,
  onSnapshot,
} from "firebase/firestore";

/**
 * Add one chat message to /chatbot/{userId}/messages
 */
export async function addChatMessage({ userId, sender, text, meta = {} }) {
  const msgsRef = collection(db, "chatbot", userId, "messages");
  await addDoc(msgsRef, {
    sender,                // "Patient" | "Bot" | "Admin"
    text,                  // message text
    ...meta,               // optional: intent, confidence, etc.
    timestamp: serverTimestamp(),
  });

  // Optional: keep a lightweight session doc updated for quick lists
  await setDoc(
    doc(db, "chatbot", userId),
    {
      lastMessage: text,
      lastSender: sender,
      updatedAt: serverTimestamp(),
    },
    { merge: true }
  );
}

/**
 * Live subscribe to a patient's chat, ordered by time
 * returns unsubscribe()
 */
export function subscribeToChat(userId, cb) {
  const q = query(
    collection(db, "chatbot", userId, "messages"),
    orderBy("timestamp", "asc")
  );
  return onSnapshot(q, cb);
}

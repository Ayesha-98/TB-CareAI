// src/utils/activityLog.js
import { doc, setDoc, updateDoc, arrayUnion, serverTimestamp } from "firebase/firestore";
import { db } from "../firebaseConfig";

/**
 * Writes/updates a user-activity log.
 * Each user gets ONE document in userActivity collection (docId = affectedUserUid).
 * All actions are appended to a "logs" array inside that document.
 */
export async function logActivity({
  performedByUid,
  performedByName,
  performedByEmail,
  affectedUserUid,
  affectedUserName,
  affectedUserEmail,
  currentRole,     // string: "Admin" | "Doctor" | "CHW" | "Patient"
  activity,        // string: "Login" | "Signup" | "Approve" | "Flag" | etc.
  details,         // free text
}) {
  const userActivityRef = doc(db, "userActivity", affectedUserUid);

  const activityEntry = {
    performedByUid: performedByUid || null,
    performedByName: performedByName || null,
    performedByEmail: performedByEmail || null,
    activity,
    details: details || "",
    currentRole: currentRole || "N/A",
    timestamp: serverTimestamp(),
  };

  try {
    // Append to existing document OR create new
    await setDoc(
      userActivityRef,
      {
        affectedUserUid,
        affectedUserName: affectedUserName || null,
        affectedUserEmail: affectedUserEmail || null,
        logs: arrayUnion(activityEntry),
      },
      { merge: true }
    );
  } catch (error) {
    console.error("Error logging activity:", error);
  }
}

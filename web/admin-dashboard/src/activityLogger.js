import { db } from "../firebaseConfig";
import { collection, addDoc, serverTimestamp, doc, setDoc, getDocs, query, where } from "firebase/firestore";

/**
 * Logs user activity to BOTH userActivities collection AND user's personal activityLog
 * Prevents duplicates by checking for existing similar activities
 */
export const logUserActivity = async ({
  userId,
  userName,
  userRole,
  message,
  details = "",
  category = "System",
  iconType = "event",
  source = "",
  actorId = "",
  actorName = "",
  actorRole = "",
  uniqueKey = "" // Optional: Use to prevent duplicates
}) => {
  try {
    const activityData = {
      userId,
      userName,
      userRole,
      message,
      details,
      category,
      iconType,
      source,
      actorId: actorId || userId,
      actorName: actorName || userName,
      actorRole: actorRole || userRole,
      createdAt: serverTimestamp(),
      timestamp: new Date().toISOString(),
      uniqueKey: uniqueKey || `${userId}_${message}_${Date.now()}`
    };

    // 1. Log to global userActivities collection (for admin dashboard)
    await addDoc(collection(db, "userActivities"), activityData);

    console.log("Activity logged successfully:", { userId, message });
    return true;
  } catch (error) {
    console.error("Error logging activity:", error);
    return false;
  }
};

/**
 * Specific activity logging functions for different user actions
 */
export const logUserRegistration = async (userData) => {
  return await logUserActivity({
    userId: userData.uid,
    userName: userData.name,
    userRole: userData.role,
    message: `${userData.name} registered as ${userData.role}`,
    details: userData.role === "Doctor" 
      ? `Specialization: ${userData.specialization || "Not specified"} | Hospital: ${userData.hospital || "Not assigned"}`
      : userData.role === "CHW"
      ? `Health Center: ${userData.healthCenter || "Not assigned"}`
      : `Email: ${userData.email || "No email"}`,
    category: "Users Registered",
    iconType: userData.role.toLowerCase(),
    uniqueKey: `registration_${userData.uid}`
  });
};

export const logPatientScreening = async (patientId, patientName, screeningData) => {
  return await logUserActivity({
    userId: patientId,
    userName: patientName,
    userRole: "Patient",
    message: `${patientName} submitted TB screening`,
    details: `Symptoms: ${screeningData.symptoms?.join(", ") || "None"} | Status: ${screeningData.status || "Pending"}`,
    category: "Medical Screening",
    iconType: "medical",
    uniqueKey: `screening_${patientId}_${Date.now()}`
  });
};

// NEW: Log when CHW adds a patient to assigned_patients
export const logCHWPatientAddition = async (chwId, chwName, patientId, patientName) => {
  return await logUserActivity({
    userId: chwId,
    userName: chwName,
    userRole: "CHW",
    message: `${chwName} added patient to their list`,
    details: `Patient: ${patientName} (ID: ${patientId})`,
    category: "CHW Work",
    iconType: "assignment",
    uniqueKey: `chw_add_patient_${chwId}_${patientId}`
  });
};

// NEW: Log when doctor makes diagnosis
export const logDoctorDiagnosis = async (doctorId, doctorName, patientId, patientName, diagnosisData) => {
  return await logUserActivity({
    userId: doctorId,
    userName: doctorName,
    userRole: "Doctor",
    message: `${doctorName} made diagnosis for ${patientName}`,
    details: `Diagnosis: ${diagnosisData.finalDiagnosis || "Pending"} | Patient: ${patientName}`,
    category: "Medical Diagnosis",
    iconType: "doctor",
    uniqueKey: `diagnosis_${doctorId}_${patientId}_${Date.now()}`
  });
};

// NEW: Log doctor profile updates
export const logDoctorProfileUpdate = async (doctorId, doctorName, doctorData) => {
  return await logUserActivity({
    userId: doctorId,
    userName: doctorName,
    userRole: "Doctor",
    message: `${doctorName} updated doctor profile`,
    details: `Specialization: ${doctorData.specialization || "Not specified"} | Hospital: ${doctorData.hospital || "Not assigned"}`,
    category: "Medical Professional",
    iconType: "doctor",
    uniqueKey: `doctor_profile_${doctorId}_${Date.now()}`
  });
};

export const logUserFlagging = async (flaggedUserId, flaggedUserName, flaggerId, flaggerName, reason) => {
  return await logUserActivity({
    userId: flaggedUserId,
    userName: flaggedUserName,
    userRole: "User",
    message: `${flaggedUserName} was flagged`,
    details: `Flagged by: ${flaggerName} | Reason: ${reason || "Not specified"}`,
    category: "User Management",
    iconType: "flag",
    actorId: flaggerId,
    actorName: flaggerName,
    actorRole: "Admin",
    uniqueKey: `flag_${flaggedUserId}_${Date.now()}`
  });
};

export const logUserUnflagging = async (userId, userName, adminId, adminName) => {
  return await logUserActivity({
    userId,
    userName,
    userRole: "User",
    message: `${userName} was unflagged`,
    details: `Unflagged by: ${adminName}`,
    category: "User Management",
    iconType: "check",
    actorId: adminId,
    actorName: adminName,
    actorRole: "Admin",
    uniqueKey: `unflag_${userId}_${Date.now()}`
  });
};

// NEW: Log patient registration by CHW
export const logPatientRegistrationByCHW = async (chwId, chwName, patientId, patientName) => {
  return await logUserActivity({
    userId: chwId,
    userName: chwName,
    userRole: "CHW",
    message: `${chwName} registered new patient`,
    details: `Patient: ${patientName} (ID: ${patientId})`,
    category: "Patient Registration",
    iconType: "person",
    uniqueKey: `chw_register_patient_${chwId}_${patientId}`
  });
};
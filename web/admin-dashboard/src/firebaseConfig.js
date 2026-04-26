import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getFirestore, collection, addDoc, serverTimestamp, getDoc, doc } from "firebase/firestore";
import { getAuth } from "firebase/auth";   

const firebaseConfig = {
  apiKey: "AIzaSyBGgY4oqDvib8egJ8AXU5WIHEUlfzU49zQ",
  authDomain: "tbcareappmain.firebaseapp.com",
  projectId: "tbcareappmain",
  storageBucket: "tbcareappmain.firebasestorage.app",
  messagingSenderId: "1056630945037",
  appId: "1:1056630945037:web:e4ce64ff3596a2cf71ec44",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const firestore = getFirestore(app);
export const auth = getAuth(app);   
// Export Firestore instance
export const db = getFirestore(app);

// ✅ Login Logger Function
export const logUserLogin = async (userId, email, role, authProvider = "email") => {
  try {
    await addDoc(collection(db, "login_logs"), {
      userId: userId,
      email: email,
      role: role,
      authProvider: authProvider,
      timestamp: serverTimestamp(),
      loginDate: new Date().toISOString().split('T')[0], // YYYY-MM-DD for easy querying
    });
    console.log(`✅ Login logged for ${email} (${role})`);
  } catch (error) {
    console.error("❌ Failed to log login:", error);
    // Don't break the login flow if logging fails
  }
};

// ✅ NEW: Audit Log Function - For tracking all admin and user actions
export const addAuditLog = async (action, details, targetUser = null) => {
  try {
    const currentUser = auth.currentUser;
    
    if (!currentUser) {
      console.log("⚠️ No user logged in, skipping audit log");
      return;
    }
    
    // Get current user's role from Firestore
    let userRole = "Unknown";
    try {
      const userDoc = await getDoc(doc(db, "users", currentUser.uid));
      if (userDoc.exists()) {
        userRole = userDoc.data().role || "Unknown";
      }
    } catch (err) {
      console.error("Failed to get user role:", err);
    }
    
    await addDoc(collection(db, "audit_logs"), {
      action: action,
      userId: currentUser.uid,
      userEmail: currentUser.email,
      userRole: userRole,
      details: details,
      targetUserId: targetUser?.uid || null,
      targetUserEmail: targetUser?.email || null,
      timestamp: serverTimestamp(),
      date: new Date().toISOString().split('T')[0], // YYYY-MM-DD for filtering
    });
    
    console.log(`✅ Audit log added: ${action} - ${details}`);
  } catch (error) {
    console.error("❌ Failed to add audit log:", error);
    // Don't break the flow if logging fails
  }
};

// ✅ NEW: Quick audit log functions for common actions
export const auditLogs = {
  // User management actions
  deactivateUser: async (targetUser) => {
    await addAuditLog("DEACTIVATE_USER", `Deactivated user: ${targetUser?.email}`, targetUser);
  },
  activateUser: async (targetUser) => {
    await addAuditLog("ACTIVATE_USER", `Activated user: ${targetUser?.email}`, targetUser);
  },
  flagUser: async (targetUser, reason) => {
    await addAuditLog("FLAG_USER", `Flagged user: ${targetUser?.email}. Reason: ${reason || "No reason"}`, targetUser);
  },
  unflagUser: async (targetUser) => {
    await addAuditLog("UNFLAG_USER", `Removed flag from user: ${targetUser?.email}`, targetUser);
  },
  approveDoctor: async (targetUser) => {
    await addAuditLog("APPROVE_DOCTOR", `Approved doctor: ${targetUser?.email}`, targetUser);
  },
  rejectDoctor: async (targetUser, reason) => {
    await addAuditLog("REJECT_DOCTOR", `Rejected doctor: ${targetUser?.email}. Reason: ${reason || "No reason"}`, targetUser);
  },
  
  // Role management
  roleChange: async (targetUser, oldRole, newRole) => {
    await addAuditLog("ROLE_CHANGE", `Changed role from ${oldRole} to ${newRole} for user: ${targetUser?.email}`, targetUser);
  },
  
  // Authentication
  login: async (email, role) => {
    const currentUser = auth.currentUser;
    if (currentUser) {
      await addAuditLog("LOGIN", `User logged in: ${email} (${role})`, null);
    }
  },
  logout: async () => {
    const currentUser = auth.currentUser;
    if (currentUser) {
      await addAuditLog("LOGOUT", `User logged out: ${currentUser.email}`, null);
    }
  },
  
  // Content management
  updateNotificationTemplate: async (templateName) => {
    await addAuditLog("UPDATE_TEMPLATE", `Updated notification template: ${templateName}`, null);
  },
  
  // System
  exportData: async (exportType) => {
    await addAuditLog("EXPORT_DATA", `Exported ${exportType} data`, null);
  },
};

export default app;
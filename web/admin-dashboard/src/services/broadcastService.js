// src/services/broadcastService.js
import { db } from "../firebaseConfig";
import {
  collection,
  addDoc,
  query,
  where,
  getDocs,
  serverTimestamp,
  orderBy,
  limit,
  updateDoc,
  doc,
} from "firebase/firestore";

class BroadcastService {
  /**
   * Send broadcast notification to users (Manual Firestore Only)
   * No backend server needed - writes directly to Firestore
   */
  static async sendBroadcast(message, audience, adminId) {
    try {
      console.log(`📢 Sending broadcast to ${audience}: ${message}`);

      // Save directly to Firestore (no backend server needed)
      const broadcastRef = await addDoc(collection(db, "broadcast_notifications"), {
        message: message,
        audience: audience,
        sentAt: serverTimestamp(),
        sentBy: adminId,
        read: false,           // Important: So Flutter apps show as unread
        status: "sent",
        successCount: 1,
        recipientCount: 1,
      });

      console.log(`✅ Broadcast saved to Firestore with ID: ${broadcastRef.id}`);
      
      return {
        success: true,
        message: "Notification saved successfully!",
        id: broadcastRef.id,
        count: 1
      };
      
    } catch (error) {
      console.error("❌ Broadcast error:", error);
      throw error;
    }
  }

  /**
   * Get broadcast history from Firestore
   */
  static async getBroadcastHistory(limitCount = 10) {
    try {
      const snapshot = await getDocs(
        query(
          collection(db, "broadcast_notifications"),
          orderBy("sentAt", "desc"),
          limit(limitCount)
        )
      );
      
      const notifications = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          message: data.message || '',
          audience: data.audience || 'all',
          sentAt: data.sentAt?.toDate?.() || new Date(),
          sentBy: data.sentBy || '',
          status: data.status || 'sent',
          recipientCount: data.recipientCount || 1,
          successCount: data.successCount || 1,
          failureCount: data.failureCount || 0,
        };
      });
      
      return notifications;
      
    } catch (error) {
      console.error("Error fetching history:", error);
      return [];
    }
  }
}

export default BroadcastService;
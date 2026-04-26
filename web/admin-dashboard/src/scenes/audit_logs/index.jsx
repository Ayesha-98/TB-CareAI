// AuditLogs.jsx - Simplified version with better grouping + CHW patients
import { Box, Typography, useTheme, Paper, Button, Chip, IconButton, Pagination, CircularProgress } from "@mui/material";
import { tokens } from "../../theme";
import Header from "../../components/Header";
import { collection, query, orderBy, getDocs } from "firebase/firestore";
import { db } from "../../firebaseConfig";
import { useEffect, useState } from "react";
import RefreshIcon from "@mui/icons-material/Refresh";
import DownloadIcon from "@mui/icons-material/Download";
import PersonAddIcon from "@mui/icons-material/PersonAdd";
import BlockIcon from "@mui/icons-material/Block";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import FlagIcon from "@mui/icons-material/Flag";
import AdminPanelSettingsIcon from "@mui/icons-material/AdminPanelSettings";
import LoginIcon from "@mui/icons-material/Login";
import PersonIcon from "@mui/icons-material/Person";
import LocalHospitalIcon from "@mui/icons-material/LocalHospital";
import PeopleIcon from "@mui/icons-material/People";

const AuditLogs = () => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const [allLogs, setAllLogs] = useState([]);
  const [groupedLogs, setGroupedLogs] = useState({});
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const rowsPerPage = 10;

  // ✅ NEW: CHW patients state
  const [chwPatients, setChwPatients] = useState([]);

  const isDark = theme.palette.mode === "dark";

  // Action configurations
  const actionConfig = {
    USER_REGISTERED: { label: "REGISTERED", icon: <PersonAddIcon sx={{ fontSize: 14 }} />, color: "#9c27b0", bg: "#9c27b015" },
    USER_DEACTIVATED: { label: "DEACTIVATED", icon: <BlockIcon sx={{ fontSize: 14 }} />, color: "#f44336", bg: "#f4433615" },
    USER_ACTIVATED: { label: "ACTIVATED", icon: <CheckCircleIcon sx={{ fontSize: 14 }} />, color: "#4caf50", bg: "#4caf5015" },
    ROLE_CHANGED: { label: "ROLE CHANGE", icon: <AdminPanelSettingsIcon sx={{ fontSize: 14 }} />, color: "#2196f3", bg: "#2196f315" },
    USER_FLAGGED: { label: "FLAGGED", icon: <FlagIcon sx={{ fontSize: 14 }} />, color: "#ff9800", bg: "#ff980015" },
    USER_UNFLAGGED: { label: "UNFLAGGED", icon: <FlagIcon sx={{ fontSize: 14 }} />, color: "#4caf50", bg: "#4caf5015" },
    DOCTOR_APPROVED: { label: "APPROVED", icon: <CheckCircleIcon sx={{ fontSize: 14 }} />, color: "#4caf50", bg: "#4caf5015" },
    DOCTOR_REJECTED: { label: "REJECTED", icon: <BlockIcon sx={{ fontSize: 14 }} />, color: "#f44336", bg: "#f4433615" },
    LOGIN: { label: "LOGIN", icon: <LoginIcon sx={{ fontSize: 14 }} />, color: "#2196f3", bg: "#2196f315" },
    LOGOUT: { label: "LOGOUT", icon: <LoginIcon sx={{ fontSize: 14 }} />, color: "#757575", bg: "#75757515" },
    // ✅ NEW: CHW action config
    CHW_PATIENT_ASSIGNED: { label: "PATIENT ASSIGNED", icon: <PeopleIcon sx={{ fontSize: 14 }} />, color: "#4caf50", bg: "#4caf5015" },
  };

  const getActionStyle = (action) => {
    return actionConfig[action] || { label: action || "ACTION", icon: null, color: "#757575", bg: "#75757515" };
  };

  // Get role icon
  const getRoleIcon = (role) => {
    const roleLower = role?.toLowerCase() || "";
    if (roleLower === "doctor") return <LocalHospitalIcon sx={{ fontSize: 12 }} />;
    if (roleLower === "chw") return <PeopleIcon sx={{ fontSize: 12 }} />;
    if (roleLower === "patient") return <PersonIcon sx={{ fontSize: 12 }} />;
    return null;
  };

  const formatTime = (timestamp) => {
    if (!timestamp) return "N/A";
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  const formatFullDate = (timestamp) => {
    if (!timestamp) return "N/A";
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' });
  };

  const isToday = (timestamp) => {
    if (!timestamp) return false;
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    const today = new Date();
    return date.toDateString() === today.toDateString();
  };

  const isYesterday = (timestamp) => {
    if (!timestamp) return false;
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return date.toDateString() === yesterday.toDateString();
  };

   const fetchLogs = async () => {
    setLoading(true);
    try {
      const q = query(collection(db, "admin_audit_logs"), orderBy("timestamp", "desc"));
      const snapshot = await getDocs(q);
      const logsData = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      // ✅ NEW: Fetch CHW assigned patients
      console.log("🔍 Fetching CHW assigned patients...");
      let patientsData = [];
      try {
        const chwSnapshot = await getDocs(collection(db, "chws"));
        
        for (const chwDoc of chwSnapshot.docs) {
          const chwPatientsRef = collection(db, `chws/${chwDoc.id}/assigned_patients`);
          const patientsSnapshot = await getDocs(chwPatientsRef);
          
          patientsSnapshot.docs.forEach(patientDoc => {
            const patientData = patientDoc.data();
            patientsData.push({
              id: `chw_patient_${patientDoc.id}`,
              ...patientData,
              chwId: chwDoc.id,
              chwName: chwDoc.data()?.name || "Unknown CHW",
              action: "CHW_PATIENT_ASSIGNED",
              type: "CHW_PATIENT_ASSIGNED",
              timestamp: patientData.createdAt || new Date(),
              actor: {
                id: chwDoc.id,
                name: chwDoc.data()?.name || "Unknown CHW",
                role: "CHW",
              },
              target: {
                id: patientData.patientId || patientDoc.id,
                name: patientData.name || patientData.patientName || "Unknown",
                role: "Patient",
              },
              details: `Patient registered by CHW and assigned to doctor: ${patientData.assignedDoctorName || 'N/A'}`,
            });
          });
        }
        
        console.log("📊 CHW patients found:", patientsData.length);
      } catch (error) {
        console.error("Error fetching CHW patients:", error);
      }
      
      // ✅ Merge with audit logs and sort
      const allData = [...logsData, ...patientsData];
      const sortedData = allData.sort((a, b) => {
        const timeA = a.timestamp?.toMillis ? a.timestamp.toMillis() : (a.timestamp?.toDate ? a.timestamp.toDate().getTime() : new Date(a.timestamp || 0).getTime());
        const timeB = b.timestamp?.toMillis ? b.timestamp.toMillis() : (b.timestamp?.toDate ? b.timestamp.toDate().getTime() : new Date(b.timestamp || 0).getTime());
        return timeB - timeA;
      });
      
      setAllLogs(sortedData);
      setChwPatients(patientsData);

      // ✅ FIXED: Group using sortedData directly (not state)
      const grouped = {
        Patients: [],
        Doctors: [],
        CHWs: [],
        Admins: [],
        Other: []
      };
      
      sortedData.forEach(log => {
        const role = log.actor?.role?.toLowerCase() || "";
        // ✅ Handle CHW patients
        if (log.type === "CHW_PATIENT_ASSIGNED") {
          grouped.CHWs.push(log);
        } else if (role === "patient") {
          grouped.Patients.push(log);
        } else if (role === "doctor") {
          grouped.Doctors.push(log);
        } else if (role === "chw") {
          grouped.CHWs.push(log);
        } else if (role === "admin") {
          grouped.Admins.push(log);
        } else {
          grouped.Other.push(log);
        }
      });
      
      console.log("📊 Grouped logs:", {
        Patients: grouped.Patients.length,
        Doctors: grouped.Doctors.length,
        CHWs: grouped.CHWs.length,
        Admins: grouped.Admins.length,
        Other: grouped.Other.length,
      });
      
      setGroupedLogs(grouped);
    } catch (error) {
      console.error("❌ Error fetching audit logs:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  const exportToCSV = () => {
    if (allLogs.length === 0) return;
    
    const headers = ["Date", "Time", "Action", "Actor", "Actor Role", "Target", "Details"];
    const csvRows = [headers.join(",")];
    
    for (const log of allLogs) {
      const row = [
        `"${formatFullDate(log.timestamp)}"`,
        `"${formatTime(log.timestamp)}"`,
        `"${log.action || log.type || ""}"`,
        `"${log.actor?.name || log.chwName || ""}"`,
        `"${log.actor?.role || "CHW"}"`,
        `"${log.target?.name || log.patientName || ""}"`,
        `"${(log.details || "").replace(/"/g, '""')}"`
      ];
      csvRows.push(row.join(","));
    }
    
    const blob = new Blob([csvRows.join("\n")], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `audit_logs_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  // Calculate stats
  const totalActivities = allLogs.length;
  const uniqueActors = new Set(allLogs.map(l => l.actor?.id || l.chwId)).size;
  const dateRange = allLogs.length > 0 
    ? `${formatFullDate(allLogs[allLogs.length - 1]?.timestamp)} - ${formatFullDate(allLogs[0]?.timestamp)}`
    : "No data";

  // Render logs for a specific role group
  const renderLogGroup = (title, logs, icon) => {
    if (logs.length === 0) return null;
    
    // Paginate within group
    const startIndex = (page - 1) * rowsPerPage;
    const endIndex = startIndex + rowsPerPage;
    const paginatedLogs = logs.slice(startIndex, endIndex);
    
    // Group by date within this role group
    const groupedByDate = paginatedLogs.reduce((groups, log) => {
      let groupKey;
      if (isToday(log.timestamp)) {
        groupKey = "TODAY - " + formatFullDate(log.timestamp);
      } else if (isYesterday(log.timestamp)) {
        groupKey = "YESTERDAY - " + formatFullDate(log.timestamp);
      } else {
        groupKey = formatFullDate(log.timestamp);
      }
      if (!groups[groupKey]) groups[groupKey] = [];
      groups[groupKey].push(log);
      return groups;
    }, {});
    
    return (
      <Box key={title} sx={{ mb: 4 }}>
        {/* Role Header */}
        <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 2, pb: 1, borderBottom: `2px solid ${colors.accent}` }}>
          {icon}
          <Typography variant="h5" fontWeight="bold" color={isDark ? colors.text.primary : "#1B4D3E"}>
            {title}
          </Typography>
          <Chip label={`${logs.length} activities`} size="small" sx={{ ml: 1, backgroundColor: colors.accent, color: "#fff" }} />
        </Box>
        
        {/* Logs for this role */}
        {Object.entries(groupedByDate).map(([dateGroup, dateLogs]) => (
          <Paper key={dateGroup} elevation={0} sx={{ mb: 2, backgroundColor: colors.background.widget, borderRadius: "12px", overflow: "hidden" }}>
            <Box sx={{ p: 1.5, backgroundColor: isDark ? "rgba(158,240,158,0.08)" : "rgba(27,77,62,0.04)", borderBottom: `1px solid ${colors.background.dashboard}` }}>
              <Typography variant="subtitle2" fontWeight="bold">📅 {dateGroup}</Typography>
            </Box>
            <Box sx={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse" }}>
                <thead>
                  <tr style={{ backgroundColor: colors.background.widgetTitle }}>
                    <th style={{ padding: "10px 16px", textAlign: "left", width: "80px" }}>Time</th>
                    <th style={{ padding: "10px 16px", textAlign: "left", width: "100px" }}>Action</th>
                    <th style={{ padding: "10px 16px", textAlign: "left", width: "220px" }}>Actor / Target</th>
                    <th style={{ padding: "10px 16px", textAlign: "left" }}>Details</th>
                  </tr>
                </thead>
                <tbody>
                  {dateLogs.map((log, idx) => {
                    const actionKey = log.action || log.type || "";
                    const style = getActionStyle(actionKey);
                    const hasTarget = log.target && log.target.name;
                    
                    return (
                      <tr key={log.id || `chw-${idx}`} style={{ borderBottom: idx < dateLogs.length - 1 ? `1px solid ${colors.background.dashboard}` : "none" }}>
                        <td style={{ padding: "10px 16px", fontSize: "0.85rem", whiteSpace: "nowrap" }}>
                          {formatTime(log.timestamp)}
                        </td>
                        <td style={{ padding: "10px 16px" }}>
                          <Chip 
                            icon={style.icon} 
                            label={style.label} 
                            size="small" 
                            sx={{ backgroundColor: style.bg, color: style.color, fontWeight: 700, fontSize: "0.7rem" }} 
                          />
                        </td>
                        <td style={{ padding: "10px 16px" }}>
                          <Box display="flex" flexDirection="column">
                            <Box display="flex" alignItems="center" gap="0.5">
                              {getRoleIcon(log.actor?.role || (log.type === "CHW_PATIENT_ASSIGNED" ? "chw" : ""))}
                              <Typography variant="body2" fontWeight={600}>
                                {log.actor?.name || log.chwName || "Unknown"}
                              </Typography>
                              <Typography variant="caption" color={isDark ? colors.text.secondary : "#888"}>
                                ({log.actor?.role || "CHW"})
                              </Typography>
                            </Box>
                            {hasTarget && (
                              <Box display="flex" alignItems="center" gap="0.5" ml={2} mt={0.5}>
                                <Typography variant="caption" color={isDark ? colors.text.secondary : "#999"}>→</Typography>
                                {getRoleIcon(log.target?.role)}
                                <Typography variant="body2" fontSize="0.8rem">
                                  {log.target.name}
                                </Typography>
                                <Typography variant="caption" color={isDark ? colors.text.secondary : "#888"}>
                                  ({log.target.role || "?"})
                                </Typography>
                              </Box>
                            )}
                            {/* For CHW patients, show patient name as target */}
                            {log.type === "CHW_PATIENT_ASSIGNED" && log.patientName && (
                              <Box display="flex" alignItems="center" gap="0.5" ml={2} mt={0.5}>
                                <Typography variant="caption" color={isDark ? colors.text.secondary : "#999"}>→</Typography>
                                <PersonIcon sx={{ fontSize: 12 }} />
                                <Typography variant="body2" fontSize="0.8rem">
                                  {log.patientName || log.name}
                                </Typography>
                                <Typography variant="caption" color={isDark ? colors.text.secondary : "#888"}>
                                  (Patient)
                                </Typography>
                              </Box>
                            )}
                          </Box>
                        </td>
                        <td style={{ padding: "10px 16px" }}>
                          <Typography variant="body2" fontSize="0.85rem">
                            {log.details || "-"}
                          </Typography>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </Box>
          </Paper>
        ))}
      </Box>
    );
  };

  // Calculate total pages based on all logs
  const totalPages = Math.ceil(allLogs.length / rowsPerPage);

  return (
    <Box m="20px">
      <Header
        title="SYSTEM AUDIT LOGS"
        subtitle="Complete history of admin-relevant activities across the platform"
      />

      {/* Stats Cards */}
      <Box display="flex" gap={3} flexWrap="wrap" mb={3}>
        <Paper elevation={0} sx={{ p: 2, minWidth: 150, backgroundColor: colors.background.widget, borderRadius: "12px", border: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}` }}>
          <Typography variant="caption" color={isDark ? colors.text.secondary : "#666"}>Total Activities</Typography>
          <Typography variant="h4" fontWeight="bold">{totalActivities}</Typography>
        </Paper>
        <Paper elevation={0} sx={{ p: 2, minWidth: 150, backgroundColor: colors.background.widget, borderRadius: "12px", border: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}` }}>
          <Typography variant="caption" color={isDark ? colors.text.secondary : "#666"}>Unique Actors</Typography>
          <Typography variant="h4" fontWeight="bold">{uniqueActors}</Typography>
        </Paper>
        <Paper elevation={0} sx={{ p: 2, minWidth: 200, backgroundColor: colors.background.widget, borderRadius: "12px", border: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}` }}>
          <Typography variant="caption" color={isDark ? colors.text.secondary : "#666"}>Date Range</Typography>
          <Typography variant="body1" fontWeight="bold">{dateRange}</Typography>
        </Paper>
        
        <Box flex={1} display="flex" justifyContent="flex-end" gap={1}>
          <IconButton onClick={fetchLogs} size="small"><RefreshIcon /></IconButton>
          <Button variant="outlined" startIcon={<DownloadIcon />} onClick={exportToCSV} disabled={allLogs.length === 0} size="small">Export</Button>
        </Box>
      </Box>

      {/* Logs Display */}
      {loading ? (
        <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
      ) : totalActivities === 0 ? (
        <Paper elevation={0} sx={{ p: 6, textAlign: "center", backgroundColor: colors.background.widget, borderRadius: "12px" }}>
          <Typography color={isDark ? colors.text.secondary : "#666"}>No activities found.</Typography>
          <Typography variant="caption" sx={{ mt: 1, display: "block" }}>Activities will appear here as users perform actions.</Typography>
        </Paper>
      ) : (
        <>
          {/* Render logs by role group */}
          {renderLogGroup("Patients", groupedLogs.Patients, <PersonIcon sx={{ color: colors.accent }} />)}
          {renderLogGroup("Doctors", groupedLogs.Doctors, <LocalHospitalIcon sx={{ color: colors.accent }} />)}
          {renderLogGroup("CHWs", groupedLogs.CHWs, <PeopleIcon sx={{ color: colors.accent }} />)}
          {renderLogGroup("Admins", groupedLogs.Admins, <AdminPanelSettingsIcon sx={{ color: colors.accent }} />)}
          {renderLogGroup("Other", groupedLogs.Other, null)}
          
          {/* Pagination */}
          {totalPages > 1 && (
            <Box sx={{ display: "flex", justifyContent: "center", mt: 3 }}>
              <Pagination 
                count={totalPages} 
                page={page} 
                onChange={(e, val) => setPage(val)} 
                color="primary" 
              />
            </Box>
          )}
        </>
      )}
    </Box>
  );
};

export default AuditLogs;
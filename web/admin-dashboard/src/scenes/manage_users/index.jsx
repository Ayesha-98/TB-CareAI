import { Box, Typography, useTheme, Button, Snackbar, Alert, TextField, Dialog, DialogTitle, DialogContent, DialogActions } from "@mui/material";
import { DataGrid } from "@mui/x-data-grid";
import { tokens } from "../../theme";
import AdminPanelSettingsOutlinedIcon from "@mui/icons-material/AdminPanelSettingsOutlined";
import LockOpenOutlinedIcon from "@mui/icons-material/LockOpenOutlined";
import SecurityOutlinedIcon from "@mui/icons-material/SecurityOutlined";
import LocalHospitalOutlinedIcon from "@mui/icons-material/LocalHospitalOutlined";
import PeopleAltOutlinedIcon from "@mui/icons-material/PeopleAltOutlined";
import FlagIcon from "@mui/icons-material/Flag";
import Header from "../../components/Header";
import { collection, onSnapshot, doc, updateDoc, setDoc, serverTimestamp } from "firebase/firestore";
import { db, addAuditLog } from "../../firebaseConfig";
import { useEffect, useState } from "react";
import { getAuth } from "firebase/auth";
import React from "react";

const ManageUsers = () => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const [users, setUsers] = useState([]);
  const [snackbar, setSnackbar] = useState({
    open: false,
    message: "",
    severity: "success",
  });
  const [flagModal, setFlagModal] = useState({
    open: false,
    userId: null,
    userName: "",
    userEmail: "",
    currentFlagged: false,
    reason: ""
  });

  const isDark = theme.palette.mode === "dark";
  const auth = getAuth();

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "users"), (snapshot) => {
      const usersData = snapshot.docs.map((doc) => {
        const data = doc.data();
        let status = data.status || "Active";
        if (data.role === "Doctor" && !data.verified) {
          status = "Pending Approval";
        }
        
        return {
          id: doc.id,
          ...data,
          status: status,
          isFlagged: data.isFlagged || false,
          flaggedAt: data.flaggedAt || null,
          flagReason: data.flagReason || "",
          createdAt: data.createdAt?.toDate() || new Date(data.createdAt),
        };
      });
      
      setUsers(usersData);
    });
    
    return () => unsubscribe();
  }, []);

  const showMessage = (message, severity = "success") => {
    setSnackbar({ open: true, message, severity });
  };

  const handleCloseSnackbar = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  const approveUser = async (id, userEmail, userName) => {
    try {
      await updateDoc(doc(db, "users", id), { 
        verified: true,
        status: "Active"
      });
      
      await addAuditLog(
        "APPROVE_DOCTOR",
        `Approved doctor: ${userName} (${userEmail})`,
        { uid: id, email: userEmail }
      );
      
      showMessage("User approved successfully (Activated).");
    } catch (error) {
      showMessage("Failed to approve user.", "error");
      console.error(error);
    }
  };

  const deactivateUser = async (id, userEmail, userName) => {
    try {
      await updateDoc(doc(db, "users", id), { 
        verified: false,
        status: "Deactivated"
      });
      
      await addAuditLog(
        "DEACTIVATE_USER",
        `Deactivated user: ${userName} (${userEmail})`,
        { uid: id, email: userEmail }
      );
      
      showMessage("User deactivated successfully.", "warning");
    } catch (error) {
      showMessage("Failed to deactivate user.", "error");
      console.error(error);
    }
  };

  const activateUser = async (id, userEmail, userName) => {
    try {
      await updateDoc(doc(db, "users", id), { 
        verified: true,
        status: "Active"
      });
      
      await addAuditLog(
        "ACTIVATE_USER",
        `Activated user: ${userName} (${userEmail})`,
        { uid: id, email: userEmail }
      );
      
      showMessage("User activated successfully.", "success");
    } catch (error) {
      showMessage("Failed to activate user.", "error");
      console.error(error);
    }
  };

  const toggleFlag = async (id, currentFlagged, userName, userEmail) => {
    if (!currentFlagged) {
      setFlagModal({
        open: true,
        userId: id,
        userName: userName,
        userEmail: userEmail,
        currentFlagged: false,
        reason: ""
      });
    } else {
      try {
        await updateDoc(doc(db, "users", id), { 
          isFlagged: false,
          flaggedAt: null,
          flaggedBy: null,
          flagReason: null
        });
        
        await addAuditLog(
          "UNFLAG_USER",
          `Removed flag from user: ${userName} (${userEmail})`,
          { uid: id, email: userEmail }
        );
        
        showMessage("Flag removed successfully.");
      } catch (error) {
        showMessage("Failed to remove flag.", "error");
        console.error(error);
      }
    }
  };

  const confirmFlag = async () => {
    try {
      const { userId, userName, userEmail, reason } = flagModal;
      
      await updateDoc(doc(db, "users", userId), { 
        isFlagged: true,
        flaggedAt: serverTimestamp(),
        flaggedBy: "admin",
        flagReason: reason || "No reason provided"
      });
      
      await addAuditLog(
        "FLAG_USER",
        `Flagged user: ${userName} (${userEmail}). Reason: ${reason || "No reason provided"}`,
        { uid: userId, email: userEmail }
      );
      
      showMessage("User flagged successfully.");
      setFlagModal({ open: false, userId: null, userName: "", userEmail: "", currentFlagged: false, reason: "" });
    } catch (error) {
      showMessage("Failed to flag user.", "error");
      console.error(error);
    }
  };

  const getRoleIcon = (role) => {
    switch (role) {
      case "Admin":
        return <AdminPanelSettingsOutlinedIcon fontSize="medium" />;
      case "Doctor":
        return <LocalHospitalOutlinedIcon fontSize="medium" />;
      case "CHW":
        return <PeopleAltOutlinedIcon fontSize="medium" />;
      case "Patient":
        return <LockOpenOutlinedIcon fontSize="medium" />;
      default:
        return <SecurityOutlinedIcon fontSize="medium" />;
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case "Active":
        return isDark ? colors.chart[1] : "#2e7d32";
      case "Pending Approval":
        return isDark ? colors.chart[4] : "#ed6c02";
      case "Deactivated":
        return colors.chart.semiNegative;
      default:
        return isDark ? colors.text.primary : "#1B4D3E";
    }
  };

  const actionButtonStyle = {
    color: "black",
    fontSize: "0.9rem",
    fontWeight: 700,
    padding: "6px 14px",
  };

  const columns = [
    { field: "id", headerName: "ID", width: 220 },
    {
      field: "name",
      headerName: "Name",
      flex: 1,
      cellClassName: "name-column--cell",
    },
    { field: "email", headerName: "Email", flex: 1 },
    {
      field: "role",
      headerName: "Role",
      flex: 1,
      renderCell: ({ row }) => (
        <Box display="flex" alignItems="center" gap="8px">
          {getRoleIcon(row.role)}
          <Typography
            sx={{ fontWeight: 700, fontSize: "1rem" }}
            color={isDark ? colors.text.primary : "black"}
          >
            {row.role}
          </Typography>
        </Box>
      ),
    },
    {
      field: "status",
      headerName: "Status",
      flex: 1,
      renderCell: ({ row }) => (
        <Typography
          sx={{ fontWeight: 700, fontSize: "1rem" }}
          color={getStatusColor(row.status)}
        >
          {row.status}
        </Typography>
      ),
    },
    {
      field: "isFlagged",
      headerName: "Flagged",
      flex: 1,
      renderCell: ({ row }) => (
        <Box display="flex" alignItems="center" gap="8px">
          {row.isFlagged && <FlagIcon sx={{ color: colors.chart.semiNegative }} />}
          <Typography
            sx={{ fontWeight: 700, fontSize: "1rem" }}
            color={
              row.isFlagged
                ? colors.chart.semiNegative
                : isDark
                ? colors.text.primary
                : "black"
            }
          >
            {row.isFlagged ? "Yes" : "No"}
          </Typography>
        </Box>
      ),
    },
    {
      field: "flagReason",
      headerName: "Flag Reason",
      flex: 1,
      renderCell: ({ row }) => (
        <Typography
          sx={{ fontWeight: 600, fontSize: "0.9rem" }}
          color={isDark ? colors.text.primary : "black"}
        >
          {row.flagReason || "-"}
        </Typography>
      ),
    },
    {
      field: "actions",
      headerName: "Actions",
      flex: 2,
      renderCell: (params) => (
        <Box display="flex" gap="12px">
          {params.row.role === "Doctor" && params.row.status === "Pending Approval" && (
            <Button
              variant="contained"
              style={{ ...actionButtonStyle, backgroundColor: colors.chart[1] }}
              size="medium"
              onClick={() => approveUser(params.row.id, params.row.email, params.row.name)}
            >
              Approve
            </Button>
          )}

          {params.row.status !== "Pending Approval" && (
            <>
              {params.row.status === "Active" ? (
                <Button
                  variant="contained"
                  style={{ ...actionButtonStyle, backgroundColor: colors.chart[3] }}
                  size="medium"
                  onClick={() => deactivateUser(params.row.id, params.row.email, params.row.name)}
                >
                  Deactivate
                </Button>
              ) : (
                <Button
                  variant="contained"
                  style={{ ...actionButtonStyle, backgroundColor: colors.chart[1] }}
                  size="medium"
                  onClick={() => activateUser(params.row.id, params.row.email, params.row.name)}
                >
                  Activate
                </Button>
              )}
            </>
          )}

          <Button
            variant="contained"
            style={{ 
              ...actionButtonStyle, 
              backgroundColor: params.row.isFlagged ? colors.chart.semiNegative : colors.chart[2] 
            }}
            size="medium"
            onClick={() => toggleFlag(params.row.id, params.row.isFlagged, params.row.name, params.row.email)}
            startIcon={params.row.isFlagged ? <FlagIcon /> : null}
          >
            {params.row.isFlagged ? "Unflag" : "Flag"}
          </Button>
        </Box>
      ),
    },
  ];

  return (
    <Box m="20px">
      <Header
        title="MANAGE USERS"
        subtitle="View, approve, edit, deactivate, or flag system users"
      />

      <Box
        m="20px 0 0 0"
        height="75vh"
        sx={{
          "& .MuiDataGrid-root": {
            border: "none",
            backgroundColor: colors.background.widget,
            borderRadius: "12px",
          },
          "& .MuiDataGrid-cell": {
            borderBottom: "none",
            fontSize: "1rem",
            fontWeight: 600,
            color: isDark ? colors.text.primary : "black",
          },
          "& .name-column--cell": {
            color: isDark ? colors.accent : colors.chart[5],
            fontWeight: 700,
            fontSize: "1.05rem",
          },
          "& .MuiDataGrid-columnHeaders": {
            backgroundColor: colors.background.widgetTitle,
            borderBottom: "none",
            color: isDark ? colors.text.secondary : "#1B4D3E",
            fontWeight: 700,
            fontSize: "1.1rem",
            borderRadius: "12px 12px 0 0",
          },
          "& .MuiDataGrid-virtualScroller": {
            backgroundColor: colors.background.dashboard,
          },
          "& .MuiDataGrid-footerContainer": {
            borderTop: "none",
            backgroundColor: colors.background.widgetTitle,
            color: isDark ? colors.text.secondary : "#1B4D3E",
            fontWeight: 600,
            fontSize: "1rem",
            borderRadius: "0 0 12px 12px",
          },
          "& .MuiCheckbox-root": { color: `${colors.accent} !important` },
        }}
      >
        <DataGrid checkboxSelection rows={users} columns={columns} />
      </Box>

      <Dialog open={flagModal.open} onClose={() => setFlagModal({...flagModal, open: false})}>
        <DialogTitle sx={{ color: isDark ? colors.text.primary : "#1B4D3E" }}>
          Flag User: {flagModal.userName}
        </DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="Reason for flagging (optional)"
            fullWidth
            variant="outlined"
            value={flagModal.reason}
            onChange={(e) => setFlagModal({...flagModal, reason: e.target.value})}
            placeholder="e.g., Suspicious activity, requires monitoring..."
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setFlagModal({...flagModal, open: false})}>Cancel</Button>
          <Button onClick={confirmFlag} variant="contained" color="warning">
            Confirm Flag
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={3000}
        onClose={handleCloseSnackbar}
        anchorOrigin={{ vertical: "top", horizontal: "center" }}
      >
        <Alert onClose={handleCloseSnackbar} severity={snackbar.severity} variant="filled">
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default ManageUsers;
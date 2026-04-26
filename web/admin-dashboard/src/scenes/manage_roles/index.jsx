import {
  Box,
  MenuItem,
  Select,
  Button,
  Stack,
  Typography,
  Snackbar,
  Alert,
} from "@mui/material";
import { DataGrid, GridToolbar } from "@mui/x-data-grid";
import { tokens } from "../../theme";
import Header from "../../components/Header";
import { useTheme } from "@mui/material";
import { useState, useEffect } from "react";
import { db, addAuditLog } from "../../firebaseConfig";
import {
  collection,
  doc,
  updateDoc,
  onSnapshot,
} from "firebase/firestore";

const RoleManagement = () => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const isDark = theme.palette.mode === "dark";

  const [rows, setRows] = useState([]);
  const [editedRoles, setEditedRoles] = useState({});
  const [originalRoles, setOriginalRoles] = useState({});
  const [selectedRow, setSelectedRow] = useState(null);
  const [snackbar, setSnackbar] = useState({
    open: false,
    message: "",
    severity: "success",
  });

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "users"), (snapshot) => {
      const usersData = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      setRows(usersData);
      
      // Store original roles
      const roles = {};
      usersData.forEach(user => {
        roles[user.id] = user.role;
      });
      setOriginalRoles(roles);
    });

    return () => unsubscribe();
  }, []);

  const showMessage = (message, severity = "success") => {
    setSnackbar({ open: true, message, severity });
  };

  const handleCloseSnackbar = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  const handleRoleChange = (id, newRole) => {
    if (selectedRow !== id) return;
    setEditedRoles((prev) => ({ ...prev, [id]: newRole }));
  };

  const handleSaveClick = async () => {
    if (Object.keys(editedRoles).length === 0) return;
    
    try {
      for (const [id, newRole] of Object.entries(editedRoles)) {
        const oldRole = originalRoles[id];
        
        if (oldRole === newRole) continue;
        
        const userRef = doc(db, "users", id);
        await updateDoc(userRef, { role: newRole });
        
        // Get user details for audit log
        const user = rows.find(r => r.id === id);
        
        // Add audit log for role change
        await addAuditLog(
          "ROLE_CHANGE",
          `Changed user role from ${oldRole} to ${newRole} for ${user?.name || id} (${user?.email || ""})`,
          { uid: id, email: user?.email || "" }
        );
      }
      
      setEditedRoles({});
      setSelectedRow(null);
      setOriginalRoles(prev => ({ ...prev, ...editedRoles }));
      showMessage("User roles updated successfully.");
    } catch (error) {
      console.error("Error updating roles:", error);
      showMessage("Failed to update role.", "error");
    }
  };

  const handleCancelChanges = () => {
    setEditedRoles({});
    setSelectedRow(null);
  };

  const roleBorderColor = (role) => {
    switch (role) {
      case "Admin":
        return colors.chart[1];
      case "Doctor":
        return colors.chart[2];
      case "CHW":
        return colors.chart[3];
      case "Patient":
        return "#F5DC71";
      default:
        return colors.accent;
    }
  };

  const columns = [
    { field: "id", headerName: "ID", flex: 0.6 },
    {
      field: "name",
      headerName: "Name",
      flex: 1,
      minWidth: 200,
      cellClassName: "name-column--cell",
    },
    {
      field: "email",
      headerName: "Email",
      flex: 1,
      minWidth: 200,
    },
    {
      field: "role",
      headerName: "Role",
      flex: 0.8,
      renderCell: ({ row }) => {
        const currentRole = editedRoles[row.id] ?? row.role;
        const isEdited = editedRoles[row.id] !== undefined;

        return (
          <Select
            value={currentRole}
            disabled={selectedRow !== row.id}
            onChange={(e) => handleRoleChange(row.id, e.target.value)}
            size="small"
            sx={{
              minWidth: "140px",
              borderRadius: "8px",
              fontWeight: 700,
              fontSize: "1rem",
              backgroundColor: "transparent",
              color: isDark ? "white" : "black",
              border: `2px solid ${roleBorderColor(currentRole)}`,
              boxShadow: isEdited ? `0 0 6px ${colors.accent}` : "none",
              "& .MuiSvgIcon-root": { color: isDark ? "white" : "black" },
            }}
          >
            <MenuItem value="Admin">Admin</MenuItem>
            <MenuItem value="Doctor">Doctor</MenuItem>
            <MenuItem value="CHW">Community Health Worker</MenuItem>
            <MenuItem value="Patient">Patient</MenuItem>
          </Select>
        );
      },
    },
  ];

  return (
    <Box m="20px">
      <Header
        title="ROLE MANAGEMENT"
        subtitle="Assign and manage user roles safely"
      />

      <Stack direction="row" spacing={2} mb={2}>
        <Button
          variant="contained"
          sx={{
            backgroundColor: colors.chart[3],
            color: isDark ? "white" : "black",
            fontWeight: 700,
            fontSize: "1rem",
            px: 3,
            py: 1,
            "&:hover": { opacity: 0.9 },
          }}
          onClick={handleSaveClick}
          disabled={Object.keys(editedRoles).length === 0}
        >
          Save Changes
        </Button>
        <Button
          variant="contained"
          sx={{
            backgroundColor: colors.chart[2],
            color: isDark ? "white" : "black",
            fontWeight: 700,
            fontSize: "1rem",
            px: 3,
            py: 1,
            "&:hover": { opacity: 0.9 },
          }}
          onClick={handleCancelChanges}
          disabled={Object.keys(editedRoles).length === 0}
        >
          Cancel Changes
        </Button>
      </Stack>

      <Box
        m="20px 0 0 0"
        height="75vh"
        sx={{
          "& .MuiDataGrid-root": { border: "none" },
          "& .MuiDataGrid-cell": {
            borderBottom: "none",
            fontSize: "1rem",
            fontWeight: 600,
            color: isDark ? "white" : "black",
          },
          "& .name-column--cell": {
            color: isDark ? colors.accent : colors.chart[5],
            fontWeight: 700,
            fontSize: "1.05rem",
          },
          "& .MuiDataGrid-columnHeaders": {
            backgroundColor: colors.background.widgetTitle,
            borderBottom: "none",
            fontWeight: 700,
            fontSize: "1.1rem",
            color: isDark ? "white" : "black",
          },
          "& .MuiDataGrid-virtualScroller": {
            backgroundColor: colors.background.widget,
          },
          "& .MuiDataGrid-footerContainer": {
            borderTop: "none",
            backgroundColor: colors.background.widgetTitle,
            fontSize: "1rem",
            fontWeight: 600,
            color: isDark ? "white" : "black",
          },
          "& .MuiCheckbox-root": {
            color: `${colors.accent} !important`,
          },
          "& .MuiDataGrid-toolbarContainer .MuiButton-text": {
            fontSize: "0.95rem",
            fontWeight: 600,
            color: isDark ? "white !important" : "black !important",
          },
        }}
      >
        <DataGrid
          rows={rows}
          columns={columns}
          onRowClick={(params) => setSelectedRow(params.id)}
          getRowClassName={(params) =>
            params.id === selectedRow ? "Mui-selected" : ""
          }
          slots={{ toolbar: GridToolbar }}
        />
      </Box>

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

export default RoleManagement;
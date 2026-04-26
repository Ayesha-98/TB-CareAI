// src/scenes/signout/LogoutButton.jsx
import React, { useState } from "react";
import { signOut } from "firebase/auth";
import { auth } from "../../firebaseConfig";
import { logActivity } from "../../utils/activityLog";
import { 
  Button, 
  CircularProgress, 
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  useTheme,
  Box,
  Typography
} from "@mui/material";
import { 
  FiLogOut, 
  FiAlertCircle 
} from "react-icons/fi";
import { tokens } from "../../theme";

function LogoutButton({ user, variant = "icon", fullWidth = false }) {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const [isLoading, setIsLoading] = useState(false);
  const [openDialog, setOpenDialog] = useState(false);

  const handleOpenDialog = () => {
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
  };

  const handleLogout = async () => {
    if (!user) return;
    
    setIsLoading(true);
    
    try {
      // Log activity (before signing out)
      await logActivity({
        performedByUid: user.uid,
        performedByName: user.displayName || user.email?.split('@')[0] || null,
        performedByEmail: user.email,
        affectedUserUid: user.uid,
        affectedUserName: user.displayName || user.email?.split('@')[0] || null,
        affectedUserEmail: user.email,
        currentRole: null,
        activity: "Logout",
        details: "User logged out successfully",
      });

      await signOut(auth);
      console.log("✅ User logged out");
    } catch (err) {
      console.error("❌ Logout error:", err);
    } finally {
      setIsLoading(false);
      setOpenDialog(false);
    }
  };

  // Icon-only variant (for sidebar/mobile)
  if (variant === "icon") {
    return (
      <>
        <Button
          onClick={handleOpenDialog}
          disabled={isLoading}
          sx={{
            minWidth: "auto",
            p: 1.5,
            borderRadius: 2,
            color: colors.text.secondary,
            backgroundColor: "transparent",
            "&:hover": {
              backgroundColor: theme.palette.mode === "dark" 
                ? "rgba(255, 80, 5, 0.12)" 
                : "rgba(255, 80, 5, 0.08)",
              color: "#FF5005",
            },
            transition: "all 0.2s ease",
          }}
        >
          {isLoading ? (
            <CircularProgress size={20} sx={{ color: "#FF5005" }} />
          ) : (
            <FiLogOut size={20} />
          )}
        </Button>

        {/* Confirmation Dialog */}
        <LogoutDialog 
          open={openDialog} 
          onClose={handleCloseDialog} 
          onConfirm={handleLogout}
          isLoading={isLoading}
          colors={colors}
          theme={theme}
        />
      </>
    );
  }

  // Full button variant (for settings/profile pages)
  return (
    <>
      <Button
        onClick={handleOpenDialog}
        disabled={isLoading}
        fullWidth={fullWidth}
        variant="outlined"
        sx={{
          py: 1.5,
          px: 3,
          borderRadius: 2,
          borderColor: "#FF5005",
          color: "#FF5005",
          backgroundColor: "transparent",
          fontWeight: 600,
          textTransform: "none",
          fontSize: "0.9rem",
          gap: 1,
          "&:hover": {
            backgroundColor: theme.palette.mode === "dark" 
              ? "rgba(255, 80, 5, 0.12)" 
              : "rgba(255, 80, 5, 0.08)",
            borderColor: "#FF5005",
          },
          "&:disabled": {
            borderColor: colors.text.secondary + "40",
            color: colors.text.secondary + "40",
          },
        }}
      >
        {isLoading ? (
          <CircularProgress size={20} sx={{ color: "#FF5005" }} />
        ) : (
          <>
            <FiLogOut size={18} />
            <span>Logout</span>
          </>
        )}
      </Button>

      {/* Confirmation Dialog */}
      <LogoutDialog 
        open={openDialog} 
        onClose={handleCloseDialog} 
        onConfirm={handleLogout}
        isLoading={isLoading}
        colors={colors}
        theme={theme}
      />
    </>
  );
}

// Separate component for the confirmation dialog
const LogoutDialog = ({ open, onClose, onConfirm, isLoading, colors, theme }) => {
  return (
    <Dialog
      open={open}
      onClose={onClose}
      PaperProps={{
        sx: {
          backgroundColor: colors.background.widget,
          borderRadius: 3,
          p: 1,
          minWidth: { xs: "90%", sm: 400 },
        },
      }}
    >
      <DialogTitle sx={{ pb: 1 }}>
        <Box display="flex" alignItems="center" gap={1.5}>
          <Box
            sx={{
              width: 40,
              height: 40,
              borderRadius: "50%",
              backgroundColor: "rgba(255, 80, 5, 0.12)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <FiAlertCircle size={22} color="#FF5005" />
          </Box>
          <Typography variant="h6" fontWeight="bold" color={colors.text.primary}>
            Confirm Logout
          </Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <DialogContentText sx={{ color: colors.text.secondary, fontSize: "0.95rem" }}>
          Are you sure you want to log out of your account? You'll need to sign in again to access your dashboard.
        </DialogContentText>
      </DialogContent>
      
      <DialogActions sx={{ p: 2, gap: 1 }}>
        <Button
          onClick={onClose}
          disabled={isLoading}
          sx={{
            px: 3,
            py: 1,
            borderRadius: 2,
            color: colors.text.secondary,
            backgroundColor: "transparent",
            fontWeight: 600,
            textTransform: "none",
            "&:hover": {
              backgroundColor: theme.palette.mode === "dark" 
                ? "rgba(255, 255, 255, 0.08)" 
                : "rgba(0, 0, 0, 0.05)",
            },
          }}
        >
          Cancel
        </Button>
        
        <Button
          onClick={onConfirm}
          disabled={isLoading}
          variant="contained"
          sx={{
            px: 3,
            py: 1,
            borderRadius: 2,
            backgroundColor: "#FF5005",
            color: "#fff",
            fontWeight: 600,
            textTransform: "none",
            "&:hover": {
              backgroundColor: "#E04800",
            },
            "&:disabled": {
              backgroundColor: "#FF5005",
              opacity: 0.6,
            },
          }}
        >
          {isLoading ? <CircularProgress size={20} sx={{ color: "#fff" }} /> : "Logout"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default LogoutButton;
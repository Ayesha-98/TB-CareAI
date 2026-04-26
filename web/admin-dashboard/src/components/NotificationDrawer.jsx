// src/components/NotificationDrawer.jsx
import React, { useState } from "react";
import {
  Drawer,
  Box,
  Typography,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  CircularProgress,
  Alert,
  Snackbar,
  Divider,
  Avatar,
} from "@mui/material";
import { useTheme } from "@mui/material/styles";
import CloseIcon from "@mui/icons-material/Close";
import SendIcon from "@mui/icons-material/Send";
import NotificationsActiveIcon from "@mui/icons-material/NotificationsActive";
import { getAuth } from "firebase/auth";
import BroadcastService from "../services/broadcastService";

const NotificationDrawer = ({ open, onClose }) => {
  const theme = useTheme();
  const auth = getAuth();
  const currentAdmin = auth.currentUser;

  const [message, setMessage] = useState("");
  const [audience, setAudience] = useState("all");
  const [sending, setSending] = useState(false);
  const [snackbar, setSnackbar] = useState({ open: false, message: "", severity: "success" });

  const audienceOptions = [
    { value: "all", label: "All Users", icon: "👥" },
    { value: "patients", label: "Patients Only", icon: "👤" },
    { value: "chws", label: "CHWs Only", icon: "👨‍⚕️" },
    { value: "doctors", label: "Doctors Only", icon: "🩺" },
  ];

  const handleSend = async () => {
    if (!message.trim()) {
      setSnackbar({
        open: true,
        message: "Please enter a message",
        severity: "warning",
      });
      return;
    }

    if (!currentAdmin) {
      setSnackbar({
        open: true,
        message: "You must be logged in",
        severity: "error",
      });
      return;
    }

    setSending(true);
    try {
      // Send directly to Firestore (no backend server needed!)
      const result = await BroadcastService.sendBroadcast(
        message.trim(),
        audience,
        currentAdmin.uid
      );

      setSnackbar({
        open: true,
        message: `✅ Notification saved to Firestore!`,
        severity: "success",
      });
      
      // Clear form and close drawer after 1 second
      setTimeout(() => {
        setMessage("");
        setAudience("all");
        onClose();
      }, 1000);
      
    } catch (error) {
      setSnackbar({
        open: true,
        message: `❌ Error: ${error.message}`,
        severity: "error",
      });
    } finally {
      setSending(false);
    }
  };

  const handleCloseSnackbar = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  return (
    <>
      <Drawer
        anchor="right"
        open={open}
        onClose={onClose}
        PaperProps={{
          sx: {
            width: { xs: "100%", sm: 400 },
            maxWidth: "100%",
            borderTopLeftRadius: 16,
            borderBottomLeftRadius: 16,
            p: 3,
          },
        }}
      >
        {/* Header */}
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
          <Box display="flex" alignItems="center" gap={1}>
            <Avatar sx={{ bgcolor: theme.palette.primary.main, width: 40, height: 40 }}>
              <NotificationsActiveIcon />
            </Avatar>
            <Box>
              <Typography variant="h6" fontWeight="bold">
                Send Notification
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Broadcast to all users or specific roles
              </Typography>
            </Box>
          </Box>
          <IconButton onClick={onClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>

        <Divider sx={{ mb: 3 }} />

        {/* Form */}
        <Box component="form" sx={{ flex: 1 }}>
          {/* Message Input */}
          <TextField
            fullWidth
            multiline
            rows={6}
            variant="outlined"
            label="Notification Message"
            placeholder="Type your announcement here..."
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            disabled={sending}
            sx={{ mb: 3 }}
          />

          {/* Audience Selector */}
          <FormControl fullWidth sx={{ mb: 3 }}>
            <InputLabel>Send to</InputLabel>
            <Select
              value={audience}
              label="Send to"
              onChange={(e) => setAudience(e.target.value)}
              disabled={sending}
            >
              {audienceOptions.map((option) => (
                <MenuItem key={option.value} value={option.value}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <Typography>{option.icon}</Typography>
                    <Typography>{option.label}</Typography>
                  </Box>
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          {/* Send Button */}
          <Button
            fullWidth
            variant="contained"
            size="large"
            onClick={handleSend}
            disabled={sending || !message.trim()}
            startIcon={sending ? <CircularProgress size={20} color="inherit" /> : <SendIcon />}
            sx={{
              py: 1.5,
              fontWeight: "bold",
              fontSize: "16px",
              mb: 2,
            }}
          >
            {sending ? "Saving..." : "Send Notification"}
          </Button>

          {/* Info Text */}
          <Typography variant="caption" color="text.secondary" align="center" display="block">
            ✨ Notification will appear instantly in user apps
          </Typography>
        </Box>
      </Drawer>

      {/* Snackbar for feedback */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={handleCloseSnackbar}
        anchorOrigin={{ vertical: "top", horizontal: "center" }}
      >
        <Alert onClose={handleCloseSnackbar} severity={snackbar.severity} sx={{ width: "100%" }}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </>
  );
};

export default NotificationDrawer;
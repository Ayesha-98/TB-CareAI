// src/components/FloatingNotificationButton.jsx
import React from "react";
import { Fab, Tooltip, Badge } from "@mui/material";
import NotificationsActiveIcon from "@mui/icons-material/NotificationsActive";
import { useTheme } from "@mui/material/styles";

const FloatingNotificationButton = ({ onClick, unreadCount = 0 }) => {
  const theme = useTheme();

  return (
    <Tooltip title="Send Notification" placement="left">
      <Fab
        color="primary"
        aria-label="send notification"
        onClick={onClick}
        sx={{
          position: "fixed",
          bottom: 24,
          right: 24,
          zIndex: 1000,
          boxShadow: "0 8px 16px rgba(0,0,0,0.2)",
          transition: "transform 0.2s",
          "&:hover": {
            transform: "scale(1.1)",
          },
        }}
      >
        <Badge badgeContent={unreadCount} color="error" invisible={unreadCount === 0}>
          <NotificationsActiveIcon />
        </Badge>
      </Fab>
    </Tooltip>
  );
};

export default FloatingNotificationButton;
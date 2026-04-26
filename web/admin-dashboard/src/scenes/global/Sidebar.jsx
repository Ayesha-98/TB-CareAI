// src/scenes/global/Sidebar.jsx
import { useState, useEffect } from "react";
import { ProSidebar, Menu, MenuItem } from "react-pro-sidebar";
import { Box, IconButton, Typography, useTheme } from "@mui/material";
import { Link, useLocation } from "react-router-dom";
import "react-pro-sidebar/dist/css/styles.css";
import { tokens } from "../../theme";

import HomeOutlinedIcon from "@mui/icons-material/HomeOutlined";
import PeopleOutlinedIcon from "@mui/icons-material/PeopleOutlined";
import ContactsOutlinedIcon from "@mui/icons-material/ContactsOutlined";
import ReceiptOutlinedIcon from "@mui/icons-material/ReceiptOutlined";
import PersonOutlinedIcon from "@mui/icons-material/PersonOutlined";
import CalendarTodayOutlinedIcon from "@mui/icons-material/CalendarTodayOutlined";
import HelpOutlineOutlinedIcon from "@mui/icons-material/HelpOutlineOutlined";
import BarChartOutlinedIcon from "@mui/icons-material/BarChartOutlined";
import PieChartOutlineOutlinedIcon from "@mui/icons-material/PieChartOutlineOutlined";
import TimelineOutlinedIcon from "@mui/icons-material/TimelineOutlined";
import MenuOutlinedIcon from "@mui/icons-material/MenuOutlined";
import MapOutlinedIcon from "@mui/icons-material/MapOutlined";

// Route to title mapping
const routeToTitleMap = {
  "/": "Dashboard",
  "/manage_users": "Manage Users",
  "/manage_roles": "Role Management",
  "/audit_logs": "Audit Logs",
  "/doctorapprovals": "Doctor Approvals",
  "/chatboteditor": "Chatbot Editor",
  "/calendar": "Calendar",
  "/bar": "Screenings Overview",
  "/pie": "TB-Positive Cases",
  "/patient": "Patient Funnel",
  "/chw": "CHW Performance",
  "/geography": "Regional Heatmap",
};

/* reusable menu item */
/* reusable menu item */
const Item = ({ title, to, icon, selected, setSelected, isCollapsed }) => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);

  return (
    <MenuItem
      active={selected === title}
      style={{
        color: selected === title ? "#ffffff" : colors.text.primary,
        backgroundColor: selected === title ? colors.accent : "transparent",
        borderRadius: "8px",
        margin: "6px 8px",
        display: "flex",
        alignItems: "center",
        justifyContent: isCollapsed ? "center" : "flex-start",
        transition: "all 0.3s ease-in-out",
        position: "relative",
      }}
      onClick={() => setSelected(title)}
      icon={icon}
    >
      {!isCollapsed && (
        <Typography
          sx={{
            fontSize: { xs: "0.9rem", sm: "1rem", md: "1.05rem" },
            fontWeight: selected === title ? 600 : 500,
            whiteSpace: "normal",
            wordBreak: "break-word",
            color: `${selected === title ? "#ffffff" : colors.text.primary} !important`,
            position: "relative",
            zIndex: 2,
            pointerEvents: "none",
          }}
        >
          {title}
        </Typography>
      )}
      <Link 
        to={to} 
        style={{ 
          position: "absolute", 
          inset: 0, 
          zIndex: 1,
        }} 
      />
    </MenuItem>
  );
};
const Sidebar = () => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const location = useLocation();
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [selected, setSelected] = useState("Dashboard");

  // Sync selected state with current route
  useEffect(() => {
    const currentPath = location.pathname;
    const matchedTitle = routeToTitleMap[currentPath];
    
    if (matchedTitle) {
      setSelected(matchedTitle);
    } else {
      const matchedKey = Object.keys(routeToTitleMap).find(key => 
        currentPath.startsWith(key) && key !== "/"
      );
      if (matchedKey) {
        setSelected(routeToTitleMap[matchedKey]);
      } else {
        setSelected("Dashboard");
      }
    }
  }, [location.pathname]);

  return (
    <Box
  sx={{
    "& .pro-sidebar-inner": {
      background: colors.background.dashboard,
      minHeight: "100vh",
      borderRight: `1px solid ${theme.palette.mode === 'light' ? '#E2E8F0' : '#2D3748'}`,
    },
    "& .pro-icon-wrapper": {
      backgroundColor: "transparent !important",
      position: "relative",      // ✅ ADD THIS
      zIndex: 2,                 // ✅ ADD THIS - brings icon above the Link overlay
    },
    "& .pro-inner-item": {
      padding: { xs: "8px 12px", sm: "10px 16px", md: "12px 18px" },
      borderRadius: "8px",
      transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
    },
    "& .pro-inner-item:hover": {
      backgroundColor: theme.palette.mode === "light" ? "rgba(27, 77, 62, 0.08)" : "rgba(158, 240, 158, 0.08)",
      color: `${colors.text.primary} !important`,
      transform: "translateX(4px)",
    },
    "& .pro-menu-item.active": {
      backgroundColor: colors.accent,
      color: "#ffffff !important",
      fontWeight: "600",
      transform: "translateX(4px)",
      boxShadow: "0 4px 12px rgba(27, 77, 62, 0.2)",
    },
  }}
>
      <ProSidebar collapsed={isCollapsed} breakPoint="md">
        {/* HEADER */}
        <Box
          sx={{
            px: 2,
            py: 2,
            display: "flex",
            alignItems: "center",
            justifyContent: isCollapsed ? "center" : "flex-start",
            gap: 2,
            background: "transparent",
            borderBottom: `1px solid ${theme.palette.mode === 'light' ? '#E2E8F0' : '#2D3748'}`,
            marginBottom: "15px",
          }}
        >
          {/* Burger icon with smooth animation */}
          <IconButton
            onClick={() => setIsCollapsed(!isCollapsed)}
            aria-label="toggle menu"
            size="large"
            sx={{
              color: colors.text.primary,
              transition: "all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)",
              transform: "scale(1)",
              "&:hover": { 
                backgroundColor: theme.palette.mode === "light" ? "rgba(27, 77, 62, 0.08)" : "rgba(158, 240, 158, 0.08)",
                color: colors.accent,
                transform: "scale(1.1)",
              },
              "&:active": {
                transform: "scale(0.95)",
              },
            }}
          >
            <MenuOutlinedIcon 
              fontSize="medium" 
              sx={{
                transition: "transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)",
              }}
            />
          </IconButton>

          
          {/* TB-CARE AI text */}
            {!isCollapsed && (
              <Typography
                variant="h5"
                sx={{
                  fontSize: { xs: "1.1rem", sm: "1.3rem", md: "1.5rem" },
                  fontWeight: "600",
                  color: colors.text.primary,
                  userSelect: "none",
                  letterSpacing: "-0.3px",
                  background: theme.palette.mode === "light" 
                    ? "linear-gradient(135deg, #1B4D3E 0%, #2E7D32 100%)"
                    : "linear-gradient(135deg, #9EF09E 0%, #4CAF50 100%)",
                  backgroundClip: "text",
                  textFillColor: "transparent",
                  WebkitBackgroundClip: "text",
                  WebkitTextFillColor: "transparent",
                  lineHeight: 1.2,
                }}
              >
                TB-CARE AI
              </Typography>
            )}

        </Box>

        {/* MENU */}
        <Menu iconShape="square">
          {/* PROFILE */}
          <Box mb="25px" display={isCollapsed ? "none" : "block"}>
            <Box display="flex" justifyContent="center" alignItems="center">
              <img
                alt="profile-user"
                width="100px"
                height="100px"
                src={`../../assets/user.png`}
                style={{ 
                  cursor: "pointer", 
                  borderRadius: "50%",
                  border: `3px solid ${theme.palette.mode === 'light' ? '#E2E8F0' : '#2D3748'}`,
                  transition: "all 0.3s ease-in-out",
                  "&:hover": {
                    borderColor: colors.accent,
                    transform: "scale(1.05)",
                  }
                }}
              />
            </Box>
            <Box textAlign="center">
              <Typography
                variant="h5"
                sx={{
                  fontSize: { xs: "1.1rem", sm: "1.3rem", md: "1.4rem" },
                  fontWeight: "600",
                  mt: "15px",
                  color: colors.text.primary,
                }}
              >
                Admin
              </Typography>
              <Typography
                variant="body2"
                sx={{
                  color: colors.text.secondary,
                  mt: "5px",
                  fontSize: { xs: "0.8rem", sm: "0.9rem" },
                }}
              >
                Administrator
              </Typography>
            </Box>
          </Box>

          {/* MENU SECTIONS */}
          <Box paddingLeft={isCollapsed ? "0px" : "10%"}>
            <Item
              title="Dashboard"
              to="/"
              icon={<HomeOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />

            <Typography
              variant="subtitle2"
              sx={{
                mt: "20px",
                mb: "8px",
                ml: isCollapsed ? 0 : "20px",
                fontSize: { xs: "0.8rem", sm: "0.9rem" },
                color: colors.text.secondary,
                fontWeight: "600",
                display: isCollapsed ? "none" : "block",
                textTransform: "uppercase",
                letterSpacing: "0.5px",
              }}
            >
              User Management
            </Typography>
            <Item
              title="Manage Users"
              to="/manage_users"
              icon={<PeopleOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />
            <Item
              title="Role Management"
              to="/manage_roles"
              icon={<ContactsOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />
            <Item
              title="Audit Logs"
              to="/audit_logs"
              icon={<ReceiptOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />

            <Typography
              variant="subtitle2"
              sx={{
                mt: "20px",
                mb: "8px",
                ml: isCollapsed ? 0 : "20px",
                fontSize: { xs: "0.8rem", sm: "0.9rem" },
                color: colors.text.secondary,
                fontWeight: "600",
                display: isCollapsed ? "none" : "block",
                textTransform: "uppercase",
                letterSpacing: "0.5px",
              }}
            >
              Content Management
            </Typography>
            <Item
              title="Doctor Approvals"
              to="/doctorapprovals"
              icon={<PersonOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />
            <Item
              title="Chatbot Configuration"
              to="/chatboteditor"
              icon={<HelpOutlineOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />
            <Item
              title="Calendar"
              to="/calendar"
              icon={<CalendarTodayOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />

            <Typography
              variant="subtitle2"
              sx={{
                mt: "20px",
                mb: "8px",
                ml: isCollapsed ? 0 : "20px",
                fontSize: { xs: "0.8rem", sm: "0.9rem" },
                color: colors.text.secondary,
                fontWeight: "600",
                display: isCollapsed ? "none" : "block",
                textTransform: "uppercase",
                letterSpacing: "0.5px",
              }}
            >
              Analytics & Monitoring
            </Typography>
            <Item
              title="Screenings Overview"
              to="/bar"
              icon={<BarChartOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />
            <Item
              title="TB-Positive Cases"
              to="/pie"
              icon={<PieChartOutlineOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />
            <Item
              title="Patient Progress"
              to="/patient"
              icon={<TimelineOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />
            <Item
              title="CHW Performance"
              to="/chw"
              icon={<TimelineOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />
            <Item
              title="Regional Heatmap"
              to="/geography"
              icon={<MapOutlinedIcon />}
              selected={selected}
              setSelected={setSelected}
              isCollapsed={isCollapsed}
            />
          </Box>
        </Menu>
      </ProSidebar>
    </Box>
  );
};

export default Sidebar;
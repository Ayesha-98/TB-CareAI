// AppLayout.jsx
import { Box } from "@mui/material";
import Sidebar from "./scenes/global/Sidebar";
import Topbar from "./scenes/global/Topbar";
import { Outlet } from "react-router-dom";

const AppLayout = () => {
  return (
    <Box display="flex" height="100vh" overflow="hidden">
      {/* Sidebar */}
      <Sidebar />

      {/* Main content */}
      <Box
        display="flex"
        flexDirection="column"
        flexGrow={1}
        sx={{
          overflowY: "auto", // makes main content scroll separately
        }}
      >
        {/* Topbar */}
        <Topbar />

        {/* Page Content */}
        <Box p={2}>
          <Outlet />
        </Box>
      </Box>
    </Box>
  );
};

export default AppLayout;

// src/scenes/global/Topbar.jsx
import { Box, IconButton, useTheme } from "@mui/material";
import { useContext } from "react";
import { ColorModeContext, tokens } from "../../theme";
import LightModeOutlinedIcon from "@mui/icons-material/LightModeOutlined";
import DarkModeOutlinedIcon from "@mui/icons-material/DarkModeOutlined";

const Topbar = () => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const colorMode = useContext(ColorModeContext);

  return (
    <Box
      display="flex"
      justifyContent="flex-end" // Changed from space-between to flex-end
      alignItems="center"
      p={2}
      sx={{
        backgroundColor: colors.background.widget, // widget bg from theme
        boxShadow:
          theme.palette.mode === "light"
            ? "0 2px 6px rgba(0,0,0,0.08)"
            : "0 2px 6px rgba(0,0,0,0.3)",
        borderRadius: "8px",
        mb: 2,
      }}
    >
      {/* ONLY THEME ICON */}
      <Box display="flex" gap={1}>
        <IconButton 
          onClick={colorMode.toggleColorMode}
          sx={{
            transition: "all 0.3s ease-in-out",
            "&:hover": {
              backgroundColor: theme.palette.mode === "light" 
                ? "rgba(27, 77, 62, 0.08)" 
                : "rgba(158, 240, 158, 0.08)",
              transform: "scale(1.1)",
            },
          }}
        >
          {theme.palette.mode === "dark" ? (
            <DarkModeOutlinedIcon 
              sx={{ 
                color: colors.text.primary,
                fontSize: "1.5rem",
              }} 
            />
          ) : (
            <LightModeOutlinedIcon 
              sx={{ 
                color: colors.text.primary,
                fontSize: "1.5rem",
              }} 
            />
          )}
        </IconButton>
      </Box>
    </Box>
  );
};

export default Topbar;
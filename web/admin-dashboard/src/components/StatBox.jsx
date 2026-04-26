import { Box, Typography, useTheme } from "@mui/material";
import { tokens } from "../theme";

const StatBox = ({ title, subtitle, icon, chartColor = "#31D6AE" }) => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);

  // Text color based on theme
  const textColor = theme.palette.mode === "light" ? "#000000" : "#ffffff";

  return (
    <Box
      width="100%"
      m="10px 0"
      p="20px"
      borderRadius="20px"
      bgcolor={theme.palette.mode === "light" ? "#ffffff" : "#1a1a1a"}
      boxShadow="0 6px 20px rgba(0,0,0,0.12)"
      sx={{
        border: `2px solid transparent`,
        backgroundImage: `linear-gradient(${theme.palette.mode === 'light' ? '#fff, #fff' : '#1a1a1a, #1a1a1a'}), linear-gradient(135deg, ${chartColor} 0%, ${chartColor}80 100%)`,
        backgroundOrigin: 'border-box',
        backgroundClip: 'padding-box, border-box',
      }}
    >
      <Box display="flex" alignItems="center" mb={2}>
        {icon && (
          <Box
            mr={2}
            display="flex"
            alignItems="center"
            justifyContent="center"
            sx={{
              width: "50px",
              height: "50px",
              borderRadius: "50%",
              bgcolor: `${chartColor}33`, // subtle background circle
              color: chartColor,
              fontSize: "28px",
            }}
          >
            {icon}
          </Box>
        )}
        <Typography
          variant="h4"
          fontWeight="bold"
          sx={{ color: textColor, fontSize: "1.8rem" }}
        >
          {title}
        </Typography>
      </Box>
      {subtitle && (
        <Typography
          variant="h6"
          fontWeight="600"
          sx={{ color: textColor, fontSize: "1rem", opacity: 0.85 }}
        >
          {subtitle}
        </Typography>
      )}
    </Box>
  );
};

export default StatBox;

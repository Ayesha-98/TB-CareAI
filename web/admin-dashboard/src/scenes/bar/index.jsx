// src/pages/bar/Bar.jsx
import { Box, useTheme } from "@mui/material";
import Header from "../../components/Header";
import ScreeningBarChart from "../../components/Barchart";

const Bar = () => {
  const theme = useTheme();

  return (
    <Box m="20px">
      {/* Heading */}
      <Header title="Screening Overview" subtitle="Monthly screening data" />

      {/* Bar Chart */}
      <Box height="70vh">
        <ScreeningBarChart isDashboard />
      </Box>
    </Box>
  );
};

export default Bar;

import { Box } from "@mui/material";
import Header from "../../components/Header";
import LineChart from "../../components/ChwChart";

const Line = () => {
  return (
    <Box m="20px">
      <Header
        title="CHW Performance"
        subtitle="Monthly trends for Community Health Worker activities"
      />

      {/* Line Chart */}
      <Box height="75vh">
        <LineChart />
      </Box>
    </Box>
  );
};

export default Line;

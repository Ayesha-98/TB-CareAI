import { Box } from "@mui/material";
import Header from "../../components/Header";
import GeographyLeaflet from "../../components/GeographyLeaflet";

const GeographyPage = () => (
  <Box m="20px">
    <Header title="Regional Heatmap" subtitle="TB-positive cases by province" />
    <Box mt="20px">
      <GeographyLeaflet />
    </Box>
  </Box>
);

export default GeographyPage;

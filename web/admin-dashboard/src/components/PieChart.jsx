import { useEffect, useState } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebaseConfig";
import { ResponsivePie } from "@nivo/pie";
import { tokens } from "../theme";
import { useTheme, Box, Typography } from "@mui/material";

const TBPositiveCasesPieChart = ({ isDashboard = false }) => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const chartColors = colors.chart;

  const [chartData, setChartData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [totalCases, setTotalCases] = useState(0);

  // Parse timestamp helper
  const parseTimestamp = (timestamp) => {
    if (!timestamp) return null;
    if (timestamp.toDate && typeof timestamp.toDate === 'function') {
      return timestamp.toDate();
    }
    if (timestamp instanceof Date) {
      return timestamp;
    }
    if (typeof timestamp === 'string') {
      const parsedDate = new Date(timestamp);
      return isNaN(parsedDate.getTime()) ? null : parsedDate;
    }
    return null;
  };

  // Function to assign colors from theme
  const getColor = (monthIndex) => {
    const colorKeys = [1, 2, 3, 4, 5, 6];
    return chartColors[colorKeys[monthIndex % colorKeys.length]];
  };

  const fetchTBPositiveCases = async () => {
    try {
      // Store to avoid duplicates
      const processedDiagnoses = new Set();
      const monthlyData = {};

      // Months order for sorting
      const monthsOrder = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      // 1️⃣ Fetch all doctors
      const doctorsSnapshot = await getDocs(collection(db, 'doctors'));
      
      for (const doctorDoc of doctorsSnapshot.docs) {
        const doctorId = doctorDoc.id;
        const doctorData = doctorDoc.data();
        
        // 2️⃣ Fetch diagnoses sub-collection for each doctor
        const diagnosesRef = collection(db, 'doctors', doctorId, 'diagnoses');
        const diagnosesSnapshot = await getDocs(diagnosesRef);
        
        for (const diagnosisDoc of diagnosesSnapshot.docs) {
          const diagnosisData = diagnosisDoc.data();
          const diagnosisId = diagnosisDoc.id;
          
          // Avoid duplicate processing
          if (processedDiagnoses.has(diagnosisId)) {
            continue;
          }
          processedDiagnoses.add(diagnosisId);
          
          // Check if this is a TB positive case
          const finalDiagnosis = diagnosisData.finalDiagnosis || '';
          const isTBPositive = finalDiagnosis.toLowerCase().includes('tb') || 
                               finalDiagnosis.toLowerCase().includes('tuberculosis');
          
          if (!isTBPositive) {
            continue;
          }
          
          // Get the diagnosis date
          const diagnosisDate = parseTimestamp(diagnosisData.createdAt);
          
          if (!diagnosisDate) {
            console.warn('No date found for diagnosis:', diagnosisId);
            continue;
          }
          
          // Get month from diagnosis date
          const monthName = diagnosisDate.toLocaleString('default', { month: 'long' });
          const monthShort = diagnosisDate.toLocaleString('default', { month: 'short' });
          const year = diagnosisDate.getFullYear();
          const monthKey = `${monthShort}-${year}`;
          
          // Initialize month entry if it doesn't exist
          if (!monthlyData[monthKey]) {
            monthlyData[monthKey] = { 
              id: monthShort, 
              label: monthShort, 
              value: 0, 
              fullMonth: monthName,
              year: year,
              diagnoses: [],
              doctorCount: 0,
              doctors: new Set()
            };
          }
          
          // Add to month's count
          monthlyData[monthKey].value++;
          monthlyData[monthKey].diagnoses.push({
            patientId: diagnosisData.patientId,
            doctorName: doctorData.name || 'Unknown Doctor',
            doctorId: doctorId,
            date: diagnosisDate
          });
          monthlyData[monthKey].doctors.add(doctorId);
        }
      }

      // Convert to array, calculate doctor counts, and sort by month order
      const monthlyArray = Object.values(monthlyData).map(item => ({
        ...item,
        doctorCount: item.doctors.size
      })).sort((a, b) => {
        // Sort by year first, then by month order
        if (a.year !== b.year) {
          return a.year - b.year;
        }
        return monthsOrder.indexOf(a.id) - monthsOrder.indexOf(b.id);
      });

      // Add colors to each month
      return monthlyArray.map((item, index) => ({
        ...item,
        color: getColor(index)
      }));

    } catch (error) {
      console.error("Error fetching TB positive cases:", error);
      return [];
    }
  };

  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true);
        const data = await fetchTBPositiveCases();
        setChartData(data);
        setTotalCases(data.reduce((sum, item) => sum + item.value, 0));
      } catch (error) {
        console.error("Error loading data:", error);
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, [theme.palette.mode]);

  // Configuration based on where it's used
  const chartConfig = {
    height: isDashboard ? 200 : 400,
    margin: isDashboard 
      ? { top: 10, right: 10, bottom: 10, left: 10 }
      : { top: 40, right: 40, bottom: 40, left: 40 },
    innerRadius: isDashboard ? 0.6 : 0.45,
    fontSize: {
      arcLabels: isDashboard ? 14 : 18,
      arcLinkLabels: isDashboard ? 11 : 13,
    },
    fontWeight: {
      arcLabels: 800,
      arcLinkLabels: 600,
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" height={chartConfig.height}>
        <Typography variant="body2" color="textSecondary">
          Loading TB cases...
        </Typography>
      </Box>
    );
  }

  if (totalCases === 0) {
    return (
      <Box 
        display="flex" 
        flexDirection="column" 
        alignItems="center" 
        justifyContent="center" 
        height={chartConfig.height}
        textAlign="center"
        sx={{ p: 2 }}
      >
        <Typography 
          variant={isDashboard ? "subtitle1" : "h6"} 
          color="textSecondary" 
          gutterBottom
          fontWeight={600}
        >
          No TB Cases
        </Typography>
        <Typography 
          variant="caption" 
          color="textSecondary" 
          sx={{ 
            opacity: 0.7, 
            fontSize: isDashboard ? '0.75rem' : '0.85rem',
            maxWidth: isDashboard ? '150px' : '250px'
          }}
        >
          No confirmed TB positive cases from doctors yet
        </Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ height: '100%', width: '100%', p: 0 }}>
      <Box sx={{ height: chartConfig.height, width: '100%', position: 'relative' }}>
        {/* Center total count */}
        <Box
          sx={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            textAlign: 'center',
            zIndex: 1,
            pointerEvents: 'none',
          }}
        >
          <Typography
            variant="h3"
            fontWeight="800"
            color={theme.palette.mode === 'light' ? '#1B4D3E' : '#9EF09E'}
            sx={{ fontSize: isDashboard ? '1.5rem' : '2rem' }}
          >
            {totalCases}
          </Typography>
          <Typography
            variant="caption"
            color="textSecondary"
            sx={{ fontSize: isDashboard ? '0.65rem' : '0.75rem' }}
          >
            Total Cases
          </Typography>
        </Box>

        <ResponsivePie
          data={chartData}
          colors={(d) => d.data.color}
          margin={chartConfig.margin}
          innerRadius={chartConfig.innerRadius}
          padAngle={0.8}
          cornerRadius={4}
          activeOuterRadiusOffset={isDashboard ? 6 : 10}
          borderWidth={2}
          borderColor={{ from: 'color', modifiers: [['darker', 0.2]] }}
          enableArcLinkLabels={!isDashboard}
          enableArcLabels={true}
          arcLabelsSkipAngle={isDashboard ? 20 : 10}
          arcLabelsTextColor="#FFFFFF"
          arcLinkLabelsSkipAngle={isDashboard ? 20 : 10}
          arcLinkLabelsColor={theme.palette.text.primary}
          arcLinkLabelsThickness={2}
          arcLinkLabelsTextColor={theme.palette.text.primary}
          arcLinkLabelsDiagonalLength={isDashboard ? 8 : 12}
          arcLinkLabelsStraightLength={isDashboard ? 8 : 12}
          arcLabel={(d) => {
            const percentage = ((d.value / totalCases) * 100).toFixed(1);
            return isDashboard ? `${d.value}` : `${d.value} (${percentage}%)`;
          }}
          arcLabelRadiusOffset={0.65}
          tooltip={({ datum }) => (
            <Box
              sx={{
                background: theme.palette.background.paper,
                padding: '12px 16px',
                borderRadius: '8px',
                border: `2px solid ${datum.data.color}`,
                boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                minWidth: isDashboard ? '160px' : '220px',
              }}
            >
              <Typography 
                variant="subtitle1" 
                fontWeight="700"
                color="text.primary"
                gutterBottom
                sx={{ fontSize: isDashboard ? '0.9rem' : '1rem' }}
              >
                📅 {datum.data.fullMonth} {datum.data.year}
              </Typography>
              
              <Box sx={{ mt: 1 }}>
                <Typography 
                  variant="body1" 
                  fontWeight="700" 
                  color={datum.data.color}
                  sx={{ fontSize: isDashboard ? '1rem' : '1.2rem' }}
                >
                  🩺 {datum.value} TB Cases
                </Typography>
                <Typography 
                  variant="caption" 
                  color="text.secondary" 
                  sx={{ fontSize: isDashboard ? '0.7rem' : '0.8rem' }}
                >
                  {((datum.value / totalCases) * 100).toFixed(1)}% of total
                </Typography>
                
                {!isDashboard && datum.data.doctorCount > 0 && (
                  <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.75rem', display: 'block', mt: 0.5 }}>
                    👨‍⚕️ {datum.data.doctorCount} doctor{datum.data.doctorCount > 1 ? 's' : ''} diagnosed
                  </Typography>
                )}
              </Box>
            </Box>
          )}
          theme={{
            arcLabels: {
              text: {
                fontSize: chartConfig.fontSize.arcLabels,
                fontWeight: chartConfig.fontWeight.arcLabels,
                fill: '#FFFFFF',
                stroke: 'rgba(0,0,0,0.6)',
                strokeWidth: isDashboard ? 2 : 3,
                strokeLinejoin: 'round',
                paintOrder: 'stroke',
              },
            },
            arcLinkLabels: {
              text: {
                fontSize: chartConfig.fontSize.arcLinkLabels,
                fontWeight: chartConfig.fontWeight.arcLinkLabels,
                fill: theme.palette.text.primary,
              },
            },
            tooltip: {
              container: {
                background: theme.palette.background.paper,
                fontSize: '14px',
                borderRadius: '8px',
                boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
              },
            },
          }}
          legends={[]}
        />
      </Box>
    </Box>
  );
};

export default TBPositiveCasesPieChart;
import { useTheme } from "@mui/material";
import { ResponsiveBar } from "@nivo/bar";
import { tokens } from "../theme";
import { useEffect, useState, useRef } from "react";
import { db } from "../firebaseConfig";
import { collection, onSnapshot, query } from "firebase/firestore";

const ScreeningBarChart = ({ isDashboard = false }) => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);

  const [screeningData, setScreeningData] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const processedScreeningIds = useRef(new Set());
  const unsubscribeRef = useRef(null);

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

  const processScreening = (screeningData, screeningId, monthlyCounts, allScreenings, patientName, patientId) => {
    if (processedScreeningIds.current.has(screeningId)) {
      return false;
    }
    
    processedScreeningIds.current.add(screeningId);
    
    if (screeningData && screeningData.timestamp) {
      const timestamp = parseTimestamp(screeningData.timestamp);
      
      if (timestamp && !isNaN(timestamp.getTime())) {
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        const monthIndex = timestamp.getMonth();
        const monthName = months[monthIndex];
        monthlyCounts[monthName] = (monthlyCounts[monthName] || 0) + 1;
        
        allScreenings.push({
          ...screeningData,
          screeningId: screeningId,
          patientName: patientName || "Patient",
          patientId: patientId
        });
        return true;
      }
    }
    return false;
  };

  const setupListeners = () => {
    console.log('🎯 Setting up Firestore listeners for all screenings...');
    setIsLoading(true);
    processedScreeningIds.current.clear();

    const monthlyCounts = {};
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    months.forEach(month => {
      monthlyCounts[month] = 0;
    });
    
    let allScreenings = [];

    // Helper to update chart after changes
    const updateChart = () => {
      const chartData = months.map((month) => ({
        month: month,
        screenings: monthlyCounts[month] || 0,
        monthFull: new Date(2024, months.indexOf(month)).toLocaleString('default', { month: 'long' })
      }));
      setScreeningData(chartData);
      setIsLoading(false);
    };

    // ========== 1. READ FROM PATIENTS COLLECTION (Self-registered patients) ==========
    const patientsQuery = query(collection(db, "patients"));
    
    const unsubscribePatients = onSnapshot(patientsQuery, (patientsSnap) => {
      console.log('📊 Patients snapshot received, total patients:', patientsSnap.docs.length);
      
      patientsSnap.docs.forEach((patientDoc) => {
        const patientData = patientDoc.data();
        const patientId = patientDoc.id;
        
        // Listen to screenings for this patient
        const screeningsRef = collection(db, "patients", patientId, "screenings");
        
        onSnapshot(screeningsRef, (screeningsSnap) => {
          screeningsSnap.docs.forEach((screeningDoc) => {
            const screeningData = screeningDoc.data();
            const screeningId = screeningDoc.id;
            
            processScreening(
              screeningData, 
              screeningId, 
              monthlyCounts, 
              allScreenings, 
              patientData.name, 
              patientId
            );
          });
          updateChart();
        });
      });
    });

    // ========== 2. READ FROM CHWS COLLECTION (Patients registered by CHW) ==========
    const chwsQuery = query(collection(db, "chws"));
    
    const unsubscribeChws = onSnapshot(chwsQuery, (chwsSnap) => {
      console.log('📊 CHWs snapshot received, total CHWs:', chwsSnap.docs.length);
      
      chwsSnap.docs.forEach((chwDoc) => {
        const chwId = chwDoc.id;
        
        // Get assigned patients for this CHW
        const assignedPatientsRef = collection(db, "chws", chwId, "assigned_patients");
        
        onSnapshot(assignedPatientsRef, (assignedPatientsSnap) => {
          assignedPatientsSnap.docs.forEach((patientDoc) => {
            const patientData = patientDoc.data();
            const patientId = patientDoc.id;
            
            // Listen to screenings for this CHW-assigned patient
            const screeningsRef = collection(db, "chws", chwId, "assigned_patients", patientId, "screenings");
            
            onSnapshot(screeningsRef, (screeningsSnap) => {
              screeningsSnap.docs.forEach((screeningDoc) => {
                const screeningData = screeningDoc.data();
                const screeningId = screeningDoc.id;
                
                processScreening(
                  screeningData, 
                  screeningId, 
                  monthlyCounts, 
                  allScreenings, 
                  patientData.name || patientData.patientName || "Patient", 
                  patientId
                );
              });
              updateChart();
            });
          });
        });
      });
    });

    // Store unsubscribe functions
    unsubscribeRef.current = () => {
      unsubscribePatients();
      unsubscribeChws();
    };
  };

  useEffect(() => {
    setupListeners();

    return () => {
      console.log('🧹 Cleaning up Firestore listeners...');
      if (unsubscribeRef.current) {
        unsubscribeRef.current();
      }
    };
  }, []);

  if (isLoading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '400px',
        color: theme.palette.mode === 'light' ? '#666' : '#ccc'
      }}>
        Loading screening data...
      </div>
    );
  }

  const getBarColor = (data) => {
    const screeningCount = data.data.screenings;
    
    if (theme.palette.mode === "light") {
      if (screeningCount === 0) return "#E2E8F0";
      if (screeningCount <= 2) return "#31D6AE";
      if (screeningCount <= 5) return "#FFB74D";
      if (screeningCount <= 10) return "#BE55A7";
      return "#F55077";
    } else {
      if (screeningCount === 0) return "#4A5568";
      if (screeningCount <= 2) return "#9EF09E";
      if (screeningCount <= 5) return "#FFA726";
      if (screeningCount <= 10) return "#AB47BC";
      return "#FF7043";
    }
  };

  const axisTextColor = theme.palette.mode === "light" ? "#666666" : "#CCCCCC";
  const axisLineColor = theme.palette.mode === "light" ? "#B0B0B0" : "#888888";

  return (
    <ResponsiveBar
      data={screeningData}
      keys={["screenings"]}
      indexBy="month"
      colors={getBarColor}
      borderRadius={6}
      margin={{ top: 60, right: 30, bottom: 70, left: 70 }}
      padding={0.35}
      valueScale={{ type: "linear" }}
      indexScale={{ type: "band", round: true }}
      borderColor={{ from: "color", modifiers: [["darker", 1.2]] }}
      axisTop={null}
      axisRight={null}
      axisBottom={{
        tickSize: 6,
        tickPadding: 8,
        tickRotation: 0,
        legend: isDashboard ? undefined : "Month",
        legendPosition: "middle",
        legendOffset: 45,
      }}
      axisLeft={{
        tickSize: 5,
        tickPadding: 5,
        tickRotation: 0,
        legend: isDashboard ? undefined : "Number of Screenings",
        legendPosition: "middle",
        legendOffset: -55,
        tickValues: 5,
      }}
      label={(d) => d.value > 0 ? d.value.toString() : ""}
      labelSkipWidth={0}
      labelSkipHeight={0}
      labelTextColor={theme.palette.mode === "light" ? "#000000" : "#FFFFFF"}
      tooltip={({ indexValue, value, data }) => {
        const isDark = theme.palette.mode === "dark";
        const monthFull = data?.monthFull || indexValue;
        
        const tooltipBackground = isDark ? "#2D3748" : "#FFFFFF";
        const tooltipTextColor = isDark ? "#FFFFFF" : "#2D3748";
        const accentColor = isDark ? "#68D391" : "#38A169";
        
        return (
          <div
            style={{
              background: tooltipBackground,
              color: tooltipTextColor,
              fontSize: '14px',
              fontWeight: 600,
              borderRadius: '8px',
              padding: '12px 16px',
              boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
              border: `2px solid ${isDark ? '#4A5568' : '#E2E8F0'}`,
              minWidth: '140px',
              textAlign: 'center',
            }}
          >
            <div style={{ 
              fontSize: '13px', 
              fontWeight: 500, 
              marginBottom: '4px',
              color: accentColor
            }}>
              {monthFull}
            </div>
            <div style={{ 
              fontSize: '16px', 
              fontWeight: 700,
              color: tooltipTextColor
            }}>
              {value} Screening{value !== 1 ? 's' : ''}
            </div>
          </div>
        );
      }}
      theme={{
        axis: {
          domain: { 
            line: { 
              stroke: axisLineColor, 
              strokeWidth: 1 
            } 
          },
          legend: { 
            text: { 
              fill: axisTextColor, 
              fontWeight: 600, 
              fontSize: 14 
            } 
          },
          ticks: {
            line: { 
              stroke: axisLineColor, 
              strokeWidth: 1 
            },
            text: { 
              fill: axisTextColor, 
              fontWeight: 500, 
              fontSize: 13 
            },
          },
        },
        grid: {
          line: {
            stroke: theme.palette.mode === "light" ? "#E2E8F0" : "#4A5568",
            strokeWidth: 1,
            strokeDasharray: "4 4",
          },
        },
        labels: {
          text: {
            fontWeight: 700,
            fontSize: 14,
            fill: theme.palette.mode === "light" ? "#000000" : "#FFFFFF",
          },
        },
      }}
      animate={true}
      motionConfig="gentle"
      enableLabel={true}
      hoverTarget="bar"
      isInteractive={true}
      legends={[]}
      role="application"
    />
  );
};

export default ScreeningBarChart;
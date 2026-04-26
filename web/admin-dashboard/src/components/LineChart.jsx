import { useEffect, useState } from "react";
import { ResponsiveLine } from "@nivo/line";
import { useTheme } from "@mui/material";
import { db } from "../firebaseConfig";
import { Calendar, ChartBar } from 'lucide-react';
import { collection, getDocs } from "firebase/firestore";

const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function groupByMonth(docs, timestampField) {
  const counts = {};
  months.forEach(m => (counts[m] = 0));

  docs.forEach(doc => {
    const timestamp = doc[timestampField];
    if (!timestamp) return;

    let date;
    
    if (timestamp.toDate && typeof timestamp.toDate === 'function') {
      date = timestamp.toDate();
    } 
    else if (typeof timestamp === 'string') {
      const cleanedTimestamp = timestamp
        .replace(' at ', ' ')
        .replace(' ', ' ')
        .replace(' UTC+5', '')
        .trim();
      date = new Date(cleanedTimestamp);
    }
    else if (timestamp instanceof Date) {
      date = timestamp;
    } else {
      return;
    }

    if (isNaN(date.getTime())) return;

    const month = months[date.getMonth()];
    counts[month] += 1;
  });

  return months.map(m => ({ x: m, y: counts[m] }));
}

// ✅ Updated: Get all screenings from both self-registered and CHW-registered patients
const getAllScreenings = async () => {
  const allScreenings = [];
  
  // 1. Get screenings from patients collection (self-registered)
  const patientsSnap = await getDocs(collection(db, "patients"));
  
  for (const patientDoc of patientsSnap.docs) {
    try {
      const screeningsRef = collection(db, "patients", patientDoc.id, "screenings");
      const screeningsSnap = await getDocs(screeningsRef);
      
      for (const screeningDoc of screeningsSnap.docs) {
        const screeningData = screeningDoc.data();
        allScreenings.push({
          ...screeningData,
          screeningId: screeningDoc.id,
          patientId: patientDoc.id,
          timestamp: screeningData.timestamp || screeningData.createdAt
        });
      }
    } catch (error) {
      console.warn(`Error fetching screenings for patient ${patientDoc.id}:`, error);
    }
  }
  
  // 2. Get screenings from CHWs assigned_patients (CHW-registered)
  const chwsSnap = await getDocs(collection(db, "chws"));
  
  for (const chwDoc of chwsSnap.docs) {
    try {
      const assignedPatientsRef = collection(db, "chws", chwDoc.id, "assigned_patients");
      const assignedPatientsSnap = await getDocs(assignedPatientsRef);
      
      for (const patientDoc of assignedPatientsSnap.docs) {
        const screeningsRef = collection(db, "chws", chwDoc.id, "assigned_patients", patientDoc.id, "screenings");
        const screeningsSnap = await getDocs(screeningsRef);
        
        for (const screeningDoc of screeningsSnap.docs) {
          const screeningData = screeningDoc.data();
          allScreenings.push({
            ...screeningData,
            screeningId: screeningDoc.id,
            patientId: patientDoc.id,
            timestamp: screeningData.timestamp || screeningData.createdAt
          });
        }
      }
    } catch (error) {
      console.warn(`Error fetching CHW screenings:`, error);
    }
  }
  
  return allScreenings;
};

// ✅ Updated: Get TB diagnoses from doctors collection
const getTBDiagnoses = async () => {
  const doctorsSnap = await getDocs(collection(db, "doctors"));
  const tbDiagnoses = new Map(); // patientId -> latest diagnosis date
  
  for (const doctorDoc of doctorsSnap.docs) {
    const diagnosesRef = collection(db, "doctors", doctorDoc.id, "diagnoses");
    const diagnosesSnap = await getDocs(diagnosesRef);
    
    for (const diagnosisDoc of diagnosesSnap.docs) {
      const diagnosisData = diagnosisDoc.data();
      const finalDiagnosis = diagnosisData.finalDiagnosis || '';
      const isTB = finalDiagnosis.toLowerCase().includes('tb') || 
                   finalDiagnosis.toLowerCase().includes('tuberculosis');
      
      if (isTB) {
        const patientId = diagnosisData.patientId;
        const diagnosisDate = diagnosisData.createdAt?.toDate?.() || new Date(diagnosisData.createdAt);
        const existing = tbDiagnoses.get(patientId);
        
        if (!existing || diagnosisDate > existing) {
          tbDiagnoses.set(patientId, diagnosisDate);
        }
      }
    }
  }
  
  return tbDiagnoses;
};

// ✅ Updated: Get lab test requested from doctors collection
const getLabTestRequested = async () => {
  const doctorsSnap = await getDocs(collection(db, "doctors"));
  const labTestRequested = new Set(); // patientId where lab test requested
  
  for (const doctorDoc of doctorsSnap.docs) {
    const diagnosesRef = collection(db, "doctors", doctorDoc.id, "diagnoses");
    const diagnosesSnap = await getDocs(diagnosesRef);
    
    for (const diagnosisDoc of diagnosesSnap.docs) {
      const diagnosisData = diagnosisDoc.data();
      if (diagnosisData.labTestRequested === true) {
        labTestRequested.add(diagnosisData.patientId);
      }
    }
  }
  
  return labTestRequested;
};

// Helper to calculate total for a stage (for percentage)
const calculateStageTotal = (data, stageId) => {
  const stage = data.find(d => d.id === stageId);
  if (!stage) return 0;
  return stage.data.reduce((sum, item) => sum + item.y, 0);
};

const PatientFunnelChart = ({ isDashboard = false }) => {
  const theme = useTheme();

  const fixedColors = [
    "#0B96F9", // Total Screenings
    "#31D6AE", // AI Analyzed
    "#FFC505", // Sent to Doctor
    "#BE55A7", // Doctor Reviewed
    "#FF9C41", // Lab Test Requested
    "#F55077"  // TB Diagnosed
  ];

  const [patientFunnelData, setPatientFunnelData] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setIsLoading(true);
        console.log("🔄 Starting patient progress data fetch...");

        const allScreenings = await getAllScreenings();
        console.log("🎯 Total screenings found:", allScreenings.length);

        const tbDiagnoses = await getTBDiagnoses();
        console.log("🩺 TB Diagnosed patients:", tbDiagnoses.size);

        const labTestRequested = await getLabTestRequested();
        console.log("🧪 Lab Test Requested patients:", labTestRequested.size);

        const totalScreenings = allScreenings;
        const aiAnalyzed = allScreenings.filter(s => !!(s.aiPrediction || s.prediction));
        const sentToDoctor = allScreenings.filter(s => s.status === "sent_to_doctor");
        const doctorReviewed = allScreenings.filter(s => s.doctorDiagnosis && s.doctorDiagnosis.trim() !== "");
        const labTestRequestedScreenings = allScreenings.filter(s => labTestRequested.has(s.patientId));
        const tbDiagnosedScreenings = allScreenings.filter(s => tbDiagnoses.has(s.patientId));

        console.log("📊 Stage counts:", {
          total: totalScreenings.length,
          aiAnalyzed: aiAnalyzed.length,
          sentToDoctor: sentToDoctor.length,
          doctorReviewed: doctorReviewed.length,
          labTestRequested: labTestRequestedScreenings.length,
          tbDiagnosed: tbDiagnosedScreenings.length
        });

        const data = [
          { id: "Total Screenings", color: fixedColors[0], data: groupByMonth(totalScreenings, "timestamp") },
          { id: "AI Analyzed", color: fixedColors[1], data: groupByMonth(aiAnalyzed, "timestamp") },
          { id: "Sent to Doctor", color: fixedColors[2], data: groupByMonth(sentToDoctor, "timestamp") },
          { id: "Doctor Reviewed", color: fixedColors[3], data: groupByMonth(doctorReviewed, "timestamp") },
          { id: "Lab Test Requested", color: fixedColors[4], data: groupByMonth(labTestRequestedScreenings, "timestamp") },
          { id: "TB Diagnosed", color: fixedColors[5], data: groupByMonth(tbDiagnosedScreenings, "timestamp") },
        ];

        setPatientFunnelData(data);

      } catch (error) {
        console.error("❌ Error fetching patient progress data:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
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
        Loading patient funnel data...
      </div>
    );
  }

  // ✅ FIXED Custom Tooltip - Using correct Nivo point structure
  const CustomTooltip = ({ point }) => {
  console.log("🔍 TOOLTIP POINT:", point);

  if (!point) return null;

  // ✅ PERFECT: Use the exact properties from your log
  const color = point.seriesColor || point.color || "#FF9C41";
  const stageName = point.seriesId || point.serieId || "Unknown";

  console.log("🎨 Color:", color, "Stage:", stageName);  // ✅ Debug

  const monthNames = {
    Jan: "January", Feb: "February", Mar: "March", Apr: "April", 
    May: "May", Jun: "June", Jul: "July", Aug: "August", 
    Sep: "September", Oct: "October", Nov: "November", Dec: "December",
  };

  const monthKey = point.data?.x || "Jan";
  const month = monthNames[monthKey] || monthKey;
  const count = point.data?.y || 0;

  return (
    <div style={{
      background: theme.palette.background.paper,
      color: theme.palette.text.primary,
      padding: "14px 18px",
      border: `2px solid ${color}`,        // ✅ #FF9C41 ORANGE!
      borderRadius: "10px",
      fontSize: "13px",
      fontWeight: 500,
      boxShadow: "0 4px 12px rgba(0,0,0,0.15)",
      minWidth: "240px",
    }}>
      <div style={{ display: "flex", alignItems: "center", marginBottom: "12px" }}>
        <div style={{
          width: "12px",
          height: "12px",
          backgroundColor: color,            // ✅ #FF9C41 ORANGE!
          borderRadius: "2px",
          marginRight: "10px",
        }} />
        <strong style={{ fontSize: "13px" }}>{stageName}</strong>  {/* Lab Test Requested */}
      </div>

      <div style={{
        display: "flex",
        justifyContent: "space-between",
        paddingTop: "8px",
        borderTop: `1px solid ${theme.palette.divider}`,
      }}>
        <span><Calendar size={16} /> Month: {month}</span>
        <span><ChartBar size={16} /> Count: {count}</span>
      </div>
    </div>
  );
};

  return (
  <ResponsiveLine
    data={patientFunnelData}
    colors={(serie) => serie.color}
    margin={{ top: 50, right: 30, bottom: 50, left: 60 }}
    xScale={{ type: "point" }}
    yScale={{ type: "linear", min: 0, max: "auto", stacked: false }}
    curve="monotoneX"
    axisTop={null}
    axisRight={null}
    axisBottom={{
      tickSize: 5,
      tickPadding: 8,
      tickRotation: 0,
      legend: isDashboard ? "" : "Month",  
      legendOffset: 36,
      legendPosition: "middle",
    }}
    axisLeft={{
      tickSize: 5,
      tickPadding: 5,
      tickRotation: 0,
      legend: isDashboard ? undefined : "Number of Patients",
      legendOffset: -50,
      legendPosition: "middle",
      tickValues: 5,
    }}
    enableGridX={false}
    enableGridY={true}
    pointSize={8}
    pointColor={{ from: "serieColor" }}
    pointBorderWidth={2}
    pointBorderColor={{ from: "serieColor" }}
    pointLabelYOffset={-12}
    useMesh={true}
    tooltip={CustomTooltip}  
    theme={{
      axis: {
        domain: { line: { stroke: theme.palette.mode === "dark" ? "#555" : "#bbb", strokeWidth: 1 } },
        ticks: {
          line: { stroke: theme.palette.mode === "dark" ? "#555" : "#bbb", strokeWidth: 1 },
          text: { fill: theme.palette.mode === "dark" ? "#fff" : "#333", fontSize: 11, fontWeight: 500 },
        },
        legend: { text: { fill: theme.palette.mode === "dark" ? "#fff" : "#333", fontSize: 12, fontWeight: 600 } },
      },
      grid: { line: { stroke: theme.palette.mode === "dark" ? "#444" : "#eee", strokeWidth: 1, strokeDasharray: "4 4" } },
    }}
    legends={[]}
  />
);
};

export default PatientFunnelChart;

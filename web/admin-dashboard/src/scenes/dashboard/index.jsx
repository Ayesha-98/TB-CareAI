// src/scenes/dashboard/index.jsx
import { useEffect, useState } from "react";
import { Box, Typography, useTheme } from "@mui/material";
import { tokens } from "../../theme";
import LocalHospitalIcon from "@mui/icons-material/LocalHospital";
import PeopleIcon from "@mui/icons-material/People";
import MedicalServicesIcon from "@mui/icons-material/MedicalServices";
import VaccinesIcon from "@mui/icons-material/Vaccines";
import Header from "../../components/Header";
import LineChart from "../../components/LineChart";
import BarChart from "../../components/Barchart";
import StatBox from "../../components/StatBox";
import GeographyLeaflet from "../../components/GeographyLeaflet";
import PieChart from "../../components/PieChart";
import React from "react";
import { useNavigate } from "react-router-dom";

// 🔥 NEW: Import notification components
import FloatingNotificationButton from "../../components/FloatingNotificationButton";
import NotificationDrawer from "../../components/NotificationDrawer";

// Firestore
import { db } from "../../firebaseConfig";
import { collection, getDocs, query, where } from "firebase/firestore";

const Dashboard = () => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const navigate = useNavigate();

  // 🔥 NEW: State for notification drawer
  const [drawerOpen, setDrawerOpen] = useState(false);

  const [stats, setStats] = useState({
    chwCount: 0,
    patientCount: 0,
    doctorCount: 0,
    screeningCount: 0,
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        const chwQuery = query(
          collection(db, "users"), 
          where("role", "==", "CHW"),
          where("status", "==", "Active")
        );
        const chwSnap = await getDocs(chwQuery);
        const chwCount = chwSnap.size;

        const doctorQuery = query(
          collection(db, "users"),
          where("role", "==", "Doctor"), 
          where("status", "==", "Active")
        );
        const doctorSnap = await getDocs(doctorQuery);
        const doctorCount = doctorSnap.size;

        const patientSnap = await getDocs(collection(db, "patients"));
        const patientCount = patientSnap.size;

        let screeningCount = 0;
        const patientsSnap = await getDocs(collection(db, "patients"));
        
        for (const patientDoc of patientsSnap.docs) {
          try {
            const screeningsRef = collection(db, "patients", patientDoc.id, "screenings");
            const screeningsSnap = await getDocs(screeningsRef);
            screeningCount += screeningsSnap.size;
          } catch (error) {
            console.log(`No screenings for patient ${patientDoc.id}`);
          }
        }

        setStats({
          chwCount,
          patientCount,
          doctorCount,
          screeningCount,
        });

      } catch (err) {
        console.error("Error fetching dashboard stats:", err);
      }
    };

    fetchData();
  }, []);

  const handleCardClick = (cardType) => {
    switch(cardType) {
      case 'chw':
        navigate('/chw');
        break;
      case 'patients':
        navigate('/patient');
        break;
      case 'doctors':
        navigate('/DoctorApprovals');
        break;
      case 'screenings':
        navigate('/bar');
        break;
      default:
        break;
    }
  };

  const cardData = [
    { 
      title: stats.chwCount.toLocaleString(), 
      subtitle: "Active CHWs", 
      progress: "0.75", 
      increase: "+5%", 
      icon: <PeopleIcon />,
      type: 'chw',
    },
    { 
      title: stats.patientCount.toLocaleString(), 
      subtitle: "Patients Registered", 
      progress: "0.60", 
      increase: "+12%", 
      icon: <LocalHospitalIcon />,
      type: 'patients',
    },
    { 
      title: stats.doctorCount.toLocaleString(), 
      subtitle: "Doctors Available", 
      progress: "0.40", 
      increase: "+3%", 
      icon: <MedicalServicesIcon />,
      type: 'doctors',
    },
    { 
      title: stats.screeningCount.toLocaleString(), 
      subtitle: "Screenings Completed", 
      progress: "0.85", 
      increase: "+20%", 
      icon: <VaccinesIcon />,
      type: 'screenings',
    },
  ];

  return (
    <Box m="20px">
      {/* HEADER */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Header
          title="HEALTH DASHBOARD"
          subtitle="Overview of CHWs, Patients, and Coverage"
        />
      </Box>

      {/* GRID & CHARTS */}
      <Box
        display="grid"
        gridTemplateColumns="repeat(12, 1fr)"
        gridAutoRows="140px"
        gap="20px"
      >
        {/* ROW 1 - STAT CARDS */}
        {cardData.map((item, index) => (
          <Box
            key={index}
            gridColumn="span 3"
            bgcolor={colors.background.widget}
            borderRadius="16px"
            display="flex"
            alignItems="center"
            justifyContent="center"
            boxShadow="0 4px 12px rgba(0,0,0,0.1)"
            sx={{
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              '&:hover': {
                transform: 'translateY(-4px)',
                boxShadow: '0 8px 24px rgba(0,0,0,0.15)',
                bgcolor: colors.background.widgetHover,
              },
              '&:active': {
                transform: 'translateY(-2px)',
              }
            }}
            onClick={() => handleCardClick(item.type)}
          >
            <StatBox
              title={item.title}
              subtitle={item.subtitle}
              progress={item.progress}
              increase={item.increase}
              icon={React.cloneElement(item.icon, {
                sx: { color: colors.accent, fontSize: "28px" },
              })}
            />
          </Box>
        ))}

        {/* ROW 2 - LINE CHART */}
        <Box
          gridColumn="span 8"
          gridRow="span 2"
          bgcolor={colors.background.widget}
          borderRadius="16px"
          boxShadow="0 4px 12px rgba(0,0,0,0.1)"
        >
          <Box height="250px" m="20px">
            <LineChart isDashboard />
          </Box>
        </Box>

        {/* MAP */}
        <Box
          gridColumn="span 4"
          gridRow="span 2"
          bgcolor={colors.background.widget}
          p="20px"
          borderRadius="16px"
          boxShadow="0 4px 12px rgba(0,0,0,0.1)"
        >
          <Typography
            variant="h4"
            fontWeight="600"
            color={colors.text.primary}
            mt="20px"
          >
            Regional Performance Map
          </Typography>
          <Box height="320px">
            <GeographyLeaflet isDashboard />
          </Box>
        </Box>

        {/* ROW 3 - PIE CHART */}
        <Box
          gridColumn="span 4"
          gridRow="span 2"
          bgcolor={colors.background.widget}
          p="20px"
          borderRadius="16px"
          boxShadow="0 4px 12px rgba(0,0,0,0.1)"
        >
          <Typography variant="h6" fontWeight="600" color={colors.text.primary} mb="15px">
            TB Positive Cases
          </Typography>
          <Box height="100%" width="100%">
            <PieChart isDashboard />
          </Box>
        </Box>

        {/* ROW 3 - BAR CHART */}
        <Box
          gridColumn="span 4"
          gridRow="span 2"
          bgcolor={colors.background.widget}
          p="20px"
          borderRadius="16px"
          boxShadow="0 4px 12px rgba(0,0,0,0.1)"
        >
          <Typography variant="h6" fontWeight="600" color={colors.text.primary} mb="15px">
            Screening Overview
          </Typography>
          <Box height="250px">
            <BarChart isDashboard />
          </Box>
        </Box>
      </Box>

     
      {/* 🔥 NEW: Floating Notification Button */}
      <FloatingNotificationButton onClick={() => setDrawerOpen(true)} />

      {/* 🔥 NEW: Notification Drawer */}
      <NotificationDrawer open={drawerOpen} onClose={() => setDrawerOpen(false)} />
    </Box>
  );
};

export default Dashboard;
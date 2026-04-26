import { useEffect, useState } from "react";
import { useTheme } from "@mui/material";
import { tokens } from "../theme";
import { db } from "../firebaseConfig";
import { collection, getDocs } from "firebase/firestore";

const ChwPerformanceChart = ({ isDashboard = false }) => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const isDark = theme.palette.mode === "dark";

  const [isLoading, setIsLoading] = useState(true);
  const [chwStats, setChwStats] = useState({
    totalCHWs: 0,
    activeCHWs: 0,
    totalScreenings: 0,
    totalPatients: 0,
    totalReferrals: 0,
    avgScreeningsPerCHW: 0,
    allChws: []
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        setIsLoading(true);
        console.log("🔄 Starting CHW performance data fetch...");

        // Get all CHWs
        const chwsSnap = await getDocs(collection(db, "chws"));
        const chwMap = {};

        // Initialize CHW data structure
        chwsSnap.forEach(chwDoc => {
          const chwData = chwDoc.data();
          chwMap[chwDoc.id] = {
            id: chwDoc.id,
            name: chwData.name || `CHW ${chwDoc.id.substring(0, 6)}`,
            screenings: [],
            patients: [],
            referrals: []
          };
        });

        console.log("👥 CHWs found:", Object.keys(chwMap).length);

        // Process data for each CHW
        for (const chwId in chwMap) {
          try {
            // Get assigned patients
            const patientsRef = collection(db, `chws/${chwId}/assigned_patients`);
            const patientsSnap = await getDocs(patientsRef);
            
            patientsSnap.forEach(patientDoc => {
              const patientData = patientDoc.data();
              chwMap[chwId].patients.push({
                ...patientData,
                id: patientDoc.id,
                createdAt: patientData.createdAt
              });
              
              // Count as referral if status is "sent_to_doctor"
              if (patientData.status === "sent_to_doctor") {
                chwMap[chwId].referrals.push({
                  ...patientData,
                  id: patientDoc.id,
                  createdAt: patientData.createdAt
                });
              }
            });

            // Get screenings from assigned_patients subcollection
            const patientsRefForScreenings = collection(db, `chws/${chwId}/assigned_patients`);
            const patientsSnapForScreenings = await getDocs(patientsRefForScreenings);
            
            for (const patientDoc of patientsSnapForScreenings.docs) {
              try {
                const screeningsRef = collection(db, `chws/${chwId}/assigned_patients`, patientDoc.id, "screenings");
                const screeningsSnap = await getDocs(screeningsRef);
                
                screeningsSnap.forEach(screeningDoc => {
                  const screeningData = screeningDoc.data();
                  chwMap[chwId].screenings.push({
                    ...screeningData,
                    screeningId: screeningDoc.id,
                    timestamp: screeningData.timestamp
                  });
                });
              } catch (error) {
                // No screenings for this patient
              }
            }

          } catch (error) {
            console.warn(`❌ Error processing data for CHW ${chwId}:`, error);
          }
        }

        // Calculate total statistics
        const allScreenings = Object.values(chwMap).flatMap(chw => chw.screenings);
        const allPatients = Object.values(chwMap).flatMap(chw => chw.patients);
        const allReferrals = Object.values(chwMap).flatMap(chw => chw.referrals);
        
        const totalCHWs = Object.keys(chwMap).length;
        const activeCHWs = Object.values(chwMap).filter(chw => chw.screenings.length > 0 || chw.patients.length > 0).length;
        const avgScreeningsPerCHW = totalCHWs > 0 ? Math.round(allScreenings.length / totalCHWs) : 0;

        // Calculate all CHW performance (no points/rank - just raw metrics)
        const allChwPerformance = Object.values(chwMap)
          .map(chw => ({
            name: chw.name,
            id: chw.id,
            screenings: chw.screenings.length,
            patients: chw.patients.length,
            referrals: chw.referrals.length,
            active: chw.screenings.length > 0 || chw.patients.length > 0
          }))
          .sort((a, b) => b.screenings - a.screenings);

        setChwStats({
          totalCHWs: totalCHWs,
          activeCHWs: activeCHWs,
          totalScreenings: allScreenings.length,
          totalPatients: allPatients.length,
          totalReferrals: allReferrals.length,
          avgScreeningsPerCHW: avgScreeningsPerCHW,
          allChws: allChwPerformance
        });

        console.log("📊 Final CHW performance data:", {
          totalCHWs: totalCHWs,
          activeCHWs: activeCHWs,
          totalScreenings: allScreenings.length,
          totalPatients: allPatients.length,
          totalReferrals: allReferrals.length
        });

      } catch (error) {
        console.error("❌ Error fetching CHW performance data:", error);
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
        color: colors.text.secondary
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '16px', marginBottom: '10px' }}>
            Loading CHW Performance Data...
          </div>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div style={{
        background: colors.background.widget,
        borderRadius: "16px",
        padding: "24px",
        margin: "20px",
        border: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`
      }}>
        
        
        {/* System Overview */}
        <div style={{
          fontSize: "14px",
          color: colors.text.secondary,
          marginBottom: "24px",
          padding: "16px",
          background: isDark ? "rgba(158,240,158,0.05)" : "rgba(27,77,62,0.03)",
          borderRadius: "12px",
          border: `1px solid ${isDark ? "rgba(158,240,158,0.1)" : "rgba(27,77,62,0.08)"}`
        }}>
          <div style={{ fontWeight: '600', marginBottom: '12px', color: colors.text.primary, fontSize: '14px' }}>
            System Overview
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px' }}>
            <div>Total CHWs: <strong style={{ color: colors.accent }}>{chwStats.totalCHWs}</strong></div>
            <div>Active CHWs: <strong style={{ color: colors.accent }}>{chwStats.activeCHWs}</strong></div>
            <div>Avg Screenings/CHW: <strong style={{ color: colors.accent }}>{chwStats.avgScreeningsPerCHW}</strong></div>
          </div>
        </div>
        
        {/* Stats Cards */}
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
          gap: "20px",
          marginBottom: "30px"
        }}>
          <div style={{
            background: colors.chart[1],
            padding: "20px",
            borderRadius: "12px",
            color: "white",
            position: "relative",
            overflow: "hidden"
          }}>
            <div style={{ position: 'absolute', top: '10px', right: '10px', opacity: 0.2, fontSize: '40px' }}>
              🩺
            </div>
            <div style={{ fontSize: "28px", fontWeight: "700", marginBottom: "8px" }}>
              {chwStats.totalScreenings}
            </div>
            <div style={{ fontSize: "14px", fontWeight: "600", marginBottom: "4px" }}>
              Total TB Screenings
            </div>
            <div style={{ fontSize: "11px", opacity: 0.9 }}>
              Screening conducted by all CHWs
            </div>
          </div>

          <div style={{
            background: colors.chart[2],
            padding: "20px",
            borderRadius: "12px",
            color: "white",
            position: "relative",
            overflow: "hidden"
          }}>
            <div style={{ position: 'absolute', top: '10px', right: '10px', opacity: 0.2, fontSize: '40px' }}>
              👥
            </div>
            <div style={{ fontSize: "28px", fontWeight: "700", marginBottom: "8px" }}>
              {chwStats.totalPatients}
            </div>
            <div style={{ fontSize: "14px", fontWeight: "600", marginBottom: "4px" }}>
              Total Patients Registered
            </div>
            <div style={{ fontSize: "11px", opacity: 0.9 }}>
              Patients added to CHW lists
            </div>
          </div>

          <div style={{
            background: colors.chart[4],
            padding: "20px",
            borderRadius: "12px",
            color: "white",
            position: "relative",
            overflow: "hidden"
          }}>
            <div style={{ position: 'absolute', top: '10px', right: '10px', opacity: 0.2, fontSize: '40px' }}>
              📤
            </div>
            <div style={{ fontSize: "28px", fontWeight: "700", marginBottom: "8px" }}>
              {chwStats.totalReferrals}
            </div>
            <div style={{ fontSize: "14px", fontWeight: "600", marginBottom: "4px" }}>
              Total Patient Referrals
            </div>
            <div style={{ fontSize: "11px", opacity: 0.9 }}>
              Patients referred to doctors
            </div>
          </div>
        </div>

        {/* CHW Performance Table */}
        {chwStats.allChws.length > 0 && (
          <div style={{
            background: colors.background.widgetTitle,
            padding: "20px",
            borderRadius: "12px",
            border: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`
          }}>
            <div style={{
              fontSize: "16px",
              fontWeight: "600",
              color: colors.text.primary,
              marginBottom: "20px",
              display: "flex",
              alignItems: "center",
              gap: "8px"
            }}>
              📋 CHW PERFORMANCE DETAILS
            </div>
            
            <div style={{
              overflowX: "auto",
              borderRadius: "12px",
              border: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`
            }}>
              <table style={{
                width: "100%",
                borderCollapse: "collapse",
                minWidth: "500px"
              }}>
                <thead>
                  <tr style={{
                    background: isDark ? "rgba(158,240,158,0.08)" : "rgba(27,77,62,0.04)"
                  }}>
                    <th style={{
                      padding: "14px 16px",
                      textAlign: "left",
                      fontSize: "13px",
                      fontWeight: "600",
                      color: colors.text.primary,
                      borderBottom: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`
                    }}>
                      CHW Name
                    </th>
                    <th style={{
                      padding: "14px 16px",
                      textAlign: "center",
                      fontSize: "13px",
                      fontWeight: "600",
                      color: colors.text.primary,
                      borderBottom: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`
                    }}>
                      Screenings
                    </th>
                    <th style={{
                      padding: "14px 16px",
                      textAlign: "center",
                      fontSize: "13px",
                      fontWeight: "600",
                      color: colors.text.primary,
                      borderBottom: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`
                    }}>
                      Patients
                    </th>
                    <th style={{
                      padding: "14px 16px",
                      textAlign: "center",
                      fontSize: "13px",
                      fontWeight: "600",
                      color: colors.text.primary,
                      borderBottom: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`
                    }}>
                      Referrals
                    </th>
                    <th style={{
                      padding: "14px 16px",
                      textAlign: "center",
                      fontSize: "13px",
                      fontWeight: "600",
                      color: colors.text.primary,
                      borderBottom: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`
                    }}>
                      Status
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {chwStats.allChws.map((chw, index) => (
                    <tr key={chw.id} style={{
                      borderBottom: index < chwStats.allChws.length - 1 ? `1px solid ${isDark ? "rgba(158,240,158,0.1)" : "rgba(27,77,62,0.08)"}` : "none",
                      background: index % 2 === 0 ? 
                        (isDark ? 'rgba(158,240,158,0.02)' : 'rgba(27,77,62,0.02)') : 
                        'transparent'
                    }}>
                      <td style={{
                        padding: "12px 16px",
                        fontSize: "14px",
                        color: colors.text.primary,
                        fontWeight: "500"
                      }}>
                        {chw.name}
                      </td>
                      <td style={{
                        padding: "12px 16px",
                        textAlign: "center",
                        fontSize: "14px",
                        color: colors.chart[1],
                        fontWeight: "600"
                      }}>
                        {chw.screenings}
                      </td>
                      <td style={{
                        padding: "12px 16px",
                        textAlign: "center",
                        fontSize: "14px",
                        color: colors.chart[2],
                        fontWeight: "600"
                      }}>
                        {chw.patients}
                      </td>
                      <td style={{
                        padding: "12px 16px",
                        textAlign: "center",
                        fontSize: "14px",
                        color: colors.chart[4],
                        fontWeight: "600"
                      }}>
                        {chw.referrals}
                      </td>
                      <td style={{
                        padding: "12px 16px",
                        textAlign: "center"
                      }}>
                        <span style={{
                          display: "inline-block",
                          padding: "4px 12px",
                          borderRadius: "20px",
                          fontSize: "11px",
                          fontWeight: "600",
                          background: chw.active ? 
                            (isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)") : 
                            (isDark ? "rgba(255,100,100,0.15)" : "rgba(255,100,100,0.1)"),
                          color: chw.active ? colors.chart[2] : colors.chart.semiNegative
                        }}>
                          {chw.active ? "Active" : "Inactive"}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            
            <div style={{
              marginTop: "16px",
              fontSize: "11px",
              color: colors.text.secondary,
              textAlign: "center"
            }}>
              
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ChwPerformanceChart;
// src/scenes/doctor_approvals/DoctorApprovals.jsx
import { useEffect, useState } from "react";
import {
  Box,
  Typography,
  Button,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Card,
  CardContent,
  Stack,
  useTheme,
  CircularProgress,
  Alert,
  Snackbar,
  Grid,
  Paper,
  Avatar,
  Divider,
  IconButton,
  Tooltip,
} from "@mui/material";
import {
  LocalHospital,
  Email,
  Work,
  Badge as BadgeIcon,
  School,
  Business,
  Visibility,
  CheckCircle,
  Cancel,
  Download,
  Verified,
  HourglassEmpty,
  LocationOn,
  Phone,
  Person,
  MedicalServices,
  Description,
  Close,
  ArrowBack,
  Shield
} from "@mui/icons-material";
import Header from "../../components/Header";
import { db } from "../../firebaseConfig";
import { 
  collection, 
  getDocs, 
  doc, 
  updateDoc,
  setDoc,
  query,
  where,
  Timestamp
} from "firebase/firestore";
import { tokens } from "../../theme";

const DoctorApprovals = () => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const isDark = theme.palette.mode === "dark";

  const [pendingDoctors, setPendingDoctors] = useState([]);
  const [selectedDoctor, setSelectedDoctor] = useState(null);
  const [loading, setLoading] = useState(false);
  const [snackbar, setSnackbar] = useState({
    open: false,
    message: "",
    severity: "success",
  });

  // Fetch pending doctor applications
  const fetchPendingDoctors = async () => {
    setLoading(true);
    try {
      const q = query(
        collection(db, 'doctor_applications'),
        where('status', '==', 'pending')
      );
      const snapshot = await getDocs(q);
      
      const doctors = await Promise.all(
        snapshot.docs.map(async (docSnap) => {
          const data = docSnap.data();
          const userQuery = query(collection(db, 'users'), where('email', '==', data.email));
          const userSnapshot = await getDocs(userQuery);
          const userData = userSnapshot.docs[0]?.data() || {};
          
          return {
            id: docSnap.id,
            ...data,
            userStatus: userData?.status || 'Unknown',
            userVerified: userData?.verified || false,
            userId: userSnapshot.docs[0]?.id,
          };
        })
      );
      
      setPendingDoctors(doctors);
    } catch (error) {
      console.error("Error fetching doctors:", error);
      showMessage("Failed to load doctor applications", "error");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPendingDoctors();
  }, []);

  const showMessage = (message, severity = "success") => {
    setSnackbar({ open: true, message, severity });
  };

  const handleCloseSnackbar = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  const approveDoctor = async (doctorId) => {
    try {
      const doctor = pendingDoctors.find((d) => d.id === doctorId);
      if (!doctor) {
        showMessage("Doctor not found", "error");
        return;
      }

      await updateDoc(doc(db, "doctor_applications", doctorId), {
        status: "approved",
        reviewedAt: Timestamp.now(),
        reviewedBy: "admin",
      });

      await createDoctorProfileFromApplication(doctor);

      if (doctor.userId) {
        await updateDoc(doc(db, "users", doctor.userId), {
          status: "Active",
          verified: true,
          role: "Doctor",
        });
      } else {
        const userQuery = query(collection(db, "users"), where("email", "==", doctor.email));
        const userSnapshot = await getDocs(userQuery);
        if (!userSnapshot.empty) {
          const userId = userSnapshot.docs[0].id;
          await updateDoc(doc(db, "users", userId), {
            status: "Active",
            verified: true,
            role: "Doctor",
          });
        }
      }

      showMessage("✅ Doctor approved successfully!");
      setSelectedDoctor(null);
      fetchPendingDoctors();

    } catch (error) {
      console.error("Error approving doctor:", error);
      showMessage(`Failed to approve doctor: ${error.message}`, "error");
    }
  };

  const createDoctorProfileFromApplication = async (doctor) => {
    try {
      const doctorProfileData = {
        uid: doctor.id,
        name: doctor.name || `Dr. ${doctor.personalInfo?.firstName} ${doctor.personalInfo?.lastName}`,
        email: doctor.email || doctor.personalInfo?.email,
        phone: doctor.phone || doctor.contactInfo?.phone || '',
        specialization: doctor.specialization || '',
        licenseNumber: doctor.licenseNumber || '',
        hospital: doctor.hospital || doctor.hospitals?.[0]?.name || '',
        experience: doctor.yearsOfExperience || doctor.experienceYears || '0',
        qualifications: doctor.qualifications || '',
        confirmedTBCount: 0,
        createdAt: Timestamp.now(),
        patientsReviewed: [],
        totalDiagnosisMade: 0,
        totalFinalVerdicts: 0,
        totalPatientsReviewed: 0,
        totalRecommendationGiven: 0,
        totalTestsRequested: 0,
        status: 'active',
        verified: true,
        applicationId: doctor.id,
        approvedAt: Timestamp.now(),
        ...(doctor.personalInfo && { 
          dateOfBirth: doctor.personalInfo.dateOfBirth,
          gender: doctor.personalInfo.gender,
        }),
        ...(doctor.contactInfo && {
          address: doctor.contactInfo.address,
          city: doctor.contactInfo.city,
          state: doctor.contactInfo.state,
          zipCode: doctor.contactInfo.zipCode,
        }),
      };

      await setDoc(doc(db, "doctors", doctor.id), doctorProfileData, { merge: true });
      return true;
    } catch (error) {
      console.error("❌ Error creating doctor profile:", error);
      throw error;
    }
  };

  const rejectDoctor = async (doctorId, reason = "") => {
    try {
      await updateDoc(doc(db, "doctor_applications", doctorId), {
        status: "rejected",
        reviewNotes: reason,
        reviewedAt: Timestamp.now(),
      });

      const doctor = pendingDoctors.find((d) => d.id === doctorId);
      if (doctor?.userId) {
        await updateDoc(doc(db, "users", doctor.userId), {
          status: "Rejected",
        });
      }

      showMessage("Doctor application rejected");
      setSelectedDoctor(null);
      fetchPendingDoctors();
    } catch (error) {
      console.error("Error rejecting doctor:", error);
      showMessage("Failed to reject doctor", "error");
    }
  };

  const getAvatarColor = (name) => {
    const colorOptions = [colors.accent, colors.chart[2], colors.chart[3], colors.chart[5]];
    const hash = name?.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0) || 0;
    return colorOptions[hash % colorOptions.length];
  };

  return (
    <Box m="20px">
      <Header 
        title="DOCTOR APPROVALS" 
        subtitle="Review and approve doctor applications"
      />

      {/* Main Content */}
      <Paper 
        elevation={0}
        sx={{ 
          backgroundColor: colors.background.widget,
          borderRadius: 3,
          overflow: 'hidden',
          border: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`
        }}
      >
        {/* Header */}
        <Box 
          sx={{ 
            p: 3,
            borderBottom: `1px solid ${isDark ? "rgba(158,240,158,0.1)" : "rgba(27,77,62,0.08)"}`,
            backgroundColor: colors.background.widgetTitle,
          }}
        >
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Box>
              <Typography 
                variant="h5" 
                fontWeight="700" 
                color={colors.text.primary}
                sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}
              >
                <Shield sx={{ color: colors.accent }} />
                Pending Applications
              </Typography>
              <Typography 
                variant="body2" 
                color={colors.text.secondary}
                sx={{ mt: 0.5 }}
              >
                Review each application carefully before approval
              </Typography>
            </Box>
            <Chip 
              label={`${pendingDoctors.length} Pending`}
              sx={{ 
                backgroundColor: colors.accent,
                color: "#fff",
                fontWeight: 600,
              }}
            />
          </Box>
        </Box>

        {/* Applications List */}
        <Box sx={{ p: 3 }}>
          {loading ? (
            <Box display="flex" justifyContent="center" alignItems="center" height="50vh">
              <CircularProgress sx={{ color: colors.accent }} />
            </Box>
          ) : pendingDoctors.length === 0 ? (
            <Box display="flex" flexDirection="column" alignItems="center" justifyContent="center" py={10}>
              <Avatar sx={{ width: 80, height: 80, backgroundColor: `${colors.accent}20`, color: colors.accent, mb: 3 }}>
                <CheckCircle sx={{ fontSize: 48 }} />
              </Avatar>
              <Typography variant="h5" fontWeight="600" color={colors.text.primary} gutterBottom>
                No Pending Applications
              </Typography>
              <Typography variant="body2" color={colors.text.secondary}>
                All doctor applications have been processed
              </Typography>
            </Box>
          ) : (
            <Grid container spacing={3}>
              {pendingDoctors.map((doctor) => (
                <Grid item xs={12} md={6} lg={4} key={doctor.id}>
                  <Card 
                    elevation={0}
                    sx={{
                      backgroundColor: colors.background.widgetTitle,
                      borderRadius: 2,
                      border: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`,
                      transition: 'all 0.2s',
                      '&:hover': {
                        transform: 'translateY(-4px)',
                        boxShadow: isDark ? '0 8px 24px rgba(0,0,0,0.3)' : '0 8px 24px rgba(0,0,0,0.1)',
                      }
                    }}
                  >
                    <CardContent sx={{ p: 0 }}>
                      {/* Header */}
                      <Box sx={{ p: 3, borderBottom: `1px solid ${isDark ? "rgba(158,240,158,0.1)" : "rgba(27,77,62,0.08)"}` }}>
                        <Box display="flex" alignItems="center" gap={2}>
                          <Avatar sx={{ backgroundColor: getAvatarColor(doctor.name), width: 56, height: 56 }}>
                            {doctor.personalInfo?.firstName?.charAt(0) || doctor.name?.charAt(0) || 'D'}
                          </Avatar>
                          <Box>
                            <Typography variant="h6" fontWeight="700" color={colors.text.primary}>
                              {doctor.personalInfo 
                                ? `Dr. ${doctor.personalInfo.firstName} ${doctor.personalInfo.lastName}`
                                : `Dr. ${doctor.name || 'Unknown'}`}
                            </Typography>
                            <Typography variant="body2" color={colors.accent} fontWeight="500">
                              {doctor.specialization || 'General Practitioner'}
                            </Typography>
                          </Box>
                        </Box>
                      </Box>

                      {/* Details */}
                      <Box sx={{ p: 3 }}>
                        <Stack spacing={2}>
                          <Box display="flex" alignItems="center" gap={1.5}>
                            <Business sx={{ fontSize: 18, color: colors.text.secondary }} />
                            <Typography variant="body2" color={colors.text.secondary}>
                              {doctor.hospital || doctor.hospitals?.[0]?.name || 'Hospital not specified'}
                            </Typography>
                          </Box>
                          
                          <Box display="flex" alignItems="center" gap={1.5}>
                            <Work sx={{ fontSize: 18, color: colors.text.secondary }} />
                            <Typography variant="body2" color={colors.text.secondary}>
                              {doctor.yearsOfExperience || doctor.experienceYears || 0} years experience
                            </Typography>
                          </Box>
                          
                          <Box display="flex" alignItems="center" gap={1.5}>
                            <Email sx={{ fontSize: 18, color: colors.text.secondary }} />
                            <Typography variant="body2" color={colors.text.secondary}>
                              {doctor.email}
                            </Typography>
                          </Box>
                        </Stack>

                        {/* Action Buttons */}
                        <Stack direction="row" spacing={1.5} sx={{ mt: 3 }}>
                          <Button
                            variant="outlined"
                            startIcon={<Visibility />}
                            onClick={() => setSelectedDoctor(doctor)}
                            fullWidth
                            sx={{
                              borderColor: colors.accent,
                              color: colors.accent,
                              borderRadius: 1.5,
                              '&:hover': { borderColor: colors.accent, backgroundColor: `${colors.accent}10` }
                            }}
                          >
                            Review
                          </Button>
                          
                          <Button
                            variant="contained"
                            startIcon={<CheckCircle />}
                            onClick={() => approveDoctor(doctor.id)}
                            fullWidth
                            sx={{
                              backgroundColor: colors.accent,
                              color: "#fff",
                              borderRadius: 1.5,
                              '&:hover': { backgroundColor: colors.accent, opacity: 0.9 }
                            }}
                          >
                            Approve
                          </Button>
                        </Stack>
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          )}
        </Box>
      </Paper>

      {/* Doctor Details Modal */}
      <Dialog 
        open={!!selectedDoctor} 
        onClose={() => setSelectedDoctor(null)}
        maxWidth="md"
        fullWidth
        PaperProps={{
          sx: {
            backgroundColor: colors.background.widget,
            borderRadius: 2,
            border: `1px solid ${isDark ? "rgba(158,240,158,0.15)" : "rgba(27,77,62,0.1)"}`,
          }
        }}
      >
        {selectedDoctor && (
          <>
            <DialogTitle sx={{ p: 0 }}>
              <Box sx={{ p: 3, borderBottom: `1px solid ${isDark ? "rgba(158,240,158,0.1)" : "rgba(27,77,62,0.08)"}`, backgroundColor: colors.background.widgetTitle }}>
                <Box display="flex" alignItems="center" justifyContent="space-between">
                  <Box display="flex" alignItems="center" gap={2}>
                    <Avatar sx={{ backgroundColor: getAvatarColor(selectedDoctor.name), width: 56, height: 56 }}>
                      {selectedDoctor.personalInfo?.firstName?.charAt(0) || selectedDoctor.name?.charAt(0) || 'D'}
                    </Avatar>
                    <Box>
                      <Typography variant="h6" fontWeight="700" color={colors.text.primary}>
                        {selectedDoctor.personalInfo 
                          ? `Dr. ${selectedDoctor.personalInfo.firstName} ${selectedDoctor.personalInfo.lastName}`
                          : `Dr. ${selectedDoctor.name}`}
                      </Typography>
                      <Typography variant="body2" color={colors.accent} fontWeight="500">
                        {selectedDoctor.specialization || 'Medical Professional'}
                      </Typography>
                    </Box>
                  </Box>
                  <IconButton onClick={() => setSelectedDoctor(null)}>
                    <Close />
                  </IconButton>
                </Box>
              </Box>
            </DialogTitle>
            
            <DialogContent sx={{ p: 3 }}>
              <Grid container spacing={3}>
                {/* Personal Information */}
                <Grid item xs={12}>
                  <Typography variant="subtitle2" fontWeight="600" color={colors.text.secondary} gutterBottom>
                    <Person sx={{ fontSize: 16, verticalAlign: 'middle', mr: 1 }} />
                    Personal Information
                  </Typography>
                  <Box sx={{ pl: 3, mt: 1 }}>
                    <Typography variant="body2" color={colors.text.primary}>
                      <strong>Name:</strong> {selectedDoctor.personalInfo?.firstName} {selectedDoctor.personalInfo?.lastName}
                    </Typography>
                    <Typography variant="body2" color={colors.text.primary} sx={{ mt: 0.5 }}>
                      <strong>Email:</strong> {selectedDoctor.email}
                    </Typography>
                    {selectedDoctor.phone && (
                      <Typography variant="body2" color={colors.text.primary} sx={{ mt: 0.5 }}>
                        <strong>Phone:</strong> {selectedDoctor.phone}
                      </Typography>
                    )}
                    {selectedDoctor.personalInfo?.dateOfBirth && (
                      <Typography variant="body2" color={colors.text.primary} sx={{ mt: 0.5 }}>
                        <strong>Date of Birth:</strong> {selectedDoctor.personalInfo.dateOfBirth}
                      </Typography>
                    )}
                    {selectedDoctor.personalInfo?.gender && (
                      <Typography variant="body2" color={colors.text.primary} sx={{ mt: 0.5 }}>
                        <strong>Gender:</strong> {selectedDoctor.personalInfo.gender}
                      </Typography>
                    )}
                  </Box>
                </Grid>

                {/* Professional Information */}
                <Grid item xs={12}>
                  <Typography variant="subtitle2" fontWeight="600" color={colors.text.secondary} gutterBottom>
                    <MedicalServices sx={{ fontSize: 16, verticalAlign: 'middle', mr: 1 }} />
                    Professional Information
                  </Typography>
                  <Box sx={{ pl: 3, mt: 1 }}>
                    <Typography variant="body2" color={colors.text.primary}>
                      <strong>Specialization:</strong> {selectedDoctor.specialization || 'Not specified'}
                    </Typography>
                    <Typography variant="body2" color={colors.text.primary} sx={{ mt: 0.5 }}>
                      <strong>Experience:</strong> {selectedDoctor.yearsOfExperience || selectedDoctor.experienceYears || 0} years
                    </Typography>
                    <Typography variant="body2" color={colors.text.primary} sx={{ mt: 0.5 }}>
                      <strong>License Number:</strong> {selectedDoctor.licenseNumber || 'Not provided'}
                    </Typography>
                    <Typography variant="body2" color={colors.text.primary} sx={{ mt: 0.5 }}>
                      <strong>Hospital/Clinic:</strong> {selectedDoctor.hospital || selectedDoctor.hospitals?.[0]?.name || 'Not specified'}
                    </Typography>
                    <Typography variant="body2" color={colors.text.primary} sx={{ mt: 0.5 }}>
                      <strong>Qualifications:</strong> {selectedDoctor.qualifications || 'Not specified'}
                    </Typography>
                  </Box>
                </Grid>

                {/* Address */}
                {selectedDoctor.contactInfo?.address && (
                  <Grid item xs={12}>
                    <Typography variant="subtitle2" fontWeight="600" color={colors.text.secondary} gutterBottom>
                      <LocationOn sx={{ fontSize: 16, verticalAlign: 'middle', mr: 1 }} />
                      Address
                    </Typography>
                    <Box sx={{ pl: 3, mt: 1 }}>
                      <Typography variant="body2" color={colors.text.primary}>
                        {selectedDoctor.contactInfo.address}
                      </Typography>
                      <Typography variant="body2" color={colors.text.primary}>
                        {selectedDoctor.contactInfo.city}, {selectedDoctor.contactInfo.state} {selectedDoctor.contactInfo.zipCode}
                      </Typography>
                    </Box>
                  </Grid>
                )}
              </Grid>
            </DialogContent>

            <Divider />

            <DialogActions sx={{ p: 3, gap: 2 }}>
              <Button 
                onClick={() => setSelectedDoctor(null)}
                variant="outlined"
                sx={{ borderColor: colors.text.secondary, color: colors.text.secondary }}
              >
                Cancel
              </Button>
              <Button 
                startIcon={<Cancel />}
                onClick={() => rejectDoctor(selectedDoctor.id, "Application rejected")}
                sx={{ backgroundColor: colors.chart.semiNegative, color: "#fff", '&:hover': { backgroundColor: colors.chart.semiNegative, opacity: 0.9 } }}
                variant="contained"
              >
                Reject
              </Button>
              <Button 
                startIcon={<CheckCircle />}
                onClick={() => approveDoctor(selectedDoctor.id)}
                sx={{ backgroundColor: colors.accent, color: "#fff", '&:hover': { backgroundColor: colors.accent, opacity: 0.9 } }}
                variant="contained"
              >
                Approve & Create Profile
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={handleCloseSnackbar}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert onClose={handleCloseSnackbar} severity={snackbar.severity} sx={{ backgroundColor: colors.background.widget, color: colors.text.primary }}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default DoctorApprovals;
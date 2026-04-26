// ChatbotEditor.jsx - Simplified version (no temperature, no API key)
import { Box, Typography, useTheme, Paper, Button, TextField, Select, MenuItem, FormControl, InputLabel, Snackbar, Alert, CircularProgress, Divider } from "@mui/material";
import { tokens } from "../../theme";
import Header from "../../components/Header";
import { db } from "../../firebaseConfig";
import { doc, getDoc, setDoc, serverTimestamp } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { useEffect, useState } from "react";
import SaveIcon from "@mui/icons-material/Save";
import RestartAltIcon from "@mui/icons-material/RestartAlt";
import SmartToyIcon from "@mui/icons-material/SmartToy";

const ChatbotEditor = () => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const isDark = theme.palette.mode === "dark";

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  
  const [config, setConfig] = useState({
    systemPrompt: "You are TB-CareAI, a medical assistant that ONLY answers questions related to tuberculosis (TB). Answer clearly and factually about TB symptoms, diagnosis, treatment, diet, cure, care, and prevention. If asked something outside TB, politely refuse.",
    offTopicResponse: "I can only answer questions related to tuberculosis (TB). Please ask about TB symptoms, treatment, prevention, or care.",
    tbKeywords: "tb, tuberculosis, cough, x-ray, treatment, medicine, isoniazid, rifampicin, symptom, prevention, infection, lungs, sputum, diet, care, cure, drug, therapy, diagnosis, fever, night sweat, weight loss, contagious, bacteria, latent, active",
  });

  const [snackbar, setSnackbar] = useState({
    open: false,
    message: "",
    severity: "success",
  });

  const showMessage = (message, severity = "success") => {
    setSnackbar({ open: true, message, severity });
  };

  const handleCloseSnackbar = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  // Load config from Firestore
  const loadConfig = async () => {
    setLoading(true);
    try {
      const docRef = doc(db, "chatbot_config", "settings");
      const docSnap = await getDoc(docRef);
      
      if (docSnap.exists()) {
        const data = docSnap.data();
        setConfig({
          systemPrompt: data.systemPrompt || config.systemPrompt,
          offTopicResponse: data.offTopicResponse || config.offTopicResponse,
          tbKeywords: data.tbKeywords || config.tbKeywords,
        });
      }
    } catch (error) {
      console.error("Error loading chatbot config:", error);
      showMessage("Failed to load configuration", "error");
    } finally {
      setLoading(false);
    }
  };

  // Save config to Firestore
  const saveConfig = async () => {
    setSaving(true);
    try {
      const auth = getAuth();
      const currentUser = auth.currentUser;
      
      await setDoc(doc(db, "chatbot_config", "settings"), {
        systemPrompt: config.systemPrompt,
        offTopicResponse: config.offTopicResponse,
        tbKeywords: config.tbKeywords,
        updatedAt: serverTimestamp(),
        updatedBy: currentUser?.email || "admin",
      });
      
      showMessage("Chatbot configuration saved successfully!", "success");
    } catch (error) {
      console.error("Error saving chatbot config:", error);
      showMessage("Failed to save configuration", "error");
    } finally {
      setSaving(false);
    }
  };

  // Reset to default values
  const resetToDefault = () => {
    setConfig({
      systemPrompt: "You are TB-CareAI, a medical assistant that ONLY answers questions related to tuberculosis (TB). Answer clearly and factually about TB symptoms, diagnosis, treatment, diet, cure, care, and prevention. If asked something outside TB, politely refuse.",
      offTopicResponse: "I can only answer questions related to tuberculosis (TB). Please ask about TB symptoms, treatment, prevention, or care.",
      tbKeywords: "tb, tuberculosis, cough, x-ray, treatment, medicine, isoniazid, rifampicin, symptom, prevention, infection, lungs, sputum, diet, care, cure, drug, therapy, diagnosis, fever, night sweat, weight loss, contagious, bacteria, latent, active",
    });
    showMessage("Reset to default values. Click Save to apply.", "info");
  };

  useEffect(() => {
    loadConfig();
  }, []);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box m="20px">
      <Header
        title="CHATBOT CONFIGURATION"
        subtitle="Configure how the AI assistant responds to users"
      />

      {/* Main Config Card */}
      <Paper
        elevation={0}
        sx={{
          p: 3,
          backgroundColor: colors.background.widget,
          borderRadius: "16px",
        }}
      >
        {/* System Prompt */}
        <Box mb={4}>
          <Typography variant="h6" fontWeight="bold" mb={1} color={isDark ? colors.text.primary : "#1B4D3E"}>
            System Prompt (Instructions for AI)
          </Typography>
          <Typography variant="caption" color={isDark ? colors.text.secondary : "#666"} display="block" mb={1}>
            This defines how the AI behaves and responds to users.
          </Typography>
          <TextField
            fullWidth
            multiline
            rows={6}
            value={config.systemPrompt}
            onChange={(e) => setConfig({ ...config, systemPrompt: e.target.value })}
            placeholder="Enter system prompt..."
            sx={{
              "& .MuiOutlinedInput-root": {
                backgroundColor: isDark ? "#1a1a1a" : "#f5f5f5",
              },
            }}
          />
        </Box>

        {/* Off-Topic Response */}
        <Box mb={4}>
          <Typography variant="h6" fontWeight="bold" mb={1} color={isDark ? colors.text.primary : "#1B4D3E"}>
            Off-Topic Response Message
          </Typography>
          <Typography variant="caption" color={isDark ? colors.text.secondary : "#666"} display="block" mb={1}>
            Message shown when users ask non-TB related questions.
          </Typography>
          <TextField
            fullWidth
            multiline
            rows={3}
            value={config.offTopicResponse}
            onChange={(e) => setConfig({ ...config, offTopicResponse: e.target.value })}
            placeholder="Enter off-topic response..."
            sx={{
              "& .MuiOutlinedInput-root": {
                backgroundColor: isDark ? "#1a1a1a" : "#f5f5f5",
              },
            }}
          />
        </Box>

        {/* TB Keywords */}
        <Box mb={4}>
          <Typography variant="h6" fontWeight="bold" mb={1} color={isDark ? colors.text.primary : "#1B4D3E"}>
            TB Keywords (comma separated)
          </Typography>
          <Typography variant="caption" color={isDark ? colors.text.secondary : "#666"} display="block" mb={1}>
            Keywords that trigger TB-related responses. Add new keywords to improve detection.
          </Typography>
          <TextField
            fullWidth
            multiline
            rows={4}
            value={config.tbKeywords}
            onChange={(e) => setConfig({ ...config, tbKeywords: e.target.value })}
            placeholder="Enter keywords separated by commas..."
            helperText="Example: tb, tuberculosis, cough, treatment"
            sx={{
              "& .MuiOutlinedInput-root": {
                backgroundColor: isDark ? "#1a1a1a" : "#f5f5f5",
              },
            }}
          />
        </Box>

        <Divider sx={{ my: 3 }} />
            
         

        {/* Action Buttons */}
        <Box display="flex" gap={2} flexWrap="wrap" justifyContent="center">
          <Button
            variant="outlined"
            startIcon={<RestartAltIcon />}
            onClick={resetToDefault}
            sx={{
              borderColor: colors.chart.semiNegative,
              color: colors.chart.semiNegative,
              "&:hover": {
                borderColor: colors.chart.semiNegative,
                backgroundColor: `${colors.chart.semiNegative}10`,
              },
            }}
          >
            Reset to Default
          </Button>
          <Button
            variant="contained"
            startIcon={saving ? <CircularProgress size={20} color="inherit" /> : <SaveIcon />}
            onClick={saveConfig}
            disabled={saving}
            sx={{
              backgroundColor: colors.accent,
              "&:hover": { backgroundColor: colors.accent, opacity: 0.9 },
            }}
          >
            {saving ? "Saving..." : "Save Changes"}
          </Button>
        </Box>
      </Paper>

      {/* Info Banner */}
      <Paper
        elevation={0}
        sx={{
          mt: 3,
          p: 2,
          backgroundColor: isDark ? "#1a1a1a" : "#f5f5f5",
          borderRadius: "12px",
          textAlign: "center",
        }}
      >
        <Typography variant="caption" color={isDark ? colors.text.secondary : "#666"}>
          💡 Changes will take effect immediately after saving. No app update required for patients.
        </Typography>
      </Paper>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={handleCloseSnackbar}
        anchorOrigin={{ vertical: "top", horizontal: "center" }}
      >
        <Alert onClose={handleCloseSnackbar} severity={snackbar.severity} variant="filled">
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default ChatbotEditor;
// src/scenes/login/Login.jsx
import React, { useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "../../firebaseConfig";
import { doc, getDoc } from "firebase/firestore";
import { logActivity } from "../../utils/activityLog";
import { 
  Box, 
  Typography, 
  TextField, 
  Button, 
  useTheme, 
  Paper, 
  CircularProgress,
  Alert,
  IconButton,
  InputAdornment
} from "@mui/material";
import { tokens } from "../../theme";
import { Visibility, VisibilityOff, AdminPanelSettings, Person, LocalHospital } from "@mui/icons-material";
import { useNavigate } from "react-router-dom";

const Login = () => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    
    // Validation
    if (!email.trim()) {
      setError("Please enter your email");
      return;
    }
    if (!password.trim()) {
      setError("Please enter your password");
      return;
    }

    setIsLoading(true);
    setError("");

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      let currentRole = null;
      let displayName = null;

      // Fetch user data from Firestore
      try {
        const userSnap = await getDoc(doc(db, "users", user.uid));
        if (userSnap.exists()) {
          const u = userSnap.data();
          currentRole = u.role ?? null;
          displayName = u.name ?? null;
        }
      } catch (e) {
        console.warn("Could not read /users:", e);
      }

      // Fallback to patients collection if no name found
      if (!displayName) {
        try {
          const patSnap = await getDoc(doc(db, "patients", user.uid));
          if (patSnap.exists()) {
            displayName = patSnap.data().name ?? null;
          }
        } catch (e) {
          console.warn("Could not read /patients:", e);
        }
      }

      // Log the login activity
      await logActivity({
        performedByUid: user.uid,
        performedByName: displayName,
        performedByEmail: user.email,
        affectedUserUid: user.uid,
        affectedUserName: displayName,
        affectedUserEmail: user.email,
        currentRole,
        activity: "Login",
        details: "User logged in successfully",
      });

      console.log("✅ Logged in:", user);
      console.log("👤 Role:", currentRole);

      // Redirect based on role
      if (currentRole === "admin" || currentRole === "Admin") {
        navigate("/dashboard");
      } else if (currentRole === "doctor" || currentRole === "Doctor") {
        navigate("/doctor/dashboard");
      } else if (currentRole === "chw" || currentRole === "CHW") {
        navigate("/chw/dashboard");
      } else if (currentRole === "patient" || currentRole === "Patient") {
        navigate("/patient/dashboard");
      } else {
        // Default redirect for unknown roles
        navigate("/dashboard");
      }

    } catch (err) {
      console.error("Login error:", err);
      
      // User-friendly error messages
      if (err.code === "auth/user-not-found") {
        setError("No account found with this email. Please sign up first.");
      } else if (err.code === "auth/wrong-password") {
        setError("Incorrect password. Please try again.");
      } else if (err.code === "auth/too-many-requests") {
        setError("Too many failed attempts. Please try again later.");
      } else if (err.code === "auth/invalid-email") {
        setError("Please enter a valid email address.");
      } else {
        setError(err.message || "Login failed. Please check your credentials.");
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Box
      sx={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: colors.background.dashboard,
        p: 2,
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Decorative background elements */}
      <Box
        sx={{
          position: "absolute",
          top: -100,
          right: -100,
          width: 300,
          height: 300,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${colors.accent}10, transparent)`,
          zIndex: 0,
        }}
      />
      <Box
        sx={{
          position: "absolute",
          bottom: -100,
          left: -100,
          width: 250,
          height: 250,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${colors.accent}10, transparent)`,
          zIndex: 0,
        }}
      />

      <Paper
        elevation={8}
        sx={{
          p: { xs: 3, sm: 4 },
          width: { xs: "90%", sm: 420 },
          borderRadius: 4,
          backgroundColor: colors.background.widget,
          boxShadow: theme.palette.mode === "dark" 
            ? "0 8px 32px rgba(0,0,0,0.3)" 
            : "0 8px 32px rgba(0,0,0,0.1)",
          zIndex: 1,
          transition: "transform 0.2s ease-in-out",
          "&:hover": {
            transform: "translateY(-4px)",
          },
        }}
      >
        {/* Logo / Icon Section */}
        <Box sx={{ textAlign: "center", mb: 3 }}>
          <Box
            sx={{
              width: 70,
              height: 70,
              margin: "0 auto",
              borderRadius: "50%",
              backgroundColor: colors.accent + "15",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              mb: 2,
            }}
          >
            <LocalHospital sx={{ fontSize: 40, color: colors.accent }} />
          </Box>
          <Typography
            variant="h4"
            fontWeight="bold"
            sx={{ 
              color: colors.text.primary, 
              textAlign: "center",
              letterSpacing: "-0.5px",
            }}
          >
            TB-Care AI
          </Typography>
          <Typography
            variant="body2"
            sx={{ 
              color: colors.text.secondary, 
              textAlign: "center",
              mt: 0.5,
            }}
          >
            Advanced TB Screening & Patient Management
          </Typography>
        </Box>

        <Typography
          variant="h5"
          fontWeight="600"
          sx={{ mb: 3, color: colors.text.primary, textAlign: "center" }}
        >
          Welcome Back
        </Typography>

        <form onSubmit={handleLogin}>
          <TextField
            fullWidth
            type="email"
            label="Email Address"
            variant="outlined"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={isLoading}
            sx={{
              mb: 2.5,
              "& .MuiOutlinedInput-root": {
                color: colors.text.primary,
                backgroundColor: colors.background.widget,
                borderRadius: 2,
                "& fieldset": {
                  borderColor: theme.palette.mode === "dark" ? "#444" : "#ddd",
                },
                "&:hover fieldset": {
                  borderColor: colors.accent,
                },
                "&.Mui-focused fieldset": {
                  borderColor: colors.accent,
                  borderWidth: 2,
                },
              },
              "& .MuiInputLabel-root": {
                color: colors.text.secondary,
                "&.Mui-focused": {
                  color: colors.accent,
                },
              },
            }}
          />

          <TextField
            fullWidth
            type={showPassword ? "text" : "password"}
            label="Password"
            variant="outlined"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            disabled={isLoading}
            sx={{
              mb: 2.5,
              "& .MuiOutlinedInput-root": {
                color: colors.text.primary,
                backgroundColor: colors.background.widget,
                borderRadius: 2,
                "& fieldset": {
                  borderColor: theme.palette.mode === "dark" ? "#444" : "#ddd",
                },
                "&:hover fieldset": {
                  borderColor: colors.accent,
                },
                "&.Mui-focused fieldset": {
                  borderColor: colors.accent,
                  borderWidth: 2,
                },
              },
              "& .MuiInputLabel-root": {
                color: colors.text.secondary,
                "&.Mui-focused": {
                  color: colors.accent,
                },
              },
            }}
            InputProps={{
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton
                    onClick={() => setShowPassword(!showPassword)}
                    edge="end"
                    sx={{ color: colors.text.secondary }}
                  >
                    {showPassword ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                </InputAdornment>
              ),
            }}
          />

          <Button
            type="submit"
            fullWidth
            variant="contained"
            disabled={isLoading}
            sx={{
              backgroundColor: colors.accent,
              color: theme.palette.mode === "dark" ? "#000" : "#fff",
              py: 1.5,
              fontWeight: "bold",
              borderRadius: 2,
              textTransform: "none",
              fontSize: "1rem",
              "&:hover": {
                backgroundColor: colors.accent,
                opacity: 0.9,
              },
              "&:disabled": {
                backgroundColor: colors.accent + "80",
                color: theme.palette.mode === "dark" ? "#000" : "#fff",
              },
            }}
          >
            {isLoading ? (
              <CircularProgress size={24} sx={{ color: theme.palette.mode === "dark" ? "#000" : "#fff" }} />
            ) : (
              "Sign In"
            )}
          </Button>

          {error && (
            <Alert 
              severity="error" 
              sx={{ mt: 2, borderRadius: 2 }}
              onClose={() => setError("")}
            >
              {error}
            </Alert>
          )}
        </form>

        <Box sx={{ mt: 3, textAlign: "center" }}>
          <Typography
            variant="body2"
            sx={{ color: colors.text.secondary }}
          >
            Don't have an account?{" "}
            <a 
              href="/signup" 
              style={{ 
                color: colors.accent, 
                textDecoration: "none",
                fontWeight: 600,
              }}
              onMouseEnter={(e) => e.target.style.textDecoration = "underline"}
              onMouseLeave={(e) => e.target.style.textDecoration = "none"}
            >
              Sign Up
            </a>
          </Typography>
          
          <Typography
            variant="body2"
            sx={{ mt: 1, color: colors.text.secondary }}
          >
            <a 
              href="/forgot-password" 
              style={{ 
                color: colors.text.secondary, 
                textDecoration: "none",
                fontSize: "0.75rem",
              }}
              onMouseEnter={(e) => e.target.style.textDecoration = "underline"}
              onMouseLeave={(e) => e.target.style.textDecoration = "none"}
            >
              Forgot Password?
            </a>
          </Typography>
        </Box>

        {/* Demo credentials hint (only in development) */}
        {process.env.NODE_ENV === "development" && (
          <Box sx={{ mt: 3, p: 1.5, borderRadius: 2, backgroundColor: colors.background.dashboard }}>
            <Typography variant="caption" sx={{ color: colors.text.secondary, display: "block", textAlign: "center" }}>
              Demo Credentials:
            </Typography>
            <Typography variant="caption" sx={{ color: colors.text.secondary, display: "block", textAlign: "center", fontSize: "10px" }}>
              ayeshamajid980@gmail.com / Ayesha123@
            </Typography>
          </Box>
        )}
      </Paper>
    </Box>
  );
};

export default Login;
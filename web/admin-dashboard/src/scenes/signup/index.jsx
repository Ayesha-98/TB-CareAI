// src/scenes/signup/SignUp.jsx
import React, { useState } from "react";
import {
  Box,
  Button,
  TextField,
  Typography,
  Paper,
  useTheme,
  Alert,
  CircularProgress,
  IconButton,
  InputAdornment,
} from "@mui/material";
import { tokens } from "../../theme";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "../../firebaseConfig";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";
import { Visibility, VisibilityOff } from "@mui/icons-material";
import { useNavigate } from "react-router-dom";

function SignUp() {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [success, setSuccess] = useState(false);

  // Fixed role as Admin
  const role = "Admin";

  const handleSignUp = async (e) => {
    e.preventDefault();
    
    // Validation
    if (!name.trim()) {
      setError("Please enter your full name");
      return;
    }
    if (!email.trim()) {
      setError("Please enter your email");
      return;
    }
    if (!password.trim()) {
      setError("Please enter your password");
      return;
    }
    if (password.length < 6) {
      setError("Password must be at least 6 characters");
      return;
    }

    setIsLoading(true);
    setError("");

    try {
      // Create user in Firebase Auth
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // Save to users collection with Admin role
      await setDoc(doc(db, "users", user.uid), {
        uid: user.uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: "Admin", // Fixed role
        verified: true, // Admin is verified by default
        flagged: false,
        status: "Active", // Admin is active by default
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });

      setSuccess(true);
      
      // Redirect to admin dashboard after 2 seconds
      setTimeout(() => {
        navigate("/admin");
      }, 2000);

      console.log("✅ Admin account created successfully:", user.uid);
    } catch (err) {
      console.error("Signup error:", err);
      
      // User-friendly error messages
      if (err.code === "auth/email-already-in-use") {
        setError("This email is already registered. Please login instead.");
      } else if (err.code === "auth/weak-password") {
        setError("Password is too weak. Please use a stronger password.");
      } else if (err.code === "auth/invalid-email") {
        setError("Please enter a valid email address.");
      } else {
        setError(err.message || "Sign up failed. Please try again.");
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Box
      display="flex"
      justifyContent="center"
      alignItems="center"
      minHeight="100vh"
      sx={{
        backgroundColor: colors.background.dashboard,
        p: 2,
      }}
    >
      <Paper
        elevation={8}
        sx={{
          padding: { xs: 3, sm: 4 },
          width: "100%",
          maxWidth: "450px",
          borderRadius: "16px",
          backgroundColor: colors.background.widget,
          boxShadow: theme.palette.mode === "dark" 
            ? "0 8px 32px rgba(0,0,0,0.3)" 
            : "0 8px 32px rgba(0,0,0,0.1)",
          transition: "transform 0.2s ease-in-out",
          "&:hover": {
            transform: "translateY(-4px)",
          },
        }}
      >
        {/* Header Section */}
        <Box textAlign="center" mb={3}>
          <Typography
            variant="h4"
            fontWeight="bold"
            color={colors.text.primary}
            sx={{ mb: 1 }}
          >
            Create Admin Account
          </Typography>
          <Typography
            variant="body2"
            color={colors.text.secondary}
          >
            Please fill in your details to create an admin account
          </Typography>
        </Box>

        {success ? (
          <Alert 
            severity="success" 
            sx={{ borderRadius: 2, mt: 2 }}
          >
            ✅ Admin account created successfully! Redirecting to dashboard...
          </Alert>
        ) : (
          <form onSubmit={handleSignUp}>
            <TextField
              label="Full Name"
              fullWidth
              margin="normal"
              variant="outlined"
              value={name}
              onChange={(e) => setName(e.target.value)}
              disabled={isLoading}
              sx={{
                "& .MuiOutlinedInput-root": {
                  color: colors.text.primary,
                  backgroundColor: colors.background.widget,
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
              label="Email Address"
              type="email"
              fullWidth
              margin="normal"
              variant="outlined"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={isLoading}
              sx={{
                "& .MuiOutlinedInput-root": {
                  color: colors.text.primary,
                  backgroundColor: colors.background.widget,
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
              label="Password"
              type={showPassword ? "text" : "password"}
              fullWidth
              margin="normal"
              variant="outlined"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={isLoading}
              helperText="Password must be at least 6 characters"
              sx={{
                "& .MuiOutlinedInput-root": {
                  color: colors.text.primary,
                  backgroundColor: colors.background.widget,
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
                "& .MuiFormHelperText-root": {
                  color: colors.text.secondary,
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

            {/* Show role as Admin (read-only) */}
            <TextField
              label="Role"
              fullWidth
              margin="normal"
              variant="outlined"
              value="Admin"
              disabled
              sx={{
                "& .MuiOutlinedInput-root": {
                  color: colors.accent,
                  backgroundColor: colors.background.widget,
                  fontWeight: "bold",
                  "& fieldset": {
                    borderColor: colors.accent,
                  },
                },
                "& .MuiInputLabel-root": {
                  color: colors.accent,
                },
              }}
            />

            {error && (
              <Alert 
                severity="error" 
                sx={{ mt: 2, borderRadius: 2 }}
                onClose={() => setError("")}
              >
                {error}
              </Alert>
            )}

            <Button
              type="submit"
              fullWidth
              variant="contained"
              disabled={isLoading}
              sx={{
                mt: 3,
                py: 1.5,
                fontSize: "16px",
                fontWeight: "bold",
                backgroundColor: colors.accent,
                borderRadius: 2,
                textTransform: "none",
                "&:hover": {
                  backgroundColor: colors.accent,
                  opacity: 0.9,
                },
                "&:disabled": {
                  backgroundColor: colors.accent + "80",
                },
              }}
            >
              {isLoading ? (
                <CircularProgress size={24} sx={{ color: "#fff" }} />
              ) : (
                "Create Admin Account"
              )}
            </Button>
          </form>
        )}

        {/* Login Link */}
        {!success && (
          <Box textAlign="center" mt={3}>
            <Typography variant="body2" color={colors.text.secondary}>
              Already have an account?{" "}
              <a
                href="/login"
                style={{
                  color: colors.accent,
                  textDecoration: "none",
                  fontWeight: 600,
                }}
                onMouseEnter={(e) => (e.target.style.textDecoration = "underline")}
                onMouseLeave={(e) => (e.target.style.textDecoration = "none")}
              >
                Sign In
              </a>
            </Typography>
          </Box>
        )}
      </Paper>
    </Box>
  );
}

export default SignUp;
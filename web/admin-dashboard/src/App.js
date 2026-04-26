import { Routes, Route } from "react-router-dom";
import AppLayout from "./AppLayout";
import Dashboard from "./scenes/dashboard";
import Manage_users from "./scenes/manage_users";
import Manage_roles from "./scenes/manage_roles";
import User_activity from "./scenes/audit_logs";
import Chat_content from "./scenes/DoctorApprovals";
import Calendar from "./scenes/calendar";
import Notification from "./scenes/chatbot";
import Bar from "./scenes/bar";
import Pie from "./scenes/pie";
import Patient from "./scenes/patient";
import Chw from "./scenes/chw";
import Geo from "./scenes/geography";
import Login from "./scenes/login";   
import SignUp from "./scenes/signup";
import LogoutButton from "./scenes/signout";

import { CssBaseline, ThemeProvider } from "@mui/material";
import { ColorModeContext, useMode } from "./theme";

function App() {
  const [theme, colorMode] = useMode();

  return (
    <ColorModeContext.Provider value={colorMode}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Routes>
          <Route path="/signup" element={<SignUp />} />
          <Route path="/login" element={<Login />} />  
          <Route path="/signout" element={<LogoutButton />} />
          <Route element={<AppLayout />}>
            <Route index element={<Dashboard />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/manage_users" element={<Manage_users />} />
            <Route path="/manage_roles" element={<Manage_roles />} /> 
            <Route path="/audit_logs" element={<User_activity />} />
            <Route path="/doctorapprovals" element={<Chat_content />} />
            <Route path="/calendar" element={<Calendar />} />
            <Route path="/chatboteditor" element={<Notification />} />
            <Route path="/bar" element={<Bar />} />
            <Route path="/pie" element={<Pie />} />
            <Route path="/patient" element={<Patient />} />
            <Route path="/chw" element={<Chw />} />
            <Route path="/geography" element={<Geo />} />
          </Route>
        </Routes>
      </ThemeProvider>
    </ColorModeContext.Provider>
  );
}

export default App;

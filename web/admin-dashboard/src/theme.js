import { createContext, useState, useMemo } from "react";
import { createTheme } from "@mui/material/styles";

// color design tokens export
export const tokens = (mode) => ({
  ...(mode === "dark"
    ? {
        background: {
          dashboard: "#191D24",
          widget: "#232935",
          widgetTitle: "#232935",
        },
        text: {
          primary: "#EFF7FF",
          secondary: "#DADFE9",
        },
        accent: "#9EF09E",
        chart: {
          1: "#9EF09E",
          2: "#5566FC",
          3: "#92B0FF",
          4: "#F5DC71",
          5: "#FF9C41",
          6: "#F55077",
          semiPositive: "#51CD37",
          semiNegative: "#FF5005",
        },
      }
    : {
        background: {
          dashboard: "#F8F9FA", // Using your app's bgColor
          widget: "#FFFFFF",
          widgetTitle: "#FFFFFF",
        },
        text: {
          primary: "#1B4D3E", // Changed to your app's primary green
          secondary: "#1B4D3E", // Changed to your app's primary green
        },
        accent: "#1B4D3E", // Changed to your app's primary green
        chart: {
          1: "#FFC505",
          2: "#31D6AE",
          3: "#0B96F9",
          4: "#BE55A7",
          5: "#062A74",
          6: "#2862DC",
          semiPositive: "#6BD955",
          semiNegative: "#FF5005",
        },
      }),
});

// mui theme settings
export const themeSettings = (mode) => {
  const colors = tokens(mode);
  return {
    palette: {
      mode: mode,
      ...(mode === "dark"
        ? {
            // 🌙 Dark Theme
            primary: {
              main: "#EFF7FF", // primary text
            },
            secondary: {
              main: "#9EF09E", // accent color
            },
            text: {
              primary: "#EFF7FF", // text primary
              secondary: "#DADFE9", // text secondary
            },
            background: {
              default: "#191D24", // dashboard bg
              paper: "#232935", // widget bg
            },
            chart: {
              1: "#9EF09E",
              2: "#5566FC",
              3: "#92B0FF",
              4: "#F5DC71",
              5: "#FF9C41",
              6: "#F55077",
              semiPositive: "#51CD37",
              semiNegative: "#FF5005",
            },
          }
        : {
            // ☀️ Light Theme - Updated with green colors
            primary: {
              main: "#1B4D3E", // Changed to your app's primary green
            },
            secondary: {
              main: "#1B4D3E", // Changed to your app's primary green
            },
            text: {
              primary: "#1B4D3E", // Changed to your app's primary green for headings
              secondary: "#1B4D3E", // Changed to your app's primary green for sidebar text
            },
            background: {
              default: "#F8F9FA", // Using your app's bgColor
              paper: "#FFFFFF", // widget bg
            },
            chart: {
              1: "#FFC505",
              2: "#31D6AE",
              3: "#0B96F9",
              4: "#BE55A7",
              5: "#062A74",
              6: "#2862DC",
              semiPositive: "#6BD955",
              semiNegative: "#FF5005",
            },
          }),
    },
    typography: {
      fontFamily: ["Source Sans Pro", "sans-serif"].join(","),
      fontSize: 12,
      h1: {
        fontFamily: ["Source Sans Pro", "sans-serif"].join(","),
        fontSize: 40,
        color: mode === "light" ? "#1B4D3E" : "#EFF7FF", // Green in light mode
      },
      h2: {
        fontFamily: ["Source Sans Pro", "sans-serif"].join(","),
        fontSize: 32,
        color: mode === "light" ? "#1B4D3E" : "#EFF7FF", // Green in light mode
      },
      h3: {
        fontFamily: ["Source Sans Pro", "sans-serif"].join(","),
        fontSize: 24,
        color: mode === "light" ? "#1B4D3E" : "#EFF7FF", // Green in light mode
      },
      h4: {
        fontFamily: ["Source Sans Pro", "sans-serif"].join(","),
        fontSize: 20,
        color: mode === "light" ? "#1B4D3E" : "#EFF7FF", // Green in light mode
      },
      h5: {
        fontFamily: ["Source Sans Pro", "sans-serif"].join(","),
        fontSize: 16,
        color: mode === "light" ? "#1B4D3E" : "#EFF7FF", // Green in light mode
      },
      h6: {
        fontFamily: ["Source Sans Pro", "sans-serif"].join(","),
        fontSize: 14,
        color: mode === "light" ? "#1B4D3E" : "#EFF7FF", // Green in light mode
      },
    },
    components: {
      MuiListItemButton: {
        styleOverrides: {
          root: {
            "&.Mui-selected": {
              backgroundColor: mode === "light" ? "rgba(27, 77, 62, 0.08)" : "rgba(158, 240, 158, 0.08)",
              "&:hover": {
                backgroundColor: mode === "light" ? "rgba(27, 77, 62, 0.12)" : "rgba(158, 240, 158, 0.12)",
              },
            },
          },
        },
      },
      MuiListItemIcon: {
        styleOverrides: {
          root: {
            color: mode === "light" ? "#1B4D3E" : "#EFF7FF", // Green in light mode for sidebar icons
            minWidth: "32px",
          },
        },
      },
      MuiListItemText: {
        styleOverrides: {
          primary: {
            color: mode === "light" ? "#1B4D3E" : "#EFF7FF", // Green in light mode for sidebar text
            fontWeight: 500,
          },
        },
      },
    },
  };
};

// context for color mode
export const ColorModeContext = createContext({
  toggleColorMode: () => {},
});

export const useMode = () => {
  const [mode, setMode] = useState("light");

  const colorMode = useMemo(
    () => ({
      toggleColorMode: () =>
        setMode((prev) => (prev === "light" ? "dark" : "light")),
    }),
    []
  );

  const theme = useMemo(() => createTheme(themeSettings(mode)), [mode]);
  return [theme, colorMode];
};
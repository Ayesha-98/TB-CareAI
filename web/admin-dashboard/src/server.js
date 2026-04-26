// server.js
import express from "express";
import fetch from "node-fetch";
import cors from "cors";

const app = express();
app.use(cors());

// 🔑 Replace with your DHIS2 credentials & server URL
const DHIS2_URL = "https://your-dhis2-server.org/api/analytics.json";
const DHIS2_USER = "your-username";
const DHIS2_PASS = "your-password";

// Example: TB incidence indicator + province org units + latest year
const QUERY =
  "?dimension=dx:TbIndicatorIdHere" +
  "&dimension=ou:ProvinceGroupIdHere" +
  "&dimension=pe:2024" +
  "&displayProperty=NAME";

app.get("/api/tb-data", async (req, res) => {
  try {
    const response = await fetch(`${DHIS2_URL}${QUERY}`, {
      headers: {
        Authorization: "Basic " + Buffer.from(`${DHIS2_USER}:${DHIS2_PASS}`).toString("base64"),
      },
    });

    const data = await response.json();

    // Simplify data: rows look like [dxId, ouId, year, value]
    const stats = data.rows.map((row) => ({
      id: row[1], // orgUnit ID from DHIS2 (province)
      value: Number(row[3]),
    }));

    res.json(stats);
  } catch (err) {
    console.error("Error fetching DHIS2 data:", err);
    res.status(500).json({ error: "Failed to fetch TB data" });
  }
});

app.listen(5000, () => {
  console.log("Server running on http://localhost:5000");
});

// src/components/GeographyLeaflet.jsx
import React, { useMemo, useEffect, useState } from "react";
import { MapContainer, TileLayer, GeoJSON, useMap, Marker, Popup } from "react-leaflet";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebaseConfig";
import geoJson from "../data/pakistan_provinces.json";
import citiesData from "../data/cities.json";
import "leaflet/dist/leaflet.css";
import "./map.css";

// Fix for default marker icons in Leaflet
import L from "leaflet";
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png",
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
});

const getCityMarkerIcon = (count) => {
  let size = 24;
  if (count > 20) size = 32;
  else if (count > 10) size = 28;
  else if (count > 5) size = 24;
  else if (count > 0) size = 20;
  else size = 16;
  
  const darkBlue = "#1B4D3E";
  
  return L.divIcon({
    className: "custom-city-marker",
    html: `<div style="
      background-color: ${darkBlue};
      width: ${size}px;
      height: ${size}px;
      border-radius: 50%;
      border: 2px solid white;
      box-shadow: 0 2px 6px rgba(0,0,0,0.3);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: ${size * 0.35}px;
      font-weight: bold;
      color: white;
      transition: transform 0.2s;
      cursor: pointer;
    ">
      ${count > 0 ? count : ""}
    </div>`,
    iconSize: [size, size],
    popupAnchor: [0, -size / 2],
  });
};

const cityToProvince = {
  "Lahore": "PK-PB", "Rawalpindi": "PK-PB", "Faisalabad": "PK-PB",
  "Multan": "PK-PB", "Gujranwala": "PK-PB", "Sialkot": "PK-PB",
  "Bahawalpur": "PK-PB", "Sargodha": "PK-PB", "Sheikhupura": "PK-PB",
  "Rahim Yar Khan": "PK-PB", "Jhang": "PK-PB", "Dera Ghazi Khan": "PK-PB",
  "Ahmedpur East": "PK-PB", "Ahmadpur East": "PK-PB", "Adilpur": "PK-PB",
  "Karachi": "PK-SD", "Hyderabad": "PK-SD", "Sukkur": "PK-SD",
  "Larkana": "PK-SD", "Nawabshah": "PK-SD", "Mirpur Khas": "PK-SD",
  "Peshawar": "PK-KP", "Abbottabad": "PK-KP", "Mardan": "PK-KP",
  "Swat": "PK-KP", "Dera Ismail Khan": "PK-KP", "Kohat": "PK-KP",
  "Quetta": "PK-BA", "Gwadar": "PK-BA", "Turbat": "PK-BA", "Khuzdar": "PK-BA",
  "Islamabad": "PK-IS",
  "Gilgit": "PK-GB", "Skardu": "PK-GB", "Khapalu": "PK-GB",
  "Muzaffarabad": "PK-JK", "Mirpur": "PK-JK",
};

const provinceNames = {
  "PK-PB": "Punjab", "PK-SD": "Sindh", "PK-KP": "Khyber Pakhtunkhwa",
  "PK-BA": "Balochistan", "PK-IS": "Islamabad", "PK-GB": "Gilgit-Baltistan",
  "PK-JK": "Azad Kashmir",
};

// Extract city from audit log details
const extractCityFromDetails = (details) => {
  if (!details) return null;
  
  const patterns = [
    /City:\s*([A-Za-z\s]+)/i,
    /city[:\s]*([A-Za-z\s]+)/i,
    /([A-Za-z\s]+)(?:\s+(?:registration|registered|joined))/i
  ];
  
  for (const pattern of patterns) {
    const match = details.match(pattern);
    if (match && match[1]) {
      const city = match[1].trim();
      if (cityToProvince[city]) return city;
    }
  }
  return null;
};

const MapController = ({ viewState, selectedProvince }) => {
  const map = useMap();
  
  useEffect(() => {
    if (viewState === "province") {
      map.setView([30.3753, 69.3451], 5.5);
    } else if (viewState === "city" && selectedProvince) {
      const provinceBounds = {
        "PK-PB": { center: [31.0, 73.0], zoom: 7.5 },
        "PK-SD": { center: [25.5, 68.5], zoom: 7.5 },
        "PK-KP": { center: [34.0, 72.0], zoom: 7.5 },
        "PK-BA": { center: [28.0, 65.0], zoom: 6.5 },
        "PK-IS": { center: [33.68, 73.04], zoom: 10 },
        "PK-GB": { center: [35.9, 74.5], zoom: 7 },
        "PK-JK": { center: [34.2, 73.7], zoom: 8 },
      };
      const bounds = provinceBounds[selectedProvince] || { center: [30.3753, 69.3451], zoom: 6 };
      map.setView(bounds.center, bounds.zoom);
    }
  }, [viewState, selectedProvince, map]);
  
  return null;
};

const GeographyLeaflet = () => {
  const [regionalData, setRegionalData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [viewState, setViewState] = useState("province");
  const [selectedProvince, setSelectedProvince] = useState(null);
  const [selectedProvinceName, setSelectedProvinceName] = useState("");
  const [cityUserCounts, setCityUserCounts] = useState({});

  const fetchRealData = async () => {
    setLoading(true);
    console.log("🔄 Starting data fetch...");
    
    try {
      const provinceCounts = {};
      const cityCounts = {};
      
      // 1. USERS collection
      console.log("📋 Fetching users...");
      const usersSnapshot = await getDocs(collection(db, "users"));
      console.log(`📊 Found ${usersSnapshot.size} users`);
      
      usersSnapshot.forEach((doc) => {
        const data = doc.data();
        const city = data.city?.trim();
        console.log(`👤 ${data.name || 'Unknown'}: "${city}"`);
        
        if (city && cityToProvince[city]) {
          const provinceId = cityToProvince[city];
          provinceCounts[provinceId] = (provinceCounts[provinceId] || 0) + 1;
          cityCounts[city] = (cityCounts[city] || 0) + 1;
          console.log(`✅ ${city} -> ${provinceId}`);
        }
      });
      
      // 2. ADMIN_AUDIT_LOGS collection
      console.log("📋 Fetching audit logs...");
      const auditSnapshot = await getDocs(collection(db, "admin_audit_logs"));
      console.log(`📊 Found ${auditSnapshot.size} audit logs`);
      
      auditSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.action === "USER_REGISTERED") {
          console.log(`👤 Audit: ${data.actor?.name}: "${data.details}"`);
          const city = extractCityFromDetails(data.details);
          
          if (city && cityToProvince[city]) {
            const provinceId = cityToProvince[city];
            provinceCounts[provinceId] = (provinceCounts[provinceId] || 0) + 1;
            cityCounts[city] = (cityCounts[city] || 0) + 1;
            console.log(`✅ Audit ${city} -> ${provinceId}`);
          }
        }
      });
      
      console.log("🏙️ City counts:", cityCounts);
      console.log("🗺️ Province counts:", provinceCounts);
      
      setCityUserCounts(cityCounts);
      
      setRegionalData([
        { id: "PK-PB", value: provinceCounts["PK-PB"] || 0 },
        { id: "PK-SD", value: provinceCounts["PK-SD"] || 0 },
        { id: "PK-KP", value: provinceCounts["PK-KP"] || 0 },
        { id: "PK-BA", value: provinceCounts["PK-BA"] || 0 },
        { id: "PK-IS", value: provinceCounts["PK-IS"] || 0 },
        { id: "PK-GB", value: provinceCounts["PK-GB"] || 0 },
        { id: "PK-JK", value: provinceCounts["PK-JK"] || 0 },
      ]);
      
    } catch (error) {
      console.error("❌ Error:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRealData();
  }, []);

  const dataMap = useMemo(() => {
    return regionalData.reduce((acc, cur) => {
      if (cur.id) acc[cur.id] = cur.value ?? 0;
      return acc;
    }, {});
  }, [regionalData]);

  function getProvinceColor(value) {
    if (value == null || value === 0) return "#e0e0e0";
    if (value > 200) return "#0a2a1f";
    if (value > 150) return "#1B4D3E";
    if (value > 100) return "#2a6e5c";
    if (value > 50) return "#3b8a73";
    if (value > 20) return "#5ba392";
    return "#8fb5a8";
  }

  function style(feature) {
    const id = feature.properties?.shapeISO;
    const value = dataMap[id];
    return {
      fillColor: getProvinceColor(value),
      fillOpacity: 0.85,
      color: "#0f172a",
      weight: 1,
      dashArray: "0",
      cursor: "pointer",
    };
  }

  function onEachFeature(feature, layer) {
    const name = feature.properties?.shapeName || "Unknown";
    const id = feature.properties?.shapeISO || "";
    const value = dataMap[id] ?? 0;
    
    layer.bindPopup(`
      <div style="padding: 8px; min-width: 150px;">
        <strong style="font-size: 16px;">${name}</strong><br/>
        <hr style="margin: 8px 0; border-color: #ddd;" />
        <span style="font-size: 14px;">👥 Total Users: <strong>${value}</strong></span><br/>
        <span style="font-size: 12px; color: #666;">Click to view cities</span>
      </div>
    `);

    layer.on({
      click: (e) => {
        e.target.openPopup();
        const provinceId = id;
        const provinceName = name;
        const citiesInProvince = citiesData.filter(city => cityToProvince[city.name] === provinceId);
        
        if (citiesInProvince.length > 0) {
          setSelectedProvince(provinceId);
          setSelectedProvinceName(provinceName);
          setViewState("city");
        }
      },
    });
  }

  const handleBackToProvinces = () => {
    setViewState("province");
    setSelectedProvince(null);
    setSelectedProvinceName("");
  };

  const center = [30.3753, 69.3451];

  return (
    <div className="leaflet-wrapper">
      <div style={{
        marginBottom: "16px",
        padding: "14px 24px",
        backgroundColor: "white",
        borderRadius: "12px",
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        boxShadow: "0 1px 3px rgba(0,0,0,0.1)"
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          {viewState === "province" ? (
            <span style={{
              fontSize: "18px", fontWeight: 700, color: "#1B4D3E",
              display: "flex", alignItems: "center", gap: "8px"
            }}>
              <span style={{ fontSize: "22px" }}>🗺️</span> Province View
            </span>
          ) : (
            <>
              <button onClick={handleBackToProvinces} style={{
                padding: "8px 16px", backgroundColor: "#1B4D3E", color: "white",
                border: "none", borderRadius: "8px", cursor: "pointer",
                fontSize: "14px", fontWeight: 600, display: "flex",
                alignItems: "center", gap: "6px",
              }}>
                ← Back
              </button>
              <span style={{
                padding: "6px 14px", backgroundColor: "#E8F5E9",
                borderRadius: "20px", fontSize: "14px", fontWeight: 700,
                color: "#1B4D3E",
              }}>
                📍 {selectedProvinceName}
              </span>
            </>
          )}
        </div>
        
        <button onClick={fetchRealData} style={{
          padding: "10px 18px", backgroundColor: "#1B4D3E", color: "white",
          border: "none", borderRadius: "8px", cursor: "pointer",
          fontSize: "14px", fontWeight: 600, display: "flex",
          alignItems: "center", gap: "6px",
        }}>
          <span style={{ fontSize: "18px" }}>↻</span> Refresh Data
        </button>
      </div>

      {loading ? (
        <div style={{
          height: "75vh", display: "flex", justifyContent: "center",
          alignItems: "center", backgroundColor: "#f5f5f5", borderRadius: "12px"
        }}>
          <div style={{ textAlign: "center" }}>
            <div style={{
              width: "40px", height: "40px", border: "3px solid #1B4D3E",
              borderTop: "3px solid transparent", borderRadius: "50%",
              animation: "spin 1s linear infinite", margin: "0 auto 16px"
            }} />
            <p>Loading map data...</p>
          </div>
        </div>
      ) : (
        <MapContainer center={center} zoom={5.5} style={{ height: "75vh", width: "100%", borderRadius: "12px" }}>
          <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" attribution='&copy; OpenStreetMap contributors' />
          
          {viewState === "province" && (
            <GeoJSON data={geoJson} style={style} onEachFeature={onEachFeature} />
          )}
          
          {viewState === "city" && (
            <>
              {citiesData
                .filter(city => cityToProvince[city.name] === selectedProvince)
                .map((city, idx) => {
                  const count = cityUserCounts[city.name] || 0;
                  return (
                    <Marker key={idx} position={[city.lat, city.lng]} icon={getCityMarkerIcon(count)}>
                      <Popup className="custom-popup">
                        <div style={{ padding: "4px", minWidth: "140px" }}>
                          <strong style={{ fontSize: "14px", color: "#1B4D3E" }}>🏙️ {city.name}</strong><br/>
                          <span style={{ fontSize: "12px", color: "#666" }}>👥 Users: <strong style={{ color: "#1B4D3E" }}>{count}</strong></span>
                        </div>
                      </Popup>
                    </Marker>
                  );
                })}
            </>
          )}
          
          <MapController viewState={viewState} selectedProvince={selectedProvince} />
        </MapContainer>
      )}
      
      <style>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
};

export default GeographyLeaflet;
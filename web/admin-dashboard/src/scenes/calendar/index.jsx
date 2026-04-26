import { useState } from "react";
import { formatDate } from "@fullcalendar/core";
import FullCalendar from "@fullcalendar/react";
import dayGridPlugin from "@fullcalendar/daygrid";
import timeGridPlugin from "@fullcalendar/timegrid";
import interactionPlugin from "@fullcalendar/interaction";
import listPlugin from "@fullcalendar/list";
import {
  Box,
  List,
  ListItem,
  ListItemText,
  Typography,
  useTheme,
  Paper,
} from "@mui/material";
import Header from "../../components/Header";
import { tokens } from "../../theme";

const Calendar = () => {
  const theme = useTheme();
  const colors = tokens(theme.palette.mode);
  const [currentEvents, setCurrentEvents] = useState([]);

  // Add new event
  const handleDateClick = (selected) => {
    const title = prompt("Enter a title for your event:");
    const calendarApi = selected.view.calendar;
    calendarApi.unselect();

    if (title) {
      calendarApi.addEvent({
        id: `${selected.dateStr}-${title}`,
        title,
        start: selected.startStr,
        end: selected.endStr,
        allDay: selected.allDay,
      });
    }
  };

  // Delete event
  const handleEventClick = (selected) => {
    if (
      window.confirm(
        `Are you sure you want to delete '${selected.event.title}'?`
      )
    ) {
      selected.event.remove();
      // Update state manually so sidebar also updates
      setCurrentEvents((prev) =>
        prev.filter((evt) => evt.id !== selected.event.id)
      );
    }
  };

  return (
    <Box m="20px">
      <Header title="Calendar" subtitle="Manage Events & Schedule" />

      <Box display="flex" gap="20px">
        {/* Sidebar */}
        <Paper
          elevation={3}
          sx={{
            flex: "1 1 25%",
            backgroundColor: colors.background.widget,
            borderRadius: "12px",
            p: 2,
          }}
        >
          <Typography
            variant="h5"
            sx={{ mb: 2, color: colors.text.primary, fontWeight: 600 }}
          >
            Events
          </Typography>

          <List>
            {currentEvents.length === 0 ? (
              <Typography sx={{ color: colors.text.secondary }}>
                No events yet. Add from the calendar ➕
              </Typography>
            ) : (
              currentEvents.map((event) => (
                <ListItem
                  key={event.id}
                  sx={{
                    backgroundColor: colors.accent,
                    borderRadius: "8px",
                    mb: 1,
                    color: "#fff",
                  }}
                >
                  <ListItemText
                    primary={event.title}
                    secondary={
                      <Typography sx={{ color: "rgba(255,255,255,0.8)" }}>
                        {formatDate(event.start, {
                          year: "numeric",
                          month: "short",
                          day: "numeric",
                        })}
                      </Typography>
                    }
                  />
                </ListItem>
              ))
            )}
          </List>
        </Paper>

        {/* Calendar */}
        <Paper
          elevation={3}
          sx={{
            flex: "1 1 75%",
            backgroundColor: colors.background.widget,
            borderRadius: "12px",
            p: 2,
          }}
        >
          <FullCalendar
            height="75vh"
            plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin, listPlugin]}
            headerToolbar={{
              left: "prev,next today",
              center: "title",
              right: "dayGridMonth,timeGridWeek,timeGridDay,listMonth",
            }}
            initialView="dayGridMonth"
            editable={true}
            selectable={true}
            selectMirror={true}
            dayMaxEvents={true}
            select={handleDateClick}
            eventClick={handleEventClick}
            eventsSet={(events) => setCurrentEvents(events)}
            initialEvents={[
              {
                id: "12315",
                title: "All-day event",
                date: "2022-09-14",
              },
              {
                id: "5123",
                title: "Timed event",
                date: "2022-09-28",
              },
            ]}
          />
        </Paper>
      </Box>
    </Box>
  );
};

export default Calendar;

import express from "express";
import fs from "fs";
import http from "http";
import path from "path";
import WebSocket from "ws";
import { ClientMessage, ServerMessage } from "./types";

// Parse command line arguments
const args = process.argv.slice(2);
const portArg = args.find((arg) => arg.startsWith("--port="));
const port = portArg ? parseInt(portArg.split("=")[1], 10) : 8088;

// Create Express app
const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Serve static files from templates directory
app.use(express.static(path.join(__dirname, "../templates")));

// Serve the main viewer page
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../templates/viewer.html"));
});

// Serve export page
app.get("/export", (req, res) => {
  res.sendFile(path.join(__dirname, "../templates/export.html"));
});

// Serve print page
app.get("/print", (req, res) => {
  res.sendFile(path.join(__dirname, "../templates/print.html"));
});

// Store connected clients
const clients = new Set<WebSocket>();

// Handle WebSocket connections
wss.on("connection", (ws: WebSocket) => {
  // Add client to set
  clients.add(ws);
  console.log("Client connected");

  // Handle messages from client
  ws.on("message", (message: WebSocket.Data) => {
    try {
      // Check if the message is not empty
      const messageStr = message.toString().trim();
      if (!messageStr) {
        console.log("Received empty message, ignoring");
        return;
      }

      const data = JSON.parse(messageStr) as ClientMessage;
      console.log("Received message:", data.type);

      // Handle click events from the browser
      if (data.type === "click") {
        // Forward to Neovim via stdout
        console.log(
          JSON.stringify({
            type: "click",
            startChar: data.startChar,
            endChar: data.endChar,
          })
        );
      } else if (data.type === "svgExport") {
        // Handle SVG export request
        console.log(
          JSON.stringify({
            type: "svgExport",
            content: data.content,
          })
        );
      } else if (data.type === "requestExport") {
        // Handle export request
        if (data.format === "svg") {
          // Request SVG from browser
          clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({ type: "requestSvg" }));

              // Store export request for when SVG is received
              client.once("message", (svgMessage) => {
                try {
                  const svgData = JSON.parse(svgMessage.toString()) as ClientMessage;
                  if (svgData.type === "svgExport" && svgData.content) {
                    // Export SVG
                    handleExport("svg", svgData.content, data.path);
                  }
                } catch (error) {
                  console.error("Error processing SVG response:", error);
                }
              });
            }
          });
        } else if (data.format === "html") {
          // Request SVG from browser
          clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({ type: "requestSvg" }));

              // Store export request for when SVG is received
              client.once("message", (svgMessage) => {
                try {
                  const svgData = JSON.parse(svgMessage.toString()) as ClientMessage;
                  if (svgData.type === "svgExport" && svgData.content) {
                    // Create HTML with the SVG content
                    const htmlContent = `<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>ABC Export</title>
</head>
<body>
  ${svgData.content}
</body>
</html>`;
                    handleExport("html", htmlContent, data.path);
                  }
                } catch (error) {
                  console.error("Error processing SVG response:", error);
                }
              });
            }
          });
        }
      } else if (data.type === "content") {
        // Echo back the content for testing
        console.log(`Received content: ${data.content.substring(0, 50)}...`);

        // Broadcast to all clients
        clients.forEach((client) => {
          if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
          }
        });
      }
    } catch (error) {
      console.error("Error processing message:", error);
      console.error("Message was:", message.toString());
    }
  });

  // Handle client disconnection
  ws.on("close", () => {
    clients.delete(ws);
    console.log("Client disconnected");
  });
});

// Listen for input from Neovim (via stdin)
process.stdin.on("data", (data: Buffer) => {
  try {
    const message = JSON.parse(data.toString().trim()) as ServerMessage;

    // Broadcast to all connected clients
    clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify(message));
      }
    });
  } catch (error) {
    console.error("Error processing stdin:", error);
  }
});

// Handle file export requests
function handleExport(format: "html" | "svg", content: string, filePath: string): void {
  try {
    fs.writeFileSync(filePath, content);
    console.log(
      JSON.stringify({
        type: "exportComplete",
        format,
        path: filePath,
      })
    );
  } catch (error) {
    console.error("Error exporting file:", error);
    console.log(
      JSON.stringify({
        type: "exportError",
        error: (error as Error).message,
      })
    );
  }
}

// Start the server
server.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});

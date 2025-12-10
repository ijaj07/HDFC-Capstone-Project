🛡️ TrustSync: Intelligent Context-Aware Notification Engine

A smart orchestration layer for banking notifications that eliminates SMS dependency, prevents phishing, and ensures 100% delivery reliability.

🚨 The Problem

In the current digital banking ecosystem, notifications are broken:

Security Risks: SMS Sender IDs are easily spoofed (Phishing).

High Latency: Critical OTPs often take 10-30 seconds via carrier networks.

High Cost: Banks pay for every SMS, even if the user is currently active inside the app.

User Anxiety: Users cannot distinguish between a genuine bank alert and a scam.

💡 The Solution: TrustSync

TrustSync is a Device-Context Orchestration Engine. Instead of blindly sending an SMS, the engine analyzes the user's real-time context (Network, App State, Device Identity) to select the safest, fastest, and cheapest delivery channel.

🧠 Core Features
1. ⚡ Intelligent Routing & Smart Fallback

The engine prioritizes channels based on user state:

Active User (In-App): Delivers a Flash Token directly to the UI. (Latency: <100ms, Cost: $0).

Background (Online): Sends a Secure Push Notification.

No Response? Automatically falls back to WhatsApp -> SMS if no acknowledgement (ACK) is received within 5 seconds.

2. 🔐 Device Binding (Identity Management)

Known Devices: Instant, frictionless login via Flash OTP.

New/Untrusted Devices: The system detects ID mismatches and forces a Hardware-Level Binding flow (Upstream Encrypted SMS) to verify the SIM card before allowing access.

3. 🪞 Mirror Box Protocol (Anti-Phishing)

The Problem: Users can't trust SMS notifications.

The Fix: Every genuine notification sent via any channel (SMS/WhatsApp) is mirrored in the App's Secure Inbox.

User Rule: "If it's not in the TrustSync Inbox, it's a scam."

🏗️ Architecture & Tech Stack
1. The Brain (Backend)

Tech: Node.js, Express.

Role: Maintains user context (is_active, has_app), manages Device Registry, executes routing logic, and handles failover timers.

Key Logic: send-notification endpoint with an automated ACK feedback loop.

2. The Client (Mobile App)

Tech: Flutter (Android/iOS/Web).

Role:

Bi-Directional Sync: Sends "ACK" signals to the backend to stop fallback timers.

Context Awareness: Reports app state (Foreground/Background).

Secure Visualization: Renders distinct UI for Verified Banking messages vs. Generic alerts.

3. The Ops Center (Dashboard & Simulator)

Tech: HTML5, CSS3 (Glassmorphism UI), Vanilla JS.

Role:

Live Dashboard: Visualizes the decision tree and latency in real-time.

Context Simulator: Allows judges to toggle scenarios (e.g., "Simulate Offline", "Simulate New Device") to test edge cases without physical device constraints.

📸 Demo Scenarios
Scenario A: The Active User (Cost Optimization)

Context: User is inside the app to pay a bill.

Simulator: Toggle User Active to ON.

Action: User clicks "Pay".

Result: In-App Flash Popup.

Benefit: Zero latency, Zero SMS cost.

Scenario B: The New Device (Security)

Context: User installs the app on a new phone.

Simulator: Set Identity to "New Device".

Action: User clicks "Login".

Result: System blocks OTP. Forces "Sending Encrypted SMS" screen to bind SIM.

Benefit: Prevents credential stuffing attacks on new devices.

Scenario C: The Smart Fallback (Reliability)

Context: User has the app but no data connection (or ignores Push).

Simulator: Toggle User Active OFF.

Action: Trigger OTP.

Result: Backend sends Push -> Waits 5s -> Sends WhatsApp/SMS.

Benefit: Ensures delivery even in poor network conditions.

🚀 How to Run Locally
Prerequisites

Node.js (v14+)

Flutter SDK

1. Start the Backend
cd backend
npm install
node index.js

The Dashboard will run at http://localhost:4000/home.html

2. Run the Mobile App
cd Prototype App
flutter pub get
# Ensure emulator/device is connected
flutter run

🔮 Future Roadmap

RSA Encryption: Replace Base64 simulation with real RSA-2048 payload encryption.

Geo-Fencing: Block notifications if the device location doesn't match the transaction location.

Biometric Integration: Replace Flash OTP click with Fingerprint/FaceID for Step-up Auth.

Built with ❤️ for the Hackathon.

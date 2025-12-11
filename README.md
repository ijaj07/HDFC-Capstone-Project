# 🛡️ **TrustSync: Intelligent Context-Aware Notification Engine**

A **smart orchestration layer for banking notifications** that eliminates SMS dependency, prevents phishing, and ensures **100% delivery reliability**.

---

## 🚨 **The Problem**

In today’s digital banking ecosystem, notification systems are fundamentally broken:

* **Security Risks:** SMS Sender IDs are easily spoofed (phishing).
* **High Latency:** Critical OTPs often take *10–30 seconds* via carrier networks.
* **High Cost:** Banks pay for every SMS—even if the user is currently active inside the app.
* **User Anxiety:** Users can’t distinguish between genuine bank alerts and scams.

---

## 💡 **The Solution: TrustSync**

**TrustSync** is a **Device-Context Orchestration Engine**.

Instead of blindly sending an SMS, the engine analyzes the user's **real-time context** (Network, App State, Device Identity) to select the **safest, fastest, and cheapest** delivery channel.

---

## 🚀 **Live Demo Notice**  
The complete **TrustSync Web App** and **TrustSync Engine** demo links are available  
at the end of this **README**.  
  
Keep reading to understand the system — and then try it live in your browser!

---

## 🧠 **Core Features**

### **1. ⚡ Intelligent Routing & Smart Fallback**

TrustSync prioritizes delivery channels based on user state:

* **Active User (In-App):** Delivers a **Flash Token** directly to the UI
  → *Latency: <100ms | Cost: $0*
* **Background (Online):** Sends a **Secure Push Notification**.
* **No Response?** Auto fallback chain:
  **Push → WhatsApp → SMS** (triggered if no ACK within 5s)

---

### **2. 🔐 Device Binding (Identity Management)**

* **Known Devices:**
  Instant, frictionless login using **Flash OTP**.
* **New / Untrusted Devices:**
  ID mismatch triggers a **Hardware-Level Binding** flow.
  System sends an **Upstream Encrypted SMS** to verify SIM before allowing login.

---

### **3. 🪞 Mirror Box Protocol (Anti-Phishing Layer)**

**The Problem:** Users don’t trust SMS notifications.
**The Fix:** Every genuine notification—regardless of channel—is **mirrored inside the App’s Secure Inbox**.

💡 **User Rule:**

> **If it's not in the TrustSync Inbox, it's a scam.**

---

## 🏗️ **Architecture & Tech Stack**

### **1. 🧩 The Brain (Backend)**

**Tech:** Node.js, Express
**Role:**

* Maintains user context (`is_active`, `has_app`)
* Manages Device Registry
* Executes routing logic
* Handles automated fallback timers & ACK loop

---

### **2. 📱 The Client (Mobile App)**

**Tech:** Flutter (Android/iOS/Web)
**Role:**

* **Bi-Directional Sync:** Sends ACK signals to stop fallback
* **Context Awareness:** Reports app state (Foreground/Background)
* **Secure UI:** Distinct UI for *Verified Banking Messages* vs *Generic Alerts*

---

### **3. 🖥️ The Ops Center (Dashboard & Simulator)**

**Tech:** HTML5, CSS3 (Glassmorphism), Vanilla JS
**Role:**

* **Live Dashboard:** Visualizes routing decisions & latency
* **Context Simulator:** Toggle conditions (Offline, New Device, etc.)
  → No physical device required for testing

---

## 📸 **Demo Scenarios**

### **A. The Active User — Cost Optimization**

**Context:** User is inside the app paying a bill
**Simulator:** `User Active = ON`
**Action:** User clicks **Pay**
**Result:** Instant **In-App Flash Popup**
**Benefit:** Zero latency, Zero SMS cost

---

### **B. The New Device — Security**

**Context:** User installs the app on a new phone
**Simulator:** `Identity = New Device`
**Action:** User clicks **Login**
**Result:** Login blocked → device must complete **Encrypted SIM Binding**
**Benefit:** Prevents credential-stuffing & device spoof attacks

---

### **C. Smart Fallback — Reliability**

**Context:** User has app but no data connection
**Simulator:** `User Active = OFF`
**Action:** Trigger OTP
**Result:** Push → wait 5s → WhatsApp/SMS
**Benefit:** Reliable delivery even in weak network zones

---

## 🚀 **How to Run Locally**

### **Prerequisites**

* **Node.js (v14+)**
* **Flutter SDK**

---

### **1. Start the Backend**

```bash
cd backend
npm install
node index.js
```

Backend Dashboard available at:
👉 **[http://localhost:4000/home.html](http://localhost:4000/home.html)**

---

### **2. Run the Mobile App**

```bash
cd Prototype App
flutter pub get
flutter run
```

---

## 🔮 **Future Roadmap**

* **RSA-2048 Encryption:** Replace Base64 simulation with real encrypted payloads
* **Geo-Fencing:** Block suspicious transactions based on location mismatch
* **Biometric Integration:** Flash OTP → Fingerprint/FaceID step-up authentication

---

### **Built with ❤️**

---

**I have hosted the TrustSync Engine backend here:**  
https://trustsync-api.onrender.com/home.html

---

**Later I will be hosting the Flutter app linked with the backend and provide the link here for easy access without installation. (Updated)**

---

## 🌐 **TrustSync Web App (Hosted Version)**

**Here is the link to access TrustSync as a Web App:**  
👉 https://trustsync.netlify.app/

### 🔔 **Important Step — Enable Notifications**
While on the onboarding page, click **“Enable Browser Notifications”** and then select **Allow**.  
This step is **mandatory** for receiving real-time notifications.

---

## 🧪 **How to Test Using the TrustSync Engine**

Once notifications are enabled:

- You can toggle any settings inside the **Backend Simulator** to test various scenarios.
- The **Web App** will display notifications based on the selected scenario.
- All routing logic and decisions are visible in the **Dashboard**.
- **Fallback** happens automatically through the routing chain.

⏱️ A small timer has been added to trigger fallback automatically.  
If you **don't** want fallback to occur, simply click **“Simulate ACK”**, which tells the system that the user has acknowledged the notification.

---

## 📱 **Recommended Experience**

Although the web app works fully,  
**I strongly recommend using the Flutter mobile app for the best, smoothest experience.**

---


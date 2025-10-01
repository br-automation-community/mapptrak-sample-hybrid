# mapptrak-sample-hybrid

This Automation Studio project demonstrates how to combine an **ACOPOStrak system** with a conventional conveyor belt.  
The workspace of the ACOPOStrak system is extended using virtual segments ([B&R Online Help](https://www.br-automation.com)).  

This sample project showcases how to synchronize shuttle movement on the ACOPOStrak and the conveyor, and highlights the shuttle transfer between the two systems.

---

## 🧩 Overview
- The application uses a **virtual segment** to simulate conveyor belt behavior.  
- Shuttles on the conveyor are simulated with a **constant conveyor velocity**.  
- At the end of the conveyor, shuttles are transferred using `MC_BR_SecAddShuttle_AcpTrak`.  

---

## ⚙️ Features
- Start/Stop Controls via the visualization interface: [127.0.0.1:81](http://127.0.0.1:81)  
- Parameter adjustments can be made while the system is powered off  
- **SceneViewer Integration** for shuttle visualization:  
  - Username: `Admin`  
  - Password: *(leave blank)*  

---

## 🚀 Usage Instructions
### 1. Launch the Application
- Open **Automation Studio** and load the `Hybrid.apj` project file.  
- Navigate to [127.0.0.1:81](http://127.0.0.1:81) in your browser to access the visualization interface.  

### 2. Control the Simulation
- Use the **Start** and **Stop** buttons to manage shuttle movement.  
- Observe shuttles moving along the virtual conveyor segment.  

<img width="1603" height="905" alt="image" src="https://github.com/user-attachments/assets/bd5b2993-0691-45bc-b531-b955a2a43e49" />

### 3. Adjust Parameters
- Ensure the system is **powered off** before making changes.  
- Modify parameters to experiment with shuttle behavior and conveyor dynamics.  

### 4. Visualize Shuttle Movement
- Open the **SceneViewer** to monitor shuttle positions.  
- Log in with:  
  - Username: `Admin`  
  - Password: *(leave blank)*  

<img width="1314" height="492" alt="image" src="https://github.com/user-attachments/assets/976e0d7e-a9ec-443c-9f08-91a4d8da903f" />


---

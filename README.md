# 🧟 Termux Zombie 4.3 CSO for CS1.6 Android

Run a fully customized Zombie CSO server for Counter-Strike 1.6 on Android using Termux + Xash3D.  
Built for solo play with powerful enhancements, exclusive models, ViP/Admin privileges, and more.

---

## 👤 Credits
- **PowerSiderS**
- **VX MOHAMED**
- **THE GhosT**
- **Death Stroke**
- **Kleo**

---

## 📋 Requirements
- [Termux](https://play.google.com/store/apps/details?id=com.termux)
- [RVNC Viewer](https://play.google.com/store/apps/details?id=com.richard.rvnc)
- Xash3D Server (by VX, runs in Termux)

---

## 🆕 What's New in v4.3
- ✅ CSO Extra Items  
- ✅ ViP / Admin / Boss Privileges  
- ✅ Score HUD  
- ✅ Exclusive Items for Privileges  
- ✅ CSO Player Models  
- ❌ Hook System *(crashes the server)*  
- ❌ Countdown *(same issue as before)*

---

## ⚙️ Installation Guide

1. **Download Xash3D Server (Update 0.2)**  
   📥 [Click here](https://www.mediafire.com/file/z14w8h2snk056ot/update%5B0.2%5D.zip/file)

2. **Open Termux and grant storage permission**  
   ```bash
   termux-setup-storage
   ```

3. **Run the setup script**  
   ```bash
   cd /storage/emulated/0/Download/termux-xash3d/ && bash termux-setup.sh
   ```

   ▶️ Need help? [Watch this YouTube guide](https://youtu.be/Xkm5aSdNnlw?si=WHKaPY1K2CM3NJwD)

4. **Run the server from Termux**  
   - Connect using: `127.0.0.1:27015 49`  
   - If using the old engine server: `127.0.0.1:27015 48`

5. **Download required files from releases**  
   - `xash3d.zip`  
   - `put files in downloaded.7z`

6. **Delete old Xash files**  
   - Path: `/storage/emulated/0/Download/termux-xash3d`

7. **Extract `xash3d.zip`**  
   - To: `/storage/emulated/0/Download/termux-xash3d/`

8. **Extract `put files in downloaded.7z`**  
   - Copy its contents to: `/storage/emulated/0/Download/downloaded/`

9. **Launch the server again (old engine only)**  
   - Choose the map: `zm_dust_world`

10. **Open CS1.6 Android**  
    - Console command:  
      ```
      connect 127.0.0.1:27015 48
      ```

---

## 🐞 Known Bugs & Solutions

- **Crash on Old Engine**  
  Too many plugins may cause crashes.  
  ➤ *Solution: Simply restart the server.*

- **Only You Can Connect (Localhost only)**  
  The server does not support LAN or external players, even with the same WiFi or mobile data.  
  ➤ *Only the local device (your phone) can connect.*

- **RVNC Viewer Shows Error Message**  
  ➤ *Fix: Clear RVNC Viewer app data and relaunch Termux server.*

---

### ❤️ Made With Love by [PowerSiderS.X DARK (KiLiDARK)](https://www.youtube.com/@PowerSiderS-CS)

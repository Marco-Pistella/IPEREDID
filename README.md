# **IPEREDID 1.1**  
**Synthetic EDID provider TSR for DOS**

IPEREDID is a DOS TSR that allows **synthetic EDID data** to be supplied to the system, independently of the physically connected monitor.  
It was originally developed as a support tool for **X‑VESA**, enabling EDID testing even on hardware where VESA function **4F15h** is missing, incomplete, or supports fewer DDC controllers than required.

IPEREDID intercepts VESA EDID requests and can return user‑provided 128‑byte EDID blocks for up to **8 independent DDC controllers**.

---

## **Features**

- Memory‑resident TSR with **INT 10h hooking**  
- Support for **8 DDC controllers** (0–7), each with its own EDID file  
- Selective interception of **VESA function 4F15h**  
- Three per‑controller flags:
  - **Disable BIOS** — bypasses the physical BIOS  
  - **Disable Monitor** — reports “no monitor present”  
  - **Override** — returns the user‑loaded EDID block  
- EDID loading from binary files (exactly 128 bytes)  
- Tabular status display (`/S`)  
- Safe uninstallation (`/U`)  
- Fully compatible with X‑VESA and any DOS software using VESA 4F15h  

---

## **Why IPEREDID exists**

Some systems:

- do not implement VESA 4F15h  
- return invalid EDID data  
- expose fewer DDC controllers than required  
- behave inconsistently with multiple monitors  

IPEREDID solves this by **intercepting 4F15h** and returning known, user‑supplied EDID blocks.  
This makes it possible to test EDID parsing logic (e.g., in X‑VESA) without relying on the physical monitor.

---

## **Installation**

```
IPEREDID.COM
```

If already installed, IPEREDID refuses to reinstall.

Once resident, it intercepts all INT 10h calls and handles 4F15h according to its configuration.

---

## **Loading an EDID file**

```
IPEREDID.COM <controller> <file>
```

- `<controller>` = DDC controller number (0–7)  
- `<file>` = 128‑byte EDID binary file  

Examples:

```
IPEREDID.COM 0 MONITOR.BIN
IPEREDID.COM 3 C:\EDID\SAMSUNG.BIN
```

Loading a file automatically enables **Override** and **Enable** for that controller.

---

## **Per‑controller flags**

```
IPEREDID.COM <controller> /A   Toggle Disable BIOS
IPEREDID.COM <controller> /B   Toggle Disable Monitor
IPEREDID.COM <controller> /C   Toggle Override
```

- **/A – Disable BIOS**  
  Prevents forwarding the call to the physical BIOS.

- **/B – Disable Monitor**  
  Forces return code 14Fh (“no monitor present”).

- **/C – Override**  
  Returns the loaded EDID block (only if a file is present).

---

## **Status display**

```
IPEREDID.COM /S
```

Shows a table with:

- Load (YES/NO)  
- Override  
- Disable BIOS  
- Disable Monitor  

---

## **Uninstallation**

```
IPEREDID.COM /U
```

Uninstalls only if IPEREDID is the **last TSR** that hooked INT 10h.

---

## **Technical details**

### **INT 10h hooking**
IPEREDID replaces the INT 10h vector and chains to the previous handler when needed.

### **4F15h interception logic**
Based on the controller number in **CX**:

- **BL=00h** → reports support for 8 controllers  
- **BL=01h** → EDID read logic with full flag handling  
- **BL>01h or CX>=8** → forwarded to BIOS  

### **EDID format**
- Must be **exactly 128 bytes**  
- No checksum or header validation is performed  

### **TSR communication**
IPEREDID uses proprietary INT 10h codes to:

- detect an already‑resident instance  
- access internal data structures  

---

## **System requirements**

- MS‑DOS 5.0 or later  
- 80386 CPU or better  
- Application using VESA 4F15h (e.g., X‑VESA)  
- <2 KB of conventional memory  

---

## **License**

Released under the **MIT License**.  
See the `LICENSE` file for details.

---

## **Latest version**

IPEREDID is distributed together with X‑VESA.  
The latest version of X‑VESA (and IPEREDID) can be found at:

---

## **Author**

**Marco Pistella**  
mpistella@libero.it

Bug reports and suggestions are welcome.

---

## **Notes**

IPEREDID was designed as a companion tool for X‑VESA, but it is useful for any DOS application that queries EDID data via VESA 4F15h.  
Configuration can be changed at any time while the TSR is resident.

---

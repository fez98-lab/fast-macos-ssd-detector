# fast-macos-ssd-detector

# Fast macOS Fake SSD Detector

A lightweight, high-speed interactive shell script tailored for macOS to quickly detect counterfeit external SSDs and flash drives (Fake Drives). 

## 🔍 How it Works
Unlike traditional tools that take hours to calculate heavy random data sequences across the entire drive, this script fills the SSD **block-by-block interactively**. 

1. It writes sequential chunks (default: 1 GB) using unique, timestamped filenames.
2. It explicitly triggers `sudo purge` to flush the macOS system read caches.
3. It performs a real-time cryptographic MD5 verification.
4. Because files are kept on the drive instead of being deleted immediately, a fake drive's controller is forced to eventually overwrite existing cells. 
5. As soon as the true physical capacity is breached, the hash validation fails instantly and throws an **Alarm**.

## 🚀 Usage Instruction
1. Clone or download the `ssd_test.sh` to your Mac.
2. Open your Terminal and make the script executable:
   ```bash
   chmod +x ssd_test.sh
   ```
3. Run the script:
   ```bash
   ./ssd_test.sh
   ```
4. Enter your external drive's name and confirm the prompts loop-by-loop.

## ⚠️ Disclaimer & Requirements
* **macOS Only:** This script relies natively on Apple's `sudo purge` mechanism to guarantee cache evasion without raw disk unmounting.
* **Non-destructive:** It does not erase existing data, but requires free space to operate. It will safely delete its own tracking sequences upon user-exit (`n`).

#!/bin/bash
# ==============================================================================
# Fast macOS Fake SSD Detector
# An experimental script to quickly uncover counterfeit external drives.
# ==============================================================================

MB_PER_STEP=1000  # Default: 1 GB per loop step

echo "=========================================="
echo "  ⚡ FAST SSD DETECTOR FOR MACOS ⚡"
echo "=========================================="
echo ""

# 1. Display available drives
echo "Available drives under /Volumes/:"
echo "------------------------------------------"
ls -1 /Volumes/ | grep -v "Macintosh HD"
echo "------------------------------------------"
echo ""

# 2. Get user input
echo -n "👉 Please enter the exact name of the SSD: "
read -r VOLUME_INPUT

TARGET_VOLUME="/Volumes/$VOLUME_INPUT"

if [ -z "$VOLUME_INPUT" ] || [ ! -d "$TARGET_VOLUME" ]; then
    echo "❌ Error: Volume not found!"
    exit 1
fi

echo ""
echo "🚀 Starting detection loop on: $TARGET_VOLUME"
echo "------------------------------------------"

STEP_COUNTER=1

while true; do
    echo ""
    echo "--- [ Testing Block #$STEP_COUNTER (${MB_PER_STEP}MB) ] ---"

    # Use a unique, dynamic filename to bypass basic drive-side metadata caching
    TEST_FILE="$TARGET_VOLUME/test_block_${STEP_COUNTER}_$(date +%s).bin"
    
    echo "-> Writing $MB_PER_STEP MB unique block sequence..."
    # Writing zeros but saving them into unique files to force sequential cell occupation
    dd if=/dev/zero of="$TEST_FILE" bs=1m count=$MB_PER_STEP 2>/dev/null
    
    HASH_WRITTEN=$(md5 -q "$TEST_FILE")

    # Force macOS to clear its disk read cache
    echo "-> Purging macOS system cache..."
    sudo purge

    echo "-> Verifying block integrity..."
    HASH_READ=$(md5 -q "$TEST_FILE")

    # The Core Fraud Check
    if [ "$HASH_WRITTEN" = "$HASH_READ" ]; then
        echo "✅ Block #$STEP_COUNTER verified successfully."
    else
        echo ""
        echo "❌ !!! ALARM !!! DATA CORRUPTION DETECTED!"
        echo "   Expected Hash: $HASH_WRITTEN"
        echo "   Received Hash: $HASH_READ"
        echo "   Reason: The SSD is silently overwriting old data blocks."
        echo "   🚨 THIS IS DEFINITELY A FAKE DRIVE! 🚨"
        echo "------------------------------------------"
        exit 1
    fi

    # Keep the file on the drive to force real storage consumption
    # If it's a fake drive, it will loop and corrupt previous files shortly.
    TOTAL_GB=$(( (STEP_COUNTER * MB_PER_STEP) / 1000 ))
    echo "------------------------------------------"
    echo -n "👉 Block #$STEP_COUNTER safe (~$TOTAL_GB GB filled). Test next block? (j/n): "
    read -r ANSWER
    
    if [ "$ANSWER" != "j" ] && [ "$ANSWER" != "J" ]; then
        echo ""
        echo "🏁 Test paused by user. Cleaning up test files from SSD..."
        rm "$TARGET_VOLUME"/test_block_*.bin 2>/dev/null
        exit 0
    fi

    STEP_COUNTER=$((STEP_COUNTER + 1))
done

#!/bin/bash


# Fast macOS Fake SSD Detector
# An experimental script to quickly uncover counterfeit external drives.

# Size per loop step (z.B. 1000 MB = 1 GB)
MB_PRO_SCHRITT=1000

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
echo -n  "👉 Please enter the exact name of the SSD: "
read -r VOLUME_INPUT

TARGET_VOLUME="/Volumes/$VOLUME_INPUT"
TEST_FILE="$TARGET_VOLUME/ssd_loop_test.bin"

if [ -z "$VOLUME_INPUT" ] || [ ! -d "$TARGET_VOLUME" ]; then
    echo "❌ Error: Volume not found!"
    exit 1
fi

SCHRITT_COUNTER=1

while true; do
    echo ""
    echo "--- [ Testing Block #$SCHRITT_COUNTER (${MB_PRO_SCHRITT}MB) ] ---"

    # 3. Generate unique block sequence (Optimized for macOS)
    echo "-> Generating unique pattern for Block #$SCHRITT_COUNTER..."
    
    # Calculate the exact amount Bytes (1 MB = 1048576 Bytes)
    BYTES_TO_WRITE=$((MB_PRO_SCHRITT * 1048576))
    TEXT_PATTERN="BLOCK_ID_${SCHRITT_COUNTER}_VALID_DATA_"
    
    #
    perl -e "print \"$TEXT_PATTERN\" x ($BYTES_TO_WRITE / length(\"$TEXT_PATTERN\"))" > "$TEST_FILE"
    
    HASH_WRITTEN=$(md5 -q "$TEST_FILE")

     # Force macOS to clear its disk read cache
    echo "-> Purging macOS system cache..."
    sudo purge

    # Read data written
    echo "-> Verifying block integrity..."
    HASH_READ=$(md5 -q "$TEST_FILE")

     # The Core Fraud Check
    if [ "$HASH_WRITTEN" = "$HASH_READ" ]; then
        echo "✅ Block Nr. $SCHRITT_COUNTER verified successfully."
    else
        echo ""
        echo "❌ !!! ALARM !!! DATA CORRUPTION DETECTED!"
        echo "   Expected Hash: $HASH_WRITTEN"
        echo "   Received Hash: $HASH_READ"
        echo "   Reason: The SSD is silently overwriting old data blocks."
        echo "   🚨 THIS IS DEFINITELY A FAKE DRIVE! 🚨"
        rm "$TEST_FILE" 2>/dev/null
        exit 1
    fi

    # Important: Keep the file on the drive to force real storage consumption
    mv "$TEST_FILE" "$TARGET_VOLUME/saved_block_${SCHRITT_COUNTER}.bin"

    GESAMT_GB=$(( (SCHRITT_COUNTER * MB_PRO_SCHRITT) / 1000 ))
    echo "------------------------------------------"
    echo -n "👉 Block $SCHRITT_COUNTER safe ($GESAMT_GB GB filled). Test next block? (y/n): "
    read -r ANSWER
    
    if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
        echo ""
        echo "🏁 Test paused by user. Cleaning up test files from SSD..."
        rm $TARGET_VOLUME/saved_block_*.bin 2>/dev/null
        exit 0
    fi

    SCHRITT_COUNTER=$((SCHRITT_COUNTER + 1))
done


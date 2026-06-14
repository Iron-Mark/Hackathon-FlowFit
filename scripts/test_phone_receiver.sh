#!/bin/bash

# Test Phone Receiver Setup
# This script helps verify that the phone is properly configured to receive data from the watch

echo "🔍 FlowFit Phone Receiver Test"
echo "================================"
echo ""

APP_PACKAGE="${FLOWFIT_ANDROID_APPLICATION_ID:-com.oldstlabs.flowfit}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get phone device ID
echo "📱 Step 1: Finding phone device..."
PHONE_DEVICE=$(adb devices | grep -v "List" | grep -v "RFAX21TD0NA" | awk '{print $1}' | head -1)

if [ -z "$PHONE_DEVICE" ]; then
    echo -e "${RED}❌ No phone device found!${NC}"
    echo "   Make sure your phone is connected via USB or WiFi debugging"
    exit 1
fi

echo -e "${GREEN}✅ Phone found: $PHONE_DEVICE${NC}"
echo ""

# Check if app is installed
echo "📦 Step 2: Checking if FlowFit is installed on phone..."
APP_INSTALLED=$(adb -s $PHONE_DEVICE shell pm list packages | grep "$APP_PACKAGE")

if [ -z "$APP_INSTALLED" ]; then
    echo -e "${RED}❌ FlowFit not installed on phone!${NC}"
    echo "   Run: flutter build apk && adb -s $PHONE_DEVICE install build/app/outputs/flutter-apk/app-debug.apk"
    exit 1
fi

echo -e "${GREEN}✅ FlowFit is installed${NC}"
echo ""

# Check if service is registered
echo "🔧 Step 3: Checking if PhoneDataListenerService is registered..."
SERVICE_REGISTERED=$(adb -s $PHONE_DEVICE shell dumpsys package "$APP_PACKAGE" | grep "PhoneDataListenerService")

if [ -z "$SERVICE_REGISTERED" ]; then
    echo -e "${RED}❌ PhoneDataListenerService not registered!${NC}"
    echo "   Check AndroidManifest.xml"
    exit 1
fi

echo -e "${GREEN}✅ Service is registered${NC}"
echo ""

# Check Bluetooth
echo "📡 Step 4: Checking Bluetooth status..."
BT_STATUS=$(adb -s $PHONE_DEVICE shell settings get global bluetooth_on)

if [ "$BT_STATUS" != "1" ]; then
    echo -e "${YELLOW}⚠️  Bluetooth is OFF on phone${NC}"
    echo "   Enable Bluetooth on your phone"
else
    echo -e "${GREEN}✅ Bluetooth is ON${NC}"
fi
echo ""

# Launch app
echo "🚀 Step 5: Launching FlowFit on phone..."
adb -s $PHONE_DEVICE shell am start -n "$APP_PACKAGE/.MainActivity"
sleep 2
echo -e "${GREEN}✅ App launched${NC}"
echo ""

# Start monitoring logs
echo "👀 Step 6: Monitoring phone logs for incoming messages..."
echo "   (Press Ctrl+C to stop)"
echo ""
echo -e "${YELLOW}Waiting for messages from watch...${NC}"
echo ""

adb -s $PHONE_DEVICE logcat -c  # Clear logs
adb -s $PHONE_DEVICE logcat | grep --line-buffered -E "PhoneDataListener|MESSAGE_RECEIVED|WearableListenerService" | while read line; do
    if echo "$line" | grep -q "Message received"; then
        echo -e "${GREEN}✅ $line${NC}"
    elif echo "$line" | grep -q "Error"; then
        echo -e "${RED}❌ $line${NC}"
    else
        echo "$line"
    fi
done

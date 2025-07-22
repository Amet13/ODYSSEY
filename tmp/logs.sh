#!/bin/bash

# ODYSSEY Log Monitoring Script
# Monitors system logs for ODYSSEY app activity

echo "🔍 ODYSSEY Log Monitor"
echo "======================"
echo "Monitoring logs for ODYSSEY app..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Monitor Console.app logs for ODYSSEY
log stream --predicate 'process == "ODYSSEY"' --info --debug | grep debug

# Alternative: Monitor system logs for ODYSSEY
# log stream --predicate 'subsystem == "com.odyssey.app"' --info --debug 
#!/usr/bin/env bash

set -euo pipefail

INTERVAL=10
ALERT_TEMP=85
NOTIFY_CMD="${NOTIFY_CMD:-notify-send}" # fallback; export to use webhook script

read_sensors() {
    if command -v sensors >/dev/null 2>&1; then
        sensors
    else
        echo "sensors not installed" >&2
        exit 1
    fi
}

parse_max_temp() {
    # Try lm-sensors output first
    if command -v sensors >/dev/null 2>&1; then
        sensors | awk '
        {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /[+\-]?[0-9]+(\.[0-9]+)?°C/) {
                    gsub("°C", "", $i)
                    print $i
                } else if ($i ~ /[+\-]?[0-9]+(\.[0-9]+)?/) {
                    # handle numbers without °C if present in other fields
                    print $i
                }
            }
        }' | awk '{ printf "%.0f\n", $1 }' | sort -nr | head -n1 || echo 0
    else
        # Fallback: read thermal_zone temps (millidegree -> °C)
        vals=$(grep -h . /sys/class/thermal/thermal_zone*/temp 2>/dev/null || true)
        if [ -n "$vals" ]; then
            # convert millidegree C to degree C and print the max
            printf "%s\n" $vals | awk '{ printf "%.0f\n", $1 / 1000 }' | sort -nr | head -n1
        else
            echo 0
        fi
    fi
}

while :; do
    max_temp=$(parse_max_temp || echo "0")
    ts=$(date --iso-8601=seconds)

    printf '%s max_temp=%s°C\n' "$ts" "$max_temp"

    if [ "${max_temp:-0}" -ge "$ALERT_TEMP" ]; then
        echo "ALERT: temperature $max_temp°C ≥ $ALERT_TEMP°C"

        if command -v "$NOTIFY_CMD" >/dev/null 2>&1; then
            "$NOTIFY_CMD" "CPU temp $max_temp°C" "Threshold $ALERT_TEMP°C exceeded"
        fi
    fi
    sleep "$INTERVAL"
done


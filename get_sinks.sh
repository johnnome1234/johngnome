#!/bin/sh
while true; do
    wpctl status | awk '
    BEGIN {
        first = 1
        printf "["
    }
    /Sinks:/ { in_sinks=1; next }
    in_sinks && (/Sources:/ || /Video/ || /Settings/) { in_sinks=0 }
    in_sinks && /\./ {
        match($0, /\*?[ \t]*([0-9]+)\.[ \t]*(.*?)[ \t]*(\[|$)/, arr)
        if (arr[1] != "") {
            active = index($0, "*") > 0 ? "true" : "false"
            if (!first) printf ","
            printf "{\"id\":\"%s\",\"name\":\"%s\",\"active\":%s}", arr[1], tolower(arr[2]), active
            first = 0
        }
    }
    END {
        print "]"
    }
    '
    sleep 2
done

#!/bin/bash

# Enumerate through all devices, which will pull in other things like
# Device Mapper. Sometimes devices may not return full smart data if
# are busy. This seems to work "okay" on a RHEL7 based laptop and
# only results in the lines disappearing until available again.

for device in `ls /sys/block` ; do 
    smartutil_output=$(mktemp --suffix=$i)
    # Run the actual smartutil command
    smartctl -i --attributes --log=selftest /dev/$device &>$smartutil_output

    serial=$(cat $smartutil_output |grep "Serial Number"|cut -c 37-)
    capacity=$(cat $smartutil_output |grep "Total" |grep "Capacity" |cut -c 37-|sed 's/\ \[.*$//')
    utilization=$(cat $smartutil_output |grep "Utilization" | cut -c 37-|sed 's/\ \[.*$//')

    PREPEND="smartutil"
    LABEL=$(echo "{device=$device serial=$serial}")

    # If we don't have a serial number, we should just bail on this device.
    # This is because we didn't manage to get SMART data for the deivce.
    if [[ "$serial" != "" ]]; then

        # These first two metrics are aggregate data and may be
        # somewhat pointless, however actual utilization may be
        # useful with nvme devices.
        echo $PREPEND\_capacity$LABEL $capacity
        echo $PREPEND\_utilizaiton$LABEL $utilization

        # Massage the data in a "fairly agnostic" way to try make as much
        # it useful as possible.
        cat $smartutil_output|grep -A100 "SMART/Health"|grep ":" |grep -v "units"|sed s/Spare/Spare_Utilization/|sed s/\%//|grep -v "Time"|awk -F '[[:space:]][[:space:]]+' '{print tolower($1) $2}'|sed s/^/$PREPEND\_/ |sed s/\ Celsius// |sed 's/\ \[.*$//' |sed s/\ /_/g |sed "s/\:/$LABEL\ /g" &>$smartutil_output

        # Lets return everything but multiple tempature sensors.
        cat $smartutil_output |grep -v "temperature_"

        # Magic to give us tempature sensor data.
        temp_sensors=$(cat $smartutil_output |grep "temperature_" | sed s/_[[:digit:]]//)
        count=1
        IFS=$'\n'
        for line in $temp_sensors; do
            echo $line | sed s/}/\ sensor=$count}/
            count=$((count+1))
        done
    fi
    # Delete the temporary file.
    rm $smartutil_output 
done

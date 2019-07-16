#!/bin/bash

# Enumerate through all devices, which will pull in other things like
# Device Mapper. Sometimes devices may not return full smart data if
# are busy.
# Tested on real bare metal with megaraid and nvme devices.

CUT_CMD='cut -s -d ":" -f2-'
SMART_CMD='smartctl -i --attributes --log=selftest'

get_serial () {
    serial=$(cat $smartutil_output | grep -i "serial" | eval $CUT_CMD | sed "s/^[ \t]*//")
}

parse_smartutil_output_megaraid () {
    # (rpittau) TODO: this is very basic, add more stuff
    get_serial
}

parse_smartutil_output_nvme () {
    get_serial
    capacity=$(cat $smartutil_output | grep -i "total" | grep -i "capacity" | eval $CUT_CMD | sed 's/\ \[.*$//')
    utilization=$(cat $smartutil_output | grep -i "utilization" | eval $CUT_CMD | sed 's/\ \[.*$//')
}

format_and_print_output () {
    PREPEND="smartutil"
    LABEL=$(echo "{device=$device serial=$serial}")

    # If we don't have a serial number, we should just bail on this device.
    # This is because we didn't manage to get SMART data for the deivce.
    if [[ "$serial" != "" ]]; then

        # These first two metrics are aggregate data and may be
        # somewhat pointless, however actual utilization may be
        # useful with nvme devices.
        echo $PREPEND\_capacity$LABEL $capacity
        echo $PREPEND\_utilization$LABEL $utilization

        # Massage the data in a "fairly agnostic" way to try make as much
        # it useful as possible.
        cat $smartutil_output|grep -A100 "SMART/Health"|grep ":" |grep -v "units"|sed s/Spare/Spare_Utilization/|sed s/\%//|grep -v "Time"|awk -F '[[:space:]][[:space:]]+' '{print tolower($1) $2}'|sed s/^/$PREPEND\_/ |sed s/\ Celsius// |sed 's/\ \[.*$//' |sed s/\ /_/g |sed "s/\:/$LABEL\ /g" &>$smartutil_output

        # Lets return everything but multiple temperature sensors.
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
}

for device in $(ls /sys/block) ; do
    serial=''
    # (rpittau) TODO: add more parsing functions based on
    # device type

    # We don't want to run smartctl on cd or dvd
    if [[ "$device" != *"sr"* ]]; then
        smartutil_output=$(mktemp --suffix=$i)
        # Run the actual smartutil command
        eval $SMART_CMD /dev/$device &>$smartutil_output

        vendor=$(cat $smartutil_output | grep -i "vendor" | eval $CUT_CMD)
        product=$(cat $smartutil_output | grep -i "product" | eval $CUT_CMD)

        # Check if we have a megaraid device
        if [[ "$vendor" =~ "DELL" && "$product" =~ "PERC" ]]; then
            # Rerun smartctl for megaraid and parse the output for each disk in the controller
            for i in {0..24}; do
                if eval $SMART_CMD /dev/$device -d megaraid,${i} &>$smartutil_output ; then
                    parse_smartutil_output_megaraid
                    format_and_print_output
                fi
            done
        # Check to see if it's a nvme device
        elif [[ "$device" == nvme* ]]; then
            # to be compatible with smart tools version < 7.x we need
            # to specify the broadcast namespace
            # see https://www.smartmontools.org/ticket/1134 for details
            eval $SMART_CMD /dev/$device -d nvme,0xffffffff &>$smartutil_output
            parse_smartutil_output_nvme
            format_and_print_output
        fi
        # Delete the temporary file.
        rm $smartutil_output
    fi
done

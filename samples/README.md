Smart output samples

The smartctl command needs root privileges to get all the
information.

Megaraid Controller
smartctl -i --attributes --log=selftest /dev/sda

Megaraid disk
smartctl -i --attributes --log=selftest /dev/sda -d megaraid,0

nvme
smartctl -i --attributes --log=selftest /dev/nvme0

SAS
smartctl -i --attributes --log=selftest /dev/sda

#!/bin/sh
# This script roots the inactive firmware, switches the active firmware bank
# and then restarts the modem to complete the process.

inactive_bank="$(cat /proc/banktable/inactive)"  # bank_1 or bank_2
inactive_overlay="/overlay/$inactive_bank"

rm -rf "$inactive_overlay"
mkdir -p "$inactive_overlay/etc"
chmod 755 "$inactive_overlay"
chmod 775 "$inactive_overlay/etc"
echo "echo root:root | chpasswd" > "$inactive_overlay/etc/rc.local"
echo "dropbear -p 6666 &" >> "$inactive_overlay/etc/rc.local"
chmod +x "$inactive_overlay/etc/rc.local"

echo "$inactive_bank" > /proc/banktable/active
sync
reboot

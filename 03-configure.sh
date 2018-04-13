#!/bin/sh

################################
# Disable WWAN support (mobiled)
################################

uci set mobiled.globals.enabled='0'
uci set mobiled.device_defaults.enabled='0'
uci commit
/etc/init.d/mobiled stop
/etc/init.d/mobiled disable


#########################
# Disable Printer sharing
#########################

uci set printersharing.config.enabled='0'
uci set samba.printers.enabled='0'
uci commit


########################################
# Disable Content Sharing (Samba / DNLA)
########################################

uci set samba.samba.enabled='0'
uci commit
/etc/init.d/samba stop
/etc/init.d/samba disable
/etc/init.d/samba-nmbd stop
/etc/init.d/samba-nmbd disable

uci set dlnad.config.enabled='0'
uci commit
/etc/init.d/dlnad stop
/etc/init.d/dlnad disable


#############################
# Disable Telephony via MMPBX
#############################

uci set mmpbx.global.enabled='0'
uci commit

/etc/init.d/mmpbxd stop
/etc/init.d/mmpbxd disable


############################
# Disable Traffic Monitoring
############################

/etc/init.d/trafficmon stop
/etc/init.d/trafficmon disable


###############################
# Disable Time of Day ACL rules
###############################

uci set tod.global.enabled='0'
uci commit

/etc/init.d/tod stop
/etc/init.d/tod disable


#####################
# Disable Wake on LAN
#####################

uci set wol.config.enabled='0'
uci commit

/etc/init.d/wol stop
/etc/init.d/wol disable


#########################
# Ability to control LEDs
#########################

# ledfw controls internet/wifi/voip/etc LEDs
/etc/init.d/ledfw stop
/etc/init.d/ledfw disable

# Install control script so we can turn LEDs on and off via the main wifi
# button (originally /usr/sbin/wifionoff.sh)
uci set button.wifi_onoff.handler='toggleleds.sh'
uci commit
cat > /usr/sbin/toggleleds.sh << EOF
#!/bin/sh

status=\$(cat /sys/class/leds/power:red/brightness)

# Currently on
if [ "\$status" -eq 255 ] || [ "\$status" -eq 1 ]; then
  /etc/init.d/ledfw stop
  for led in /sys/class/leds/*; do
    echo '0' > "\$led/brightness"
    echo 'none' > "\$led/trigger"
  done
else
  /etc/init.d/ledfw start
  for led in /sys/class/leds/power:red; do
    echo '255' > "\$led/brightness"
    echo 'default-on' > "\$led/trigger"
  done
fi
EOF
chmod +x /usr/sbin/toggleleds.sh

# Shut all the LEDs down so this takes effect immediately
/usr/sbin/toggleleds.sh

# Shut down LEDs on boot
echo '/usr/sbin/toggleleds.sh' >> /etc/rc.local

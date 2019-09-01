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

# Install control script so we can turn LEDs on and off via the 'Status' button
# Some firmware refer to this as `button.info` rather than `button.easy_reset`
uci set button.easy_reset.handler='toggleleds.sh'  # Original value: rtfd
uci set button.easy_reset.min='0'                  # Original value: 7
uci set button.easy_reset.max='2'                  # Original value: 90
uci commit
cat > /usr/sbin/toggleleds.sh << EOF
#!/bin/sh

ledfw_status=\$(pidof ledfw.lua)

# If currently on
if [ -n "\$ledfw_status" ]; then
  /etc/init.d/ledfw stop
  for led in /sys/class/leds/*; do
    echo '0' > "\$led/brightness"
    echo 'none' > "\$led/trigger"
  done
else
  /etc/init.d/ledfw start

  # Wifi LEDs don't come back on til you restart hostapd
  hostapd_status=\$(pidof hostapd)
  if [ -n "\$hostapd_status" ]; then
    /etc/init.d/hostapd restart
  fi

  sleep 0.5

  # Blue power light
  led="/sys/class/leds/power"
  echo '0' > "\$led:red/brightness"
  echo '255' > "\$led:blue/brightness"
fi
EOF
chmod +x /usr/sbin/toggleleds.sh


cat > /etc/init.d/leds-off << EOF
#!/bin/sh /etc/rc.common

START=99   # Must be after ledfw (12) and led (96)
LEDFW_STATUS=\$(pidof ledfw.lua)

start() {
  if [ -n "\$LEDFW_STATUS" ]; then
    # Toggle off if ledfw is running
    /usr/sbin/toggleleds.sh
  else
    # Explictly turn everything off
    for led in /sys/class/leds/*; do
      echo '0' > "\$led/brightness"
      echo 'none' > "\$led/trigger"
    done
  fi
}
EOF
chmod +x /etc/init.d/leds-off

# Shut all the LEDs down so this takes effect immediately
/etc/init.d/leds-off enable
/etc/init.d/leds-off start


###########################################
# Enable opkg repository feeds from OpenWrt
#
# Note that by default, the TG799vac only has 32MB of storage (~25MB free) so if
# you want to install lots of packages, you should consider an extroot config
# with a USB stick.
#
# See https://openwrt.org/docs/guide-user/additional-software/extroot_configuration
###########################################

echo -n "
src/gz chaos_calmer http://archive.openwrt.org/chaos_calmer/15.05.1/brcm63xx/smp/packages/base
src/gz luci http://archive.openwrt.org/chaos_calmer/15.05.1/brcm63xx/smp/packages/luci
src/gz management http://archive.openwrt.org/chaos_calmer/15.05.1/brcm63xx/smp/packages/management
src/gz routing http://archive.openwrt.org/chaos_calmer/15.05.1/brcm63xx/smp/packages/routing
src/gz packages http://archive.openwrt.org/chaos_calmer/15.05.1/brcm63xx/smp/packages/packages
src/gz telephony http://archive.openwrt.org/chaos_calmer/15.05.1/brcm63xx/smp/packages/telephony
" >> /etc/opkg/distfeeds.conf

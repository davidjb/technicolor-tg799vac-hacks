#!/bin/sh

###############
# Wifi: disable
###############

uci set wireless.radio_2G.state='0'
uci set wireless.radio_5G.state='0'
uci commit

/etc/init.d/hostapd stop
/etc/init.d/hostapd disable

#######################
# Disable DHCP services
#######################

# Disable odhcpd as this isn't necessary in bridge mode
/etc/init.d/odhcpd stop
/etc/init.d/odhcpd disable

# Disable dnsmasq as all interfaces are ignored now
# eg uci show dhcp.lan.ignore='1'
/etc/init.d/dnsmasq stop
/etc/init.d/dnsmasq disable

############################
# ntpd: disable network time
############################

# The modem can't access the Internet so no point running this
uci set system.ntp.enable='0'
uci set system.ntp.enable_server='0'
uci commit

/etc/init.d/sysntpd stop
/etc/init.d/sysntpd disable

####################
# Disable IGMP Proxy
####################

# Not needed as we're no longer a router and thus unconcerned with multicast
/etc/init.d/igmpproxy stop
/etc/init.d/igmpproxy disable

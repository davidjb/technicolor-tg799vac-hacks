#!/bin/sh
# This script detoxes OpenWRT from Telstra in various ways.
#
# Initially based upon the configuration by CRC at
# https://www.crc.id.au/hacking-the-technicolor-tg799vac-and-unlocking-features/
# with changes such as better structure and coupling of commands, disable more
# unnecessary services, use standard `/etc/init.d/[service] stop` commands over
# `kill` and so on.

############
# General
############

# Default hostname
uci set system.@system[0].hostname='OpenWRT'

# Generify PPPoE username/password
uci set network.ppp.username='home@example.com'
uci set network.ppp.password=''

# Enable firmware upload via GUI and config import/export
sed -e 's/if currentuserrole == "guest" /if currentuserrole == "admin" /' -i /www/docroot/modals/gateway-modal.lp
uci set system.config.export_plaintext='1'
uci set system.config.export_unsigned='1'
uci set system.config.import_plaintext='1'
uci set system.config.import_unsigned='1'
uci commit

# Enable generic packages from the brcm63xx architecture
# Note that some/mamy packages may conflict so YMMV with what can be installed
# Download files at https://archive.openwrt.org/chaos_calmer/15.05.1/brcm63xx/generic/packages/
# and install via `opkg install ./package-name.ipk`
cat >> /etc/opkg.conf << EOF
arch all 100
arch brcm63xx-tch 200
arch brcm63xx 300
EOF


###################
# Enable SSH server
###################

# Enable Dropbear
uci set dropbear.lan.enable='1'
uci set dropbear.lan.PasswordAuth=on
uci set dropbear.lan.RootPasswordAuth=on
uci commit
/etc/init.d/dropbear start
/etc/init.d/dropbear enable

# Remove SSH key backdoor that gets shipped by default O_O
echo > /etc/dropbear/authorized_keys


################################
# DHCP (dnsmasq) reconfiguration
################################

# Disable DHCP for backdoor networks
uci set dhcp.hotspot.disabled='1'
uci set dhcp.fonopen.disabled='1'
uci commit
/etc/init.d/dnsmasq restart


#####################################
# Disable DHPC relay (dhcpopassthrud)
#
# The Relay Setup card will still show 'enabled' but this is because it is hard
# coded into /www/cards/018_relaysetup.lp.
#####################################

/etc/init.d/dhcpopassthrud stop
/etc/init.d/dhcpopassthrud disable


#####################
# NTP reconfiguration
#####################

uci del_list system.ntp.server=chronos.ntp.telstra.net
uci del_list system.ntp.server=chronos1.ntp.telstra.net
uci commit
/etc/init.d/sysntpd restart


##################################
# Disble CWMP over-the-air updates
##################################

# Display the CWMP configuration tile
uci set web.cwmpconfmodal=rule
uci set web.cwmpconfmodal.target='/modals/cwmpconf-modal.lp'
uci add_list web.cwmpconfmodal.roles='admin'
uci add_list web.ruleset_main.rules=cwmpconfmodal

# Disable cwmpd
uci set cwmpd.cwmpd_config.state=0
uci set cwmpd.cwmpd_config.upgradesmanaged=0
uci set cwmpd.cwmpd_config.periodicinform_enable=0
uci set cwmpd.cwmpd_config.acs_pass='0'
uci set cwmpd.cwmpd_config.acs_user='0'
uci set cwmpd.cwmpd_config.acs_url='invalid'
uci commit

/etc/init.d/cwmpd stop
/etc/init.d/cwmpd disable
/etc/init.d/cwmpdboot stop
/etc/init.d/cwmpdboot disable
killall -9 cwmpd cwmpdboot watchdog-tch


####################################
# Disable Telstra Air connection sharing
#
# By default, Telstra shares your home network out to the world
# as "Telstra Air". This disables hotspotd to stop this madness.
#
# Ref: https://crowdsupport.telstra.com.au/t5/Modems-Hardware/Turning-off-Telstra-Air-on-Telstra-Gateway-device/td-p/565407
####################################

uci set hotspotd.main.ipv4=0
uci set hotspotd.main.enable=false
uci set hotspotd.main.deploy=false
uci set hotspotd.TLS2G.enable=0
uci set hotspotd.FON2G.enable=0
uci commit
/etc/init.d/hotspotd stop
/etc/init.d/hotspotd disable


###########################
# Disable Wifi Doctor Agent
#
# No idea on specifics, but this is spyware that's hoovering up your wifi
# data and posting it back to Telstra and Technicolor. No way is this sort of
# backdoor okay.
#
# From http://www.technicolor.com/en/who-we-are/press-news-center/news/telstra-launches-largest-deployment-wireless-doctor:
#
#  Wireless Doctor makes possible active radio resource management; perfect
#  call center visibility; self-installation of Wi-Fi extenders; targeted Wi-Fi
#  extender CAPEX strategies; and active client steering.
#
# Original settings:
# wifi_doctor_agent.config.cs_url='https://coll-v2-ap.wifi-doctor.org/'
# wifi_doctor_agent.as_config.url='https://device-auth-ap.wifi-doctor.org/oauth/token'
#
# Ref: self-investigation / https://forums.whirlpool.net.au/archive/2703814
###########################

uci set wifi_doctor_agent.config.enabled=0
uci set wifi_doctor_agent.config.cs_url='http://localhost'
uci set wifi_doctor_agent.as_config.url='http://locahost'
uci commit
/etc/init.d/wifi-doctor-agent stop
/etc/init.d/wifi-doctor-agent disable


###########################
# Disable LTE Doctor Logger
###########################

uci set ltedoctor.logger.enabled=0
uci commit
/etc/init.d/lte-doctor-logger stop
/etc/init.d/lte-doctor-logger disable


####################################################
# Disable TLS-vSPARC (internet connection telemetry)
#
# By default, Telstra have a ping/speedtest app running continuiously for
# whatever purpose. Anectodal evidence says it's "only monitoring!" but we're
# not going to waste our CPU and bandwidth for anyone.
#
# Ref: https://forums.whirlpool.net.au/archive/2678687
####################################################

uci set tls-vsparc.Config.Enabled='0'
uci set tls-vsparc.Passive.PassiveEnabled='0'
uci commit
/etc/init.d/tls-vsparc stop
/etc/init.d/tls-vsparc disable

##############
# Disable UPnP
#
# Aside from being generally buggy, this uPnP config has an oddly named setting called
# minitr064d.password.dslfreset with a value set what looks to be a hard-coded password.
# Looks like another backdoor to me.
#
# Ref: https://www.forbes.com/sites/andygreenberg/2013/01/29/disable-a-protocol-called-upnp-on-your-router-now-to-avoid-a-serious-set-of-security-bugs/#12054ae876b4
##############

uci set upnpd.config.enable_natpmp='0'
uci set upnpd.config.enable_upnp='0'
uci set minitr064d.config.enable_upnp='0'
uci commit
/etc/init.d/minitr064d stop
/etc/init.d/minitr064d disable
/etc/init.d/miniupnpd-tch stop
/etc/init.d/miniupnpd-tch disable


###############
# Web interface
###############

# xDSL card / modal
# Speed up connection time if you choose the correct item – e.g. vdsl2
uci add_list web.ruleset_main.rules=xdsllowmodal
uci set web.xdsllowmodal=rule
uci set web.xdsllowmodal.target='/modals/xdsl-low-modal.lp'
uci add_list web.xdsllowmodal.roles='admin'

# Parental Controls card / modal
uci add_list web.parentalblock.roles=admin

# Telephony UI
uci add_list web.ruleset_main.rules=mmpbxinoutgoingmapmodal
uci set web.mmpbxinoutgoingmapmodal=rule
uci set web.mmpbxinoutgoingmapmodal.target='/modals/mmpbx-inoutgoingmap-modal.lp'
uci add_list web.mmpbxinoutgoingmapmodal.roles='admin'

uci add_list web.ruleset_main.rules=mmpbxstatisticsmodal
uci set web.mmpbxstatisticsmodal=rule
uci set web.mmpbxstatisticsmodal.target='/modals/mmpbx-statistics-modal.lp'
uci add_list web.mmpbxstatisticsmodal.roles='admin'
sed -e 's/{"mmpbx-sipdevice-modal.lp", T"Sip Device"},/{"mmpbx-sipdevice-modal.lp", T"Sip Device"},\n{"mmpbx-inoutgoingmap-modal.lp", T"In-Out Mapping"},\n{"mmpbx-statistics-modal.lp", T"Statistics"},/' -i /www/snippets/tabs-voice.lp
sed -e 's/getrole()=="guest"/getrole()=="admin"/' -i /www/snippets/tabs-voice.lp

# IP Extras card / modal
uci add_list web.ruleset_main.rules=iproutesmodal
uci set web.iproutesmodal=rule
uci set web.iproutesmodal.target='/modals/iproutes-modal.lp'
uci add_list web.iproutesmodal.roles='admin'

# System Extras card / modal
uci add_list web.ruleset_main.rules=systemmodal
uci set web.systemmodal=rule
uci set web.systemmodal.target='/modals/system-modal.lp'
uci add_list web.systemmodal.roles='admin'

# DHCP Relay Setup card / modal
uci add_list web.ruleset_main.rules=relaymodal
uci set web.relaymodal=rule
uci set web.relaymodal.target='/modals/relay-modal.lp'
uci add_list web.relaymodal.roles='admin'

# NAT Helpers card / modal
uci add_list web.ruleset_main.rules=natalghelpermodal
uci set web.natalghelpermodal=rule
uci set web.natalghelpermodal.target='/modals/nat-alg-helper-modal.lp'
uci add_list web.natalghelpermodal.roles='admin'

# Diagnostics modal additional features
uci add_list web.ruleset_main.rules=diagnosticstcpdumpmodal
uci set web.diagnosticstcpdumpmodal=rule
uci set web.diagnosticstcpdumpmodal.target='/modals/diagnostics-tcpdump-modal.lp'
uci add_list web.diagnosticstcpdumpmodal.roles='admin'
sed -e 's/session:hasAccess("\/modals\/diagnostics-network-modal.lp")/session:hasAccess("\/modals\/diagnostics-network-modal.lp") and \n session:hasAccess("\/modals\/diagnostics-tcpdump-modal.lp")/' -i /www/cards/009_diagnostics.lp
sed -e 's^alt="network"></div></td></tr>\\^alt="network"></div></td>\\\n <td><div data-toggle="modal" data-remote="modals/diagnostics-tcpdump-modal.lp" data-id="diagnostics-tcpdump-modal"><img href="#" rel="tooltip" data-original-title="TCPDUMP" src="/img/network_sans-32.png" alt="network"></div></td></tr>\\^' -i /www/cards/009_diagnostics.lp
sed -e 's/{"logviewer-modal.lp", T"Log viewer"},/{"logviewer-modal.lp", T"Log viewer"},\n {"diagnostics-tcpdump-modal.lp", T"tcpdump"},\n/' -i /www/snippets/tabs-diagnostics.lp

# T-Voice (deprecated app; probably ineffective)
uci add_list web.tvoicesipconfig.roles=admin
uci add_list web.tvoicecontacts.roles=admin
uci add_list web.tvoicecalllog.roles=admin
uci add_list web.tvoicecapability.roles=admin

# Prevent limiting cards in Bridge Mode
sed 's/if info.bridged then/if false then/' -i /www/lua/cards_limiter.lua

uci commit


##############
# Finishing up
##############

# Restart Nginx so that changes to Lua files are picked up
# If running any configuration parts above which involve `.lp` files, this step
# will need to be run separately.
/etc/init.d/nginx restart

# Technicolor Hacks

A collection of configuration for detoxing and improving the Technicolor
TG799vac modem. Firstly, we flash the modem and get root, using the publicised
methods care of [Mark Smith](https://forums.whirlpool.net.au/user/686) online.
Then, we access the modem, switch back to more recent firmware, and then tweak
that firmware to remove backdoors, telemetry, unecessary services, add
features like SSH, modem UI improvements, disables LEDs so your night stays
dark (and changes your physical WiFi button to toggle LEDs on/off) and more.

The configuration present may work on other devices, but it is specifically
geared for the TG799vac.  No guarantees are made that any or all of the code
will work for you.  Test careful and be prepared.

## How to

### Setup

1. Get the latest version of `autoflashgui`, the firmware flashing and root
   tool:

       git clone https://github.com/mswhirl/autoflashgui.git

1. Get the firmware for your TG799vac device.  You'll need the two firmwares
   as indicated below.  For completeness, here are the hashes:

   ... TODO

1. Setup the `autoflashgui` tool:

       cd autoflashgui
       virtualenv .
       . ./bin/activate
       pip install robobrowser==0.5.3

### Flash and get root

1. Start the tool:

       python autoflashgui.py

1. Flash `vant-f_CRF683-17.2.188-820-RA.rbi` with the tool.  This will fail to
   root (console will continually keep trying to connect and fail; this is
   okay).

1. Kill the tool in the console with `Control-C`.

1. Flash `vant-f_CRF687-16.3.7567-660-RG.rbi` with the tool. This will take a
   little while as it authenticates, then flashes, waits for a reboot of the
   modem and then eventually proceeds to perform command injection on the
   modem.

1. When done, SSH to the modem as `root` and change the password
   **immediately**:

       ssh root@10.0.0.138
       passwd

1. Remove the pre-existing `/etc/dropbear/authorized_keys` file and ideally
   replace it with your own.  This is a fun little backdoor the devs left
   there, judging by the comment `TCH Debug` on one of the keys.

1. Reboot the modem to complete disabling the services that were killed during
   the rooting process with `autoflashgui.py`

### Root and switch to new firmware

By this point, your modem is now running `16.3` firmware and has the `17.2`
firmware on board in its inactive, secondary flash partition.  We'll now
switch over to the latter firmware after injecting the ability to give
ourselves root.

1. Re-connect to the modem's wifi network and SSH back in:

       ssh root@10.0.0.138

1. Run the contents of `01-root-and-switch-fw.sh` in the SSH session:

       curl https:// | sh 

   There are more secure ways to run the file; like `curl`ing the file and
   then inspecting the contents.  It's up to you how safe you'd like to play
   it and mostly how much you trust me / GitHub.

1. Wait several minutes for the modem to reboot.

### Reconfigure new firmware

At this point, the modem is back running `17.2` and SSH is available on port
`6666`.  We can now go wild and clean up the modem.

1. Re-connect to the modem's wifi network and SSH back in.  The password is
   currently `root`, which you'll change **immediately**:

       ssh root@10.0.0.138 -p 6666
       passwd

1. Run the contents of `02-detox.sh` in the SSH session.  The plan here is to
   disable and reset Telstra-based config on the device.

       curl https:// | sh 

1. Add your own SSH public key into the file `/etc/dropbear/authorized_keys`.

1. At this point, you can now SSH back into the modem whenever you'd like on the
   standard port `22`:

       ssh root@10.0.0.138

   Once you've confirmed you can do this, clear the original configuration we
   used to root the modem with:

        echo > /etc/rc.local

   We do this last to be entirely sure you're not going to accidentally lock
   yourself out.

1. Reboot the modem again to finalise the configuration. This implicitly
   results in the SSH server on port `6666` no longer being started.

       reboot

## Final setup

1. Configure the following optional settings with `03-configure.sh`.  These
   are specific to using the modem as a bridge only and with my specific
   requirements. It does the following:

   * Disables WWAN support
   * Disables Printer sharing
   * Disables Samba / DLNA
   * Disables Telephony (MMPBX)
   * Disables Traffice Monitoring
   * Disables Time of Day ACL rules
   * Explicitly disables Wake on LAN (not enabled by default)
   * Disables *all* LEDs by default (and on boot)
   * Adds ability to turn LEDs on or using the WiFi toggle button (via the
     newly added `toggleleds.sh` script)
   * BETA: Drops the CPU speed down to reduce power consumption

1. If on VDSL2 (eg FTTN/FTTC/FTTB), run the contents of `04-vdsl2.sh` as well.

   Otherwise, you can go to the xDSL Config card in the UI and select your mode(s).
   If you do this, click `Save` and close the modal; the modal will look like
   it didn't work, but it will have saved.

1. Head to the web-based UI at `http://10.0.0.138` and go to the Advanced tab.

1. Go to the `Gateway` card and set the timezone.  Disable `Network Timezone`
   and then choose the appropriate `Current Timezone`.

## Notes

### Introspection

To further investigate what's *actually* going on in this modem, the following
are helpful:

* `ps` command - shows everything that's running
* `netstat -lenp` command - shows everything that's listening on sockets (TCP,
  UPD, Unix etc)
* `uci show` command - dumps the entire OpenWRT configuration for you to look
  at
* `logread -f` command - access logs for most services (which use `syslog`.
  Pass an argument of `-e nginx` to match log entries just related to Nginx,
  which is perfect for debugging errors in the web UI.
* `/etc/init.d/*` files - look at the services present; some of which may be
  enabled or not
* `/etc/config/*` files - generally the source files for `uci show` but
  displayed in a perhaps more human-readable fashion
* `/www/*` files - the source files for the Lua web interface
* `/sbin/*.sh`, `/usr/bin/*.sh`, `/usr/sbin/*.sh` files - the locations
  containing various executable files, many of which are custom-written for
  this hardware

### Services

* `transformer`: critical service as it underpins the Gateway web UI.
  Stopping and disabling this service will crash/reboot the modem.

### VDSL2 Introspection

    xdslctl --help
    xdslctl profile --show

Note that running `xdslctl configure` makes the DSL line resync and possibly
other things as well; reboot the modem after this to ensure any side effects
don't persist.

From <http://whrl.pl/Re6mCZ>.

### Telnet fallback

OpenWRT has a telnet fallback if your system is configured accordingly and
Dropbear/SSH aren't running: it'll run telnet instead.  If this isn't what you
want, then you can disable it thusly:

    /etc/init.d/telnet stop
    /etc/init.d/telnet disable

Note that this might result in you being locked out later if say SSH were to
crash on boot.  Unlikely, but you never know.

### VLAN for VDSL2

It's possible to add the VLAN configuration into the UI.  For now, I don't
need this but I'll consider formalising it later.  Edit this file:
`/www/docroot/modals/broadband-modal.lp`:

    local lp = require("web.lp")
    lp.setpath("/www/snippets/")

    [...]

    lp.include('broadband-vlan.lp');

and resart Nginx.

## Credit and thanks

The root method is care of Mark Smith
<https://forums.whirlpool.net.au/user/686> and is greatly appreciated.

The basis for the tweak instructions come from Mark Smith and also from
Steve's blog at
<https://www.crc.id.au/hacking-the-technicolor-tg799vac-and-unlocking-features/>.

## Licence

MIT, see `LICENCE.txt`

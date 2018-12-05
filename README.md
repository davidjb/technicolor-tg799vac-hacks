# Technicolor Hacks

A collection of configuration for detoxing and improving the [Technicolor
TG799vac](https://bc.whirlpool.net.au/bc/hardware/?action=h_view&model_id=1622)
modem. Firstly, we flash the modem and get root, using the publicised methods
care of [Mark Smith](https://forums.whirlpool.net.au/user/686) online.  Then,
we access the modem, switch back to more recent firmware, and then tweak that
firmware to remove backdoors, telemetry, unecessary services, add features
like SSH, modem UI improvements, disables LEDs so your night stays dark,
changes your physical `Status` button, also known as the "easy reset" button,
to toggle LEDs on/off, and more.

The configuration present may work on other devices, but it is specifically
geared for the TG799vac. There are no guarantees made that any or all of the code
will work for you or suit your needs.  Test carefully and be prepared that
some or all may not work on your device or your firmware.

Instructions are currently written for use on a \*nix-style OS but have
been successfully also used under Windows as well.  If you're on Windows,
you can can try with the 
[Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
or simply just do things manually (such as downloading zip files from GitHub
instead of cloning and running scripts interactive using PuTTY).

## How to

### Setup

1. Disconnect any form of WAN connection from your modem, such as the xDSL
   line or Ethernet connection on the WAN port.  This is super important in
   ensuring that the modem's firmware doesn't go auto-updating.
   
1. Have a computer or device on hand where you can set up the following tools.
   If you don't have Python (with tkinter support) or Git installed, you'll
   need to install them both or figure out a plan to proceed manually.
   
   Your device will need to have a GUI (eg not be a headless server) 
   as well for at least when tkinter gets used for the `autoflashgui` tool.
   Everything else should work headless, if you're so inclined.
   
1. Get the latest version of these scripts; you'll need them for later:

   ```sh
   git clone https://github.com/davidjb/technicolor-tg799vac-hacks.git
   ```
   
   Make sure you do this on your computer/device rather than on your modem.

1. Get the latest version of `autoflashgui`, the firmware flashing and root
   tool.  My fork has one fix awaiting a PR into the main repository which
   is why I'm using that for now:

   ```sh
   git clone https://github.com/davidjb/autoflashgui.git
   ```
   
   Again, make sure this is on your computer/device and not your modem.

1. [Get the
   firmware](https://drive.google.com/drive/folders/1n9IAp9qUauTT9eMLf3oYQMbodFEGFHyL)
   for your TG799vac device.  You'll need the two firmwares
   as indicated below.  For completeness, here are the SHA-256 hashes:

   ```
   38b41546133b2e979befce8e824654289aa237446fc4118444f271423c35e3fa vant-f_CRF687-16.3.7567-660-RG.rbi
   0c9bf5e739600ceae61362eebc6ee271783ff85e5d60e3c3076f98bd37648d02 vant-f_CRF683-17.2.188-820-RA.rbi
   ```

1. Setup the `autoflashgui` tool:

   ```sh
   cd autoflashgui
   virtualenv .
   source ./bin/activate
   pip install robobrowser==0.5.3
   ```

### Flash and get root

If your modem happens to be running a newer firmware version (such as an
Over-The-Air [OTA] upgrade that happened) or you happen to get locked out for
any reason, try a factory reset with the modem physically disconnected from
the Internet.

To factory reset, get a paperclip and hold down the reset button for 15
seconds.  Release the button and wait a few moments -- the modem will restore,
all the LEDs will flash and the modem will reset.

1. Start the tool:

   ```sh
   python autoflashgui.py
   ```

1. Flash `vant-f_CRF683-17.2.188-820-RA.rbi` with the tool.  This will fail to
   root (console will continually keep trying to connect and fail; this is
   okay).  In my second attempt with a modem starting from firmware 15.3, this
   actually appeared to succeed and send comamnds to the newly-booted 17.2
   firmware, but the SSH port wasn't open.


1. Kill the tool in the console with `Control-C`.

1. Flash `vant-f_CRF687-16.3.7567-660-RG.rbi` with the tool. This will take a
   little while as it authenticates, then flashes, waits for a reboot of the
   modem and then eventually proceeds to perform command injection on the
   modem.

   If at this point the modem is not allowing SSH connections, then you may
   need to reflash the version of 17.2 now when on what should be a rooted
   version of 16.3.  This is something I observed when the firmware first
   started out at 17.2 on one specific device, so I suspect the flashing of
   17.2 when already on some version of 17.2 meant the flash didn't take or
   apply correctly.  In any case, reflashing 17.2 at this point (and then
   reflashing 16.3 *again*...) solved this for me.  Once you do get an SSH
   session available, you can continue on.

1. When done, SSH to the modem as `root` and change the password
   **immediately**:

   ```sh
   ssh root@10.0.0.138
   # Now on the modem...
   passwd
   ```

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

1. Re-connect to the modem's wifi network and SSH back in to run the contents
   of `01-root-and-switch-fw.sh`:

   ```sh
   ssh root@10.0.0.138 'sh' < ./01-root-and-switch-fw.sh
   ```

   There are more secure ways to run the file, like actually inspecting the
   contents.  It's up to you how safe you'd like to play it and mostly how
   much you trust me / GitHub.

1. Wait several minutes for the modem to reboot.

### Reconfigure new firmware

At this point, the modem is back running `17.2` and SSH is available on port
`6666`.  We can now go wild and clean up the modem.

1. Re-connect to the modem's wifi network and SSH back in.  The password is
   currently `root`, which you'll change **immediately**:

   ```sh
   ssh root@10.0.0.138 -p 6666
   # Now on the modem...
   passwd
   exit
   ```

1. Run the contents of `02-detox.sh` on the modem the SSH session.  The plan
   here is to disable and reset Telstra-based config on the device, disable
   OTA updates, close other security holes and backdoors, disable telemetry,
   replace the Telstra logo with Technicolor's logo and unlock various other
   features like SSH, web UI and so on. Consult the source to check the
   specifics if you want to opt-in to specific changes:

   ```sh
   ssh root@10.0.0.138 -p 6666 'sh' < ./02-detox.sh
   ```
   
   There's a bit happening here in this script so I encourage you to check out
   the [source](https://github.com/davidjb/technicolor-hacks/blob/master/02-detox.sh)
   to note what's being disabled and modified.  In particular, you can confirm
   that TR-069/CWMP is disabled by following the [comments in the script](https://github.com/davidjb/technicolor-hacks/blob/master/02-detox.sh#L88)
   so that you're sure you've protected yourself against the relevant
   [security risks](https://en.wikipedia.org/wiki/TR-069#Security_risks)
   associated with this protocol.

1. At this point, you can now SSH back into the modem whenever you'd like on the
   standard port `22`:

   ```sh
   ssh root@10.0.0.138
   ```

1. Once you've confirmed you can do this, run the following in the SSH session
   on the modem to clear the original configuration we used to root the modem:

   ```sh
   echo > /etc/rc.local
   ```

   We do this last to be entirely sure you're not going to accidentally lock
   yourself out.

1. Add your own SSH public key into the file `/etc/dropbear/authorized_keys`
   on the modem.  Edit on the modem via an editor like `vi` or SCP a file from
   your computer across.

1. Back on your host machine, copy the `technicolor-logo.svg` image to your
   modem's `img` directory such that it becomes available for use in the web interface:

   ```sh
   scp technicolor-logo.svg root@10.0.0.138:/www/docroot/img/
   ```
   
   If on Windows, you can use WinSCP to achieve this.

1. Reboot the modem again to finalise the configuration. This implicitly
   results in the SSH server on port `6666` no longer being started.

   ```sh
   ssh root@10.0.0.138 'reboot'
   ```

## Futher customisation

The following are specific configuration items to using the modem *as* a basic
modem only, with a few improvements like the ability to turn off the LEDs and
speed boosts.

1. Run `03-configure.sh` to set various additional settings:

   ```sh
   ssh root@10.0.0.138 'sh' < ./03-configure.sh
   ```

   It does the following:

   * Disables WWAN support
   * Disables Printer sharing
   * Disables Samba / DLNA
   * Disables Telephony (MMPBX)
   * Disables Traffice Monitoring
   * Disables Time of Day ACL rules
   * Explicitly disables Wake on LAN (not enabled by default)
   * Adds ability to turn LEDs on or using the physical `Status` button (via
     the newly added `toggleleds.sh` script)
   * Disables *all* LEDs by default (and on boot)

   You can opt-in or out of any of these changes by just running the bits you
   want or commenting out the bits you don't.

1. If on VDSL2 (eg FTTN/FTTC/FTTB), run `04-vdsl2.sh` as well:

   ```sh
   ssh root@10.0.0.138 'sh' < ./04-vdsl2.sh
   ```

   Otherwise, you can go to the xDSL Config card in the UI and select your mode(s).
   If you do this, click `Save` and close the modal; the modal will look like
   it didn't work, but it will have saved.

1. Head to the web-based UI at `http://10.0.0.138` and go to the Advanced tab.
   Go to the `Gateway` card and set the timezone.  Disable `Network Timezone`
   and then choose the appropriate `Current Timezone`.

## Getting Internet access

The last step in actually getting connected up the Internet comes down to
on how you're planning on using the modem.

### As a modem/router

Head to the web-based UI at `http://10.0.0.138` and go to the Advanced tab.

Go to the `Internet Access` card and set the PPPoE username and password
and the modem should connect automatically.  You're done.

### As a bridged modem

1. Connect an Ethernet cable between port 1 (far left) of the modem and your
   router's WAN port.

1. Head to the web-based UI at `http://10.0.0.138` and go to the Advanced tab.

1. Go to the `Local Network` card and click the link in the card heading.

1. Scroll down to `Network mode` and click `Bridged Mode`.

1. Confirm this action and the modem will reboot automatically.

1. Whilst it reboots, go to your router's settings and configure your WAN to
   use PPoE with the relevant username and password.  How you do this depends
   on your router.

1. Once the modem has restarted, your router should be automatically connected
   to the Internet.

From here, we need to reconfigure the modem a futher time to shut a few final
services down like dnsmasq, WiFi and so on.  In truth, most things are already
configured to have been disabled (via `uci` configuration), but certain
services like `dnsmasq` and `odhcpd` are still running, though they're not
doing anything.

You can configure the setup however you'd like, but To make life simple, I put
the modem on my main network so I can still SSH to it.  If you don't want
this, you could manually plug an Ethernet cable into the modem if you ever
need to access it again.

1. Change the modem's IP address to be a static IP your router's subnet (such as
   `192.168.1.x`) so it'll work as a device on the router's network:

   ```sh
   ssh root@10.0.0.138
   # Set your own LAN IP address and subnet here
   uci set network.lan.ipaddr='192.168.1.x'
   uci set network.lan.netmask='255.255.255.0'
   uci commit
   /etc/init.d/network restart
   ```

1. Connect an Ethernet cable between any port on the modem to a LAN port on
   your router.

1. Access your router's network and check you now access the modem at
   `192.168.1.x`.  The dashboard should load fine.

1. Once you've confirmed this, then run the final `05-bridge-mode.sh` script
   to shut down the remaining services.  **Note:** this includes terminating
   WiFi so make sure you're accessing the modem via Ethernet (eg via your
   router) at this point.  Also make sure you use your new IP address.

   ```sh
   ssh root@192.168.1.x 'sh' < ./05-bridge-mode.sh
   ```

1. Check out your extremely slimmed down set of open connections with
   `netstat -lenp`: just Nginx for the web UI and Dropbear for SSH with network
   connections and underlying dependencies listening on UNIX domain sockets.

## Even more

1. Install any other OpenWRT packages you want. At this point, your bridged
   modem probably doesn't have access to the web so download packages to your
   local computer, SCP them to the modem and run the following command on
   the modem to install them:

   ```sh
   opkg install ./package-name-here1.0_brcm63xx.ipk
   ```

1. Set the `admin` user's password in your modem's UI under the `Maintenance`
   tab. Once this is set, the UI will prompt for login instead of just showing
   the advanced dashboard automatically.

1. Improve the security on the web interface for the modem by installing the
   `nginx.conf` file present in this repo over the top of the existing config.
   This requires a little tweaking because of server name-specific
   configuration to workaround redirection in nginx:

   ```sh
   # Run this on your host machine
   IP=192.168.1.x
   HOSTNAME=modem.example.com
   sed "s/10.0.0.138/$IP/g" nginx.template.conf > nginx.conf
   sed -i "s/mygateway.gateway/$HOSTNAME/g" nginx.conf
   scp nginx.conf root@$IP:/etc/nginx/nginx.conf
   ssh root@$IP '/etc/init.d/nginx restart'
   ```

   This config hardens the Nginx instance by stopping listening on
   "assistance" port 55555 and port 8080 for proxying, as well as minor
   improvements as well with using HSTS, redirecting port 80 to 443 and
   running only over 443 / HTTPS.

   Note that the modem generated its own self-signed certificate so you might
   want to consider setting up your own Let's Encrypt certificate on the modem
   via [acme.sh](https://github.com/Neilpang/acme.sh).

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
* `for F in /etc/init.d/* ; do $F enabled && echo $F on || echo $F **disabled**; done` -
  display the status of all init scripts
* `/etc/config/*` files - generally the source files for `uci show` but
  displayed in a perhaps more human-readable fashion
* `/www/*` files - the source files for the Lua web interface
* `/sbin/*.sh`, `/usr/bin/*.sh`, `/usr/sbin/*.sh` files - the locations
  containing various executable files, many of which are custom-written for
  this hardware

### Services

* `transformer`: critical service as it underpins the Gateway web UI.
  Stopping and disabling this service will crash/reboot the modem.

### Compatible OpenWrt packages (opkg)

To confirm which version of OpenWrt you're running, look at the release file
by running the following command on the modem:

    cat /etc/openwrt_release

In my case, this looks like so:

    DISTRIB_ID='OpenWrt'
    DISTRIB_RELEASE='Chaos Calmer'
    DISTRIB_REVISION='r46610'
    DISTRIB_CODENAME='chaos_calmer'
    DISTRIB_TARGET='brcm63xx-tch/VANTF'
    DISTRIB_DESCRIPTION='OpenWrt Chaos Calmer 15.05.1'
    DISTRIB_TAINTS='no-all busybox'

So I can see I'm using version 15.05.1, the release called Chaos Calmer. I can
also see the chipset/architecture my OpenWrt and its packages were built for
-- `brcm63xx-tch`.  The `-tch` at the end implies something special for
Technicolor (assuming TCH isn't some grand coincidence since they use TCH as
their stock ticker, SSH key comments and so on) but in my experience, packages
for the `brcm63xx` architecture all work fine.

The following packages from
<https://archive.openwrt.org/chaos_calmer/15.05.1/brcm63xx/generic/packages/packages/>
have been confirmed to work on this device:

* `openssh-client`
* `openssh-client-utils`
* `openssh-keygen`
* `openssh-sftp-client`
* `unzip`

For other release versions or differing hardware, browse up the directory
structure on that URL and find your own compatible packages.

Various backup copies of packages can be found in the `pkg/` directory in this
repository.  I manually copy the packages onto my modem since my modem is
configured as a bridge and is explicitly configured not to have Internet
access.

Most other packages for this OpenWrt release/architecture should work, but
some may conflict with existing packages or files on the device.  There's also
only 32MB of storage on the modem (24.3MB available on mine) so this is a
pretty limiting factor in installing extra software.

### VDSL2 Introspection

    xdslctl --help
    xdslctl profile --show

Note that running `xdslctl configure` makes the DSL line resync and possibly
other things as well; reboot the modem after this to ensure any side effects
don't persist.

From <http://whrl.pl/Re6mCZ>.

### Bridging

    brctl help
    brctl show

Shows the current status of the bridge on the modem.

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
need this but I'll consider formalising it later.  Edit the file at
`/www/docroot/modals/broadband-modal.lp` like so:

    local lp = require("web.lp")
    lp.setpath("/www/snippets/")

    [...]

    lp.include('broadband-vlan.lp');

and resart Nginx.

### IPoE

There are various settings for IPoE within uci's settings (eg `uci show`).
Evidence online says that IPoE is possible with this modem and may

### Power configuration

```sh
pwrctl config --cpuspeed 8      # Default: 1  (UI shows 0)
pwrctl config --wait on         # Default: on
pwrctl config --sr on           # Default: off
pwrctl config --ethapd on       # Default: on
pwrctl config --eee on          # Default: on
pwrctl config --autogreeen on   # Default: on
pwrctl config --avs deep        # Default: off + doesn't do anything
```

In initial testing, teaking settings appeared to drop power consumption
slightly but it's too soon to tell.  The `--avs` (Adaptive Voltage Scaling)
option doesn't appear to have any effect on the TG799vac; it always stays
disabled.

### Jumbo frames

```sh
uci set network.bcmsw.jumbo='1'
uci commit
/lib/network/switch.sh
```

(currently untested)

## Credit and thanks

The root method is care of Mark Smith
<https://forums.whirlpool.net.au/user/686> and is greatly appreciated.

The basis for the tweak instructions come from Mark Smith, from
Steve's blog at
<https://www.crc.id.au/hacking-the-technicolor-tg799vac-and-unlocking-features/>
and various comments on [this Whirlpool
thread](https://forums.whirlpool.net.au/archive/2650998).

## Contributing

Pull requests are welcome for adding features or fixing bugs.  Open an issue
to discuss improving the default choices.  Note this is not a support forum so
any questions or requests for help will be closed.

## Licence

MIT, see `LICENCE.txt`

## TODO

* Disable LED ligtts on Ethernet ports. This looks to be possible via
  `ethswctl -c regaccess ...` but we need to know the right offset and data
  settings.

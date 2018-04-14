#!/bin/sh

# Remove old ADSL profiles and modes
uci del_list xdsl.dsl0.profile='8a'
uci del_list xdsl.dsl0.profile='8b'
uci del_list xdsl.dsl0.profile='8c'
uci del_list xdsl.dsl0.profile='8d'
uci del_list xdsl.dsl0.profile='12a'
uci del_list xdsl.dsl0.profile='12b'
uci del_list xdsl.dsl0.multimode='gdmt'
uci del_list xdsl.dsl0.multimode='adsl2annexm'
uci del_list xdsl.dsl0.multimode='adsl2plus'

# Increase the max sync speed
uci set xdsl.dsl0.maxaggrdatarate='200000'   # Default: 160000
uci set xdsl.dsl0.maxdsdatarate='140000'     # Default: 110000
uci set xdsl.dsl0.maxusdatarate='60000'      # Default: 60000

uci commit

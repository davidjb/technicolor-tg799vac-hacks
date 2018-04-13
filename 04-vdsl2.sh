#!/bin/sh

uci del_list xdsl.dsl0.profile='8a'
uci del_list xdsl.dsl0.profile='8b'
uci del_list xdsl.dsl0.profile='8c'
uci del_list xdsl.dsl0.profile='8d'
uci del_list xdsl.dsl0.profile='12a'
uci del_list xdsl.dsl0.profile='12b'
uci del_list xdsl.dsl0.multimode='gdmt'
uci del_list xdsl.dsl0.multimode='adsl2annexm'
uci del_list xdsl.dsl0.multimode='adsl2plus'
uci commit

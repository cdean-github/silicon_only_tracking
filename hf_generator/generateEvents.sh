#!/bin/bash

source /opt/sphenix/core/bin/sphenix_setup.sh -n new

export SPHENIX=/sphenix/u/cdean/sPHENIX
export MYINSTALL=$SPHENIX/install
export LD_LIBRARY_PATH=$MYINSTALL/lib:$LD_LIBRARY_PATH
export ROOT_INCLUDE_PATH=$MYINSTALL/include:$ROOT_INCLUDE_PATH

source /opt/sphenix/core/bin/setup_local.sh $MYINSTALL

root.exe -q -b Fun4All_HFG.C\(\"$1\"\)
echo Script done

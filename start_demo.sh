#!/bin/bash
#
# Copyright (c) 2019 - Adjacent Link LLC, Bridgewater, New Jersey
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in
#   the documentation and/or other materials provided with the
#   distribution.
# * Neither the name of Adjacent Link LLC nor the names of its
#   contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#


usage="usage: start_demo.sh [-e ENVFILE] [-c CONFIGFILE] [-p SSHPORT] [-k SSHKEYFILE] SSHUSER DEMODIR"

envfile=/dev/null

sshuser=

sshkeyfile=
sshkeyfileopt=

sshport=22

configfile=
configfileopt=

while getopts ":hbc:e:p:k:" opt; do
    case $opt in
        c) configfile=${OPTARG};
           configfileopt="--config ${configfile}"
           echo "configfile="${configfile}
           ;;
        e) envfile=${OPTARG};
           echo "envfile=${envfile}"
           ;;
        p) sshport=${OPTARG};
           echo "sshport=${sshport}"
           ;;
        k) sshkeyfile=${OPTARG};
           sshkeyfileopt="--sshkey ${sshkeyfile}"
           echo "sshkeyfile="${sshkeyfile}
           ;;
        h) echo ${usage} && exit 0
           ;;
        \?) echo "Invalid option -$OPTARG"
            ;;
    esac
done

shift $((OPTIND-1))

if [ $# != "2" ]; then
    echo ${usage}
    exit 1
fi

sshuser=$1
demodir=$2

echo "sshuser=${sshuser}"
echo "demodir=${demodir}"

if [ ! -d ${demodir} ]; then
    echo ${usage}
    exit 1
fi

# make output directory
if [ ! -d '/tmp/etce' ]; then
    mkdir -p '/tmp/etce'
fi

lxcplanfile=$demodir/doc/lxcplan.xml

hostfile=$demodir/doc/hostfile

if [ -f "/tmp/etce/lxcroot/etce.lxc.lock" ]; then
    echo "Detected a running ETCE demo. Run ./stop_demo.sh first."
    exit 1
fi

# start lxcs if the lxcplanfile exists
if [ -f ${lxcplanfile} ]; then
    sudo etce-lxc start --writehosts ${lxcplanfile}

    # wait for them to come up
    echo "Waiting for LXCs ..."
    sleep 5
fi

echo

etce-test run -v --user ${sshuser} ${sshkeyfileopt} --env ${envfile} --port ${sshport} ${configfileopt} etcedemo ${hostfile} ${demodir}

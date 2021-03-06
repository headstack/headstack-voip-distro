#!/bin/bash
#
# ipset      Start and stop ipset firewall sets
#
# config: /etc/ipset/ipset
#

IPSET=ipset
IPSET_BIN=/usr/sbin/${IPSET}
IPSET_DATA=/etc/${IPSET}/${IPSET}

IPTABLES_CONFIG=/etc/sysconfig/iptables-config
IP6TABLES_CONFIG=${IPTABLES_CONFIG/iptables/ip6tables}

TMP_FIFO=/tmp/${IPSET}.$$

if [[ ! -x ${IPSET_BIN} ]]; then
        echo "${IPSET_BIN} does not exist."
        exit 5
fi

CLEAN_FILES=TMP_FIFO
trap "rm -f \$CLEAN_FILES" EXIT

# Default ipset configuration:
[[ -z $IPSET_SAVE_ON_STOP ]] && IPSET_SAVE_ON_STOP=no           # Overridden by ip(6)tables IP(6)TABLES_SAVE_ON_STOP
[[ -z $IPSET_SAVE_ON_RESTART ]] && IPSET_SAVE_ON_RESTART=no     # Overridden by ip(6)tables IP(6)TABLES_SAVE_ON_RESTART

# Load iptables configuration(s)
[[ -f "$IPTABLES_CONFIG" ]] && . "$IPTABLES_CONFIG"
[[ -f "$IP6TABLES_CONFIG" ]] && . "$IP6TABLES_CONFIG"

# It doesn't make sense to save iptables config and not our config
[[ ${IPTABLES_SAVE_ON_STOP} = yes || ${IP6TABLES_SAVE_ON_STOP} = yes ]] && IPSET_SAVE_ON_STOP=yes
[[ ${IPTABLES_SAVE_ON_RESTART} = yes || ${IP6TABLES_SAVE_ON_RESTART} = yes ]] && IPSET_SAVE_ON_RESTART=yes

check_can_unload() {
    # If the xt_set module is loaded and can't be unloaded, then iptables is
    # using ipsets, so refuse to stop the service.
    if [[ -n $(lsmod | grep "^xt_set ") ]]; then
        rmmod xt_set 2>/dev/null
        [[ $? -ne 0 ]] && echo Current iptables configuration requires ipsets && return 1
    fi

    return 0
}

flush_n_delete() {
    local ret=0 set

    # Flush sets
    ${IPSET_BIN} flush
    let ret+=$?

    # Delete ipset sets. If we don't do them individually, then none
    # will be deleted unless they all can be.
    for set in $(${IPSET_BIN} list -name); do
            ${IPSET_BIN} destroy 2>/dev/null
            [[ $? -ne 0 ]] && ret=1
    done

    return $ret
}

start_clean()
{
    mkfifo -m go= "${TMP_FIFO}"
    [[ $? -ne 0 ]] && return 1

    # Get the lists of sets in current(old) config and new config
    old_sets="$(${IPSET_BIN} list -name | sort -u)"
    new_sets="$(grep ^create "${IPSET_DATA}" | cut -d " " -f 2 | sort -u)"

    # List of sets no longer wanted
    drop_sets="$( printf "%s\n" "${old_sets}" > "${TMP_FIFO}"  &
                  printf "%s\n" "${new_sets}" | comm -23 "${TMP_FIFO}" -
                )"

    # Get rid of sets no longer needed
    # Unfortunately -! doesn't work for destroy, so we have to do it a command at a time
    for dset in $drop_sets; do
        ipset destroy $dset 2>/dev/null
        # If it won't go - ? in use by iptables, just clear it
        [[ $? -ne 0 ]] && ipset flush $dset
    done

    # Now delete the set members no longer required
    ${IPSET_BIN} save | grep "^add " | sort >${TMP_FIFO} &
      grep "^add " ${IPSET_DATA} | sort | comm -23 ${TMP_FIFO} - | sed -e "s/^add /del /" \
      | ${IPSET_BIN} restore -!

    # At last we can add the set members we haven't got
    ipset restore -! <${IPSET_DATA}

    rm ${TMP_FIFO}

    return 0
}

start() {
    # Do not start if there is no config file.
    [[ ! -f "$IPSET_DATA" ]] && echo "Loaded with no configuration" && return 0

    # We can skip the first bit and do a simple load if
    # there is no current ipset configuration
    res=1
    if [[ -n $(${IPSET_BIN} list -name) ]]; then
        # The following may fail for some bizarre reason
        start_clean
        res=$?

        [[ $res -ne 0 ]] && echo "Some old configuration may remain"
    fi

    # res -ne 0 => either start_clean failed, or we didn't need to run it
    if [[ $res -ne 0 ]]; then
        # This is the easy way to start but would leave any old
        # entries still configured. Still, better than nothing -
        # but fine if we had no config
        ${IPSET_BIN} restore -! <${IPSET_DATA}
        res=$?
    fi

    if [[ $res -ne 0 ]]; then
        return 1
    fi

    return 0
}

stop() {
    # Nothing to stop if ip_set module is not loaded.
    lsmod | grep -q "^ip_set "
    [[ $? -ne 0 ]] && return 6

    flush_n_delete
    [[ $? -ne 0 ]] && echo Warning: Not all sets were flushed/deleted

    return 0
}

save() {
    # Do not save if ip_set module is not loaded.
    lsmod | grep -q "^ip_set "
    [[ $? -ne 0 ]] && return 6

    [[ -z $(${IPSET_BIN} list -name) ]] && return 0

    ret=0
    TMP_FILE=$(/bin/mktemp -q /tmp/$IPSET.XXXXXX) \
        && CLEAN_FILES+=" $TMP_FILE" \
        && chmod 600 "$TMP_FILE" \
        && ${IPSET_BIN} save > $TMP_FILE 2>/dev/null \
        && [[ -s $TMP_FILE ]] \
        || ret=1

    if [[ $ret -eq 0 ]]; then
        # No need to do anything if the files are the same
        if [[ ! -f $IPSET_DATA ]]; then
            mv $TMP_FILE $IPSET_DATA && chmod 600 $IPSET_DATA || ret=1
        else
            diff -q $TMP_FILE $IPSET_DATA >/dev/null

            if [[ $? -ne 0 ]]; then
                if [[ -f $IPSET_DATA ]]; then
                    cp -f --preserve=timestamps $IPSET_DATA $IPSET_DATA.save \
                        && chmod 600 $IPSET_DATA.save \
                        || ret=1
                fi
                if [[ $ret -eq 0 ]]; then
                    cp -f --preserve=timestamps $TMP_FILE $IPSET_DATA \
                        && chmod 600 $IPSET_DATA \
                        || ret=1
                fi
            fi
        fi
    fi

    rm -f $TMP_FILE
    return $ret
}


case "$1" in
    start)
        start
        RETVAL=$?
        ;;
    stop)
        check_can_unload || exit 1
        [[ $IPSET_SAVE_ON_STOP = yes ]] && save
        stop
        RETVAL=$?
        [[ $RETVAL -eq 6 ]] && echo "${IPSET}: not running" && exit 0
        ;;
    reload)
        [[ $IPSET_SAVE_ON_RESTART = yes ]] && save
        stop
        RETVAL=$?
        [[ $RETVAL -eq 6 ]] && echo "${IPSET}: not running" && exit 0
        start
        RETVAL=$?
        ;;
    *)
        echo "Usage: $IPSET {start|stop|reload}" >&2
        exit 1
esac

exit $RETVAL

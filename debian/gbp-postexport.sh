#!/bin/sh -e

debian/rules orig

log=$(mktemp)
debian/rules debian/control-real | tee $log
ret=1
grep -q SUCCESSFULLY $log && ret=0
rm -f $log
exit $ret

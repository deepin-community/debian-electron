#!/bin/bash

set -e
_dirname=$RULES_pkgname-$RULES_electron_ver
_tarname=${RULES_pkgname}_$RULES_electron_ver
tar cf - $_dirname | xz -T0 > $_tarname.orig.tar.xz

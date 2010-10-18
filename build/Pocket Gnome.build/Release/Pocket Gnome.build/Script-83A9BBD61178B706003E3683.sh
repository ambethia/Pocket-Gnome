#!/bin/sh
REV=`/usr/bin/svnversion -nc ${PROJECT_DIR} | /usr/bin/sed -e 's/^[^:]*://;s/[A-Za-z]//'`;echo "BUILD_NUMBER = $REV" > ${PROJECT_DIR}/buildnumber.xcconfig


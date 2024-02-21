#! /bin/sh

wget -q http://localhost:3142/acng-report.html -O /dev/null && echo 'Status: Okay' || exit 1

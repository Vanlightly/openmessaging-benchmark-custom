#!/usr/bin/env bash

for var in "$@"
do
    echo "Will run ${var}"
    ./${var}
    echo "Sleeping, will wake up in 10 minutes..."
    sleep 300
    echo "Waking up in 5 minutes..."
    sleep 300
    echo "Waking up for the next test! If there is no next test, you can kill me now!"
done

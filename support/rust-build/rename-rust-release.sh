#!/usr/bin/env bash

for I in *1.62.1-dev*; do
     NEW_NAME=`echo $I | sed -e 's/1.62.1-dev/1.62.1.0/g'`
     mv $I $NEW_NAME
done


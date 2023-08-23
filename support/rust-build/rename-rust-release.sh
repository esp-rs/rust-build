#!/usr/bin/env bash

for I in *1.72.0-dev*; do
     NEW_NAME=`echo $I | sed -e 's/1.72.0-dev/1.72.0.0/g'`
     mv $I $NEW_NAME
done


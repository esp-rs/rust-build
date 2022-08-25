#!/usr/bin/env bash

for I in *1.63.0-dev*; do
     NEW_NAME=`echo $I | sed -e 's/1.63.0-dev/1.63.0.2/g'`
     mv $I $NEW_NAME
done


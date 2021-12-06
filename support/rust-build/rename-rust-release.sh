#!/bin/bash

for I in *1.57.0-dev*; do
     NEW_NAME=`echo $I | sed -e 's/1.57.0-dev/1.57.0.2/g'`
     mv $I $NEW_NAME
done


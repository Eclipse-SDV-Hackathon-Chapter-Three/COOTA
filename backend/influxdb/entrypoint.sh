#!/bin/bash

influxdb3 serve --without-auth --node-id=node0 --object-store=file --data-dir=/var/lib/influxdb3/data --plugin-dir=/var/lib/influxdb3/plugins &

sleep 10

influxdb3 create database signals

sleep infinity
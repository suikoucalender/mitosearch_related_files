#!/bin/bash

sdir=$(dirname `readlink -f $0 || echo $0`)

/opt/bin/entry_point.sh &
sleep 10
python3 "$sdir"/download_metadata.py
sudo mv /home/seluser/Downloads/SraAccList.txt .
sudo chown `ls -lnd "$sdir"|awk '{print $3}'`:`ls -lnd "$sdir"|awk '{print $4}'` SraAccList.txt

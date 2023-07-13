#!/bin/bash
ssh-keygen -t rsa -N '' -f KEY
truc=$(cat /var/lib/jenkins/.ssh/KEY.pub)
sed "s|PUB_KEY_PRIV|$truc|g" ./TEMPLATE1.tf

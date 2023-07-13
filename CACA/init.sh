#!/bin/bash
ssh-keygen -t rsa -N '' -f KEY
truc=$(echo /var/lib/jenkins/.ssh/KEY.pub)
sed "s|PUB_KEY_PRIV|$truc|g" ./TEMPLATE1.tf

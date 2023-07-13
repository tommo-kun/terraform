#!/bin/bash
ssh-keygen -t rsa -N '' -f KEY
truc=$(cat KEY.pub)
sed "s|PUB_KEY_PRIV|$truc|g" ./TEMPLATE1.tf

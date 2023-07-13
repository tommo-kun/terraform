#!/bin/bash
ssh-keygen -t rsa -N '' -f KEY
sed 's|PUB_KEY_PRIV|$(echo /var/lib/jenkins/.ssh/KEY.pub)|g' ./TEMPLATE1.tf

#!/bin/bash
scp -i TSIEUDAT-KEYSSH.pem KEY.pem ec2-user@$(cat public_ip):/home/ec2-user/

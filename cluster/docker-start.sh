#! /bin/bash
service sshd start
service rsyslog start
tail -f /var/log/messages

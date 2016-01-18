#!/usr/bin/expect -f
set timeout 20

spawn bash -c "scp .ssh/id_rsa_appd.pub [lindex $argv 1]@[lindex $argv 0]:"
expect "yes/no" { 
    send "yes\r"
    expect "*?assword" { send -- "[lindex $argv 2]\r" }
    } "*?assword" { send -- "[lindex $argv 2]\r" }
expect eof

spawn bash -c "ssh [lindex $argv 1]@[lindex $argv 0] mkdir -p .ssh"
expect "*?assword:*" {
  send -- "[lindex $argv 2]\r"
  send -- "\r"
}
expect eof

spawn bash -c "ssh [lindex $argv 1]@[lindex $argv 0] chmod 700 .ssh"
expect "*?assword:*" {
  send -- "[lindex $argv 2]\r"
  send -- "\r"
}
expect eof

spawn bash -c "ssh [lindex $argv 1]@[lindex $argv 0] 'cat id_rsa_appd.pub >> .ssh/authorized_keys'"
expect "*?assword:*" {
  send -- "[lindex $argv 2]\r"
  send -- "\r"
}
expect eof

spawn bash -c "ssh [lindex $argv 1]@[lindex $argv 0] chmod 640 .ssh/authorized_keys"
expect "*?assword:*" {
  send -- "[lindex $argv 2]\r"
  send -- "\r"
}
expect eof

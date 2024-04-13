#!/bin/bash
sudo adduser automation --disabled-password --gecos ""
sudo usermod -aG sudo automation
sudo -u automation mkdir /home/automation/.ssh
sudo -u automation touch /home/automation/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAlK9SYgHttisI9NMozvE0HNroEK2bBG406szUfIGz1Xq+CGTdW1x197nBh36zqa5gYbhQCM/uGKOaGCPB+6R6gW0CpaHjPvcKW+pKAUaEWkQzeRYaS1yEJjD4Fh+DFqgaYKh+VTCH7RC2c6N+YdKKJkaSan2iaI9Z5nLjAxJloepbJBTDnhPQVasqNUykh6ZbYyYM5p3EEhYPrw5bMZJJkyHV44UexfqBmroSgbA87PtyUw/+9T9aG3yYwtAafUZJlZpWbeHdMRW/SVYmt/wCze5x+IAxqjk+48b8HeltR5Nys33VSQybuKNrcnumDNzthLFMQvF4ABO66yCTQ5NaBQ== automation" | sudo tee -a /home/automation/.ssh/authorized_keys
sudo chown -R automation:automation /home/automation/.ssh
sudo chmod 700 /home/automation/.ssh
sudo chmod 600 /home/automation/.ssh/authorized_keys
echo "automation ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/automation

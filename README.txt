NOTE ON SUPER USER

Super user permissions are indicated with '#' while regular permissions are prefixed with '$'. Super user can be achived with the commands:

    $sudo COMMAND
    $sudo sh -c "COMMAND"
    $sudo su
        #COMMAND
        #exit

The last option opens a commandline that will interpret all commands as the super user, this is generally seen as less safe



REBOOTING

After any command enabling or restarting a daemon or changing configurations, a system reboot may be recomended:

    #reboot



LAUNCHING AT STARTUP

The Raspberry Pi default username is 'pi' and the default password is 'raspberry'. These will be required at first login and when logging in through SSH which can be setup with:

    #apt-get install openssh-server
    #nano /etc/ssh/sshd_config
    #systemctl enable ssh.socket

To launch the server at boot, enable the autologin@.serivce in systemd and remove the original login daemon:

    #rm /etc/systemd/system/getty.target.wants/*
    #systemctl enable autologin@.service

Then execute the launcher.sh script in the bash rc file if in the first terminal (TTY1):

    $echo 'if [ $(tty) == /dev/tty1 ]; then' >> ~/.bashrc
    $echo 'cd ~/RiggingServer' >> ~/.bashrc
    $echo './launcher.sh' >> ~/.bashrc
    $echo 'cd' >> ~/.bashrc
    $echo 'fi' >> ~/.bashrc

Limiting this to TTY1 allows SSH login without issues



STARTING NETWORKING

The networking requires the NetworkManager package, so this must be installed:

    #apt-get install network-manager

NetworkManager also needs to manage the wireless card:

    #echo 'managed=true' >> /etc/NetworkManager/NetworkManager.conf
    #systemctl restart network-manager

Check the device status with:

    #nmcli device



ENABLING I2C

Enable the kernal option for I2C under interfacing options in rasppi-config

    #raspi-config

Then install the dependancies

    #apt-get install i2c-tools
    #apt-get install python-smbus

Find devices and their addresses on I2C channel 1

    #i2cdetect -y 1

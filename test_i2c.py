#!/usr/bin/env python3
import smbus

#initiate I2C bus
bus = smbus.SMBus(1)

#set device I2C address
address = 0x68

#set some registers
aX = 0x3B
aY = 0x3D
aZ = 0x3F
gX = 0x43
gY = 0x45
gZ = 0x47
aConf = 0x1C
gConf = 0x1B
power = 0x6B

#wake imu
bus.write_byte_data(address, power, 0x00)

#set gyro range 250
bus.write_byte_data(address, gConf, 0x00)

#loop until Ctl-C is pressed
while True:
    #get two bytes from gyro x
    high = bus.read_byte_data(address, gX)
    low = bus.read_byte_data(address, gX + 1)

    #convert bytes using big endian in 250 deg/s range
    value = int.from_bytes([high, low], 'big', signed = True) / 131.072

    #print the gyro value
    print(value)

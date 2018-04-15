#!/usr/bin/env python3
import socket
import threading
import json
import time
import math
import smbus

#rigging data server
class server():
    #set configuration variables
    port = 6500
    alpha = 0 #0.005

    #number of times to poll data when calibrating
    n = 100

    #initialize the server
    def __init__(self):
        #initialize i2c bus
        self.bus = smbus.SMBus(1)

        #make socket listening on port
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('', self.port))
        s.listen(1)

        #make new socket accepting a connection
        self.sock, addr = s.accept()
    
        #sensor data
        self.data = {'t' : 0}

        #start with no data collection active
        self.running = False

        #accepted commands
        self.send_request = 'send'.encode()
        self.start_request = 'start'.encode()
        self.stop_request = 'stop'.encode()

        #start listening for commands
        self.listen()

    #accept commands
    def listen(self):
        #loop until listening is set to false
        listening = True
        while listening:
            #accept a command from the client
            command = self.sock.recv(2048)

            #start processing data in the background
            if command == self.start_request:
                #enable polling
                self.running = True
        
                #build sensors
                self.sensors = {'rf': self.init_bno055(0x28)} #,
                    #'lf': self.init_mpu6050(0x68)}

                #initialize the sensor data
                for s in self.sensors:
                    self.calibrate(self.sensors[s])
                    self.data[s] = [0, 0, 0]

                #start processing thread
                self.data['t'] = time.time()
                t = threading.Thread(target = self.process)
                t.start()

                #confirm start
                self.sock.send(str(self.data['t']).encode())

            #transmit current data values
            elif command == self.send_request:

                #pack the data in the json standard format with no whitespace
                self.sock.send(self.pack().encode())

            #end data collection and shutdown (if stop request)
            else:
                listening = False
                self.running = False
                self.sock.send('{}'.encode())

    #initialize bno055 sensor
    def init_bno055(self, address):
        #sensor register data
        bno055 = {
            'mx':(0xF,  0xE), 'my':(0x11,0x10), 'mz':(0x13,0x12),
            'ax':(0x9,  0x8), 'ay':(0xB,  0xA), 'az':(0xD,0xC),
            'gx':(0x15,0x14), 'gy':(0x17,0x16), 'gz':(0x19,0x18)}

        #set gyro rage to 125 deg/s
        self.bus.write_byte_data(address, 0x0A, 0x4)

        #enable all sensors without fusion
        self.bus.write_byte_data(address, 0x3D, 0x7)

        #make dictionary for sensor
        sensor = {'address':address, 'registers':bno055, 'calibrations':{'gx':0, 'gy':0, 'gz':0}, 'range':125}

        #return the sensor dictionary
        return sensor

    #initialize an mpu6050 sensor
    def init_mpu6050(self, address):
        #sensor register data
        mpu6050 = {
            'ax':(0x3B,0x3C), 'ay':(0x3D,0x3E), 'az':(0x3f,0x40),
            'gx':(0x43,0x44), 'gy':(0x45,0x46), 'gz':(0x47,0x48)}

        #wake sensor
        self.bus.write_byte_data(address, 0x6B, 0x00)

        #set ranges to 250 deg/s
        self.bus.write_byte_data(address, 0x1C, 0x00)

        #set accel ranges to  m/s/s
        self.bus.write_byte_data(address, 0x1B, 0x00)

        #make dictionary for sensor
        sensor = {'address':address, 'registers':mpu6050, 'calibrations':{'gx':0, 'gy':0, 'gz':0}, 'range':250}

        #return the sensor dictionary
        return sensor

    #calibrate a sensor
    def calibrate(self, sensor):
        #loop over registers to calibrate
        for c in sensor['calibrations']:
            #pick by name
            register = sensor['registers'][c]

            #average first readings
            total = 0
            for i in range(self.n):
                total += self.get_register_data(sensor['address'], register)
            average = total / self.n

            #save calibration
            sensor['calibrations'][c] = average

    #read from sensors and integrate on a loop
    def process(self):
        #attempt to process requests
        try:
            #loop until server is shut down
            while self.running:
                #start by reading time and change in time
                t = time.time()
                dt = t - self.data['t']
                self.data['t'] = t
    
                #loop over sensors and registers to get readings for each
                for s in self.sensors:
                    #pick a sensor by name
                    sensor = self.sensors[s]
    
                    #dictionary of sensor reading
                    read = {}
    
                    #loop over registers
                    for r in sensor['registers']:
                        #pick a register by name
                        register = sensor['registers'][r]
    
                        try:
                            calibration = sensor['calibrations'][r]
                        except:
                            calibration = 0
    
                        #read each register for sensor
                        read[r] = self.get_register_data(sensor['address'], register, calibration)
    
                    #get angles from acceleration
                    x = math.atan2(read['ay'], read['az'])*180/math.pi - 90
                    y = math.atan2(read['ax'], read['az'])*180/math.pi
                    z = 90 - math.atan2(read['ay'], read['ax'])*180/math.pi
    
                    #calculate the impact of gravity on that angle
                    mag = math.sqrt(read['ax']**2 + read['ay']**2 + read['az']**2)
                    xMag = 1 #math.sqrt(read['ay']**2 + read['az']**2) / mag
                    yMag = 0 #math.sqrt(read['ax']**2 + read['az']**2) / mag
                    zMag = 1 #math.sqrt(read['ay']**2 + read['ax']**2) / mag
    
                    #range factor
                    scale = sensor['range']*2**-15

                    #update data for sensor
                    self.data[s][0] = (1 - self.alpha * xMag) * (self.data[s][0] + read['gx']*scale * dt) + self.alpha * xMag * x
                    self.data[s][1] = (1 - self.alpha * yMag) * (self.data[s][1] + read['gy']*scale * dt) + self.alpha * yMag * y
                    self.data[s][2] = (1 - self.alpha * zMag) * (self.data[s][2] + read['gz']*scale * dt) + self.alpha * zMag * z

        #print out any errors from requests
        except Exception as e:
            print(e)

    #pack data into one dictionary for json dump
    def pack(self):
        data = self.data

        #return data encoded into a string
        return json.dumps(data, separators = (',', ':'))

    #read short using sensor address and register address
    def get_register_data(self, address, register, calibration = 0):
        #get high and low bytes
        h = self.bus.read_byte_data(address, register[0])
        l = self.bus.read_byte_data(address, register[1])

        #move high byte up 8 digits and add low byte
        value = (h << 8) + l

        #convert from unsigned to signed short
        if value >= 0x8000:
            value -= 0x10000

        #return signed short
        return value - calibration

#start a new server object
server()

#!/usr/bin/python
import argparse
import serial
import csv
import struct
import time
import random


cmds = { 
    'ADDR' : 1 ,
    'LOAD' : 2,
    'WRITE' : 3,
    'READ' : 4,
    'READ_REQ' : 5,
    'COUNT': 6,
    'CONST': 7,
    }

def cmd(cmd, data=0):
    if args.verbose:
        print(cmd, data)
    ser.write(struct.pack('B', cmds[cmd] ))
    ser.write(struct.pack('>I', data))
    # final byte to register the instruction
    ser.write(struct.pack('B', 0 ))
    # couldn't get 4 bytes to work - so reading 5!
    data = ser.read(5)
    b, data, = struct.unpack('>BI', data)
    return data


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="communicate with FPGA over serial")
    parser.add_argument('--port', default='/dev/ttyUSB0', help="serial port")
    parser.add_argument('--read', default=False, help="read test")
    parser.add_argument('--write', default=False, help="write test")
    parser.add_argument('--sequential', default=True, help="sequential write")
    parser.add_argument('--random', default=False, help="random write")
    parser.add_argument('--num-tests', type=int, default=10, help="number of tests")
    parser.add_argument('-v','--verbose', dest="verbose", action="store_const", help="verbose", const=True)

    args = parser.parse_args()

    ser=serial.Serial()
    ser.port=args.port
    ser.baudrate=115200
    ser.timeout=1
    ser.open()
    print("port open")

    write = False
    read = True
    tests = 0
    try:
        for addr in range(0, args.num_tests):
            tests += 1
            if tests % 100 == 0:
                print(tests, addr)

            if args.sequential:
                number = addr % 255
            elif args.random:
                number = random.randint(0,255)
            else:
                exit("must give sequential or random argument")
            data = cmd('ADDR', addr)
            if write:
                cmd('LOAD', number)
                cmd('WRITE')
                print(addr, number)
            if read:
                cmd('READ_REQ')
                read_data = cmd('READ')
                print(addr, read_data)

            if read and write:
                if(read_data == number):
                    pass
                    #print("pass")
                else:
                    print("failed at addr %d, was %d" % (addr, read_data))

    except KeyboardInterrupt as e:
        print("quitting")
        print(addr)

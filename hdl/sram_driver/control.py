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
    parser.add_argument('--write', const=True, action="store_const", help="write test")
    parser.add_argument('--read', const=True, action="store_const", help="read test")
    parser.add_argument('--sequential', const=True, action="store_const", help="sequential write")
    parser.add_argument('--random', const=True, action="store_const", help="random write")
    parser.add_argument('--addr-end', type=int, default=10, help="number to end")
    parser.add_argument('--addr-start', type=int, default=0, help="where to start")
    parser.add_argument('-v','--verbose', dest="verbose", action="store_const", help="verbose", const=True)

    args = parser.parse_args()

    ser=serial.Serial()
    ser.port=args.port
    ser.baudrate=115200
    ser.timeout=1
    ser.open()
    print("port open")

    tests = 0
    try:
        for addr in range(args.addr_start, args.addr_end):
            tests += 1
            if tests % 100 == 0:
                print(tests, addr)

            if args.sequential:
                number = addr % 255
            elif args.random:
                number = random.randint(0,255)
            else:
                if args.write:
                    exit("must give sequential or random argument")

            data = cmd('ADDR', addr)
            if args.write:
                cmd('LOAD', number)
                cmd('WRITE')
                print(addr, number)
            if args.read:
                cmd('READ_REQ')
                read_data = cmd('READ')
                print(addr, read_data)

            if args.read and args.write:
                if(read_data == number):
                    pass
                    #print("pass")
                else:
                    print("failed at addr %d, was %d" % (addr, read_data))

    except KeyboardInterrupt as e:
        print("quitting")
        print(addr)

#!/usr/bin/python
import argparse
from pprint import pprint

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="search for BCD patterns in data")
    parser.add_argument('--dumpfile', help="dumpfile", required=True)
    parser.add_argument('--score', help="number to search", required=True)

    args = parser.parse_args()

    print("looking for %s in %s" % (args.score, args.dumpfile))

    with open(args.dumpfile) as fh:
        lines = fh.readlines()

    print("read %d lines" % len(lines))

    index = 0
    save_lines = []
    found = False
    for line in lines:
        # interested in the last digit only
        digit = line[6]

        if digit == args.score[index]:
            save_lines.append(line)
            index += 1
            found = True
        elif found == True:
            found = False
            index = 0
            save_lines = []

        if index == len(args.score):
            print("done")
            pprint(save_lines)
            exit(0)


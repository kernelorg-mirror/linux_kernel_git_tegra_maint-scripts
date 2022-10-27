#!/usr/bin/python

import pyparsing as pp, sys
from lib import devicetree

def dump_node(node, indent = 0):
    prefix = ' ' * indent
    print('%snode: %s' % (prefix, node))

    for prop in node.properties:
        print('%s  property: %s' % (prefix, prop))

    for child in node.children:
        dump_node(child, indent + 2)

def check_node(filename, node, indent = 0):
    #prefix = ' ' * indent
    #print('%s%s' % (prefix, node))
    prev = None

    for child in node.children:
        if child.unit_address is not None:
            if prev is not None:
                if child.unit_address < prev.unit_address:
                    if prev.name == 'memory' and prev.unit_address == 0x80000000:
                        if False:
                            print('WARNING: %s: %s < %s' % (filename, child, prev))
                    else:
                        print('ERROR: %s: %s < %s' % (filename, child, prev))

            prev = child

    for child in node.children:
        check_node(filename, child, indent + 2)

#dts = devicetree.compile(sys.argv[1])
#with open(sys.argv[1] + '.tmp', 'w') as fobj:
#    fobj.write(dts)

#with open(sys.argv[1], 'r') as fobj:
#    dts = fobj.read()

#print('DTS:')
#for no, line in enumerate(dts.splitlines(), start = 1):
#    print('%3d: %s' % (no, line))

try:
    for filename in sys.argv[1:]:
        #print('parsing %s...' % filename)
        #ast = devicetree.DeviceTree.parseString(dts, parseAll = True)
        #ast = devicetree.DeviceTree.parseFile(filename, parseAll = True)
        ast = devicetree.load(filename)
        #ast.pprint()

        #for node in ast:
        #    if isinstance(node, devicetree.Node):
        #        dump_node(node)

        #print('checking %s...' % filename)

        for node in ast:
            if isinstance(node, devicetree.Node):
                check_node(filename, node)

except pp.ParseException as e:
    print(e.line)
    print(' ' * (e.column - 1) + '^')
    print(e)

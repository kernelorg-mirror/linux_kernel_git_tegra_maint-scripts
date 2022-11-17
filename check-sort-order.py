#!/usr/bin/python

import pyparsing as pp, sys
from lib import devicetree

topmost_nodes = [
        'aliases', 'chosen', 'firmware', 'reserved-memory', 'memory'
    ]

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

    # thermal zones are ordered by zone ID
    if node.name == 'thermal-zones':
        return

    # PMIC regulators are ordered by importance
    if node.name == 'regulators':
        return

    # pinmux definitions are ordered (if at all) by pin offset
    if node.name == 'pinmux' and node.parent:
        if node.parent.name == 'pinmux' and node.parent.unit_address:
            return

    for child in node.children:
        # make sure aliases, chosen, firmware, reserved-memory and memory nodes are at the top
        if child.name in topmost_nodes:
            if prev and prev.name not in topmost_nodes:
                print('ERROR: %s: %s must appear before any other nodes (%s)' % (filename, child, prev))

            continue

        # pad controller pad and port definitions are sorted by type, not alphabetically
        if node.name == 'padctl':
            if child.name in [ 'pads', 'ports' ]:
                continue

        if node.name in [ 'pads', 'ports' ]:
            continue

        # regulator nodes are ordered by importance
        if child.name.startswith('regulator-'):
            continue

        # i2c-bus nodes are typically last
        if child.name == 'i2c-bus':
            continue

        # XXX operating-points are sorted numerically
        if child.name.startswith('opp-') or child.name.startswith('timing-'):
            continue

        if prev is not None:
            if child.unit_address is None:
                if prev.unit_address is None:
                    if child.name < prev.name:
                        print('ERROR: %s: %s < %s' % (filename, child, prev))
            else:
                if prev.unit_address is not None:
                    if child.unit_address < prev.unit_address:
                        if prev.name == 'memory' and prev.unit_address == 0x80000000:
                            if False:
                                print('WARNING: %s: %s < %s' % (filename, child, prev))
                        else:
                            print('ERROR: %s: %s < %s' % (filename, child, prev))
                else:
                    if prev.name not in [ 'aliases', 'chosen', 'firmware', 'reserved-memory' ]:
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
        print('parsing %s...' % filename)
        #ast = devicetree.DeviceTree.parseString(dts, parseAll = True)
        #ast = devicetree.DeviceTree.parseFile(filename, parseAll = True)
        ast = devicetree.load(filename)
        #ast.pprint()

        if False:
            for node in ast:
                if isinstance(node, devicetree.Node):
                    dump_node(node)

        if True:
            #print('checking %s...' % filename)

            for node in ast:
                if isinstance(node, devicetree.Node):
                    check_node(filename, node)

except pp.ParseException as e:
    print(e.line)
    print(' ' * (e.column - 1) + '^')
    print(e)

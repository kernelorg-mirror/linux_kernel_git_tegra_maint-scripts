#!/usr/bin/python

import pyparsing as pp, subprocess

pp.ParserElement.enablePackrat()

source_position = pp.Literal('#') + pp.pyparsing_common.integer('line_number') + \
        pp.dbl_quoted_string('filename') + pp.Opt(pp.pyparsing_common.integer)

node_name = pp.Word(pp.alphanums + ',.-+_') ^ pp.Literal('/')
unit_address = pp.delimited_list(pp.pyparsing_common.hex_integer, combine = True)
node_handle = node_name('name') + pp.Opt(pp.Literal('@') + unit_address('address'))

property_name = pp.Word(pp.alphanums + ',.-_+?#')

label = pp.Word(pp.alphanums + '_').setResultsName('label')
label_creation = pp.Combine(label + pp.Literal(':'))

node_path = pp.Combine(pp.Literal('/') + pp.delimitedList(node_handle, delim = '/', combine = True))
node_path.set_results_name('path')

label_reference = pp.Literal('&').suppress() + label
path_reference = pp.Literal('&{').suppress() + node_path + pp.Literal('}').suppress()
reference = label_reference ^ path_reference

integer_suffix = pp.Literal('U') ^ pp.Literal('L') ^ pp.Literal('UL')
integer = (pp.pyparsing_common.integer ^ (pp.Literal('0x').suppress() + pp.pyparsing_common.hex_integer)) + \
        pp.Opt(integer_suffix.suppress())

operator = pp.oneOf('~ ! * / + - << >> < <= > >= == != & ^ | && ||')
arith_expr = pp.Forward()
ternary_element = arith_expr ^ integer
ternary_expr = ternary_element + pp.Literal('?') + ternary_element + pp.Literal(':') + ternary_element
arith_expr << pp.nestedExpr(content = (pp.OneOrMore(operator ^ integer) ^ ternary_expr))

cell_array = pp.Literal('<').suppress() + \
        pp.ZeroOrMore(integer ^ reference ^ arith_expr) + \
        pp.Literal('>').suppress()
hexbyte = pp.Word(pp.hexnums, exact = 2)
hexbyte.set_name('hex byte')
hexbyte.set_parse_action(pp.token_map(int, 16))
bytestring = pp.Literal('[').suppress() + \
        (pp.OneOrMore(hexbyte ^ label_creation.suppress())) + \
        pp.Literal(']').suppress()

include_directive = pp.Literal('/include/') + pp.dbl_quoted_string
bits_directive = pp.Literal('/bits/') + pp.pyparsing_common.integer + cell_array
generic_directive = pp.QuotedString(quoteChar = '/', unquoteResults = False) + \
        pp.Opt(pp.dbl_quoted_string ^ property_name ^ node_handle ^ reference) + \
        pp.Literal(';').suppress()
property_directive = include_directive ^ bits_directive
directive = include_directive ^ bits_directive ^ generic_directive

stringlist = pp.delimited_list(pp.dbl_quoted_string)

property_values = pp.Forward()
property_values << pp.delimitedList(cell_array ^ stringlist ^ reference ^ property_directive ^ bytestring)
property_assignment = property_name('name') + pp.Opt(pp.Literal('=').suppress() + \
        property_values).setResultsName('value') + pp.Literal(';').suppress()

node_opener = pp.Opt(label_creation) + node_handle + pp.Literal('{').suppress()
node_reference_opener = reference + pp.Literal('{').suppress()
node_closer = pp.Literal('}').suppress() + pp.Literal(';').suppress()
node_definition = pp.Forward()
node_definition << (node_opener ^ node_reference_opener) + \
        pp.ZeroOrMore(property_assignment ^ directive ^ node_definition ^ source_position) + \
        node_closer

class Property:
    def __init__(self, name, value):
        self.name = name
        self.value = value

    def __str__(self):
        return 'Property: %s = %s' % (self.name, self.value)

class Directive:
    def __init__(self, name):
        self.name = name

    def __str__(self):
        return 'Directive: %s' % self.name

class Node:
    def __init__(self, name, address, properties = None, children = None):
        self.name = name
        self.properties = properties
        self.children = children

        if address:
            self.unit_address = 0

            for cell in address.split(','):
                self.unit_address = (self.unit_address << 32) + int(cell)
        else:
            self.unit_address = None

    def __str__(self):
        if self.unit_address is not None:
            unit_address = self.unit_address
            cells = []

            while True:
                cells.append(unit_address & 0xffffffff)
                unit_address >>= 32

                if unit_address == 0:
                    break

            unit_address = ','.join([ '%x' % x for x in reversed(cells) ])

            return '%s@%s' % (self.name, unit_address)
        else:
            return '%s' % self.name

class Reference:
    def __init__(self, name):
        self.name = name

    def __repr__(self):
        return '&' + self.name

    def __str__(self):
        return 'Reference: %s' % self.name

class SourcePosition:
    def __init__(self, filename, line):
        self.filename = filename
        self.line = line

    def __str__(self):
        return 'SourcePosition: %s, %s' % (self.filename, self.line)

def transform_source_position(string, location, tokens):
    #print('source position: location: %s, tokens: %s' % (location, tokens))

    return SourcePosition(tokens.filename, tokens.line_number)

def transform_directive(string, location, tokens):
    #print('directive: location: %s, tokens: %s' % (location, tokens))

    return Directive(tokens[0])

def transform_node(string, location, tokens):
    #print('node: location:', location, 'tokens:', tokens)

    properties = [ e for e in tokens.asList() if isinstance(e, Property) ]
    directives = [ e for e in tokens.asList() if isinstance(e, Directive) ]
    children = [ e for e in tokens.asList() if isinstance(e, Node) ]

    #print('properties:', properties, 'directives:', directives, 'children:', children)
    return Node(tokens.name, tokens.address, properties = properties, children = children)

def fail_node(string, location, expression, error):
    print()
    print('FAIL: node: error:', error)
    print()

def transform_property_assignment(string, location, tokens):
    #print('property: location:', location, 'tokens:', tokens)

    return Property(tokens.name, tokens.value)

def transform_reference(string, location, tokens):
    #print('reference: location:', location, 'tokens:', tokens)

    return Reference(tokens[0])

source_position.setParseAction(transform_source_position)
directive.setParseAction(transform_directive)
node_definition.setParseAction(transform_node)
#node_definition.setFailAction(fail_node)
property_assignment.setParseAction(transform_property_assignment)
reference.setParseAction(transform_reference)

DeviceTree = pp.ZeroOrMore(source_position ^ directive ^ node_definition)
#DeviceTree.ignore(pp.cStyleComment)
#DeviceTree.ignore('//' + pp.SkipTo(pp.lineEnd))
#DeviceTree.ignore('#include' + pp.SkipTo(pp.lineEnd))
#DeviceTree.set_debug()
pp.enable_all_warnings()

def compile(filename):
    preprocess = [ 'gcc', '-E', '-I', 'scripts/dtc/include-prefixes', '-nostdinc', '-undef',
                   '-D__DTS__', '-x', 'assembler-with-cpp', filename ]
    result = subprocess.run(preprocess, capture_output = True, text = True)

    if result.returncode != 0:
        raise Exception(result.stderr)

    #lines = []

    #for line in result.stdout.splitlines():
    #    if line.startswith('#'):
    #        continue

    #    lines.append(line)

    #return '\n'.join(lines)
    return result.stdout

def parent_nodes(tree, parent = None):
    for item in tree:
        if isinstance(item, Node):
            item.parent = parent
            parent_nodes(item.children, item)

def load(filename):
    dts = compile(filename)

    ast = DeviceTree.parse_string(dts, parseAll = True)
    parent_nodes(ast)

    return ast

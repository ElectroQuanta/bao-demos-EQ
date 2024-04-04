import sys
import fdt

class DeviceTreeNode:
    def __init__(self, name, properties=None):
        self.name = name
        self.properties = properties or {}
        self.children = []

def build_tree(node):
    tree_node = DeviceTreeNode(node.name, node.props)
    for child in node.subnodes:
        tree_node.children.append(build_tree(child))
    return tree_node

def print_tree(node, indent=0):
    print(' ' * indent + node.name)
    for prop_name, prop_value in node.properties.items():
        print(' ' * (indent + 2), prop_name, '=', prop_value)
    for child in node.children:
        print_tree(child, indent + 2)

def parse_device_tree(dtb_file):
    with open(dtb_file, 'rb') as f:
        dtb_blob = f.read()
    dtb = fdt.parse_dtb(dtb_blob)
    dtb_parsed = dtb.to_fdt()
    return build_tree(dtb_parsed)

# Example usage
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <dtb_file>")
        sys.exit(1)

    dtb_file = sys.argv[1]
    parsed_tree = parse_device_tree(dtb_file)
    print_tree(parsed_tree)

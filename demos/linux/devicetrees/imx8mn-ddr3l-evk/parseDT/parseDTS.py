class DeviceTreeNode:
    def __init__(self, name):
        self.name = name
        self.properties = {}
        self.children = []

def parse_device_tree(dts_file):
    with open(dts_file, 'r') as f:
        dts_content = f.readlines()
    root = DeviceTreeNode("root")
    current_node = root
    for line in dts_content:
        line = line.strip()
        if line.endswith("{"):
            # Start of a new node
            node_name = line.split()[0]
            new_node = DeviceTreeNode(node_name)
            current_node.children.append(new_node)
            current_node = new_node
        elif line == "};":
            # End of current node
            current_node = current_node.parent
        else:
            # Property line
            if line.endswith(";"):
                line = line[:-1]  # Remove the semicolon
            prop_name, prop_value = line.split(" = ")
            current_node.properties[prop_name.strip()] = prop_value.strip()
    return root

def print_device_tree(node, indent=0):
    print(' ' * indent, node.name)
    for prop_name, prop_value in node.properties.items():
        print(' ' * (indent + 2), prop_name, '=', prop_value)
    for child in node.children:
        print_device_tree(child, indent + 4)

# Example usage
if __name__ == "__main__":
    dts_file = 'linux-6.1.55-OPTIMAL.dts'
    parsed_tree = parse_device_tree(dts_file)
    print_device_tree(parsed_tree)

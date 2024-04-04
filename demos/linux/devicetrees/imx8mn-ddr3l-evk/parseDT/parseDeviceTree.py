import sys
from pydevicetree import Devicetree

# Example usage
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <dts_file>")
        sys.exit(1)
    
    # dtb_file = sys.argv[1]
    dts_file = sys.argv[1]
    tree = Devicetree.parseFile(dts_file)
    tree

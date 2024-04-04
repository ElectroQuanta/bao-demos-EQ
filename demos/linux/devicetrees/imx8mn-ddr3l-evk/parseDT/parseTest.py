import sys
import fdt
# import os
#
# def split_filename(filepath):
#     path, filename = os.path.split(filepath)
#     filename, extension = os.path.splitext(filename)
#     return path, filename, extension

# -----------------------------------------------
# convert *.dtb to *.dts
# ----------------------------------------------
def dtb2dts(dtb_file, dts_file):
    with open(dtb_file, "rb") as f:
        dtb_data = f.read()

    dt1 = fdt.parse_dtb(dtb_data)
    #print(dt1.info())
    g = dt1.walk(dt1.root.path)
    l = list(dt1.walk(dt1.root.path))
    for i in range(5):
        nodeItem = l.pop()
        n = dt1.get_node(nodeItem[0])

    for nodeI in g:
        print(nodeI)
       #  print(n)
        p_interrupts = n.get_property("interrupts")


    next(g)
    for nodeI in g:
        print(nodeI)
        print("\n")



    with open(dts_file, "w") as f:
        f.write(dt1.to_dts())

# Example usage
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <dtb_file> <dts_file>")
        sys.exit(1)
    
    # dtb_file = sys.argv[1]
    dtb2dts(sys.argv[1], sys.argv[2])

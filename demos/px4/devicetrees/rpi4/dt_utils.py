"""
Calculate the interrupt value based on the type of interrupt.
val: value shown in the dts
ppi: 0 (SPI); 1 (PPI)
returns the interrupt value
"""
def calc_int(val, ppi):
    val = val + 16
    if ppi == 0:
        val = val + 16
    return val


"""
Calculate the physical address of the device tree.
va: virtual address
va_start: initial virtual address of the containing region
pa_start: initial physical address of the mapped region
pa: returned
"""
def calc_pa(va, va_start, pa_start):
    return hex(((va - va_start) + pa_start))

"""
Calculate the size in GB
1 byte = 8 bits
1 KB = 2^10 = 1024 bytes
1 MB = (2^10)^2 = 1024 ^ 2
1 GB = (2^10)^3 = 1024 ^ 3
"""
def size_MB(val):
    return (val / (1024 ** 2))


def mem_region(st_addr, sz):
    end_addr = st_addr + sz - 1
    return {
        "start_address": hex(st_addr),
        "end_address": hex(end_addr),
        "size": hex(sz)
    }

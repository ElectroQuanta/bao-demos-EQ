"""Utils for device tree and VM's calculations."""


def calc_int(val, ppi):
    """Calculate the interrupt value based on the type of interrupt.

    val: value shown in the dts
    ppi: 0 (SPI); 1 (PPI)
    returns the interrupt value
    """
    val = val + 16
    if ppi == 0:
        val = val + 16
    return val


def calc_pa(va, va_start, pa_start):
    """Calculate the physical address of the device tree.

    va: virtual address
    va_start: initial virtual address of the containing region
    pa_start: initial physical address of the mapped region
    pa: returned
    """
    return hex(((va - va_start) + pa_start))


def size_MB(val):
    """Calculate the size in MB.

    1 byte = 8 bits
    1 KB = 2^10 = 1024 bytes
    1 MB = (2^10)^2 = 1024 ^ 2
    1 GB = (2^10)^3 = 1024 ^ 3
    """
    return (val / (1024 ** 2))


def mem_region(st_addr, sz):
    """Calculate mem region from start address and size.

    Parameters
    ----------
    st_addr: Start address
    sz: size

    Returns
    ----------
    start_address: in hex
    end_address: in hex
    size: in hex
    """
    end_addr = st_addr + sz - 1
    return {
        "start_address": hex(st_addr),
        "end_address": hex(end_addr),
        "size": hex(sz)
    }


def calc_vm_mem_regions(bao_size_MB, px4_mem_size_MB):
    """Calculate VM memory regions.

    bao_size_MB: bao size in MB
    PX4_size_MB: PX4 size in MB
    """
    # bao_size_MB = 180
    # px4_mem_size_MB = 152
    bao_load_addr = 0x8_0000
    mem_end = 0x3b40_0000
    bao_size = bao_size_MB * 1024 * 1024 - bao_load_addr
    bao_end = bao_load_addr + bao_size
    mem_avail = mem_end - bao_end
    px4_size = px4_mem_size_MB * 1024 * 1024

    print(f"Mem avail (MB): {size_MB(mem_avail)}")
    region = mem_region(bao_end, px4_size)
    print(f"PX4: RAM (MB): {px4_mem_size_MB}")
    print(region)
    print(f"Cam: RAM (MB): {size_MB(mem_avail - px4_size)}")
    region = mem_region(bao_end + px4_size, mem_avail - px4_size)
    print(region)


calc_vm_mem_regions(188, 136)

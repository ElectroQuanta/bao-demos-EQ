#include <config.h>

VM_IMAGE(vm1, XSTR(BAO_DEMOS_WRKDIR_IMGS/linux.bin))
//#define VM1_ENTRY 0x80000000
#define RPI4_MEM_GB_CFG 8
#define VM1_ENTRY     0x20000000ULL
#define VM1_MEM1_BASE 0x00080000ULL
#define VM1_MEM2_BASE 0x40000000ULL
#define VM1_MEM1_SIZE (VM1_MEM2_BASE - VM1_MEM1_BASE - 0x4c00000ULL)
//#define VM1_MEM2_SIZE (((RPI4_MEM_GB_CFG-1) * 0x40000000ULL) - 0x4000000ULL)
#define VM1_MEM2_SIZE 0x80000000ULL

struct config config = {
    
    CONFIG_HEADER /**< Legacy: not required anymore */

 //   .shmemlist_size = 1,
 //   .shmemlist = (struct shmem[]) {
 //       [0] = { .size = 0x00010000, }
 //   },
    
    .vmlist_size = 1,
    //.vmlist = (struct vm_config[])
    .vmlist =
	{
/**< VM1 */
	  {
            //.image = VM_IMAGE_BUILTIN(vm1, VM1_ENTRY),

            .image = {
                .base_addr = VM1_ENTRY,
                .load_addr = VM_IMAGE_OFFSET(vm1),
                .size = VM_IMAGE_SIZE(vm1)
            },

            .entry = VM1_ENTRY,


            .platform = {
                .cpu_num = 4,
                
                //.region_num = 3,
                .region_num = 3,
                .regions =  (struct vm_mem_region[]) {
                    //{
                    //    .base = 0x0,
                    //    .size = 0x3b400000,
                    //    .place_phys = true,
                    //    .phys = 0x0
                    //},
                    //{
                    //    .base = 0x40000000,
                    //    .size = 0xbc000000,
                    //    .place_phys = true,
                    //    .phys = 0x40000000
                    //},
                    //{
                    //    .base = 0x100000000,
                    //    .size = 0x80000000,
                    //    .place_phys = true,
                    //    .phys = 0x100000000,
                    //},
                    {
                        .base = VM1_MEM1_BASE,
                        .size = VM1_MEM1_SIZE,
                        .place_phys = true,
                        .phys = VM1_MEM1_BASE
                    },
                    {
                        .base = 0x40000000,
                        .size = 0xbc000000,
                        .place_phys = true,
                        .phys = 0x40000000
                    },
                    {
                        .base = 0x100000000,
                        .size = 0x80000000,
                        .place_phys = true,
                        .phys = 0x100000000,
                    },
                    //{
                    //    .base = VM1_MEM2_BASE,
                    //    .size = VM1_MEM2_SIZE,
                    //    .place_phys = true,
                    //    .phys = VM1_MEM2_BASE
                    //},
                },

              // .ipc_num = 1,
              //  .ipcs = (struct ipc[]) {
              //      {
              //          .base = 0xf0000000,
              //          .size = 0x00010000,
              //          .shmem_id = 0,
              //          .interrupt_num = 1,
              //          .interrupts = (irqid_t[]) {52}
              //      }
              //  },

                //.dev_num = 17,
                .dev_num = 17,
                .devs =  (struct vm_dev_region[]) {
/**< Arch timer */
                    {   
                        .interrupt_num = 1,
                        .interrupts = 
						(irqid_t[]) {27}                         
                    },
/**< Ethernet controller */
                    {
                        /* GENET */
                        .pa = 0xfd580000,
                        .va = 0xfd580000,
                        .size = 0x10000,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[]) {189, 190}  
                    },
/**< UART 5 (ttyAMA5) */
                    {
                        .pa = 0xfe201a00,
                        .va = 0xfe201a00,
                        .size = 0x200,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {153}  
                    },
/**< Clock manager (cprman) */
                    {
                        .pa = 0xfe101000,
                        .va = 0xfe101000,
                        .size = 0x2000,
                    },
/**< DSI0 (clock source) */
                    {
                        .pa = 0xfe209000,
                        .va = 0xfe209000,
                        .size = 0x78,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {132}  
                    },
/**< DSI1 (clock source) */
                    {
                        .pa = 0xfe700000,
                        .va = 0xfe700000,
                        .size = 0x8c,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {140}  
                    },
/**< Mailbox (required for firmware) */
                    {
                        .pa = 0xfe00b880,
                        .va = 0xfe00b880,
                        .size = 0x40,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {65}  
                    },
/**< GPIO controller */
                    {
                        .pa = 0xfe200000,
                        .va = 0xfe200000,
                        .size = 0xb4,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[]) {145, 146}  
                    },
/**< UART 0 (ttyAMA0) */
                    {
                        .pa = 0xfe201000,
                        .va = 0xfe201000,
                        .size = 0x200,
                   //     .interrupt_num = 1,
                   //     .interrupts = (irqid_t[]) {153}  
                    },
/**< aux (Auxiliary clock) */
                    {
                        .pa = 0xfe215000,
                        .va = 0xfe215000,
                        .size = 0x08,
                    },
/**< spi1 (ttySC0, ttySC1) */
                    {
                        .pa = 0xfe215080,
                        .va = 0xfe215080,
                        .size = 0x40,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {125}  
                    },
/**< spi0 (spidev) */
                    {
                        .pa = 0xfe204000,
                        .va = 0xfe204000,
                        .size = 0x200,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {150}  
                    },
/**< dma (dma-controller) */
                    {
                        .pa = 0xfe007000,
                        .va = 0xfe007000,
                        .size = 0xb00,
                    },
/**< i2c_arm */
                    {
                        .pa = 0xfe804000,
                        .va = 0xfe804000,
                        .size = 0x1000,
                   //     .interrupt_num = 1,
                   //     .interrupts = (irqid_t[]) {149}  
                    },
/**< i2c0if */
                    {
                        .pa = 0xfe205000,
                        .va = 0xfe205000,
                        .size = 0x200,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {149}  
                    },
/**< csi1-1 (camera) */
                    {
                        .pa = 0xfe801000,
                        .va = 0xfe801000,
                        .size = 0x800,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {135}  
                    },
/**< csi1-2 (camera) */
                    {
                        .pa = 0xfe802004,
                        .va = 0xfe802004,
                        .size = 0x04,
                  //      .interrupt_num = 1,
                  //      .interrupts = (irqid_t[]) {135}  
                    },

/**< Devices end */
                },

                .arch = {
                    .gic = {
                        .gicd_addr = 0xff841000,
                        .gicc_addr = 0xff842000,
                    }
                }
            },
	  },
	}
};

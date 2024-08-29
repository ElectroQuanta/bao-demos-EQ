#include <config.h>

VM_IMAGE(linux_image, XSTR(BAO_DEMOS_WRKDIR_IMGS/linux.bin));
#define LINUX_IMG_ENTRY 0x20000000

struct config config = {
    
//    CONFIG_HEADER /**< Legacy: not required anymore */

 //   .shmemlist_size = 1,
 //   .shmemlist = (struct shmem[]) {
 //       [0] = { .size = 0x00010000, }
 //   },
    
    .vmlist_size = 1,
    .vmlist = {
        { 
            .image = VM_IMAGE_BUILTIN(linux_image, LINUX_IMG_ENTRY),

            .entry = LINUX_IMG_ENTRY,

            .platform = {
                .cpu_num = 4,
                
                .region_num = 3,
                .regions =  (struct vm_mem_region[]) {
                    {
                        .base = 0x0,
                        .size = 0x3b400000,
                        .place_phys = true,
                        .phys = 0x0
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
                        .phys = 0x40000000
                    },
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

                .dev_num = 3,
                .devs =  (struct vm_dev_region[]) {
                    {
                        /* GENET */
                        .pa = 0xfd580000,
                        .va = 0xfd580000,
                        .size = 0x10000,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[]) {189, 190}  
                    },
/**< Arch timer */
                    {   
                        /* Arch timer interrupt */
                        .interrupt_num = 1,
                        .interrupts = 
                            (irqid_t[]) {27}                         
                    },
/**< UART 1 */
                    {
                        .pa = 0x7e215040,
                        .va = 0x7e215040,
                        .size = 0x40,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {125}  
                    },
                },

                .arch = {
                    .gic = {
                        //.gicd_addr = 0xff841000,
                        //.gicd_addr = 0xff841000,
                        .gicc_addr = 0x40041000,
                        .gicd_addr = 0x40042000,
                    }
                }
            },
        },
    },
};

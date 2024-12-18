#include <config.h>

VM_IMAGE(linux_image, XSTR(BAO_DEMOS_WRKDIR_IMGS/linux.bin));
//#define VM_MEM1_BASE  0x40000000ULL
//#define VM_MEM1_SIZE  0x40000000ULL
#define VM_MEM1_BASE  0x09000000ULL
//#define VM_MEM1_SIZE  0x20000000ULL
#define VM_MEM1_SIZE  0x0b000000ULL
#define VM_MEM2_BASE  0x40000000ULL
#define VM_MEM2_SIZE  0xbc000000ULL

struct config config = {

    .vmlist_size = 1,
    .vmlist = {{//.image = {.base_addr = VM_MEM1_BASE,
                //          .load_addr = VM_IMAGE_OFFSET(linux_image),
                //          .size = VM_IMAGE_SIZE(linux_image)},

                .image = VM_IMAGE_BUILTIN(linux_image, VM_MEM1_BASE),

                .entry = VM_MEM1_BASE,

                .platform = {.cpu_num = 1,

                             .region_num = 2,
                             .regions = (struct vm_mem_region[]){
                                 {.base = VM_MEM1_BASE,
                                  .size = VM_MEM1_SIZE,
                                  .place_phys = true,
                                  .phys = VM_MEM1_BASE},
                                 {.base = VM_MEM2_BASE,
                                  .size = VM_MEM2_SIZE,
                                  .place_phys = true,
                                  .phys = VM_MEM2_BASE}
                                 },

                    /* .ipc_num = 1, */
                    /*  .ipcs = (struct ipc[]) { */
                    /*      { */
                    /*          .base = 0xf0000000, */
                    /*          .size = 0x00010000, */
                    /*          .shmem_id = 0, */
                    /*          .interrupt_num = 1, */
                    /*          .interrupts = (irqid_t[]) {52} */
                    /*      } */
                    /*  }, */

                    .dev_num = 9,
                    .devs = (struct vm_dev_region[]){
                        /**< Arch timer interrupt */
                        {.interrupt_num = 1, .interrupts = (irqid_t[]){27}},
                        /**< UARTs {0,2-5} (ttyAMA0, ttyAMA5) */
                        {.pa = 0xfe201000,
                         .va = 0xfe201000,
                         .size = 0x1000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[]){153}},
                        /**< Clock manager (cprman) */
                        {
                            .pa = 0xfe101000,
                            .va = 0xfe101000,
                            .size = 0x2000,
                        },

                        /**< Mailbox (required for firmware) */
                        {//.pa = 0xfe00b880,
                         //.va = 0xfe00b880,
                         .pa = 0xfe00b000,
                         .va = 0xfe00b000,
                         .size = 0x1000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[]){65}},

                        /**< GPIO controller */
                        {.pa = 0xfe200000,
                         .va = 0xfe200000,
                         //.size = 0xb4,
                         .size = 0x1000,
                         .interrupt_num = 2,
                         .interrupts = (irqid_t[]){145, 146}},

                        /**< SPI1 (ttySC0, ttySC1) and (aux) */
                        {.pa = 0xfe215000,
                         .va = 0xfe215000,
                         .size = 0x1000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[]){125}},

                        /**< spi0 (spidev) */
                        {.pa = 0xfe204000,
                         .va = 0xfe204000,
                         .size = 0x1000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[]){150}},

                        /**< dma (dma-controller) */
                        {.pa = 0xfe007000,
                         .va = 0xfe007000,
                         .size = 0x1000,
                         .interrupt_num = 9,
                         .interrupts = (irqid_t[]){112, 113, 114, 115, 116, 117,
                                                   118, 119, 120}},
                        /**< i2c_arm (i2c1) */
                        {.pa = 0xfe804000,
                         .va = 0xfe804000,
                         .size = 0x1000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[]){149}},
		},

		.arch = {
		  .gic = {
			.gicd_addr = 0xff841000,
			.gicc_addr = 0xff842000,
		  }
		}
	  },
	}, /**< End VM1 */
  }, /**< End vm_list */
}; /**< End config */

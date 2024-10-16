#include <config.h>

VM_IMAGE(vm1, XSTR(BAO_DEMOS_WRKDIR_IMGS/linux.bin))
//#define VM1_ENTRY 0x80000000
#define RPI4_MEM_GB_CFG 8
//#define VM1_ENTRY     0x20000000ULL
//#define VM1_MEM1_BASE 0x00080000ULL
//#define VM1_MEM2_BASE 0x40000000ULL
//#define VM1_MEM1_SIZE (VM1_MEM2_BASE - VM1_MEM1_BASE - 0x4c00000ULL)
////#define VM1_MEM2_SIZE (((RPI4_MEM_GB_CFG-1) * 0x40000000ULL) - 0x4000000ULL)
//#define VM1_MEM2_SIZE 0x80000000ULL

#define VM1_ENTRY     0x200000ULL
#define VM1_MEM1_BASE VM1_ENTRY
#define VM1_MEM1_SIZE 0x20000000ULL

struct config config = {

    .vmlist_size = 1,
    .vmlist = {/**< VM1 */
               {.image = VM_IMAGE_BUILTIN(vm1, VM1_ENTRY),

                .entry = VM1_ENTRY,

                .platform = {

		  .cpu_num = 4,

		  .region_num = 1,
		  .regions = (struct vm_mem_region[]){
		    {
		      .base = VM1_MEM1_BASE,
		      .size = VM1_MEM1_SIZE,
		      .place_phys = false,
		      .phys = VM1_MEM1_BASE},
		  },


                .dev_num = 6,
                .devs =  (struct vm_dev_region[]) {
/**< Arch timer */
		  {   
		    .interrupt_num = 1,
		    .interrupts = 
		    (irqid_t[]) {27}                         
                    },
/**< UART 5 (ttyAMA5) */
                    {
                        .pa = 0xfe201000,
                        .va = 0xfe201000,
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
/**< GPIO controller */
                    {
                        .pa = 0xfe200000,
                        .va = 0xfe200000,
                        .size = 0xb4,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[]) {145, 146}  
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
// /**< UART 0 (ttyAMA0) */
//                     {
//                         .pa = 0xfe201000,
//                         .va = 0xfe201000,
//                         .size = 0x200,
//                    //     .interrupt_num = 1,
//                    //     .interrupts = (irqid_t[]) {153}
//                     },
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

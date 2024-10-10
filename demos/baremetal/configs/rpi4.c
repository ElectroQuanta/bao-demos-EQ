#include <config.h>

VM_IMAGE(baremetal_image, XSTR(BAO_DEMOS_WRKDIR_IMGS/baremetal.bin));

#define VM1_BASE_ADDR      0x200000ULL
#define VM1_MEM_BASE_ADDR  0x080000ULL

struct config config = {
    
//    CONFIG_HEADER
    
    .vmlist_size = 1,
    .vmlist = {
	  { 
	  //.image = {
	  //    .base_addr = 0x200000,
	  //    .load_addr = VM_IMAGE_OFFSET(baremetal_image),
	  //    .size = VM_IMAGE_SIZE(baremetal_image)
	  //},

            .image = VM_IMAGE_BUILTIN(baremetal_image, VM1_BASE_ADDR),


            .entry = VM1_BASE_ADDR,

            .platform = {
                .cpu_num = 4,
                
                .region_num = 1,
                .regions =  (struct vm_mem_region[]) {
                    {
                        .base = VM1_BASE_ADDR,
                        .size = 0x4000000 
                    }
                },

                .dev_num = 2,
                .devs =  (struct vm_dev_region[]) {
		  //                    {   
		  //                        /* UART1 */
		  //                        .pa = 0xfe215000,
		  //                        .va = 0xfe215000,
		  //                        .size = 0x1000,
		  //                        .interrupt_num = 1,
		  //                        .interrupts = (irqid_t[]) {125}                        
		  //                    },
/**< UART 5 (ttyAMA5) */
                    {
                        .pa = 0xfe201000,
                        .va = 0xfe201000,
                        .size = 0x200,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {153}  
                    },
                    {   
                        /* Arch timer interrupt */
                        .interrupt_num = 1,
                        .interrupts = 
                            (irqid_t[]) {27}                         
                    }
                },

                .arch = {
                    .gic = {
                        .gicd_addr = 0xff841000,
                        .gicc_addr = 0xff842000,
                    }
                }
            },
        }
    },
};

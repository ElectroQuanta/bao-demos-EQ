#include <config.h>

VM_IMAGE(baremetal_image, XSTR(BAO_DEMOS_WRKDIR_IMGS/baremetal.bin));
//#define BAO_ENTRY_ADDR 0x200000

/**< Macros to calculate interrupts number */
#define ADD_NRS(a, b) ((a) + (b))
#define GIC_PPI_VAL(x) ADD_NRS(x, 16)
#define GIC_SPI_VAL(x) ADD_NRS(x, 32)

#define RAM1_ADDR 0x80000000U
#define RAM1_SIZE 0x80000000U
#define RAM2_ADDR 0x880000000ULL
#define RAM2_SIZE 0x80000000U

#define CPU_NUM 2 /**< Dual-core A72 processor */

#define UBOOT_ADDR (RAM_ADDR + 0x80000)
#define UBOOT_FIT_ADDR 0x90000000
//#define BAO_ENTRY_ADDR 0xA0000000
#define BAO_ENTRY_ADDR RAM1_ADDR

// https://github.com/torvalds/linux/raw/master/arch/arm64/boot/dts/ti/k3-j721e.dtsi
// a72_timer0: timer-cl0-cpu0 {
// 	compatible = "arm,armv8-timer";
// 	interrupts = <GIC_PPI 13 IRQ_TYPE_LEVEL_LOW>, /* cntpsirq */
// 		     <GIC_PPI 14 IRQ_TYPE_LEVEL_LOW>, /* cntpnsirq */
// 		     <GIC_PPI 11 IRQ_TYPE_LEVEL_LOW>, /* cntvirq */
// 		     <GIC_PPI 10 IRQ_TYPE_LEVEL_LOW>; /* cnthpirq */
// };
#define TIMER_VIRQ_GIC_PPI 11
#define TIMER_INTERRUPT (GIC_PPI_VAL(TIMER_VIRQ_GIC_PPI))


/**< UART0 (see k3-j721e-main.dtsi)*/
// main_uart0: serial@2800000 {
// 	compatible = "ti,j721e-uart", "ti,am654-uart";
// 	reg = <0x00 0x02800000 0x00 0x100>;
// 	interrupts = <GIC_SPI 192 IRQ_TYPE_LEVEL_HIGH>;
#define UART0_ADDR 0x2800000 /**< main_uart0: serial@2800000 (main.dtsi) */
#define UART0_GIC_SPI 192
#define UART0_INTERRUPT (GIC_SPI_VAL(UART0_GIC_SPI))

struct config config = {
    
    CONFIG_HEADER
    
    .vmlist_size = 1,
    .vmlist = {
        { 
            .image = {
                .base_addr = BAO_ENTRY_ADDR,
                .load_addr = VM_IMAGE_OFFSET(baremetal_image),
                .size = VM_IMAGE_SIZE(baremetal_image)
            },

            .entry = BAO_ENTRY_ADDR,

            .platform = {
                .cpu_num = CPU_NUM,
                
                .region_num = 2,
                .regions =  (struct vm_mem_region[]) {
                    {
                        .base = RAM1_ADDR,
                        .size = RAM1_SIZE
                    },
                    {
                        .base = RAM2_ADDR,
                        .size = RAM2_SIZE
                    },
                    
                },

                .dev_num = 2,
                .devs =  (struct vm_dev_region[]) {
                    {   
                        .pa = UART0_ADDR,
                        .va = UART0_ADDR,
                        .size = 0x100,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {UART0_INTERRUPT}
                    },
                    {
                        /**< Arch timer interrupt (see k3-j721e-main.dtsi)*/
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {TIMER_INTERRUPT}
                    }
                },

                .arch = {
                    .gic = {
                        .gicd_addr = 0x01800000,
                        .gicr_addr = 0x01900000,
                        .gicc_addr = 0x6f000000
                        //.interrupt_num = 1,
//                        .gich_addr = 0x6f010000,
//                        .gicv_addr = 0x6f020000,
                    }
                }
            },
        }
    },
};

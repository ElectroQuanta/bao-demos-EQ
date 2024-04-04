#include <config.h>

/**
 * Declare VM images using the VM_IMAGE macro, passing an identifier and the
 * path for the image.
 */
VM_IMAGE(linux_image, XSTR(BAO_DEMOS_WRKDIR_IMGS/linux.bin));
VM_IMAGE(freertos_image, XSTR(BAO_DEMOS_WRKDIR_IMGS/freertos.bin));

/**< Macros to calculate interrupts number */
#define ADD_NRS(a, b) ((a) + (b))
#define GIC_PPI_VAL(x) ADD_NRS(x, 16)
#define GIC_SPI_VAL(x) ADD_NRS(x, 32)


/**
 * Configuration defines
 */
/**< See memory@40000000 in @devicetrees/$PLATFORM/linux.dts */
#define LINUX_BASE_ADDR (0x40000000)
#define UBOOT_BASE_ADDR (0x40200000)
#define FREERTOS_BASE_ADDR (0x0)
#define FREERTOS_RAM_SIZE (0x8000000)
#define LINUX_CPU_NUM (3)
#define FREERTOS_CPU_NUM (1)
#define LINUX_RAM_BASE_ADDR (LINUX_BASE_ADDR)
#define LINUX_RAM_SIZE (0x30000000) // 750 MB
/**< See bao-ipc@f0000000 in @devicetrees/$PLATFORM/linux.dts */
#define BAO_IPC_ADDR (0xF0000000)
#define BAO_IPC_SIZE (0x00010000)
#define BAO_IPC_INTERRUPT_ID (52)
#define SHMEM_SIZE (BAO_IPC_SIZE)
/**< GIC: See interrupt-controller@38800000 in @devicetrees/$PLATFORM/linux.dts */
#define LINUX_GICD_ADDR (0x38800000)
#define LINUX_GICR_ADDR (0x38880000)
/**< FreeRTOS GIC is statically defined */
#define FREERTOS_GICD_ADDR (0xF9010000)
#define FREERTOS_GICD_ADDR (0xF9020000)
/**< Arm arch timer */
#define TIMER_VIRQ_GIC_PPI 11
#define ARCH_TIMER_INTERRUPT_ARM (GIC_PPI_VAL(TIMER_VIRQ_GIC_PPI))

/**< Ethernet ctrl: See ethernet@30be0000 in @devicetrees/$PLATFORM/linux.dts */
// ethernet@30be0000 {
// 	reg = <0x30be0000 0x10000>;
// 	interrupts = <0x00 0x76 0x04 0x00 0x77 0x04 0x00 0x78 0x04 0x00 0x79 0x04>;
// 	clocks = <0x02 0x8b 0x02 0x8b 0x02 0x63 0x02 0x62 0x02 0x64>;
// 	clock-names = "ipg\0ahb\0ptp\0enet_clk_ref\0enet_out";
// };
#define ETHERNET_CTRL_ADDR (0x30be0000)
#define ETHERNET_CTRL_SIZE (0x00010000)
#define ETHERNET_CTRL_INTERRUPT_NUM (4)
#define ETHERNET_CTRL_INTERRUPT1 (GIC_SPI_VAL(118)) // GIC_SPI_VAL(0x76) 
#define ETHERNET_CTRL_INTERRUPT2 (GIC_SPI_VAL(119)) // GIC_SPI_VAL(0x77)
#define ETHERNET_CTRL_INTERRUPT3 (GIC_SPI_VAL(120)) // GIC_SPI_VAL(0x78)
#define ETHERNET_CTRL_INTERRUPT4 (GIC_SPI_VAL(121)) // GIC_SPI_VAL(0x79)
/**< Ethernet clock generator */
//			clock-controller@30380000 {
//				compatible = "fsl,imx8mn-ccm";
//				reg = <0x30380000 0x10000>;
//				#clock-cells = <0x01>;
//				clocks = <0x16 0x17 0x18 0x19 0x1a 0x1b>;
//				clock-names = "osc_32k\0osc_24m\0clk_ext1\0clk_ext2\0clk_ext3\0clk_ext4";
//				u-boot,dm-spl;
//				u-boot,dm-pre-reloc;
//				phandle = <0x02>;
//			};
#define ETHERNET_CLK_ADDR (0x30380000)
#define ETHERNET_CLK_SIZE (0x00010000)


/**< Mailbox unit (MU): See mailbox@30aa0000 in @devicetrees/$PLATFORM/linux.dts */
//mailbox@30aa0000 {
//	compatible = "fsl,imx8mn-mu\0fsl,imx6sx-mu";
//	reg = <0x30aa0000 0x10000>;
//	interrupts = <0x00 0x58 0x04>;
//	clocks = <0x02 0x95>;
//	#mbox-cells = <0x02>;
//	phandle = <0x95>;
//};
#define MU_BASE_ADDR (0x30aa0000)
#define MU_SIZE      (0x00010000)
#define MU_INTERRUPT_ID    (GIC_SPI_VAL(88)) //GIC_SPI_VAL(0x58)




/**
 * The configuration itself is a struct config that MUST be named config.
 */
struct config config = {
    
    /**
     * This macro must be always placed in the config struct, to initialize,
     * configuration independent fields. (DEPRECATED)
     */
    // CONFIG_HEADER

    /**
     * This defines an array of shared memory objects that may be associated
     * with inter-partition communication objects in the VM platform definition
     * below using the shared memory object ID, ie, its index in the list.
     */
    .shmemlist_size = 1,
    .shmemlist = (struct shmem[]) {
        [0] = { .size = SHMEM_SIZE, }
    },
    
    .vmlist_size = 2,
    .vmlist = {
        {
/**< VM 1: Linux */
            .image = VM_IMAGE_BUILTIN(linux_image, LINUX_BASE_ADDR),
            .entry = LINUX_BASE_ADDR,
            //.cpu_affinity = 0b110111,

            .platform = {
                .cpu_num = LINUX_CPU_NUM,   
                
                .region_num = 1,
                .regions =  (struct vm_mem_region[]) {
                    {
                        .base = LINUX_RAM_BASE_ADDR,
                        .size = LINUX_RAM_SIZE
                    }
                },

                .ipc_num = 1,
                .ipcs = (struct ipc[]) {
                    {
                        .base = BAO_IPC_ADDR,
                        .size = BAO_IPC_SIZE,
                        .shmem_id = 0,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {BAO_IPC_INTERRUPT_ID}
                    }
                },

/**
 * We are assigning a MU to the linux guest because the linux drivers 
 * assume linux can directly interact with the SCU to configure its devices.
 * Therefore, this guest will be able to configure peripheral not assigned
 * to it, as for example, the lpuart0 used by bao and freertos. In the future 
 * we will have to either move the cores and peripherals belonging to this guest
 * to a separate scfw partition or paravirtualise the MUS and interpose the guest 
 * communication to the SCU to limit which resources it might configure.
 */ 
                .dev_num = 4,
                .devs =  (struct vm_dev_region[]) {  
                    {

                        /**< Mailbox message unit */
                        .pa = MU_BASE_ADDR,
                        .va = MU_BASE_ADDR,
                        .size = MU_SIZE,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {MU_INTERRUPT_ID},    
                    },
                    {   
                        /* Arch timer interrupt */
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {ARCH_TIMER_INTERRUPT_ARM}
                    },
                    {
                        /**< Ethernet controller */
                        .pa = ETHERNET_CTRL_ADDR,
                        .va = ETHERNET_CTRL_ADDR,
                        .size = ETHERNET_CTRL_SIZE,
                        .interrupt_num = ETHERNET_CTRL_INTERRUPT_NUM,
                        .interrupts = (irqid_t[])
                        {
                            ETHERNET_CTRL_INTERRUPT1,
                            ETHERNET_CTRL_INTERRUPT2,
                            ETHERNET_CTRL_INTERRUPT3,
                            ETHERNET_CTRL_INTERRUPT4,
                        },    
                        .id = 0x2,
                    },
                    {   
                        /**< Ethernet clock generator */
                        .pa = ETHERNET_CLK_ADDR,
                        .va = ETHERNET_CLK_ADDR,
                        .size = ETHERNET_CLK_SIZE,
                    },
                },

                .arch = {
                    .gic = {
                        .gicd_addr = LINUX_GICD_ADDR,
                        .gicr_addr = LINUX_GICR_ADDR
                    },
                }
            },
        },

/**< VM 2: FreeRTOS */
        {

            .image = VM_IMAGE_BUILTIN(freertos_image,
                                        FREERTOS_BASE_ADDR // guest physical addr
                ),
            .entry = FREERTOS_BASE_ADDR,
            //.cpu_affinity = 0b001000,

            .platform = {
                .cpu_num = FREERTOS_CPU_NUM,
                .region_num = 1,
                .regions =  (struct vm_mem_region[]) {
                    {
                        .base = FREERTOS_BASE_ADDR,
                        .size = FREERTOS_RAM_SIZE 
                    }
                },

                .ipc_num = 1,
                .ipcs = (struct ipc[]) {
                    {
                        .base = 0x70000000,
                        .size = BAO_IPC_SIZE,
                        .shmem_id = 0,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {BAO_IPC_INTERRUPT_ID}
                    }
                },

                .dev_num = 2,
                .devs =  (struct vm_dev_region[]) {
                    {   
                        /* lpuart0 */
                        .pa = 0x5a060000,
                        .va = 0xff000000,
                        .size = 0x1000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {377}                           
                    },
                    {   
                        /* Arch timer interrupt */
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {ARCH_TIMER_INTERRUPT_ARM}
                    }
                },

                .arch = {
                    .gic = {
                        .gicd_addr = FREERTOS_GICD_ADDR,
                        .gicr_addr = FREERTOS_GICR_ADDR,
                    }
                }
            },
        }
    },
};

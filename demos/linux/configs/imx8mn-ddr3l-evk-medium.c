#include <config.h>

/**
 * Declare VM images using the VM_IMAGE macro, passing an identifier and the
 * path for the image.
 */
VM_IMAGE(linux_image, XSTR(BAO_DEMOS_WRKDIR_IMGS/linux.bin));

/**< Macros to calculate interrupts number */
#define ADD_NRS(a, b) ((a) + (b))
#define GIC_PPI_VAL(x) ADD_NRS(x, 16)
#define GIC_SPI_VAL(x) ADD_NRS(x, 32)


/**
 * Configuration defines
 */
/**< See memory@40000000 in @devicetrees/$PLATFORM/linux.dts */
#define LINUX_BASE_ADDR     (0x40000000)
#define UBOOT_BASE_ADDR     (0x40200000)
#define LINUX_RUN_BASE_ADDR (0x40400000)
#define LINUX_CPU_NUM (4)
//#define LINUX_RAM_BASE_ADDR (UBOOT_BASE_ADDR)
#define LINUX_RAM_BASE_ADDR (LINUX_RUN_BASE_ADDR)
#define LINUX_RAM_SIZE (0x30000000) // 750 MB
/**< See bao-ipc@f0000000 in @devicetrees/$PLATFORM/linux.dts */
//#define BAO_IPC_ADDR (0xF0000000)
//#define BAO_IPC_SIZE (0x00010000)
//#define BAO_IPC_INTERRUPT_ID (52)
//#define SHMEM_SIZE (BAO_IPC_SIZE)
/**< GIC: See interrupt-controller@38800000 in @devicetrees/$PLATFORM/linux.dts */
#define LINUX_GICD_ADDR (0x38800000)
#define LINUX_GICR_ADDR (0x38880000)
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

/**< UART  */
// serial@30890000 {
// 	compatible = "fsl,imx8mn-uart\0fsl,imx6q-uart";
// 	reg = <0x30890000 0x10000>;
// 	interrupts = <0x00 0x1b 0x04>;
// 	clocks = <0x02 0xaa 0x02 0xaa>;
// 	clock-names = "ipg\0per";
// 	status = "okay";
// 	pinctrl-names = "default";
// 	pinctrl-0 = <0x1f>;
// 	u-boot,dm-spl;
// 	phandle = <0x7e>;
// };
#define UART2_ADDR (0x30890000)
#define UART2_SIZE (0x00010000)
#define UART2_INTERRUPT_NUM (1)
#define UART2_INTERRUPT (GIC_PPI_VAL(27)) // GIC_SPI_VAL(0x1b)


/**< UART 1 */
// serial@30860000 {
// 	compatible = "fsl,imx8mn-uart\0fsl,imx6q-uart";
// 	reg = <0x30860000 0x10000>;
// 	interrupts = <0x00 0x1a 0x04>;
// 	clocks = <0x02 0xa9 0x02 0xa9>;
// 	clock-names = "ipg\0per";
// 	dmas = <0x1d 0x16 0x04 0x00 0x1d 0x17 0x04 0x00>;
// 	dma-names = "rx\0tx";
// 	status = "disabled";
// 	phandle = <0x7c>;
// };
#define UART1_ADDR (0x30860000)
#define UART1_SIZE (0x00010000)
#define UART1_INTERRUPT_NUM (1)
#define UART1_INTERRUPT (GIC_PPI_VAL(26)) // GIC_SPI_VAL(0x1a)




/**
 * The configuration itself is a struct config that MUST be named config.
 */
struct config config = {
    
    .vmlist_size = 1,
    .vmlist = {
        {
/**< VM 1: Linux */
            .image = VM_IMAGE_BUILTIN(linux_image, LINUX_RAM_BASE_ADDR),

            .entry = LINUX_RAM_BASE_ADDR,
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

                .dev_num = 12,
                .devs =  (struct vm_dev_region[]) {
                    //{
		    //    //i2c@30a20000 {
		    //    //	compatible = "fsl,imx8mn-i2c\0fsl,imx21-i2c";
		    //    //	#address-cells = <0x01>;
		    //    //	#size-cells = <0x00>;
		    //    //	reg = <0x30a20000 0x10000>;
		    //    //	interrupts = <0x00 0x23 0x04>;
                    //    .pa = 0x30a20000,
                    //    .va = 0x30a20000,
                    //    .size = 0x10000,
                    //    .interrupt_num = 1,
                    //    .interrupts = (irqid_t[])
                    //    {
                    //        GIC_SPI_VAL(35), // GIC_PPI_VAL(0x23)
                    //    },    
                    //},
                    {
			//dma-controller@302b0000 {
			//	compatible = "fsl,imx8mn-sdma\0fsl,imx8mq-sdma";
			//	reg = <0x302b0000 0x10000>;
			//	interrupts = <0x00 0x22 0x04>;
			//	clocks = <0x02 0xbd 0x02 0xbd>;
			//	clock-names = "ipg\0ahb";
			//	#dma-cells = <0x03>;
			//	fsl,sdma-ram-script-name = "imx/sdma/sdma-imx7d.bin";
			//	phandle = <0x68>;
			//};
                        .pa = 0x302b0000,
                        .va = 0x302b0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            GIC_SPI_VAL(34), // GIC_PPI_VAL(0x22)
                        },    
                    },
                    {   
                        /* Arch timer interrupt */
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {ARCH_TIMER_INTERRUPT_ARM}
                    },
                    //{
                    //    /**< Ethernet controller */
                    //    .pa = ETHERNET_CTRL_ADDR,
                    //    .va = ETHERNET_CTRL_ADDR,
                    //    .size = ETHERNET_CTRL_SIZE,
                    //    .interrupt_num = ETHERNET_CTRL_INTERRUPT_NUM,
                    //    .interrupts = (irqid_t[])
                    //    {
                    //        ETHERNET_CTRL_INTERRUPT1,
                    //        ETHERNET_CTRL_INTERRUPT2,
                    //        ETHERNET_CTRL_INTERRUPT3,
                    //        ETHERNET_CTRL_INTERRUPT4,
                    //    },    
                    //    //.id = 0x2,
                    //},
                    //{   
                    //    /**< Ethernet clock generator */
                    //    .pa = ETHERNET_CLK_ADDR,
                    //    .va = ETHERNET_CLK_ADDR,
                    //    .size = ETHERNET_CLK_SIZE,
                    //},
                    {
                        /**< UART serial2 (serial@30890000) */
                        .pa = UART2_ADDR,
                        .va = UART2_ADDR,
                        .size = UART2_SIZE,
                        .interrupt_num = UART2_INTERRUPT_NUM,
                        .interrupts = (irqid_t[])
                        {
                            UART2_INTERRUPT,
                        },    
                        
                    },
                    {
                        /**< Clock controller (clock-controller@30360000) */
			//clock-controller@30360000 {
			//	compatible = "fsl,imx8mn-anatop\0fsl,imx8mm-anatop";
			//	reg = <0x30360000 0x10000>;
			//	#clock-cells = <0x01>;
			//	phandle = <0x6a>;
			//};
                        .pa = 0x30360000,
                        .va = 0x30360000,
                        .size = 0x10000,
                    },
                    {
                        /**< Clock controller (clock-controller@30360000) */
			// clock-controller@30380000 {
			// 	compatible = "fsl,imx8mn-ccm";
			// 	reg = <0x30380000 0x10000>;
			// 	#clock-cells = <0x01>;
			// 	clocks = <0x16 0x17 0x18 0x19 0x1a 0x1b>;
			// 	clock-names = "osc_32k\0osc_24m\0clk_ext1\0clk_ext2\0clk_ext3\0clk_ext4";
			// 	u-boot,dm-spl;
			// 	u-boot,dm-pre-reloc;
			// 	phandle = <0x02>;
			// };
                        .pa = 0x30380000,
                        .va = 0x30380000,
                        .size = 0x10000,
                    },
                    {
			//pinctrl@30330000 {
			//	compatible = "fsl,imx8mn-iomuxc";
			//	reg = <0x30330000 0x10000>;
                        .pa = 0x30330000,
                        .va = 0x30330000,
                        .size = 0x10000,
                    },
                    {
                        /**< UART serial1 (serial@30860000) */
                        .pa = UART1_ADDR,
                        .va = UART1_ADDR,
                        .size = UART1_SIZE,
                        .interrupt_num = UART1_INTERRUPT_NUM,
                        .interrupts = (irqid_t[])
                        {
                            UART1_INTERRUPT,
                        },    
                        
                    },
                    {
                        /**< mailbox (mailbox@30aa0000) */
//			mailbox@30aa0000 {
//				compatible = "fsl,imx8mn-mu\0fsl,imx6sx-mu";
//				reg = <0x30aa0000 0x10000>;
//				interrupts = <0x00 0x58 0x04>;
//				clocks = <0x02 0x95>;
//				#mbox-cells = <0x02>;
//				phandle = <0x95>;
//			};
                        .pa = 0x30aa0000,
                        .va = 0x30aa0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            GIC_SPI_VAL(88), // GIC_PPI_VAL(0x58)
                        },    
                        
                    },
                    //{
                    //    // caam-sm@100000 {
                    //    //     compatible = "fsl,imx6q-caam-sm";
                    //    //     reg = <0x100000 0x8000>;
                    //    //     phandle = <0x5f>;
                    //    // };
                    //    .pa = 0x100000,
                    //    .va = 0x100000,
                    //    .size = 0x8000,
                    //},

                    {
                        /**< ddr-pmu (mailbox@3d800000) */
                        // ddr-pmu@3d800000 {
                        //     compatible = "fsl,imx8mn-ddr-pmu\0fsl,imx8m-ddr-pmu";
                        //     reg = <0x3d800000 0x400000>;
                        //     interrupts = <0x00 0x62 0x04>;
                        // };
                        .pa = 0x3d800000,
                        .va = 0x3d800000,
                        .size = 0x400000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            GIC_SPI_VAL(98), // GIC_PPI_VAL(0x62)
                        },    
                        
                    },
                    // {
		    //     // mmc@30b40000 {
		    //     // 	reg = <0x30b40000 0x10000>;
		    //     // 	interrupts = <0x00 0x16 0x04>;
                    //     .pa = 0x30b40000,
                    //     .va = 0x30b40000,
                    //     .size = 0x10000,
                    //     .interrupt_num = 1,
                    //     .interrupts = (irqid_t[])
                    //     {
                    //         GIC_SPI_VAL(22), // GIC_PPI_VAL(0x16)
                    //     },    
                    //     
                    // },
                    // {
		    //     // mmc@30b50000 {
		    //     // 	reg = <0x30b50000 0x10000>;
		    //     // 	interrupts = <0x00 0x17 0x04>;
                    //     .pa = 0x30b50000,
                    //     .va = 0x30b50000,
                    //     .size = 0x10000,
                    //     .interrupt_num = 1,
                    //     .interrupts = (irqid_t[])
                    //     {
                    //         GIC_SPI_VAL(23), // GIC_PPI_VAL(0x17)
                    //     },    
                    //     
                    // },
                    {
			// mmc@30b60000 {
			// 	reg = <0x30b60000 0x10000>;
			// 	interrupts = <0x00 0x18 0x04>;
                        .pa = 0x30b60000,
                        .va = 0x30b60000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            GIC_PPI_VAL(24), // GIC_PPI_VAL(0x18)
                        },    
                        
                    },
                    {
			// gpc@303a0000 {
			// 	compatible = "fsl,imx8mn-gpc";
			// 	reg = <0x303a0000 0x10000>;
			// 	interrupt-parent = <0x01>;
			// 	interrupts = <0x00 0x57 0x04>;
                        .pa = 0x303a0000,
                        .va = 0x303a0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            GIC_SPI_VAL(87), // GIC_SPI_VAL(0x57)
                        },    
                        
                    },
                    {
			//dma-controller@30bd0000 {
			//	compatible = "fsl,imx8mn-sdma\0fsl,imx8mq-sdma";
			//	reg = <0x30bd0000 0x10000>;
			//	interrupts = <0x00 0x02 0x04>;
                        .pa = 0x30bd0000,
                        .va = 0x30bd0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            GIC_PPI_VAL(2), // GIC_PPI_VAL(0x02)
                        },    
                        
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
    },
};

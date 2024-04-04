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
#define LINUX_BASE_ADDR     0x40000000UL
#define LINUX_RAM_SIZE_1GB  0x40000000UL
#define UBOOT_BASE_ADDR     0x40200000UL
#define LINUX_RUN_BASE_ADDR 0x40400000UL
#define LINUX_START_ADDR    0x50000000UL
#define LINUX_CPU_NUM (4)
#define LINUX_RAM_BASE_ADDR (UBOOT_BASE_ADDR)
//#define LINUX_RAM_BASE_ADDR (LINUX_RUN_BASE_ADDR)
//#define LINUX_RAM_BASE_ADDR (LINUX_START_ADDR)
//#define LINUX_RAM_BASE_ADDR (LINUX_BASE_ADDR)
#define LINUX_RAM_SIZE (0x30000000) // 750 MB
//#define LINUX_RAM_SIZE ( LINUX_RAM_SIZE_1GB - (LINUX_RAM_BASE_ADDR - LINUX_BASE_ADDR ))  
//#define LINUX_RAM_SIZE ( 0x20000000UL )  
/**< See bao-ipc@f0000000 in @devicetrees/$PLATFORM/linux.dts */
//#define BAO_IPC_ADDR (0xF0000000)
//#define BAO_IPC_SIZE (0x00010000)
//#define BAO_IPC_INTERRUPT_ID (52)
//#define SHMEM_SIZE (BAO_IPC_SIZE)
/**< GIC: See interrupt-controller@38800000 in @devicetrees/$PLATFORM/linux.dts */
#define LINUX_GICD_ADDR (0x38800000UL)
#define LINUX_GICR_ADDR (0x38880000UL)
/**< Arm arch timer */
#define TIMER_VIRQ_GIC_PPI 11
#define ARCH_TIMER_INTERRUPT_ARM (GIC_PPI_VAL(TIMER_VIRQ_GIC_PPI))

/**< How to read a device tree
 * src: https://www.kernel.org/doc/Documentation/devicetree/bindings/interrupt-controller/arm%2Cgic.txt
 * - interrupt-controller : Identifies the node as an interrupt controller
 * - #interrupt-cells : Specifies the number of cells needed to encode an
 *   interrupt source.  The type shall be a <u32> and the value shall be 3.
 * 
 *   The 1st cell is the interrupt type:
 *     - 0 for SPI interrupts,
 *     - 1 for PPI interrupts.
 * 
 *   The 2nd cell contains the interrupt number for the interrupt type.
 *     - SPI interrupts are in the range [0-987].
 *     - PPI interrupts are in the range [0-15].
 * 
 *   The 3rd cell is the flags, encoded as follows:
 * 	bits[3:0] trigger type and level flags.
 * 		1 = low-to-high edge triggered
 * 		2 = high-to-low edge triggered (invalid for SPIs)
 * 		4 = active high level-sensitive
 * 		8 = active low level-sensitive (invalid for SPIs).
 * 	bits[15:8] PPI interrupt cpu mask.  Each bit corresponds to each of
 * 	the 8 possible cpus attached to the GIC.  A bit set to '1' indicated
 * 	the interrupt is wired to that CPU.  Only valid for PPI interrupts.
 * 	Also note that the configurability of PPI interrupts is IMPLEMENTATION
 * 	DEFINED and as such not guaranteed to be present (most SoC available
 * 	in 2014 seem to ignore the setting of this flag and use the hardware
 * 	default value).
 */




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
                        .size = LINUX_RAM_SIZE,
                        //.place_phys = true,
                        //.phys = LINUX_RAM_BASE_ADDR,
                    }
                },

                .dev_num = 11,
                .devs =  (struct vm_dev_region[]) {
                    /**< Arch timer interrupt */
                    {
                        //timer {
                        //    compatible = "arm,armv8-timer";
                        //    interrupts = <0x01 0x0d 0xf08 0x01 0x0e 0xf08 0x01 0x0b 0xf08 0x01 0x0a 0xf08>;
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {
                            //GIC_PPI_VAL(10), // 10, //ARCH_TIMER_INTERRUPT_ARM,
                            // GIC_PPI_VAL(11), // 11, //ARCH_TIMER_INTERRUPT_ARM,
                            // GIC_PPI_VAL(12), // 12, //ARCH_TIMER_INTERRUPT_ARM,
                            // GIC_PPI_VAL(13), // 13, //ARCH_TIMER_INTERRUPT_ARM,
                            27,
                        },
                    },
                    /**< LED GPIO (gpio@30220000) */
                    {
			//gpio@30220000 {
			//	compatible = "fsl,imx8mn-gpio\0fsl,imx35-gpio";
			//	reg = <0x30220000 0x10000>;
			//	interrupts = <0x00 0x44 0x04 0x00 0x45 0x04>;
                        .pa = 0x30220000,
                        .va = 0x30220000,
                        .size = 0x10000,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[])
                        {
                            GIC_SPI_VAL(0x44), //(0x44 + 32), // GIC_SPI_VAL(68), // GIC_SPI_VAL(0x44)
                            GIC_SPI_VAL(0x45), //(0x45 + 32), // GIC_SPI_VAL(69), // GIC_SPI_VAL(0x45)
                        },    
                        //.id = 0x2,
                    },
                    /**< Ethernet GPIO (gpio@30230000) */
                    {
			//gpio@30230000 {
			//	compatible = "fsl,imx8mn-gpio\0fsl,imx35-gpio";
			//	reg = <0x30230000 0x10000>;
			//	interrupts = <0x00 0x46 0x04 0x00 0x47 0x04>;
                        .pa = 0x30230000,
                        .va = 0x30230000,
                        .size = 0x10000,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[])
                        {
                            GIC_SPI_VAL(0x46), //(0x46UL + 32UL), // GIC_SPI_VAL(70), // GIC_SPI_VAL(0x46)
                            GIC_SPI_VAL(0x47), //(0x47UL + 32UL) // GIC_SPI_VAL(71), // GIC_SPI_VAL(0x47)
                        },    
                        //.id = 0x2,
                    },
                    /**< Pin Controller (pinctrl@30330000) */
                    {
			//pinctrl@30330000 {
			//	compatible = "fsl,imx8mn-iomuxc";
			//	reg = <0x30330000 0x10000>;
                        .pa = 0x30330000,
                        .va = 0x30330000,
                        .size = 0x10000,
                    },
                    /**< EFuse (efuse@30350000) */
                    {
                        // efuse@30350000 {
                        // 	compatible = "fsl,imx8mn-ocotp\0fsl,imx8mm-ocotp\0syscon\0simple-mfd";
                        // 	reg = <0x30350000 0x10000>;
                        .pa = 0x30350000,
                        .va = 0x30350000,
                        .size = 0x10000,
                    },
                    /**< Analog Clock Controller Module (anatop@30360000) */
                    {
			// anatop@30360000 {
			// 	compatible = "fsl,imx8mn-anatop\0fsl,imx8mm-anatop\0syscon";
			// 	reg = <0x30360000 0x10000>;
			// };
                        .pa = 0x30360000,
                        .va = 0x30360000,
                        .size = 0x10000,
                    },
                    /**< Ethernet clock generator (clock-controller@30380000) */
                    {   
			// clock-controller@30380000 {
			// 	compatible = "fsl,imx8mn-ccm";
			// 	reg = <0x30380000 0x10000>;
			// };
                        .pa = 0x30380000,
                        .va = 0x30380000,
                        .size = 0x10000,
                    },
                    /**< General Power Controller (gpc@303a0000) */
                    {
			// gpc@303a0000 {
			// 	compatible = "fsl,imx8mn-gpc";
			// 	reg = <0x303a0000 0x10000>;
			//	interrupts = <0x00 0x57 0x04>;
                        .pa = 0x303a0000,
                        .va = 0x303a0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            GIC_SPI_VAL(0x57), //(0x57UL + 32UL), 
                        },    
                    },
                    /**< UART serial2 (serial@30890000) */
                    {
                        // serial@30890000 {
                        // 	compatible = "fsl,imx8mn-uart\0fsl,imx6q-uart";
                        // 	reg = <0x30890000 0x10000>;
                        // 	interrupts = <0x00 0x1b 0x04>;
                        .pa = 0x30890000,
                        .va = 0x30890000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            GIC_SPI_VAL(0x1b) // (0x1bUL + 32UL), //GIC_SPI_VAL(27), // GIC_SPI_VAL(0x1b),
                        },    
                        
                    },
                    /**< Ethernet controller (ethernet@30be0000) */
                    {
                         // ethernet@30be0000 {
                         // 	reg = <0x30be0000 0x10000>;
                         // 	interrupts = <0x00 0x76 0x04 0x00 0x77 0x04 0x00 0x78 0x04 0x00 0x79 0x04>;
                         .pa = 0x30be0000,
                         .va = 0x30be0000,
                         .size = 0x10000,
                         .interrupt_num = 4,
                         .interrupts = (irqid_t[])
                         {
                             GIC_SPI_VAL(0x76), //(0x76UL + 32UL), // GIC_SPI_VAL(118), // GIC_SPI_VAL(0x76) 
                             GIC_SPI_VAL(0x77), //(0x77UL + 32UL), // GIC_SPI_VAL(119), // GIC_SPI_VAL(0x77)
                             GIC_SPI_VAL(0x78), //(0x78UL + 32UL), // GIC_SPI_VAL(120), // GIC_SPI_VAL(0x78)
                             GIC_SPI_VAL(0x79), //(0x79UL + 32UL), // GIC_SPI_VAL(121), // GIC_SPI_VAL(0x79)
                         },    
                         //.id = 0x2,
                    },

		    //                    /**< CAAM Secure Non-Volatile Storage (CAAM-SNVS) (caam-snvs@30370000) */
		    //                    {
		    //		    //caam-snvs@30370000 {
		    //		    //	compatible = "fsl,imx6q-caam-snvs";
		    //		    //	reg = <0x30370000 0x10000>;
		    //		    //	clocks = <0x02 0xd3>;
		    //		    //	clock-names = "ipg";
		    //		    //};
		    //                         .pa = 0x30370000,
		    //                         .va = 0x30370000,
		    //                         .size = 0x10000,
		    //                    },


                    /**< Secure Non-Volatile Storage (SNVS) (snvs@30370000) */
                    {
		    //snvs@30370000 {
		    //	compatible = "fsl,sec-v4.0-mon\0syscon\0simple-mfd";
		    //	reg = <0x30370000 0x10000>;
		    //	phandle = <0x1a>;

		    //	snvs-rtc-lp {
		    //		compatible = "fsl,sec-v4.0-mon-rtc-lp";
		    //		regmap = <0x1a>;
		    //		offset = <0x34>;
		    //		interrupts = <0x00 0x13 0x04 0x00 0x14 0x04>;
		    //		clocks = <0x02 0xd3>;
		    //		clock-names = "snvs-rtc";
		    //	};

		    //	snvs-powerkey {
		    //		compatible = "fsl,sec-v4.0-pwrkey";
		    //		regmap = <0x1a>;
		    //		interrupts = <0x00 0x04 0x04>;
		    //		clocks = <0x02 0xd3>;
		    //		clock-names = "snvs-pwrkey";
		    //		linux,keycode = <0x74>;
		    //		wakeup-source;
		    //		status = "okay";
		    //	};
		    //};
                         .pa = 0x30370000,
                         .va = 0x30370000,
                         .size = 0x10000,
                         .interrupt_num = 3,
                         .interrupts = (irqid_t[])
                         {
                             GIC_SPI_VAL(0x13), 
                             GIC_SPI_VAL(0x14), 
                             GIC_SPI_VAL(0x04), 
                         },    
                    },

//                    /**< DMA controller (dma-controller@302b0000) */
//                    {
//			// dma-controller@302b0000 {
//			// 	compatible = "fsl,imx8mn-sdma\0fsl,imx8mq-sdma\0fsl,imx7d-sdma";
//			// 	reg = <0x302b0000 0x10000>;
//			// 	interrupts = <0x00 0x22 0x04>;
//			// };
//                        .pa = 0x302b0000,
//                        .va = 0x302b0000,
//                        .size = 0x10000,
//                        .interrupt_num = 1,
//                        .interrupts = (irqid_t[])
//                        {
//                            GIC_SPI_VAL(34), // GIC_SPI_VAL(0x44)
//                        },    
//                    },
//                    /**< DMA controller (dma-controller@302b0000) */
//                    {
//			//dma-controller@302c0000 {
//			//	compatible = "fsl,imx8mn-sdma\0fsl,imx8mq-sdma\0fsl,imx7d-sdma";
//			//	reg = <0x302c0000 0x10000>;
//			//	interrupts = <0x00 0x67 0x04>;
//                        .pa = 0x302c0000,
//                        .va = 0x302c0000,
//                        .size = 0x10000,
//                        .interrupt_num = 1,
//                        .interrupts = (irqid_t[])
//                        {
//                            GIC_SPI_VAL(107), // GIC_SPI_VAL(0x44)
//                        },    
//                    },

//                    /**< iomux (iomuxc-gpr@30340000) */
//                    {
//			// iomuxc-gpr@30340000 {
//			// 	compatible = "fsl,imx8mn-iomuxc-gpr\0syscon";
//			// 	reg = <0x30340000 0x10000>;
//                        .pa = 0x30340000,
//                        .va = 0x30340000,
//                        .size = 0x10000,
//                    },
//                    /**< usb (usb@32e40000) */
//                    {
//			//usb@32e40000 {
//			//	compatible = "fsl,imx8mn-usb\0fsl,imx7d-usb";
//			//	reg = <0x32e40000 0x200>;
//			//	interrupts = <0x00 0x28 0x04>;
//                        .pa = 0x32e40000,
//                        .va = 0x32e40000,
//                        .size = 0x200,
//                        .interrupt_num = 1,
//                        .interrupts = (irqid_t[])
//                        {
//                            GIC_SPI_VAL(40), // GIC_SPI_VAL(0x28),
//                        },    
//                    },
//                    /**< usbmisc (usbmisc@32e40200) */
//                    {
//			// usbmisc@32e40200 {
//			// 	compatible = "fsl,imx8mn-usbmisc\0fsl,imx7d-usbmisc";
//			// 	reg = <0x32e40200 0x200>;
//			// };
//                        .pa = 0x32e40200,
//                        .va = 0x30340000,
//                        .size = 0x200,
//                    },
//                    /**< GPIO */
//                    {
//			//gpio@30240000 {
//			//	compatible = "fsl,imx8mn-gpio\0fsl,imx35-gpio";
//			//	reg = <0x30240000 0x10000>;
//			//	interrupts = <0x00 0x48 0x04 0x00 0x49 0x04>;
//			//};
//                        .pa = 0x30240000,
//                        .va = 0x30240000,
//                        .size = 0x10000,
//                        .interrupt_num = 2,
//                        .interrupts = (irqid_t[])
//                        {
//                            GIC_SPI_VAL(72), // GIC_SPI_VAL(0x48)
//                            GIC_SPI_VAL(73), // GIC_SPI_VAL(0x49)
//                        },    
//                        //.id = 0x2,
//                    },
//                    /**< I2C */
//                    {
//			//i2c@30a20000 {
//			//	compatible = "fsl,imx8mn-i2c\0fsl,imx21-i2c";
//			//	reg = <0x30a20000 0x10000>;
//			//	interrupts = <0x00 0x23 0x04>;
//                        .pa = 0x30a20000,
//                        .va = 0x30a20000,
//                        .size = 0x10000,
//                        .interrupt_num = 1,
//                        .interrupts = (irqid_t[])
//                        {
//                            GIC_SPI_VAL(35), // GIC_PPI_VAL(0x23)
//                        },    
//                        //.id = 0x2,
//                    },
//                    /**< UART serial0 (serial@30860000) */
//                    {
//			// serial@30860000 {
//			// 	compatible = "fsl,imx8mn-uart\0fsl,imx6q-uart";
//			// 	reg = <0x30860000 0x10000>;
//			// 	interrupts = <0x00 0x1a 0x04>;
//                        .pa = 0x30860000,
//                        .va = 0x30860000,
//                        .size = 0x10000,
//                        .interrupt_num = 1,
//                        .interrupts = (irqid_t[])
//                        {
//                            GIC_PPI_VAL(26), // GIC_SPI_VAL(0x1a),
//                        },    
//                        
//                    },

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

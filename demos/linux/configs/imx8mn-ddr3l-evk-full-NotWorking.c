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
//#define LINUX_RAM_BASE_ADDR (UBOOT_BASE_ADDR)
#define LINUX_RAM_BASE_ADDR (LINUX_START_ADDR)
//#define LINUX_RAM_SIZE (0x30000000) // 750 MB
#define LINUX_RAM_SIZE ( LINUX_RAM_SIZE_1GB - (LINUX_START_ADDR - LINUX_BASE_ADDR ))  
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
                        // .place_phys = true,
                        // .phys = LINUX_RAM_BASE_ADDR,
                    }
                },

                .dev_num = 67,
                .devs =  (struct vm_dev_region[]) {
                    /**< Power management unit (PMU) */
                    {
                        // pmu {
                        //     compatible = "arm,cortex-a53-pmu";
                        //     interrupts = <0x01 0x07 0xf04>;
                        // };
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {
                            0x07UL + 16UL, // PPI
                        },
                    },
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
                    /**< Gasket (gasket@32e28060) */
                    {   
                        // gasket@32e28060 {
                        //     compatible = "syscon";
                        //     reg = <0x00 0x32e28060 0x00 0x28>;
                        .pa = 0x32e28060,
                        .va = 0x32e28060,
                        .size = 0x28,
                    },
                    /**< Camera: ISI (isi@32e20000) */
                    {
                        // isi@32e20000 {
                        //     compatible = "fsl,imx8mn-isi";
                        //     reg = <0x00 0x32e20000 0x00 0x2000>;
                        //     interrupts = <0x00 0x10 0x04>;
                         .pa = 0x32e20000,
                         .va = 0x32e20000,
                         .size = 0x2000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x10UL + 32UL), // 
                         },    
                    },
                    /**< Camera: CSI (csi@32e30000) */
                    {
                        // csi@32e30000 {
                        //     compatible = "fsl,imx8mn-mipi-csi";
                        //     reg = <0x00 0x32e30000 0x00 0x10000>;
                        //     interrupts = <0x00 0x11 0x04>;
                         .pa = 0x32e30000,
                         .va = 0x32e30000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x11UL + 32UL), // 
                         },    
                    },
                    /**< caam-sm (caam-sm@00100000) */
                    {   
                        // caam-sm@00100000 {
                        //     compatible = "fsl,imx6q-caam-sm";
                        //     reg = <0x100000 0x8000>;
                        .pa = 0x100000,
                        .va = 0x100000,
                        .size = 0x8000,
                    },
                    /**< SAI (sai@30020000) */
                    {
                        // sai@30020000 {
                        //     compatible = "fsl,imx8mn-sai\0fsl,imx8mq-sai";
                        //     reg = <0x30020000 0x10000>;
                        //     interrupts = <0x00 0x60 0x04>;
                         .pa = 0x30020000,
                         .va = 0x30020000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x60UL + 32UL),
                         },    
                    },
                    /**< SAI (sai@30030000) */
                    {
                        // sai@30030000 {
                        //     compatible = "fsl,imx8mn-sai\0fsl,imx8mq-sai";
                        //     reg = <0x30030000 0x10000>;
                        //     interrupts = <0x00 0x32 0x04>;
                         .pa = 0x30030000,
                         .va = 0x30030000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x32UL + 32UL),
                         },    
                    },
                    /**< SAI (sai@30050000) */
                    {
                        // sai@30050000 {
                        //     compatible = "fsl,imx8mn-sai\0fsl,imx8mq-sai";
                        //     reg = <0x30050000 0x10000>;
                        //     interrupts = <0x00 0x5a 0x04>;
                         .pa = 0x30050000,
                         .va = 0x30050000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x5aUL + 32UL),
                         },    
                    },
                    /**< SAI (sai@30060000) */
                    {
                        // sai@30060000 {
                        //     compatible = "fsl,imx8mn-sai\0fsl,imx8mq-sai";
                        //     reg = <0x30060000 0x10000>;
                        //     interrupts = <0x00 0x5a 0x04>;
                         .pa = 0x30060000,
                         .va = 0x30060000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x5aUL + 32UL),
                         },    
                    },
                    /**< Audio controller (audio-controller@30080000) */
                    {
                        // audio-controller@30080000 {
                        //     compatible = "fsl,imx8mm-micfil";
                        //     reg = <0x30080000 0x10000>;
                        //     interrupts = <0x00 0x6d 0x04 0x00 0x6e 0x04 0x00 0x2c 0x04 0x00 0x2d 0x04>;
                         .pa = 0x30080000,
                         .va = 0x30080000,
                         .size = 0x10000,
                         .interrupt_num = 4,
                         .interrupts = (irqid_t[])
                         {
                             (0x6dUL + 32UL), 
                             (0x6eUL + 32UL), 
                             (0x2cUL + 32UL), 
                             (0x2dUL + 32UL), 
                         },    
                    },
                    /**< SPDIF (spdif@30090000) */
                    {
                        // spdif@30090000 {
                        //     compatible = "fsl,imx35-spdif";
                        //     reg = <0x30090000 0x10000>;
                        //     interrupts = <0x00 0x06 0x04>;
                         .pa = 0x30090000,
                         .va = 0x30090000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x06UL + 32UL), 
                         },    
                    },
                    /**< SAI (spdif@30090000) */
                    {
                        // sai@300b0000 {
                        //     compatible = "fsl,imx8mn-sai\0fsl,imx8mq-sai";
                        //     reg = <0x300b0000 0x10000>;
                        //     interrupts = <0x00 0x6f 0x04>;
                         .pa = 0x30090000,
                         .va = 0x30090000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x06UL + 32UL), 
                         },    
                    },
                    /**< SAI (sai@300b0000) */
                    {
                        // sai@300b0000 {
                        //     compatible = "fsl,imx8mn-sai\0fsl,imx8mq-sai";
                        //     reg = <0x300b0000 0x10000>;
                        //     interrupts = <0x00 0x6f 0x04>;
                         .pa = 0x300b0000,
                         .va = 0x300b0000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x6FUL + 32UL), 
                         },    
                    },
//                    /**< easrc (easrc@300c0000) */
//                    {
//                        // easrc@300c0000 {
//                        //     compatible = "fsl,imx8mn-easrc";
//                        //     reg = <0x300c0000 0x10000>;
//                        //     interrupts = <0x00 0x7a 0x04>;
//                         .pa = 0x300c0000,
//                         .va = 0x300c0000,
//                         .size = 0x10000,
//                         .interrupt_num = 1,
//                         .interrupts = (irqid_t[])
//                         {
//                             (0x7aUL + 32UL), 
//                         },    
//                    },

                    /**< GPIO (gpio@30200000) */
                    {
			//gpio@30200000 {
			//	compatible = "fsl,imx8mn-gpio\0fsl,imx35-gpio";
			//	reg = <0x30200000 0x10000>;
			//	interrupts = <0x00 0x40 0x04 0x00 0x41 0x04>;
			//};
                        .pa = 0x30200000,
                        .va = 0x30200000,
                        .size = 0x10000,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[])
                        {
                            (0x40UL + 32UL), 
                            (0x41UL + 32UL), 
                        },    

                    },
                    /**< GPIO (gpio@30210000) */
                    {
			//gpio@30210000 {
			//	compatible = "fsl,imx8mn-gpio\0fsl,imx35-gpio";
			//	reg = <0x30210000 0x10000>;
			//	interrupts = <0x00 0x42 0x04 0x00 0x43 0x04>;
			//};
                        .pa = 0x30210000,
                        .va = 0x30210000,
                        .size = 0x10000,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[])
                        {
                            (0x42UL + 32UL), 
                            (0x43UL + 32UL), 
                        },    

                    },
                    /**< GPIO (gpio@30220000) */
                    {
			//gpio@30220000 {
			//	compatible = "fsl,imx8mn-gpio\0fsl,imx35-gpio";
			//	reg = <0x30220000 0x10000>;
			//	interrupts = <0x00 0x44 0x04 0x00 0x45 0x04>;
			//};
                        .pa = 0x30220000,
                        .va = 0x30220000,
                        .size = 0x10000,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[])
                        {
                            (0x44UL + 32UL), 
                            (0x45UL + 32UL), 
                        },    

                    },
                    /**< GPIO (gpio@30230000) */
                    {
			//gpio@30230000 {
			//	compatible = "fsl,imx8mn-gpio\0fsl,imx35-gpio";
			//	reg = <0x30230000 0x10000>;
			//	interrupts = <0x00 0x46 0x04 0x00 0x47 0x04>;
			//};
                        .pa = 0x30230000,
                        .va = 0x30230000,
                        .size = 0x10000,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[])
                        {
                            (0x46UL + 32UL), 
                            (0x47UL + 32UL), 
                        },    

                    },
                    /**< GPIO (gpio@30240000) */
                    {
			//gpio@30240000 {
			//	compatible = "fsl,imx8mn-gpio\0fsl,imx35-gpio";
			//	reg = <0x30240000 0x10000>;
			//	interrupts = <0x00 0x48 0x04 0x00 0x49 0x04>;
			//};
                        .pa = 0x30240000,
                        .va = 0x30240000,
                        .size = 0x10000,
                        .interrupt_num = 2,
                        .interrupts = (irqid_t[])
                        {
                            (0x48UL + 32UL), 
                            (0x49UL + 32UL), 
                        },    

                    },
                    /**< tmu (tmu@30260000) */
                    {
//			tmu@30260000 {
//				compatible = "fsl,imx8mn-tmu\0fsl,imx8mm-tmu";
//				reg = <0x30260000 0x10000>;
                        .pa = 0x30260000,
                        .va = 0x30260000,
                        .size = 0x10000,
                    },
                    /**< watchdog (watchdog@30280000) */
                    {
			//watchdog@30280000 {
			//	compatible = "fsl,imx8mn-wdt\0fsl,imx21-wdt";
			//	reg = <0x30280000 0x10000>;
			//	interrupts = <0x00 0x4e 0x04>;
                        .pa = 0x30280000,
                        .va = 0x30280000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x4eUL + 32UL), 
                        },    

                    },
                    /**< watchdog (watchdog@30290000) */
                    {
			//watchdog@30290000 {
			//	compatible = "fsl,imx8mn-wdt\0fsl,imx21-wdt";
			//	reg = <0x30290000 0x10000>;
			//	interrupts = <0x00 0x4f 0x04>;
                        .pa = 0x30290000,
                        .va = 0x30290000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x4fUL + 32UL), 
                        },    

                    },
                    /**< watchdog (watchdog@302a0000) */
                    {
			//watchdog@302a0000 {
			//	compatible = "fsl,imx8mn-wdt\0fsl,imx21-wdt";
			//	reg = <0x302a0000 0x10000>;
			//	interrupts = <0x00 0x0a 0x04>;
                        .pa = 0x302a0000,
                        .va = 0x302a0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x0aUL + 32UL), 
                        },    

                    },
                    /**< DMA controller (dma-controller@302b0000) */
                    {
			// dma-controller@302b0000 {
			// 	compatible = "fsl,imx8mn-sdma\0fsl,imx8mq-sdma\0fsl,imx7d-sdma";
			// 	reg = <0x302b0000 0x10000>;
			// 	interrupts = <0x00 0x22 0x04>;
			// };
                        .pa = 0x302b0000,
                        .va = 0x302b0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x22UL + 32UL), 
                        },    
                    },
                    /**< DMA controller (dma-controller@302c0000) */
                    {
			//dma-controller@302c0000 {
			//	compatible = "fsl,imx8mn-sdma\0fsl,imx8mq-sdma\0fsl,imx7d-sdma";
			//	reg = <0x302c0000 0x10000>;
			//	interrupts = <0x00 0x67 0x04>;
                        .pa = 0x302c0000,
                        .va = 0x302c0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x67UL + 32UL), 
                        },    
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
                    /**< iomux (iomuxc-gpr@30340000) */
                    {
			// iomuxc-gpr@30340000 {
			// 	compatible = "fsl,imx8mn-iomuxc-gpr\0syscon";
			// 	reg = <0x30340000 0x10000>;
                        .pa = 0x30340000,
                        .va = 0x30340000,
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
                    /**< caam_secvio */
                    {
			//caam_secvio {
			//	compatible = "fsl,imx6q-caam-secvio";
			//	interrupts = <0x00 0x14 0x04>;
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x14UL + 32UL), 
                        },    

                    },
                    /**< CAAM SNVS (caam-snvs@30370000) */
                    {
			// caam-snvs@30370000 {
			// 	compatible = "fsl,imx6q-caam-snvs";
			// 	reg = <0x30370000 0x10000>;
                        .pa = 0x30370000,
                        .va = 0x30370000,
                        .size = 0x10000,
                    },
                    // snvs@30370000 {
                    // 	compatible = "fsl,sec-v4.0-mon\0syscon\0simple-mfd";
                    // 	reg = <0x30370000 0x10000>;
                    // 	phandle = <0x1a>;

                    // 	snvs-rtc-lp {
                    // 		compatible = "fsl,sec-v4.0-mon-rtc-lp";
                    // 		regmap = <0x1a>;
                    // 		offset = <0x34>;
                    // 		interrupts = <0x00 0x13 0x04 0x00 0x14 0x04>;
                    // 		clocks = <0x02 0xd3>;
                    // 		clock-names = "snvs-rtc";
                    // 	};

                    // 	snvs-powerkey {
                    // 		compatible = "fsl,sec-v4.0-pwrkey";
                    // 		regmap = <0x1a>;
                    // 		interrupts = <0x00 0x04 0x04>;
                    // 		clocks = <0x02 0xd3>;
                    // 		clock-names = "snvs-pwrkey";
                    // 		linux,keycode = <0x74>;
                    // 		wakeup-source;
                    // 		status = "okay";
                    // 	};
                    // };
                    /**< Clock generator (clock-controller@30380000) */
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
                        .pa = 0x303a0000,
                        .va = 0x303a0000,
                        .size = 0x10000,
                    },
                    /**< Reset controller (reset-controller@30390000) */
                    {
			// reset-controller@30390000 {
			// 	compatible = "fsl,imx8mn-src\0fsl,imx8mq-src\0syscon";
			// 	reg = <0x30390000 0x10000>;
			// 	interrupts = <0x00 0x59 0x04>;
                         .pa = 0x30390000,
                         .va = 0x30390000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x59UL + 32UL), 
                         },    
                    },
                    /**< PWM (pwm@30660000) */
                    {
			// pwm@30660000 {
			// 	compatible = "fsl,imx8mn-pwm\0fsl,imx27-pwm";
			// 	reg = <0x30660000 0x10000>;
			// 	interrupts = <0x00 0x51 0x04>;
                         .pa = 0x30660000,
                         .va = 0x30660000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x51UL + 32UL), 
                         },    
                    },
                    /**< PWM (pwm@30670000) */
                    {
			// pwm@30670000 {
			// 	compatible = "fsl,imx8mn-pwm\0fsl,imx27-pwm";
			// 	reg = <0x30670000 0x10000>;
			// 	interrupts = <0x00 0x52 0x04>;
                         .pa = 0x30670000,
                         .va = 0x30670000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x52UL + 32UL), 
                         },    
                    },
                    /**< PWM (pwm@30680000) */
                    {
			// pwm@30680000 {
			// 	compatible = "fsl,imx8mn-pwm\0fsl,imx27-pwm";
			// 	reg = <0x30680000 0x10000>;
			// 	interrupts = <0x00 0x53 0x04>;
                         .pa = 0x30680000,
                         .va = 0x30680000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x53UL + 32UL), 
                         },    
                    },
                    /**< PWM (pwm@30690000) */
                    {
			// pwm@30690000 {
			// 	compatible = "fsl,imx8mn-pwm\0fsl,imx27-pwm";
			// 	reg = <0x30690000 0x10000>;
			// 	interrupts = <0x00 0x54 0x04>;
                         .pa = 0x30690000,
                         .va = 0x30690000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x54UL + 32UL), 
                         },    
                    },
                    /**< Timer (timer@306a0000) */
                    {
			// timer@306a0000 {
			// 	compatible = "nxp,sysctr-timer";
			// 	reg = <0x306a0000 0x20000>;
                         .pa = 0x306a0000,
                         .va = 0x306a0000,
                         .size = 0x20000,
                    },
                    /**< SPI (spi@30820000) */
                    {
                        // spi@30820000 {
                        //     compatible = "fsl,imx8mn-ecspi\0fsl,imx51-ecspi";
                        //     reg = <0x30820000 0x10000>;
                        //     interrupts = <0x00 0x1f 0x04>;
                         .pa = 0x30820000,
                         .va = 0x30820000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x1FUL + 32UL), 
                         },    
                    },
                    /**< SPI (spi@30830000) */
                    {
                        // spi@30830000 {
                        //     compatible = "fsl,imx8mn-ecspi\0fsl,imx51-ecspi";
                        //     reg = <0x30830000 0x10000>;
                        //     interrupts = <0x00 0x20 0x04>;
                         .pa = 0x30830000,
                         .va = 0x30830000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x20UL + 32UL), 
                         },    
                    },
                    /**< SPI (spi@30840000) */
                    {
                        // spi@30840000 {
                        //     compatible = "fsl,imx8mn-ecspi\0fsl,imx51-ecspi";
                        //     reg = <0x30840000 0x10000>;
                        //     interrupts = <0x00 0x21 0x04>;
                         .pa = 0x30840000,
                         .va = 0x30840000,
                         .size = 0x10000,
                         .interrupt_num = 1,
                         .interrupts = (irqid_t[])
                         {
                             (0x21UL + 32UL), 
                         },    
                    },
                    /**< UART serial0 (serial@30860000) */
                    {
			// serial@30860000 {
			// 	compatible = "fsl,imx8mn-uart\0fsl,imx6q-uart";
			// 	reg = <0x30860000 0x10000>;
			// 	interrupts = <0x00 0x1a 0x04>;
                        .pa = 0x30860000,
                        .va = 0x30860000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                             (0x1AUL + 32UL), 
                        },    
                        
                    },
                    /**< UART serial1 (serial@30880000) */
                    {
			// serial@30880000 {
			// 	compatible = "fsl,imx8mn-uart\0fsl,imx6q-uart";
			// 	reg = <0x30880000 0x10000>;
			// 	interrupts = <0x00 0x1c 0x04>;
                        .pa = 0x30880000,
                        .va = 0x30880000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                             (0x1CUL + 32UL), 
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
                            (0x1bUL + 32UL), //GIC_SPI_VAL(27), // GIC_SPI_VAL(0x1b),
                        },    
                        
                    },
                    /**< crypto (crypto@30900000) */
                    {
			// crypto@30900000 {
			// 	compatible = "fsl,sec-v4.0";
			// 	reg = <0x30900000 0x40000>;
			// 	ranges = <0x00 0x30900000 0x40000>;
			// 	interrupts = <0x00 0x5b 0x04>;
                        .pa = 0x30900000,
                        .va = 0x30900000,
                        .size = 0x40000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x5bUL + 32UL),
                        },    
                        
                    },
                    /**< I2C (i2c@30a20000) */
                    {
			//i2c@30a20000 {
			//	compatible = "fsl,imx8mn-i2c\0fsl,imx21-i2c";
			//	reg = <0x30a20000 0x10000>;
			//	interrupts = <0x00 0x23 0x04>;
                        .pa = 0x30a20000,
                        .va = 0x30a20000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x23UL + 32UL),
                        },    
                    },
                    /**< I2C (i2c@30a30000) */
                    {
			//i2c@30a30000 {
			//	compatible = "fsl,imx8mn-i2c\0fsl,imx21-i2c";
			//	reg = <0x30a30000 0x10000>;
			//	interrupts = <0x00 0x24 0x04>;
                        .pa = 0x30a30000,
                        .va = 0x30a30000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x24UL + 32UL),
                        },    
                    },
                    /**< I2C (i2c@30a40000) */
                    {
			//i2c@30a40000 {
			//	compatible = "fsl,imx8mn-i2c\0fsl,imx21-i2c";
			//	reg = <0x30a40000 0x10000>;
			//	interrupts = <0x00 0x25 0x04>;
                        .pa = 0x30a40000,
                        .va = 0x30a40000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x25UL + 32UL),
                        },    
                    },
                    /**< I2C (i2c@30a50000) */
                    {
			//i2c@30a50000 {
			//	compatible = "fsl,imx8mn-i2c\0fsl,imx21-i2c";
			//	reg = <0x30a50000 0x10000>;
			//	interrupts = <0x00 0x26 0x04>;
                        .pa = 0x30a50000,
                        .va = 0x30a50000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x26UL + 32UL),
                        },    
                    },
                    /**< UART serial3 (serial@30a60000) */
                    {
                        // serial@30a60000 {
                        // 	compatible = "fsl,imx8mn-uart\0fsl,imx6q-uart";
                        // 	reg = <0x30a60000 0x10000>;
                        // 	interrupts = <0x00 0x1d 0x04>;
                        .pa = 0x30a60000,
                        .va = 0x30a60000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x1dUL + 32UL), 
                        },    
                        
                    },
                    /**< mailbox (mailbox@30aa0000) */
                    {
			// mailbox@30aa0000 {
			// 	compatible = "fsl,imx8mn-mu\0fsl,imx6sx-mu";
			// 	reg = <0x30aa0000 0x10000>;
			// 	interrupts = <0x00 0x58 0x04>;
                        .pa = 0x30aa0000,
                        .va = 0x30aa0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x58UL + 32UL), 
                        },    
                        
                    },
                    /**< mmc (mmc@30b40000) */
                    {
			// mmc@30b40000 {
			// 	compatible = "fsl,imx8mn-usdhc\0fsl,imx8mm-usdhc\0fsl,imx7d-usdhc";
			// 	reg = <0x30b40000 0x10000>;
			// 	interrupts = <0x00 0x16 0x04>;
                        .pa = 0x30b40000,
                        .va = 0x30b40000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x16UL + 32UL), 
                        },    
                        
                    },
                    /**< mmc (mmc@30b50000) */
                    {
			// mmc@30b50000 {
			// 	compatible = "fsl,imx8mn-usdhc\0fsl,imx8mm-usdhc\0fsl,imx7d-usdhc";
			// 	reg = <0x30b50000 0x10000>;
			// 	interrupts = <0x00 0x17 0x04>;
                        .pa = 0x30b50000,
                        .va = 0x30b50000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x17UL + 32UL), 
                        },    
                        
                    },
                    /**< mmc (mmc@30b60000) */
                    {
			// mmc@30b60000 {
			// 	compatible = "fsl,imx8mn-usdhc\0fsl,imx8mm-usdhc\0fsl,imx7d-usdhc";
			// 	reg = <0x30b60000 0x10000>;
			// 	interrupts = <0x00 0x18 0x04>;
                        .pa = 0x30b60000,
                        .va = 0x30b60000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x18UL + 32UL), 
                        },    
                        
                    },
                    /**< spi (spi@30bb0000) */
                    {
			//spi@30bb0000 {
			//	#address-cells = <0x01>;
			//	#size-cells = <0x00>;
			//	compatible = "nxp,imx8mm-fspi";
			//	reg = <0x30bb0000 0x10000 0x8000000 0x10000000>;
			//	interrupts = <0x00 0x6b 0x04>;
                        .pa = 0x30bb0000,
                        .va = 0x30bb0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x6bUL + 32UL), 
                        },    
                        
                    },
                    /**< flash (flash@0) */
                    {
			//spi@30bb0000 {
			//	#address-cells = <0x01>;
			//	#size-cells = <0x00>;
			//	compatible = "nxp,imx8mm-fspi";
			//	reg = <0x30bb0000 0x10000 0x8000000 0x10000000>;
			//	interrupts = <0x00 0x6b 0x04>;
                        .pa = 0x8000000,
                        .va = 0x8000000,
                        .size = 0x10000000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x6bUL + 32UL), 
                        },    
                        
                    },
                    /**< DMA controller (dma-controller@30bd0000) */
                    {
			// dma-controller@30bd0000 {
			// 	compatible = "fsl,imx8mn-sdma\0fsl,imx8mq-sdma\0fsl,imx7d-sdma";
			// 	reg = <0x30bd0000 0x10000>;
			// 	interrupts = <0x00 0x02 0x04>;
                        .pa = 0x30bd0000,
                        .va = 0x30bd0000,
                        .size = 0x10000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x02UL + 32UL), 
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
                             (0x76UL + 32UL), // GIC_SPI_VAL(118), // GIC_SPI_VAL(0x76) 
                             (0x77UL + 32UL), // GIC_SPI_VAL(119), // GIC_SPI_VAL(0x77)
                             (0x78UL + 32UL), // GIC_SPI_VAL(120), // GIC_SPI_VAL(0x78)
                             (0x79UL + 32UL), // GIC_SPI_VAL(121), // GIC_SPI_VAL(0x79)
                         },    
                         //.id = 0x2,
                    },
                    /**< blk controller (blk-ctrl@32e28000) */
                    {
			// blk-ctrl@32e28000 {
			// 	compatible = "fsl,imx8mn-disp-blk-ctrl\0syscon";
			// 	reg = <0x32e28000 0x100>;
                        .pa = 0x32e28000,
                        .va = 0x32e28000,
                        .size = 0x100,
                    },
                    /**< usb (usb@32e40000) */
                    {
			//usb@32e40000 {
			//	compatible = "fsl,imx8mn-usb\0fsl,imx7d-usb";
			//	reg = <0x32e40000 0x200>;
			//	interrupts = <0x00 0x28 0x04>;
                        .pa = 0x32e40000,
                        .va = 0x32e40000,
                        .size = 0x200,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x28UL + 32UL), // GIC_SPI_VAL(118), // GIC_SPI_VAL(0x76) 
                        },    
                    },
                    /**< usbmisc (usbmisc@32e40200) */
                    {
			// usbmisc@32e40200 {
			// 	compatible = "fsl,imx8mn-usbmisc\0fsl,imx7d-usbmisc";
			// 	reg = <0x32e40200 0x200>;
			// };
                        .pa = 0x32e40200,
                        .va = 0x30340000,
                        .size = 0x200,
                    },
                    /**< DMA controller (dma-controller@33000000) */
                    {
                        // dma-controller@33000000 {
                        //     compatible = "fsl,imx7d-dma-apbh\0fsl,imx28-dma-apbh";
                        //     reg = <0x33000000 0x2000>;
                        //     interrupts = <0x00 0x0c 0x04 0x00 0x0c 0x04 0x00 0x0c 0x04 0x00 0x0c 0x04>;
                        .pa = 0x33000000,
                        .va = 0x33000000,
                        .size = 0x2000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x0CUL + 32UL), 
                        },    
                        
                    },
                    /**< NAND controller (nand-controller@33002000) */
                    {
                        // nand-controller@33002000 {
                        //     compatible = "fsl,imx8mn-gpmi-nand\0fsl,imx7d-gpmi-nand";
                        //     reg = <0x33002000 0x2000 0x33004000 0x4000>;
                        //     reg-names = "gpmi-nand\0bch";
                        //     interrupts = <0x00 0x0e 0x04>;
                        .pa = 0x33000000,
                        .va = 0x33000000,
                        .size = 0x2000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x0EUL + 32UL), 
                        },    
                        
                    },
                    /**< NAND controller (nand-controller@33002000) */
                    {
                        // nand-controller@33002000 {
                        //     compatible = "fsl,imx8mn-gpmi-nand\0fsl,imx7d-gpmi-nand";
                        //     reg = <0x33002000 0x2000 0x33004000 0x4000>;
                        //     reg-names = "gpmi-nand\0bch";
                        //     interrupts = <0x00 0x0e 0x04>;
                        .pa = 0x33004000,
                        .va = 0x33004000,
                        .size = 0x4000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x0EUL + 32UL), 
                        },    
                        
                    },
                    /**< DDR PMU (ddr-pmu@3d800000) */
                    {
                        // ddr-pmu@3d800000 {
                        //     compatible = "fsl,imx8mn-ddr-pmu\0fsl,imx8m-ddr-pmu";
                        //     reg = <0x3d800000 0x400000>;
                        //     interrupts = <0x00 0x62 0x04>;
                        .pa = 0x3d800000,
                        .va = 0x3d800000,
                        .size = 0x400000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[])
                        {
                            (0x62UL + 32UL), 
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

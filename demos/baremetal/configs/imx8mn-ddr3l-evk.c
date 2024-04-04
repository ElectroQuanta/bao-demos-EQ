#include <config.h>

VM_IMAGE(baremetal_image, XSTR(BAO_DEMOS_WRKDIR_IMGS/baremetal.bin));

/**< Macros to calculate interrupts number */
#define ADD_NRS(a, b) ((a) + (b))
#define GIC_PPI_VAL(x) ADD_NRS(x, 16)
#define GIC_SPI_VAL(x) ADD_NRS(x, 32)

/**< RAM: imx8mn-dd3rl-evk.dts */
//	memory@40000000 {
//		device_type = "memory";
//		reg = <0x00 0x40000000 0x00 0x80000000>;
//	};
#define RAM1_ADDR 0x40400000
#define RAM1_SIZE_2GB 0x80000000 /**< U-boot device tree */
#define RAM1_SIZE_1GB 0x10000000 /**< DDR3L Datasheet (1GB) */
#define CPU_NUM 4 /**< Quad-core A53 processor */

#define BAO_ENTRY_ADDR RAM1_ADDR

/**< GIC: imx8mn.dtsi */
// timer {
//     compatible = "arm,armv8-timer";
//     interrupts = <GIC_PPI 13 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>,
//         <GIC_PPI 14 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>,
//         <GIC_PPI 11 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>,
//         <GIC_PPI 10 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>;
//     clock-frequency = <8000000>;
//     arm,no-tick-in-suspend;
// };
#define TIMER_VIRQ_GIC_PPI 11
#define TIMER_INTERRUPT (GIC_PPI_VAL(TIMER_VIRQ_GIC_PPI))


/**< imx8mn.dtsi */
// uart2: serial@30890000 {
//     compatible = "fsl,imx8mn-uart", "fsl,imx6q-uart";
//     reg = <0x30890000 0x10000>;
//     interrupts = <GIC_SPI 27 IRQ_TYPE_LEVEL_HIGH>;
//     clocks = <&clk IMX8MN_CLK_UART2_ROOT>,
//         <&clk IMX8MN_CLK_UART2_ROOT>;
//     clock-names = "ipg", "per";
//     status = "disabled";
// };
/**< imx8mn-evk.dtsi */
//chosen {
//	stdout-path = &uart2;
//};
#define UART2_ADDR 0x30890000
#define UART2_SIZE 0x10000
#define UART2_GIC_SPI 27
#define UART2_INTERRUPT (GIC_SPI_VAL(UART2_GIC_SPI))


/**< GIC: imx8mn.dtsi */
//    gic: interrupt-controller@38800000 {
//            compatible = "arm,gic-v3";
//            reg = <0x38800000 0x10000>,
//            <0x38880000 0xc0000>;
//#interrupt-cells = <3>;
//            interrupt-controller;
//            interrupts = <GIC_PPI 9 IRQ_TYPE_LEVEL_HIGH>;
//        };
// 	
// }
#define GICD_ADDR 0x38800000
#define GICR_ADDR 0x38880000
#define GIC_GIC_PPI 9 /**< Interrupt for the GIC500 controller (in PPI) */
#define GIC_INTERRUPT (GIC_PPI_VAL(GIC_GIC_PPI))


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
                
                .region_num = 1,
                .regions =  (struct vm_mem_region[]) {
                    {
                        .base = RAM1_ADDR,
                        .size = RAM1_SIZE_1GB
                    }
                },

                .dev_num = 2,
                .devs =  (struct vm_dev_region[]) {
                    {   
                        /* imx_uart */
                        .pa = UART2_ADDR,
                        .va = UART2_ADDR,
                        .size = UART2_SIZE,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {UART2_INTERRUPT}
                    },
                    {   
                        /* Arch timer interrupt */
                        .interrupt_num = 1,
                        .interrupts = 
                            (irqid_t[]) {TIMER_INTERRUPT}                         
                    }
                },

                .arch = {
                    .gic = {
                        .gicd_addr = GICD_ADDR,
                        .gicr_addr = GICR_ADDR,
                    }
                }
            },
        }
    },
};

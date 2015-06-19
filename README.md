#jTDC

The jTDC is a high resolution [FPGA](https://en.wikipedia.org/wiki/Field-programmable_gate_array) based [TDC](https://en.wikipedia.org/wiki/Time-to-digital_converter) with an RMS resolution of less than 30ps. It has been developed for the Xilinx Spartan6, but can also run on the Xilinx Virtex5 or better. It provides up to 99 TDC channels with an input counter (SCALER) for each data input (overflow after 32bit).

One of the key features of this implementation is its rate stability: Each input can see up to 200 MHz without a hit being overseen; a true double pulse resolution of 5ns.

The jTDC can generate a [TRIGGER](https://en.wikipedia.org/wiki/Trigger_(particle_physics)) signal based on the data inputs. The example implementations in this repository provide a simple *OR* of all data inputs, but since this is an FPGA project, any complex trigger logic can be implemented.

If needed, both edges of the input signal can be recorded. Hence, if the input signals are delivered by a *time-over-threshold (TOT)* discriminator, a TOT-ADC information can be extracted from the TDC data.

So a single jTDC module provides TDC, TOT-ADC, TRIGGER and SCALER, which can eliminate the need to split detector signals.

The example implementation projects were created using Xilinx ISE Design Suite 14.4. The example implementations run on [ELB-VFB6](http://www.elbonn.de/cms/item.php?theme=elb-vme-vfb6&language=en) boards.

## Introduction

The jTDC is a high resolution [FPGA](https://en.wikipedia.org/wiki/Field-programmable_gate_array) based [TDC](https://en.wikipedia.org/wiki/Time-to-digital_converter) with an RMS resolution of less than 30ps. It has been developed for the Xilinx Spartan6, but can also run on the Xilinx Virtex5 or newer. It provides up to 99 TDC channels with an input counter (SCALER) for each data input (overflow after 32bit).

One of the key features of this implementation is its rate stability: Each input can record up to 200 MHz without a hit being overseen; a true double pulse resolution of 5ns.

The jTDC can generate one or more [TRIGGER](https://en.wikipedia.org/wiki/Trigger_(particle_physics)) signals based on the data inputs. The example implementations in this repository provide a simple *OR* of all data inputs, but since this is an FPGA project, any complex trigger logic can be implemented.

If needed, both edges of the input signal can be recorded. Hence, if the input signals are delivered by a *time-over-threshold (TOT)* discriminator, a TOT-ADC information can be extracted from the TDC data.

So a single jTDC module can provide TDC, TOT-ADC, TRIGGER and SCALER, which could eliminate the need to split detector signals.

The example implementation projects were created using Xilinx ISE Design Suite 14.4. The example implementations run on [ELB-VFB6](http://www.elbonn.de/cms/item.php?theme=elb-vme-vfb6&language=en) boards. The author is not affiliated with ELB. You are free to provide example imlementations for other plattforms.

## Acknowledgements

The author wants to thank Prof. Klein (Physics Institute of the University of Bonn) for his support in making this work available to the public. Furthermore, the author wants to thank his fellow colleagues Dr. Jürgen Hannappel, Oliver Freyermuth and Daniel Hammann for their important feedback during the developing process. The jTDC would not have been possible without the numerous coffee breaks, where many ideas and concepts have been born. Last but not least, the author wants to thank Georg Scheluchin for performing most of the tests involving the discriminator mezzanine.

## License, Documentation & Support

The jTDC is provided 'as is', you may use and modify it according to the GNU General Public License ([GNU GPLv3] (http://www.gnu.org/licenses/gpl-3.0.en.html)). Documentation is provided through the [jTDC wiki](https://github.com/jobisoft/jTDC/wiki). If you need further assistence, you may contact the author for additional support.

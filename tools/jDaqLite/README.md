# jDaqLite
Standalone DAQ for example implementation of [jTDC modules](https://github.com/jobisoft/jTDC) (FPGA based 30ps RMS TDCs)

This program is using the Universe II PCI-VME bridge to communicate with the FPGA. The example implementations of the jTDC provide a module ID which is queried by this program via VME. If your setup is working, calling
```
./jDAQLite [baseaddress]
```
should provide you a list of all available options for the module at the given baseadress.

/*
    Implementation of class VMEBridge
    Copyright (C) 2008 Andreas Ehmanns <universeII@gmx.de>
 
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#define _XOPEN_SOURCE 500

#include <iostream>
#include <stdio.h>
#include <unistd.h>
#include <ctype.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/poll.h>

#include <vector>

#include "include/vmeioctl.h"
#include "include/vmelib.h"

using namespace std;


//----------------------------------------------------------------------------
//  initiates VME SYSRST
//----------------------------------------------------------------------------
void VMEBridge::vmeSysReset()
{
    ioctl(uni_handle, IOCTL_VMESYSRST, 0);
}


//----------------------------------------------------------------------------
//  resets universeII driver
//----------------------------------------------------------------------------
int VMEBridge::resetDriver()
{
    if (ioctl(uni_handle, IOCTL_RESET_ALL, 0) != 0) {
        *Err << "Error resetting universeII driver!\n";
        return -1;
    }

    return 0;
}


//----------------------------------------------------------------------------
//  get memory mapped address of an image
//----------------------------------------------------------------------------
uintptr_t VMEBridge::getAddr(int handle, int size)
{
    char *mapped_data;

    mapped_data = (char *) mmap(NULL, size, PROT_WRITE | PROT_READ, MAP_SHARED,
                                handle, 0);

    if (mapped_data == (char *) -1) {
        *Err << "Unable to mmap() image/DMA to user space!\n";
        return 0;
    }

    return (uintptr_t) mapped_data;
}


//----------------------------------------------------------------------------
//  Write Universe II register 'reg'
//     reg: register offset as stated in Tundra universeII user manual
//----------------------------------------------------------------------------
unsigned int VMEBridge::readUniReg(int reg)
{
	unsigned int data;
	
	if (pread(uni_handle, &data, 4, reg) != 4) {
		*Err << "Bus error writing at Universe II register 0x" << hex << reg << dec << "!\n";
		return 0;
	}
	return data;
}


//----------------------------------------------------------------------------
//  Read Universe II register 'reg'
//     reg: register offset as stated in Tundra universeII user manual
//----------------------------------------------------------------------------
void VMEBridge::writeUniReg(int reg, unsigned int data)
{
	if (pwrite(uni_handle, &data, 4, reg) != 4) {
		*Err << "Bus error writing at Universe II register 0x" << hex << reg << dec << "!\n";
	}
}


//----------------------------------------------------------------------------
//  Read or more long word(s) (4 bytes) from 'addr' and store in 'data' 
//----------------------------------------------------------------------------
int VMEBridge::rl(int image, unsigned int addr, unsigned int *data, int size)
{
    if (image > 7)
        return -2;  // this is no master image

    if (pread(vme_handle[image], data, size,
              (addr - vmeBaseAddr[image]) | 0x40000000) != size) {
        *Err << "Bus error reading at address 0x" << hex << addr << dec
             << ", image " << image << "!\n";
        return -1;
    }

    return 0;
}


int VMEBridge::rl(int image, unsigned int addr, unsigned int *data)
{
    return rl(image, addr, data, 4);
}


//----------------------------------------------------------------------------
//  Write one or more long word(s) (4 bytes) from 'data' to 'addr' 
//----------------------------------------------------------------------------
int VMEBridge::wl(int image, unsigned int addr, unsigned int *data, int size)
{
    if (image > 7)
        return -2;  // this is no master image

    if (pwrite(vme_handle[image], data, size,
               (addr - vmeBaseAddr[image]) | 0x40000000) != size) {
        *Err << "Bus error writing at address 0x" << hex << addr << dec
             << ", image " << image << "!\n";
        return -1;
    }

    return 0;
}


int VMEBridge::wl(int image, unsigned int addr, unsigned int data)
{
    return wl(image, addr, &data, 4);
}


int VMEBridge::wl(int image, unsigned int addr, unsigned int *data)
{
    return wl(image, addr, data, 4);
}


//----------------------------------------------------------------------------
//  Read one or more word(s) (2 bytes) from 'addr' and store in 'data'
//----------------------------------------------------------------------------
int VMEBridge::rw(int image, unsigned int addr, unsigned short *data, int size)
{
    if (image > 7)
        return -2;  // this is no master image

    if (pread(vme_handle[image], data, size,
              (addr - vmeBaseAddr[image]) | 0x20000000) != size) {
        *Err << "Bus error reading at address 0x" << hex << addr << dec
             << ", image " << image << "!\n";
        return -1;
    }

    return 0;
}


int VMEBridge::rw(int image, unsigned int addr, unsigned short *data)
{
    return rw(image, addr, data, 2);
}


//----------------------------------------------------------------------------
//  Write one or more word(s) (2 bytes) from 'data' to 'addr'
//----------------------------------------------------------------------------
int VMEBridge::ww(int image, unsigned int addr, unsigned short *data, int size)
{
    if (image > 7)
        return -2;  // this is no master image

    if (pwrite(vme_handle[image], data, size,
               (addr - vmeBaseAddr[image]) | 0x20000000) != size) {
        *Err << "Bus error writing at address 0x" << hex << addr << dec
             << ", image " << image << "!\n";
        return -1;
    }

    return 0;
}


int VMEBridge::ww(int image, unsigned int addr, unsigned short data)
{
    return ww(image, addr, &data, 2);
}


int VMEBridge::ww(int image, unsigned int addr, unsigned short *data)
{
    return ww(image, addr, data, 2);
}


//----------------------------------------------------------------------------
//  Read one or more byte(s) from 'addr' and store in 'data'
//----------------------------------------------------------------------------
int VMEBridge::rb(int image, unsigned int addr, unsigned char *data, int size)
{
    if (image > 7)
        return -2;  // this is no master image

    if (pread(vme_handle[image], data, size,
              (addr - vmeBaseAddr[image]) | 0x10000000) != size) {
        *Err << "Bus error reading at address 0x" << hex << addr << dec
             << ", image " << image << "!\n";
        return -1;
    }

    return 0;
}


int VMEBridge::rb(int image, unsigned int addr, unsigned char *data)
{
    return rb(image, addr, data, 1);
}


//----------------------------------------------------------------------------
//  Write one or more byte(s) from 'data' to 'addr'
//----------------------------------------------------------------------------
int VMEBridge::wb(int image, unsigned int addr, unsigned char *data, int size)
{
    if (image > 7)
        return -2;  // this is no master image

    if (pwrite(vme_handle[image], data, size,
               (addr - vmeBaseAddr[image]) | 0x10000000) != size) {
        *Err << "Bus error writing at address 0x" << hex << addr << dec
             << ", image " << image << "!\n";
        return -1;
    }

    return 0;
}


int VMEBridge::wb(int image, unsigned int addr, unsigned char data)
{
    return wb(image, addr, &data, 1);
}


int VMEBridge::wb(int image, unsigned int addr, unsigned char *data)
{
    return wb(image, addr, data, 1);
}


//----------------------------------------------------------------------------
//  Test if a Bus Error occured
//----------------------------------------------------------------------------
int VMEBridge::testBerr()
{
    if (ioctl(uni_handle, IOCTL_TEST_BERR, 0))
        return 1;

    return 0;
}


//----------------------------------------------------------------------------
//  Test if 'addr' is an existing VME address
//----------------------------------------------------------------------------
int VMEBridge::there(unsigned int addr, unsigned int mode)
{
    int result;
    there_data_t tdata;

    tdata.addr = addr;
    tdata.mode = mode;

    result = ioctl(uni_handle, IOCTL_TEST_ADDR, &tdata);

    switch (result) {
        case 1:
            return 1;
        case -1:
            *Err << "Address " << hex << addr << dec
                 << " is not supported by any image!\n";
            return 0;
        case -2:
            *Err << "Wrong data width!\n";
            return 0;
        default:
            return 0;
    }

    return 1;
}


int VMEBridge::there(unsigned int addr)
{
    return there(addr, 1);
}


int VMEBridge::there8(unsigned int addr)
{
    return there(addr, D8);
}


int VMEBridge::there16(unsigned int addr)
{
    return there(addr, D16);
}


int VMEBridge::there32(unsigned int addr)
{
    return there(addr, D32);
}


//----------------------------------------------------------------------------
//  Checks if the VME irq parameters are in required range
//----------------------------------------------------------------------------
int VMEBridge::checkIrqParamter(unsigned int level, unsigned int statusID)
{
    if ((level < 1) || (level > 7)) {
        *Err << "Parameter VMEirq level must be in 1..7!\n";
        return -1;
    }

    if ( (statusID > 255)) {
        *Err << "Parameter status/ID must be in 0..255!\n";
        return -2;
    }

    return 0;
}


//----------------------------------------------------------------------------
//  setup IRQ handling
//----------------------------------------------------------------------------
int VMEBridge::setupIrq(int image,
                        unsigned int irqLevel, unsigned int statusID,
                        unsigned int addrSt, unsigned int valSt,
                        unsigned int addrCl, unsigned int valCl)
{
    irq_setup_t irqsetup;

    if (checkIrqParamter(irqLevel, statusID) != 0)
        return -1;

    irqsetup.vmeIrq = irqLevel;
    irqsetup.vmeStatus = statusID;
    irqsetup.vmeAddrSt = addrSt;
    irqsetup.vmeValSt = valSt;
    irqsetup.vmeAddrCl = addrCl;
    irqsetup.vmeValCl = valCl;

    if (ioctl(vme_handle[image], IOCTL_SET_IRQ, &irqsetup)) {
        *Err << "Irq/status combination is already in use!\n";
        return -2;
    }

    return 0;
}


//----------------------------------------------------------------------------
//  release IRQ: Removes allocation for IRQ for given Level and statusID
//----------------------------------------------------------------------------
int VMEBridge::freeIrq(int image, unsigned int irqLevel, unsigned int statusID)
{
    irq_setup_t irqsetup;

    if (checkIrqParamter(irqLevel, statusID) != 0)
        return -1;

    irqsetup.vmeIrq = irqLevel;
    irqsetup.vmeStatus = statusID;

    if (ioctl(vme_handle[image], IOCTL_FREE_IRQ, &irqsetup)) {
        *Err << "Irq/status combination not found!\n";
        return -2;
    }

    return 0;
}


//----------------------------------------------------------------------------
//  wait for IRQ
//----------------------------------------------------------------------------
int VMEBridge::waitIrq(unsigned int irqLevel, unsigned int statusID,
                       unsigned long timeout)
{
	irq_wait_t irqData;

    if (checkIrqParamter(irqLevel, statusID) != 0)
        return -1;

    irqData.irqLevel = irqLevel;
    irqData.statusID = statusID;
    irqData.timeout = timeout;

    if (ioctl(uni_handle, IOCTL_WAIT_IRQ, &irqData) != 0)
        return -2;

    return 0;
}


int VMEBridge::waitIrq(unsigned int irqLevel, unsigned int statusID)
{
	return waitIrq(irqLevel, statusID, 0);
}


//----------------------------------------------------------------------------
//  Generate VMEBus irq
//----------------------------------------------------------------------------
int VMEBridge::generateVmeIrq(unsigned int irqLevel, unsigned int statusID)
{

    if (checkIrqParamter(irqLevel, statusID) != 0)
        return -1;

    if (statusID & 1) {
        *Err << "Error! Due to a limitation of the universeII chip, software "
             << "generated VMEBus interrupts can only be performed with an "
             << "even statusID!\n(see docu for more information)\n";
        return -2;
    }

    ioctl(uni_handle, IOCTL_GEN_VME_IRQ, (statusID << 24) | irqLevel);

    return 0;
}


//----------------------------------------------------------------------------
//  Checks if mailbox number is in range 0..3
//----------------------------------------------------------------------------
int VMEBridge::checkMbxNr(int mailbox)
{
    if ((mailbox < 0) || (mailbox > 3)) {
        *Err << "Mailbox number must be in 0..3!\n";
        return -1;
    }

    return 0;
}


//----------------------------------------------------------------------------
//  setup universeII mailbox use
//----------------------------------------------------------------------------
int VMEBridge::setupMBX(int mailbox)
{
    if (checkMbxNr(mailbox) != 0)
        return -1;

    if (ioctl(uni_handle, IOCTL_SET_MBX, mailbox) != 0) {
        *Err << "Mailbox " << mailbox << " already in use!\n";
        return -2;
    }

    return 0;
}


//----------------------------------------------------------------------------
//  wait for VME access to mailbox
//----------------------------------------------------------------------------
unsigned int VMEBridge::waitMBX(int mailbox, unsigned int timeout)
{
    unsigned int mbx;

    if (checkMbxNr(mailbox) != 0)
        return 0xFFFFFFFF;

    if ((timeout < 1) || (timeout > 10000)) {
        *Err << "Timeout value must be in [1..10000] s!\n";
        return 0xFFFFFFFF;
    }

    mbx = ioctl(uni_handle, IOCTL_WAIT_MBX, (timeout << 16) | mailbox);

    if (mbx == 0xFFFFFFFF) {
        *Err << "Mailbox " << mailbox << " timed out!\n";
        return 0xFFFFFFFF;
    }

    return mbx;
}


unsigned int VMEBridge::waitMBX(int mailbox)
{
    return waitMBX(mailbox, 1);
}


//----------------------------------------------------------------------------
//  release mailbox
//----------------------------------------------------------------------------
int VMEBridge::releaseMBX(int mailbox)
{
    if (checkMbxNr(mailbox) != 0)
        return -1;

    if (ioctl(uni_handle, IOCTL_RELEASE_MBX, mailbox) != 0) {
        *Err << "Mailbox " << mailbox << " is not in use!\n";
        return -2;
    }

    return 0;
}


//----------------------------------------------------------------------------
//  Request ownership of UniverseII onboard DMA and setup multiple buffer
//----------------------------------------------------------------------------
unsigned int VMEBridge::requestDMA(int nrOfBufs)
{
    int result, i = 0;

    switch (nrOfBufs) {
        case 1:
        case 2:
        case 4:
        case 8:
        case 16:
        case 32:
        case 64:
        case 128:
            break;
        default:
            *Err << "requestDMA: bufNr must be in [1..128] and of 2^n!\n";
            return 0;
    }

    do {
        result = ioctl(dma_handle, IOCTL_REQUEST_DMA, nrOfBufs);
        i++;
    } while ((!result) && (i < 100));

    if (i == 100) {
        *Err << "Timeout: Can't allocate UniverseII onboard DMA!\n";
        return 0;
    }

    dmaImageSize = 0x20000;
    dmaBufSize = 0x20000 / nrOfBufs;
    dmaMaxBuf = nrOfBufs - 1;
    dmaImageBase = getAddr(dma_handle, dmaImageSize);

    return dmaImageBase;
}


unsigned int VMEBridge::requestDMA(void)
{
    return requestDMA(1);
}


//----------------------------------------------------------------------------
//  Release ownership of UniverseII onboard DMA
//----------------------------------------------------------------------------
void VMEBridge::releaseDMA(void)
{
    ioctl(dma_handle, IOCTL_RELEASE_DMA, 0);
    if (munmap((char *) dmaImageBase, dmaImageSize))
        *Err << "Can't munmap allocated memory for DMA";

    dmaImageSize = 0;
    dmaBufSize = 0;
    dmaMaxBuf = 0;
}


//----------------------------------------------------------------------------
//  Checks validity of DMA parameters 'count' and 'buffer Number'
//----------------------------------------------------------------------------
int VMEBridge::checkDmaParam(unsigned int count, unsigned int bufNr)
{
    if (count > dmaBufSize) {
        *Err << "DMA operation exceeds buffer size of " << dmaBufSize / 1024
             << " kB!\n";
        return -1;
    }

    if (bufNr > dmaMaxBuf) {
        *Err << "DMAwrite: Buffer number too high! Only " << dmaMaxBuf + 1
             << " buffer(s) available!\n";
        return -2;
    }

    return 0;
}


//----------------------------------------------------------------------------
//  write data PCI -> VME using onboard DMA
//----------------------------------------------------------------------------
int VMEBridge::DMAwrite(unsigned int dest, unsigned int count,
                        int vas, int vdw, unsigned int bufNr)
{
    int offset;
    dma_param_t param;

    if (checkDmaParam(count, bufNr) != 0)
        return -1;

    param.addr = dest;
    param.count = count;
    param.vas = vas;
    param.vdw = vdw;
    param.dma_ctl = dma_ctl;
    param.bufNr = bufNr;

    offset = pwrite(dma_handle, &param, sizeof(param), 0);
    if (offset < 0) {
        *Err << "DMA error! Not all bytes written!\n"
             << "offset: " << offset << "!\n";
        return -2;
    }

    return offset;
}


int VMEBridge::DMAwrite(unsigned int dest, unsigned int count, int vas, int vdw)
{
    return DMAwrite(dest, count, vas, vdw, 0);
}


//----------------------------------------------------------------------------
//  read data VME -> PCI using onboard DMA
//----------------------------------------------------------------------------
int VMEBridge::DMAread(unsigned int source, unsigned int count,
                       int vas, int vdw, unsigned int bufNr)
{
    int offset;
    dma_param_t param;

    if (checkDmaParam(count, bufNr) != 0)
        return -1;

    param.addr = source;
    param.count = count;
    param.vas = vas;
    param.vdw = vdw;
    param.dma_ctl = dma_ctl;
    param.bufNr = bufNr;

    offset = pread(dma_handle, &param, sizeof(param), 0);
    if (offset < 0) {
        *Err << "DMA error! Not all bytes read!\n"
             << "offset: " << offset << "!\n";
        return -3;
    }

    return offset;
}


int VMEBridge::DMAread(unsigned int source, unsigned int count,
                       int vas, int vdw)
{
    return DMAread(source, count, vas, vdw, 0);
}


//----------------------------------------------------------------------------
//  Create new command packet list and return list number
//----------------------------------------------------------------------------
int VMEBridge::newCmdPktList(void)
{
    int list;

    list = ioctl(uni_handle, IOCTL_NEW_DCP, 0);
    if (list < 0) {
        *Err << "Can't create new command packet list!\n";
        return -1;
    }

    usedLists.push_back(list);

	listPtr[list]=0;
    return list;
}


//----------------------------------------------------------------------------
//  Create new command packet list and return list number
//----------------------------------------------------------------------------
int VMEBridge::delCmdPktList(int list)
{
    vector <int>::iterator it;

    if (list < 0) {
        *Err << "Invalid list number: " << list << "!\n";
        return -1;
    }

    ioctl(uni_handle, IOCTL_DEL_DCL, list);

    for (it = usedLists.begin(); it != usedLists.end(); it++)
        if (*it == list) {
            usedLists.erase(it);
            break;
        }

    return 0;
}



//----------------------------------------------------------------------------
//  Add command packet to 'list'
//----------------------------------------------------------------------------
unsigned int VMEBridge::addCmdPkt(int list, int write, unsigned int vmeAddr,
                                  int size, int vas, int vdw)
{
//     unsigned int offset;
	int offset;
    list_packet_t lpacket;

    if ((write < 0) || (write > 1)) {
        *Err << "Illigal write parameter!\n";
        return 0xFFFFFFFF;
    }
    lpacket.dctl = (write << 31) | vdw | vas;
    lpacket.dtbc = size;
    lpacket.dva = vmeAddr;
    lpacket.list = list;

    offset = ioctl(uni_handle, IOCTL_ADD_DCP, &lpacket);

    if (offset < 0) {
        *Err << "Can't add Command Packet to list " << list << "!\n";
        return 0xFFFFFFFF;
    }
	listPtr[list] += size + offset;

	return listPtr[list] - size;
}


//----------------------------------------------------------------------------
//  Execute DMA command packet 'list'
//----------------------------------------------------------------------------
int VMEBridge::execCmdPktList(int list)
{
    int ret;

    ret = ioctl(uni_handle, IOCTL_EXEC_DCP, list);

    if (ret > 0) {
        *Err << "Error executing list " << list << ", packet nr " << ret << "!\n";
        return -1;
    }

    if (ret < 0) {
        *Err << "DMA error occured before/while executing list " << list << "!\n";
        return -2;
    }

    return 0;
}


//----------------------------------------------------------------------------
//  Get PCI base address to access VME directly
//----------------------------------------------------------------------------
uintptr_t VMEBridge::getPciBaseAddr(int image)
{
    if ((image < 0) || (image > 17)) {
        *Err << "getPciBaseAddr: Image nr. " << image << " is invalid!\n";
        return 0xFFFFFFFF;
    }

    return vmeImageBase[image];
}


//----------------------------------------------------------------------------
//  set/reset different options for 'image'
//----------------------------------------------------------------------------
void VMEBridge::setOption(int image, unsigned int opt)
{
    unsigned int par;

    par = 0;

    if (opt & 0x1) // program AM
    {
      if (image < 10)
            par |= 0x00004000;
        else
            par |= 0x00800000;
    }
    if ((image > 9) && (opt & 0x2)) // data AM for slave images
        par |= 0x00400000;

    if (opt & 0x4)  // super AM
    {
      if (image < 10)
            par |= 0x00001000;
        else
            par |= 0x00200000;
    }
    if ((image > 9) && (opt & 0x8)) // non-priv AM for slave images
        par |= 0x00100000;

    if (opt & 0x10) // block transfer on
    {
      if (image < 10)
            par |= 0x00000100;
        else
            *Err << "BLT_ON is no valid option for slave images!\n";
    }
    if (opt & 0x40) // posted write enable
        par |= 0x40000000;

    if (opt & 0x100)    // enable prefetched read
    {
      if (image < 10) // slave images only!!!
            *Err << "PREF_READ_EN is no valid option for master images!\n";
        else
            par |= 0x20000000;
    }
    if (opt & 0x400)    // enable PCI bus lock for RMW cycles
    {
      if (image < 10)
            *Err << "PCI_LCK_RMW_EN is no valid option for master images!\n";
        else
            par |= 0x00000040;
    }
    if (par)
    {
      if (image == DMA)
    
            dma_ctl |= par & 0x0000F100;
        else
            ioctl(vme_handle[image], IOCTL_SET_OPT, par);
    }
    par = 0;

    if (opt & 0x2)  // data AM for master images
        if (image < 10)
            par |= 0x10004000;

    if (opt & 0x8)  // non privileged AM
        if (image < 10)
            par |= 0x10001000;

    if (opt & 0x20) // block transfer off
    {
      if (image < 10)
            par |= 0x10000100;
        else
            *Err << "BLT_OFF is no valid option for slave images!\n";
    }
    if (opt & 0x80) // disable posted write
        par |= 0x50000000;

    if (opt & 0x200)    // disable prefetched read
    {
      if (image < 10) // slave images only!!!
            *Err << "PREF_READ_DIS is no valid option for master images!\n";
        else
            par |= 0x30000000;
    }
    if (opt & 0x800)    // enable PCI bus lock for RMW cycles
    {
      if (image < 10)
            *Err << "PCI_LCK_RMW_DIS is no valid option for master images!\n";
        else
            par |= 0x10000040;
    }
    
    if (par)
    {
      if (image == DMA)
            dma_ctl &= ~(par & 0x0000F100);
        else
            ioctl(vme_handle[image], IOCTL_SET_OPT, par);
    }
}


//----------------------------------------------------------------------------
//  vmemap          Note: Images 1-3 have to be 64k aligned
//----------------------------------------------------------------------------
int VMEBridge::vmemap(int image, unsigned int vme_base, unsigned int size,
                      unsigned int ctl, int ms)
{
    int ret;
    image_regs_t imageRegs;

	imageRegs.base = vme_base;
	imageRegs.size = (((size - 1) / 0x10000) + 1) * 0x10000;
    imageRegs.ms = ms;

// Disable image and check that device is accessible

    ctl &= ~CTL_EN;
    if (ioctl(vme_handle[image], IOCTL_SET_CTL, ctl)) {
        *Err << "vmemap: Can't write to image " << image << "!  ";
        bridge_error = -6;
        return -6;
    }

    ret = ioctl(vme_handle[image], IOCTL_SET_IMAGE, &imageRegs);

	if (ret < 0) {
		*Err << "Error: Failed to allocate Image " << image << "!\n";
        bridge_error = -7;
        return -7;
    }

// Enable image

    ctl |= CTL_EN;
    ioctl(vme_handle[image], IOCTL_SET_CTL, ctl);

    return 0;
}


//----------------------------------------------------------------------------
//  getImage
//----------------------------------------------------------------------------
int VMEBridge::getImage(unsigned int base, unsigned int size,
                        int vas, int vdw, int ms)
{
    char vmeDev[80];
    int image;
    unsigned int ctl;

//  Try to allocate a new image;  ms = 0: master image, ms = 1: slave image

    image = ioctl(uni_handle, IOCTL_GET_IMAGE, ms);

    if (image < 0) {
        *Err << "No free image available!\n";
        bridge_error = -4;
        return -1;
    }

    if (!ms)
        sprintf(vmeDev, "/dev/vme_m%i", image);
    else
        sprintf(vmeDev, "/dev/vme_s%i", image - 10);

    vme_handle[image] = open(vmeDev, O_RDWR, 0);
    if (vme_handle[image] < 1) {
        *Err << "Can't open VME image device nr. " << image << "!\n";
        vme_handle[image] = -1;
        bridge_error = -5;
        return -2;
    }

    if (base & 0x0000FFFF) {
        base &= 0xFFFF0000;
        *Std << "Warning: Base address must be 64k aligned! "
             << "Base address will be set to " << hex << base << dec << "!\n";
    }
// setup registers CTL, TO, BD, BS of image

    if (ms) {   // Slave image
        ctl = 0x40F00000 | vas; // enable posted write, data/program
        if (size > 0x20000) {   // and non-priv/super AM
            size = 0x20000;
            *Err << "Size of slave images is limited to 128 kB!\n";
        }
    } else {    // Master image
        ctl = 0x40000000 | vdw | vas;   // enable posted write, non-priv. data
        vmeBaseAddr[image] = base;
    }

    if (vmemap(image, base, size, ctl, ms) < 0)
        return -3;

    vmeImageBase[image] = getAddr(vme_handle[image], size);
    vmeImageSize[image] = size;

    return image;
}


//----------------------------------------------------------------------------
//  releaseImage
//----------------------------------------------------------------------------
void VMEBridge::releaseImage(int image)
{
    if (munmap((char *) vmeImageBase[image], vmeImageSize[image]))
        *Err << "Can't munmap allocated memory of image " << image << "!";
    else {
        vmeImageBase[image] = 0;
        vmeImageSize[image] = 0;
        if (image < 8)
            vmeBaseAddr[image] = 0;
    }

    if (vme_handle[image] != -1) {
        if (close(vme_handle[image]))
            *Err << "Can't free image " << image << "!";
        else
            vme_handle[image] = -1;
    }
}


//----------------------------------------------------------------------------
//  Constructor
//----------------------------------------------------------------------------
VMEBridge::VMEBridge(void)
{
    int i;

    Std = &cout;
    Err = &cerr;

    bridge_error = 0;

    uni_handle = open("/dev/vme_ctl", O_RDWR, 0);
    if (uni_handle < 1) {
        *Err << "Can't open Universe Control device!\n";
        bridge_error = -1;
    }

    dma_handle = open("/dev/vme_dma", O_RDWR, 0);
    if (dma_handle < 1) {
        *Err << "Can't open DMA image device!\n";
        bridge_error = -2;
    }

    for (i = 0; i < 8; i++)
        vmeBaseAddr[i] = 0;

    for (i = 0; i < 18; i++) {
        vme_handle[i] = -1;
        vmeImageBase[i] = 0;
        vmeImageSize[i] = 0;
    }

    dmaImageSize = 0;
    dma_ctl = 0;
}


//----------------------------------------------------------------------------
//  Destructor
//----------------------------------------------------------------------------
VMEBridge::~VMEBridge(void)
{
    int i;

    vector <int>::iterator it;

// remove all existing DMA command packet lists

    for (it = usedLists.begin(); it != usedLists.end(); it++)
        ioctl(uni_handle, IOCTL_DEL_DCL, *it);

// close all opened images and unmap memory

    for (i = 0; i < 18; i++) {
        if (vme_handle[i] != -1) {
            if (munmap((char *) vmeImageBase[i], vmeImageSize[i]))
                *Err << "Can't munmap allocated memory for image " << i <<
                    "!\n";
            if (close(vme_handle[i]))
                *Err << "Can't close image " << i << "!\n";
        }
    }

// close control device

    if (close(uni_handle))
        *Err << "Can't close universeII main control device!\n";

// unmap DMA memory and close DMA device

    if (dmaImageSize)
        if (munmap((char *) dmaImageBase, dmaImageSize))
            *Err << "Can't munmap allocated memory for DMA!\n";

    if (close(dma_handle))
        *Err << "Can't close DMA handle!\n";

}

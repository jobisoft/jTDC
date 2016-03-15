/*
    Definition of class VMEBridge
    Copyright (C) 2008 Andreas Ehmanns <ehmanns@iskp.uni-bonn.de>
 
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

#ifndef VMELIB_H
#define VMELIB_H

#include <vector>
#include <stdint.h>
#include <stddef.h>
#include<ostream>


//----------------------------------------------------------------------------
// Defines
//----------------------------------------------------------------------------
#define CTL_EN		0x80000000

#define PROG_AM         0x1
#define DATA_AM         0x2
#define SUPER_AM        0x4
#define NON_PRIV_AM     0x8
#define BLT_ON          0x10
#define BLT_OFF         0x20
#define POST_WRITE_EN   0x40
#define POST_WRITE_DIS  0x80
#define PREF_READ_EN    0x100
#define PREF_READ_DIS   0x200

#define D64    0x00C00000
#define D32    0x00800000
#define D16    0x00400000
#define D8     0x00000000

#define A32    0x00020000
#define A24    0x00010000
#define A16    0x00000000

#define MASTER 0
#define SLAVE  1

#define DMA    9

//----------------------------------------------------------------------------
// Prototypes
//----------------------------------------------------------------------------

class VMEBridge
{
  private:
    static const unsigned int slave_base_addr[];
    int vme_handle[18], uni_handle, dma_handle;

	unsigned int listPtr[256], dma_ctl;
    uintptr_t vmeBaseAddr[8];
    uintptr_t vmeImageBase[18];
    size_t  vmeImageSize[18];
    uintptr_t dmaImageBase;
    ptrdiff_t dmaImageSize;
    unsigned int dmaMaxBuf;
    size_t dmaBufSize;
    std::vector < int >usedLists;

    int there(unsigned int addr, unsigned int mode);
    int checkIrqParamter(unsigned int level, unsigned int statusID);
    int checkMbxNr(int mailbox);
    int checkDmaParam(unsigned int count, unsigned int bufNr);
    uintptr_t getAddr(int, int);
    int vmemap(int, unsigned int, unsigned int, unsigned int, int);

  public:
     VMEBridge();
     virtual ~ VMEBridge();

// image related function

    int getImage(unsigned int base, unsigned int size,
                 int vas, int vdw, int ms);
    void releaseImage(int image);
    uintptr_t getPciBaseAddr(int image);

// Options

    void setOption(int image, unsigned int opt);

// IRQ

    int setupIrq(int image, unsigned int irqLevel, unsigned int statusID,
                 unsigned int addrSt, unsigned int valSt,
                 unsigned int addrCl, unsigned int valCl);
    int freeIrq(int image, unsigned int irqLevel, unsigned int statusID);
    int waitIrq(unsigned int irqLevel, unsigned int statusID);
    int waitIrq(unsigned int irqLevel, unsigned int statusID,
                unsigned long timeout);
    int generateVmeIrq(unsigned int irqLevel, unsigned int statusID);

// Mailbox use

    int setupMBX(int mailbox);
    unsigned int waitMBX(int mailbox, unsigned int timeout);
    unsigned int waitMBX(int mailbox);
    int releaseMBX(int mailbox);

// DMA

    unsigned int requestDMA(void);
    unsigned int requestDMA(int);
    void releaseDMA(void);
    int DMAread(unsigned int source, unsigned int count, int vas, int vdw);
    int DMAread(unsigned int source, unsigned int count, int vas, int vdw,
                unsigned int bufNr);
    int DMAwrite(unsigned int dest, unsigned int count, int vas, int vdw);
    int DMAwrite(unsigned int dest, unsigned int count, int vas, int vdw,
                 unsigned int bufNr);

// DMA linked list operations

    int newCmdPktList(void);
    int delCmdPktList(int list);
    unsigned int addCmdPkt(int list, int write, unsigned int vmeAddr,
                           int size, int vas, int vdw);
    int execCmdPktList(int list);

// Read/Write access to VME resources, data size 1,2,4 byte(s)

    int rl(int image, uint32_t addr, unsigned int *data);
    int wl(int image, unsigned int addr, unsigned int *data);
    int wl(int image, unsigned int addr, unsigned int data);

    int rw(int image, unsigned int addr, unsigned short *data);
    int ww(int image, unsigned int addr, unsigned short *data);
    int ww(int image, unsigned int addr, unsigned short data);

    int rb(int image, unsigned int addr, unsigned char *data);
    int wb(int image, unsigned int addr, unsigned char *data);
    int wb(int image, unsigned int addr, unsigned char data);

// Block read/write functions

    int rl(int image, unsigned int addr, unsigned int *data, int size);
    int wl(int image, unsigned int addr, unsigned int *data, int size);

    int rw(int image, unsigned int addr, unsigned short *data, int size);
    int ww(int image, unsigned int addr, unsigned short *data, int size);

    int rb(int image, unsigned int addr, unsigned char *data, int size);
    int wb(int image, unsigned int addr, unsigned char *data, int size);

    int testBerr();
    int there(unsigned int addr);
    int there8(unsigned int addr);
    int there16(unsigned int addr);
    int there32(unsigned int addr);

// Access to Universe II Register (for use of unsupported features)

    unsigned int readUniReg(int);
    void writeUniReg(int, unsigned int);

    int resetDriver();
    void vmeSysReset();

    int bridge_error;

  protected:   // logging streams

    std::ostream * Std;
    std::ostream *Err;

  public:

     virtual void setErrorlog(std::ostream * log)
    {
        Err = log;
    }

    virtual void setStdlog(std::ostream * log)
    {
        Std = log;
    }

};

#endif

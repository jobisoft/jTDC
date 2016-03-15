/*
    jDAQLite, simple user interface to read out jTDC modules
    Copyright (C) 2014 John Bieling <john.bieling@uni-bonn.de>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.    
*/

#include "vmelib/include/vmelib.h"

#include <iostream>
#include <map>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <unistd.h>

#include <sys/time.h>
#include <stdlib.h>
#include <signal.h>
#include <termios.h>

int NB_ENABLE = 1;
int NB_DISABLE = 0;

using namespace std;




 //* * * * * * * * * * * * * * * * * * * *//
 //*   H E L P E R   F U N C T I O N S   *//
 //* * * * * * * * * * * * * * * * * * * *//

bool abort_request;

void CtrlCHandler(int sig)
{
        abort_request = true;
        cout << "anceling..." << endl;
        signal(sig,SIG_IGN);  
}

int kbhit()
{
        struct timeval tv;
        fd_set fds;
        tv.tv_sec = 0;
        tv.tv_usec = 0;
        FD_ZERO(&fds);
        FD_SET(STDIN_FILENO, &fds); //STDIN_FILENO is 0
        select(STDIN_FILENO+1, &fds, NULL, NULL, &tv);
        return FD_ISSET(STDIN_FILENO, &fds);
}

void nonblock(int state)
{
        struct termios ttystate;
        
        //get the terminal state
        tcgetattr(STDIN_FILENO, &ttystate);
        
        if (state==NB_ENABLE)
        {
                //turn off canonical mode
                ttystate.c_lflag &= ~ICANON;
                //minimum of number input read.
                ttystate.c_cc[VMIN] = 1;
        }
        else if (state==NB_DISABLE)
        {
                //turn on canonical mode
                ttystate.c_lflag |= ICANON;
        }
        //set the terminal attributes.
        tcsetattr(STDIN_FILENO, TCSANOW, &ttystate);
}

float voltage_from_adc_value(short int adc_value){
        return (2*adc_value*4.096/32768);
}










 //* * * * * * * * * * * * * * * * * * * * * *//
 //*   P A R A M E T E R   H A N D L I N G   *//
 //* * * * * * * * * * * * * * * * * * * * * *//

enum PNAME {ERROR,RATES,COUNTS,DUTY,RESET,INIT,START1,EVENTS,RANGE,GEOID,TRIGGER,SELF,VERBOSE,VVERBOSE,RBASE};

class parameterHandle {
        private:
                struct PDATA {
                        string sShort;
                        string sLong;
                        string sDescription;
                        bool moredata;
                        uint value;
                        bool flag;
                        bool allowed;
                };
                string intro;
                string outro;
                map<PNAME, PDATA> dataset;
        public:
                parameterHandle();
                void add(PNAME p, bool moredata, string l, string s, string d);
                PNAME find(string);
                bool hasMoredata(PNAME);
                void storeValue(PNAME,string);
                uint get(PNAME);
                void set(PNAME);
                bool isSet(PNAME);
                void allow(PNAME);
                bool check();
                void setIntro(string);
                void setOutro(string);
                string getIntro();
                string getOutro();
                
};

parameterHandle::parameterHandle() {
        dataset.clear();
}


void parameterHandle::setIntro(string str) { intro = str; }
void parameterHandle::setOutro(string str) { outro = str; }


bool parameterHandle::hasMoredata(PNAME p) {
        return dataset.at(p).moredata;
}


void parameterHandle::storeValue(PNAME p, string value) {
        dataset.at(p).flag = true;
        if (dataset.at(p).moredata) {
                dataset.at(p).value = strtoul(value.c_str(),NULL,0);
        }
}

uint parameterHandle::get(PNAME p) {
        return dataset.at(p).value;        
}

void parameterHandle::set(PNAME p) {
        dataset.at(p).flag = true;
}


bool parameterHandle::isSet(PNAME p) {
        return dataset.at(p).flag;
}


void parameterHandle::allow(PNAME p) {
        dataset.at(p).allowed = true;
}


PNAME parameterHandle::find(string needle) {
        //iterate over map and find parameterHandle
        PNAME found = ERROR;
        map<PNAME, PDATA>::iterator i;
   
        for (i = dataset.begin(); i != dataset.end(); i++) {
                if ((i->second.sShort == needle) || (i->second.sLong == needle)) {
                        found = i->first;
                        break;
                }
        }        
        return found;
}


void parameterHandle::add(PNAME p, bool m, string l, string s, string d) {
        PDATA prep;
        prep.sShort = s;
        prep.sLong = l;
        prep.sDescription = d;
        prep.moredata = m;  
        prep.value = 0;
        prep.flag = false;
        prep.allowed = false;
        dataset.insert( std::pair<PNAME,PDATA>(p,prep) );       
}



bool parameterHandle::check ()
{
        bool isOK = true;
        string dummy = "";
        
        map<PNAME, PDATA>::iterator i;
        
        for (i = dataset.begin(); i != dataset.end(); i++) {
                if (i->second.flag && !i->second.allowed) isOK = false;
        }        

        
        if (!isOK) {
                cout << intro << endl << endl;
                for (i = dataset.begin(); i != dataset.end(); i++) {
                        if (i->second.moredata) dummy = " <...>";
                        else dummy = "      ";
                        if (i->second.allowed) {
                                cout << "\t   " << i->second.sLong << "\t" << i->second.sShort << dummy << "\t : " << i->second.sDescription << endl;
                        }
                }        
                cout << endl ;
                cout << outro << endl << endl;
        }
        
        return isOK;
}










 //* * * * * * * * * * * * * * * * * *//
 //*   C O R E   F U N C T I O N S   *//
 //* * * * * * * * * * * * * * * * * *//

void jScaler (VMEBridge* vme, int VMEImage, uint baseaddress, bool rate, bool reset, bool dutycycle)
{
        cout << "Initializing module for SCALER readout ... " << endl << endl;
        
        uint counter_reset = 2;
        uint counter_latch = 4; 
                                        
        uint clockregister = 0x0044;
        uint counterbase = 0x4000;

        uint clockfreq = 200;
        
        //set config register
        uint config_register = 0;
        if (dutycycle) config_register = 1 << 5;
        vme->wl(VMEImage,baseaddress +0x0020,config_register); 

        //reset all counters for start
        vme->wl(VMEImage,baseaddress +0x0024,counter_reset); 
        //disable external latch
        vme->wl(VMEImage,baseaddress +0x0028,0x70000000); 


        //If we are in rate mode, we need to reset, otherwise it will do stupid things on overflow
        if (rate == true || dutycycle == true) reset = true;


        bool keeprunning = true;

        nonblock(NB_ENABLE);        
        while (keeprunning)
        {

                if (reset) vme->wl(VMEImage,baseaddress +0x0024,counter_latch+counter_reset);
                else vme->wl(VMEImage,baseaddress +0x0024,counter_latch);

                printf(" Module: jTDC\n\n");

                //step 1: read out all counters
                uint clk = 0;
                uint scaler[98];
        
                vme->rl(VMEImage,baseaddress + clockregister,&clk); 
                
                for (uint counter=0;counter<98;counter+=1) {
                                vme->rl(VMEImage,baseaddress + counterbase + 4*counter,&scaler[counter]); 
                }

                //step 2: print scaler values
                printf(" Clk  : %9X \n", clk);

                if (rate == true) {
                                printf(" Channel  0 (NIM_IN[0]) : %9.0f Hz\n", (scaler[0]*1E9/(1000.*clk/clockfreq)));
                                printf(" Channel 97 (NIM_IN[1]) : %9.0f Hz\n\n", (scaler[97]*1E9/(1000.*clk/clockfreq)));
                } else {
                                printf(" Channel  0 (NIM_IN[0]) : %9d \n", scaler[0]);
                                printf(" Channel 97 (NIM_IN[1]) : %9d \n\n", scaler[97]);
                }               
                cout << " Channel  |  InputCounter                Channel  |  InputCounter                Channel  |  InputCounter"  << endl;
                cout << "--------------------------              --------------------------              --------------------------"  << endl;


                for (uint counter=1;counter<33;counter+=1)
                {                       

                                if (rate == true) {
                                        printf("    %2u    |  %9.0f Hz                   %2u    |  %9.0f Hz                   %2u    |  %9.0f Hz \n", counter, (scaler[counter]*1E9/(1000.*clk/clockfreq)), counter+32, (scaler[counter+32]*1E9/(1000.*clk/clockfreq)),  counter+64,  (scaler[counter+64]*1E9/(1000.*clk/clockfreq)));
                                } else if (dutycycle == true) {
                                  
                                        for (int g=0;g<3;g++) {
                                            double duty = (double)scaler[counter+g*32]/clk;
                                            if (duty>0.5) printf("  \033[1;31m  %2u  \033[0m  |  %9.7f %%                ", counter+g*32, duty);
                                            else printf("    %2u    |  %9.7f %%                ", counter+g*32, duty);
                                        }
                                        cout << endl;
                                        
                                } else {
                                        printf("    %2u    |  %9d                      %2u    |  %9d                      %2u    |  %9d \n", counter, scaler[counter], counter+32, scaler[counter+32],  counter+64,  scaler[counter+64]);
                                }
                                                
                }
                cout << endl;
                cout << " (Q)uit    (R)eset   : " << flush;
                usleep(500000);

                int keypress = kbhit();
                if (keypress != 0)
                {
                        char c=fgetc(stdin);
                        if (c=='q') 
                        {
                                keeprunning = false;
                                cout << " -> Quit!";
                        }
                        
                        if (c=='r') 
                        {
                                vme->wl(VMEImage,baseaddress +0x0024,counter_reset); 
                                cout << " -> Reset Counters";
                        }
                        cout << endl << endl;                       
                }

        }
        nonblock(NB_DISABLE);        
                                              
}






void jDisc (VMEBridge* vme, int VMEImage, uint baseaddress, bool rate, bool reset, bool init, bool dutycycle)
{
        cout << "Initializing module for SCALER and VOLTAGE readout ... " << endl << endl;
        
        uint counter_reset = 2;
        uint counter_latch = 4; 
                                        
        uint clockregister = 0x0044;
        uint counterbase = 0x4000;
        uint discbase = 0xA000;
        uint clockfreq = 200;
        
        if (dutycycle) {
            reset = true;
        }
        
        if (init) {
                //reset DAQs and HYSTH
                vme->wl(VMEImage,baseaddress + discbase + 0x004,0x1); //MEZA +0
                vme->wl(VMEImage,baseaddress + discbase + 0x044,0x1); //MEZB +40
                vme->wl(VMEImage,baseaddress + discbase + 0x084,0x1); //MEZC +80

                usleep(200);
                //reset THRESH
                vme->wl(VMEImage,baseaddress + discbase + 0x010,0x7000);
                vme->wl(VMEImage,baseaddress + discbase + 0x050,0x7000);
                vme->wl(VMEImage,baseaddress + discbase + 0x090,0x7000);
          
                //set config register
                uint config_register = 0;
                if (dutycycle) config_register = 1 << 5;
                vme->wl(VMEImage,baseaddress +0x0020,config_register); 
        }

        //reset all counters for start
        vme->wl(VMEImage,baseaddress +0x0024,counter_reset); 
        //disable external latch
        vme->wl(VMEImage,baseaddress +0x0028,0x70000000); 
                
        //If we are in rate mode, we need to reset, otherwise it will do stupid things on overflow
        if (rate == true) reset = true;


        bool keeprunning = true;

        nonblock(NB_ENABLE);        
        while (keeprunning)
        {

                if (reset) vme->wl(VMEImage,baseaddress +0x0024,counter_latch+counter_reset); 
                else vme->wl(VMEImage,baseaddress +0x0024,counter_latch);

                cout << " Module: jDisc" << endl << endl;

                //step 1: read out all counters
                uint clk = 0;
                uint scaler[50];
                uint threshs[48];
        
                vme->rl(VMEImage,baseaddress + clockregister,&clk); 
                
                for (uint counter=0;counter<50;counter+=1) {
                                vme->rl(VMEImage,baseaddress + counterbase + 4*counter,&scaler[counter]); 
                }

                for (uint counter=0;counter<48;counter+=1) {
                        vme->rl(VMEImage,baseaddress + discbase + 0x100 + 4*counter,&threshs[counter]); 
                }
                
                
                //step 2: print scaler values
                printf(" Clk  : %9d \n", clk);

                if (rate == true) {
                                printf(" Channel  0 (NIM_IN[0]) : %9.0f Hz \n", (scaler[0]*1E9/(1000.*clk/clockfreq)));
                                printf(" Channel 49 (NIM_IN[1]) : %9.0f Hz \n\n", (scaler[49]*1E9/(1000.*clk/clockfreq)));
                } else {
                                printf(" Channel  0 (NIM_IN[0]) : %9d \n", scaler[0]);
                                printf(" Channel 49 (NIM_IN[1]) : %9d \n\n", scaler[49]);
                }               
                cout << "     Channel  |  InputCounter                 Channel  |  InputCounter                 Channel  |  InputCounter"  << endl;
                cout << "    --------------------------               --------------------------               --------------------------"  << endl;

                //print scaler
                for (uint counter=1;counter<17;counter+=1)
                {                       
                                if (rate == true) {
                                        printf("        %2u    |  %9.0f Hz                    %2u    |  %9.0f Hz                    %2u    |  %9.0f Hz \n", counter, (scaler[counter]*1E9/(1000.*clk/clockfreq)), counter+16, (scaler[counter+16]*1E9/(1000.*clk/clockfreq)),  counter+32,  (scaler[counter+32]*1E9/(1000.*clk/clockfreq)));
                                } else if (dutycycle == true) {
                                  
                                    for (int g=0;g<3;g++) {
                                        double duty = (double)scaler[counter+g*16]/clk;
                                        if (duty>0.5) printf("  \033[1;31m  %2u  \033[0m  |  %9.7f %%                ", counter+g*16, duty);
                                        else printf("    %2u    |  %9.7f %%                ", counter+g*16, duty);
                                    }
                                    cout << endl;
                                    
                                } else {
                                        printf("        %2u    |  %9d                       %2u    |  %9d                       %2u    |  %9d \n", counter, scaler[counter], counter+16, scaler[counter+16],  counter+32,  scaler[counter+32]);
                                }                                                
                }
                cout << endl;
                cout << "     Channel  |  Threshold (Hysterese)        Channel  |  Threshold (Hysterese)        Channel  |  Threshold (Hysterese) "  << endl;
                cout << "    -----------------------------------      -----------------------------------      -----------------------------------"  << endl;

                //print voltages
                for (uint counter=0;counter<16;counter+=1)
                {                       
                                printf("        %2u    |  %8.5f (%8.5f)             %2u    |  %8.5f (%8.5f)             %2u    |  %8.5f (%8.5f) \n", counter, voltage_from_adc_value(threshs[counter] & 0xffff),voltage_from_adc_value((threshs[counter]>>16) & 0xffff), counter+16, voltage_from_adc_value(threshs[counter+16] & 0xffff), voltage_from_adc_value((threshs[counter+16]>>16) & 0xffff),  counter+32,  voltage_from_adc_value(threshs[counter+32] & 0xffff), voltage_from_adc_value((threshs[counter+32]>>16) & 0xffff));
                }               
                cout << endl;


                //read offset, ref and GND
               uint offset_A[5];
               uint offset_B[5];
               uint offset_C[5];

                for (uint counter=0;counter<5;counter+=1)
                {                       
                        vme->rl(VMEImage,baseaddress + discbase + 0x200 + 4*counter,&offset_A[counter]); 
                        vme->rl(VMEImage,baseaddress + discbase + 0x240 + 4*counter,&offset_B[counter]); 
                        vme->rl(VMEImage,baseaddress + discbase + 0x280 + 4*counter,&offset_C[counter]); 
                }               

                //print Offset, Ref and GND
                printf(" DAC1_OFFSET  |  %8.5f  %8.5f                    |  %8.5f  %8.5f                    |  %8.5f  %8.5f \n",  voltage_from_adc_value((offset_A[0]>>16) & 0xffff),   voltage_from_adc_value(offset_A[0] & 0xffff),   voltage_from_adc_value((offset_B[0]>>16) & 0xffff),   voltage_from_adc_value(offset_B[0] & 0xffff),  voltage_from_adc_value((offset_C[0]>>16) & 0xffff),   voltage_from_adc_value(offset_C[0] & 0xffff));
                printf(" DAC2_OFFSET  |  %8.5f  %8.5f                    |  %8.5f  %8.5f                    |  %8.5f  %8.5f \n",  voltage_from_adc_value((offset_A[1]>>16) & 0xffff),   voltage_from_adc_value(offset_A[1] & 0xffff),   voltage_from_adc_value((offset_B[1]>>16) & 0xffff),   voltage_from_adc_value(offset_B[1] & 0xffff),  voltage_from_adc_value((offset_C[1]>>16) & 0xffff),   voltage_from_adc_value(offset_C[1] & 0xffff));
                
                printf(" DAC1_REF     |  %8.5f  %8.5f                    |  %8.5f  %8.5f                    |  %8.5f  %8.5f \n",  voltage_from_adc_value((offset_A[2]>>16) & 0xffff),   voltage_from_adc_value(offset_A[2] & 0xffff),   voltage_from_adc_value((offset_B[2]>>16) & 0xffff),   voltage_from_adc_value(offset_B[2] & 0xffff),  voltage_from_adc_value((offset_C[2]>>16) & 0xffff),   voltage_from_adc_value(offset_C[2] & 0xffff));
                printf(" DAC2_REF     |  %8.5f  %8.5f                    |  %8.5f  %8.5f                    |  %8.5f  %8.5f \n",  voltage_from_adc_value((offset_A[3]>>16) & 0xffff),   voltage_from_adc_value(offset_A[3] & 0xffff),   voltage_from_adc_value((offset_B[3]>>16) & 0xffff),   voltage_from_adc_value(offset_B[3] & 0xffff),  voltage_from_adc_value((offset_C[3]>>16) & 0xffff),   voltage_from_adc_value(offset_C[3] & 0xffff));

                printf(" DAC_GNDF     |  %8.5f                              |  %8.5f                              |  %8.5f        \n",  voltage_from_adc_value(offset_A[4]),     voltage_from_adc_value(offset_B[4]),   voltage_from_adc_value(offset_C[4]));               

                cout << endl;

              

                
                cout << " (Q)uit    (R)eset   : " << flush;
                usleep(500000);

                int keypress = kbhit();
                if (keypress != 0)
                {
                        char c=fgetc(stdin);
                        if (c=='q') 
                        {
                                keeprunning = false;
                                cout << " -> Quit!";
                        }
                        
                        if (c=='r') 
                        {
                                vme->wl(VMEImage,baseaddress +0x0024,counter_reset); 
                                cout << " -> Reset Counters";
                        }
                        cout << endl << endl;                       
                }

        }
        nonblock(NB_DISABLE);        
                                              
}



void jTDC (VMEBridge* vme, int VMEImage, uint baseaddress, uint maxevents, uint triggerselect, uint geoid, uint range, bool verbose, bool vverbose)
{
        
        //bits of config register
        uint tdc_reset = 1;

        //default values
        if (range == 0) range = 254;
        if (triggerselect > 1) triggerselect = 1;
        
        cout << "Initializing module for TDC readout ... ";                                 

        //memory map
        uintptr_t FPGAbase = vme->getPciBaseAddr(VMEImage);
        volatile uint *mEventfifo = (uint*) (FPGAbase + 0x8888);
        volatile uint *mDatafifo = (uint*) (FPGAbase + 0x4444);
        

        //set jTDC config as desired by user
        uint current_settings;
        vme->rl(VMEImage,baseaddress + 0x0020,&current_settings); 
        vme->wl(VMEImage,baseaddress +0x0020, (current_settings & 0x60) | ((range << 8) + ((triggerselect & 0x1) << 7) + (geoid & 0x1F))); 
        

        //enable all channels
        vme->wl(VMEImage,baseaddress + 0x2000, 0xFFFFFFFF); 
        vme->wl(VMEImage,baseaddress + 0x2004, 0xFFFFFFFF); 
        vme->wl(VMEImage,baseaddress + 0x2008, 0xFFFFFFFF); 


        //read out jTDC properties
        uint info;
        vme->rl(VMEImage,baseaddress +0x0024,&info); 


        uint channels;
        uint bits;
        uint fw;
        
        channels = (info >> 24) & 255;
        bits = (info >> 16) & 255;
        fw = (info >> 0) & 255;
        
        cout << "done" << endl << endl;
        printf(" Firmware  :  %8X\n",fw);
        printf(" Channels  :  %8i\n",channels);
        printf(" Bit/Chan  :  %8i\n",bits);
        printf(" GeoID     :  %8i\n",geoid);
        printf(" Range[ns] :  %8i\n",range*5);
        printf(" Trigger   : ");
        if (triggerselect == 0) printf("   NIM[0]\n"); else printf("LVDS_A[0]\n");        
        cout << endl;
        
        char fname[1024];
        time_t tnow;
        struct tm *now;
        tnow = time(NULL);
        now = localtime(&tnow);
        strftime(fname,sizeof(fname),"run_%y%m%d_%H%M%S.dat",now);

	printf("starting %s\n", fname);
        printf("max event %d\n",maxevents);

        //read out TDC
        vme->wl(VMEImage,baseaddress +0x0024,tdc_reset); 

	ofstream datfile;
	datfile.open (fname, ios::out | ios::trunc | ios::binary); 

        for(uint eventcounter=1; eventcounter<=maxevents;eventcounter++)
        {               
                //wait for an event in eventfifo
                uint eventfifo = 0xdeadbeef;
                do {
                        eventfifo = *mEventfifo;
                        usleep(1); //somehow it doesnot react on ^C, if this is not in here
                } while (eventfifo==0 && !abort_request);
                        
		//force litte endian, because that is the endian-ness of the two 16bit words in one 32bit word generated by the FPGA
		//http://stackoverflow.com/a/13995796
		char eventbuffer[4];
		eventbuffer[0] = (eventfifo & 0x000000ff);
		eventbuffer[1] = (eventfifo & 0x0000ff00) >> 8;
		eventbuffer[2] = (eventfifo & 0x00ff0000) >> 16;
		eventbuffer[3] = (eventfifo & 0xff000000) >> 24;
                datfile.write(eventbuffer,4);

                //look into eventfifo value
                int entries_found_in_eventfifo = (eventfifo & 0x1fff);
                uint eventnumber_found_in_eventfifo = ((eventfifo >> 16) & 0xffff);
                if (vverbose) printf("\nEventnumber %d has %d entries.", eventnumber_found_in_eventfifo, entries_found_in_eventfifo);

                //read out all data words from this event
                for (uint entries = 0; entries<entries_found_in_eventfifo && !abort_request; entries++) 
                {
                        uint datafifo = *mDatafifo;
			//force litte endian, because that is the endian-ness of the two 16bit words in one 32bit word generated by the FPGA
			//http://stackoverflow.com/a/13995796
			char databuffer[4];
			databuffer[0] = (datafifo & 0x000000ff);
			databuffer[1] = (datafifo & 0x0000ff00) >> 8;
			databuffer[2] = (datafifo & 0x00ff0000) >> 16;
			databuffer[3] = (datafifo & 0xff000000) >> 24;
			datfile.write(databuffer,4);
                }
                
                //give some usefull user feedback
                if  ((maxevents>99) && (eventcounter)%(maxevents/100) == 0) {printf(".");  fflush(stdout);}
                if  ((maxevents>9) && (eventcounter)%(maxevents/10) == 0) {printf(" %8d [%3d%%]\n", eventcounter, ((eventcounter*100)/maxevents)); fflush(stdout);}
                if (abort_request) break;
        } 

        datfile.close();
        cout << "done" << endl << endl;
}










 //* * * * * * * *//
 //*   M A I N   *//
 //* * * * * * * *//

int main (int argc, char **argv) 
{
        abort_request = false;
        signal(SIGINT, (sighandler_t)&CtrlCHandler);

        std::cout << endl;
        std::cout << "jDAQLite  Copyright (C) 2014   John Bieling (john.bieling@uni-bonn.de)" << std::endl;
        std::cout << endl;
        std::cout << "This program comes with ABSOLUTELY NO WARRANTY." << std::endl;
        std::cout << "This is free software, and you are welcome to redistribute it" << std::endl;
        std::cout << "under certain conditions." << std::endl;
        std::cout << endl;
        std::cout <<  "This tool can be used to readout the FPGA based jTDC modules." << std::endl;
        std::cout << endl;        
        
        
        //We need at least a baseaddress
        uint baseaddress = 0;
        if(argc > 1) {
                baseaddress = strtoul(argv[1],NULL,0);
                sprintf(argv[1]," "); //so we can pass argv on the subclass
        } else {
                cout << "\tusage: jDAQLite baseaddress [options]" << endl << endl;
                cout << "If no options are provided, a list of all available options for the device" << endl << "found at the given baseaddress is shown." << endl << endl;
                exit(0);
        }
        

        
        //Check firmware at given baseaddress
        cout << "Checking FPGA firmware at address 0x" << hex << baseaddress << dec << " ... ";
        VMEBridge* vme = new VMEBridge();
        int VMEImage = vme->getImage(baseaddress,0x00010000,A32,D32,MASTER);

        if (VMEImage==-1) {
                cout << endl << "It was not possible to access the VME interface, did you ssh into the VME CPU?" << endl << endl;
                exit(1);
        }
        
        uint version = 0;
        uint moduleid = 0;
        vme->rl(VMEImage,baseaddress + 0x0024,&version); 
        moduleid = (version >> 8) & 255;
        version = version & 255;

        

        //Define all possible parameters
        parameterHandle *params = new parameterHandle();
        params->setIntro("\tusage: jDAQLite baseaddress [options]");
        params->add(ERROR              ,false ,""              ,""     ,"");
        params->add(RATES              ,false ,"--rates"       ,"-hz"  ,"read out scaler and calculate rate");
        params->add(COUNTS             ,false ,"--counts"      ,"-c"   ,"read out scaler and display plain counts");
        params->add(DUTY               ,false ,"--dutycycle"   ,"-d"   ,"count dutycycle of input signals, instead of hits");
        params->add(RESET              ,false ,"--reset"       ,"-r"   ,"reset scalers after each readout");
        params->add(INIT               ,false ,"--init"        ,"-i"   ,"init the module to default values");
        params->add(START1             ,false ,"--start_one"   ,"-1"   ,"when displaying scaler data, the channels start counting from 1 instead of 0");
        params->add(EVENTS             ,true  ,"--events"      ,"-e"   ,"specify how may TDC Events are supposed to be read out");
        params->add(VERBOSE            ,false ,"--verbose"     ,"-v"   ,"be verbose during TDC readout (only on error)");
        params->add(VVERBOSE           ,false ,"--vverbose"    ,"-vv"  ,"be very verbose during TDC readout (on every event)");
        params->add(GEOID              ,true  ,"--geoid"       ,"-g"   ,"set the TDC geoid <geoid>");
        params->add(RANGE              ,true  ,"--window"      ,"-w"   ,"set the TDC window <window/5ns>");
        params->add(TRIGGER            ,true  ,"--trigger"     ,"-t"   ,"set the TDC trigger <0/1> (0=NIM[0], 1=LVDS_A[0])");
        params->add(SELF               ,false ,"--selftrig"    ,"-s"   ,"produce TDC trigger via VME ('random trigger')");
        params->add(RBASE              ,true  ,"--remotebase"  ,"-rb"  ,"(counter-)base address of the remote fpga module");

        
        
        //Get all parameters - at this point we check only, if it is a valid parameter, not if it is valid for a certain subroutine
        int valid = 0;
        if(argc > 2) 
        {
                for (int i=2;i<argc;i++) 
                {
                        PNAME p = params->find(string(argv[i]));
                        if (p != ERROR) { 
                                valid++;                                 
                                if (params->hasMoredata(p)) {
                                        if (i+2>argc) { valid = 0; break; } //no "next" argv to get value from
                                        else i++; //jump to value, and ignore as parameter next time
                                }

                                params->storeValue(p,string(argv[i]));                                
                        }
                        else { valid = 0; break; } //as soon as we find an invalid parameter, abort
                }                      
       }              
       if (argc <= 2 || valid == 0) params->set(ERROR); 


       //check dependencies
       if (params->isSet(VVERBOSE)) params->set(VERBOSE);               
       
       
       //Check exlusivnes - globally valid
       uint exclusiv = 0;
       if (params->isSet(DUTY)) exclusiv++;
       if (params->isSet(RATES)) exclusiv++;
       if (params->isSet(COUNTS)) exclusiv++;
       if (params->isSet(EVENTS)) exclusiv++;
       if (exclusiv != 1) params->set(ERROR); 
       
        
       
        //depending on moduleid, evaluate parameters
        switch (moduleid)
        {
                
                case 0x35 : //jScaler with additional dutycycle option
                case 0x34 : //jTDC
                        cout << "found jTDC with firmware version " << hex << version << dec << endl << endl;
                        params->allow(DUTY);
                        params->allow(RATES);
                        params->allow(COUNTS);                       
                        params->allow(RESET);
                        params->allow(EVENTS);                       
                        params->allow(VERBOSE);
                        params->allow(VVERBOSE);
                        params->allow(RANGE);                       
                        params->allow(GEOID);
                        params->allow(TRIGGER);                       
                        params->setOutro("You must either provide --rates, --counts or --events (exclusivly). If option --rates is provided,\nthe option --reset is applied automatically.");
                        if (params->check()) 
                        {
                                if (params->isSet(EVENTS)) jTDC (vme, VMEImage, baseaddress, params->get(EVENTS), params->get(TRIGGER), params->get(GEOID), params->get(RANGE), params->isSet(VERBOSE),params->isSet(VVERBOSE));
                                else jScaler (vme, VMEImage, baseaddress, params->isSet(RATES), params->isSet(RESET), params->isSet(DUTY));
                        }
                break;

                case 0x40 : //jDisc
                        cout << "found jDiscriminator with firmware version " << hex << version << dec << endl << endl;
                        params->allow(DUTY);
                        params->allow(RATES);
                        params->allow(COUNTS);                       
                        params->allow(RESET);
                        params->allow(INIT);
                        params->allow(EVENTS);                       
                        params->allow(VERBOSE);
                        params->allow(VVERBOSE);
                        params->allow(RANGE);                       
                        params->allow(GEOID);
                        params->allow(TRIGGER);                       
                        params->setOutro("You must either provide --rates, --counts or --events (exclusivly). If option --rates is provided,\nthe option --reset is applied automatically.");
                        if (params->check()) 
                        {
                                if (params->isSet(EVENTS)) jTDC (vme, VMEImage, baseaddress, params->get(EVENTS), params->get(TRIGGER), params->get(GEOID), params->get(RANGE), params->isSet(VERBOSE),params->isSet(VVERBOSE));
                                else jDisc (vme, VMEImage, baseaddress, params->isSet(RATES), params->isSet(RESET), params->isSet(INIT), params->isSet(DUTY));
                        }
                break;

                default : printf("found unknown firmware (0x%X) Aborting.\n",moduleid); break;
        }
        
        return 0;
}

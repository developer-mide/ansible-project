// Test software (also for software dev team?):
//   Generates the UDP data with simulated datastream.h field content

#include <stdio.h>
#include <string.h>
#include <stdlib.h> 
#include <unistd.h>
#include <time.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#include "datastream.h"
#include "math.h"

#define BUFLEN 1472 // 1472 bytes is the maximum UDP payload at the standard MTU of 1500
#define PORT 8888
#define RECVIP "127.0.0.1"

struct timespec ts_rate = { .tv_sec=0, .tv_nsec=(long int)(1e9/(32000/16)) };
struct timespec ts_sleep = { .tv_sec=0, .tv_nsec=(long int)(100*1e3) }; // 100 us sleep granularity


wfb_UDP_packet d, dprev;

uint64_t Timestamp_ns(void) {
        struct timespec newTimeVal;
        clock_gettime(CLOCK_MONOTONIC, &newTimeVal);
        uint64_t curr_nanoseconds = (long)newTimeVal.tv_sec * (uint64_t)1000000000 + newTimeVal.tv_nsec;
        return curr_nanoseconds;
}

void die(const char *errprefix) {
	perror(errprefix);
	exit(1);
}

int main(void)
{
	struct sockaddr_in si;
	
	int s;
	socklen_t slen = sizeof(si);
	
	//create a UDP socket
	if ((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) { die("socket"); }
	
	// zero out the structure
	memset((char *) &si, 0, sizeof(si));
	
	si.sin_family = AF_INET;
	si.sin_port = htons(PORT);
	si.sin_addr.s_addr = inet_addr(RECVIP); //htonl(INADDR_ANY);
	
	uint64_t startup_time=Timestamp_ns();

	//keep sending data
	int waitcount=0;
	for (int pnr=0; ; pnr++) {
		uint64_t runtime=(Timestamp_ns()-startup_time);
		uint64_t exptime=(uint64_t)ts_rate.tv_nsec * (pnr+1);

        // Populate simulated waveform data buffer here:
        d.UDP_seq_nr=pnr;
		d.discovery_time=exptime;
		d.dt_begin_UDP_transfer=runtime-exptime; // needs work here
		d.header[0]=waitcount;
		for (int w=0; w<WFB_ELEMENT_ARRAY_SIZE;w++) {
			int samplenr=(pnr*WFB_ELEMENT_ARRAY_SIZE+w) % 32000;
			d.va[w]=sin( 2 * M_PI * 60.0 * samplenr/32000.0 ) * 240*sqrt(2) * 2000;
			d.vb[w]=sin( 2 * M_PI * 60.0 * samplenr/32000.0 ) *-120*sqrt(2) * 2000;
			d.vc[w]=(pnr*WFB_ELEMENT_ARRAY_SIZE+w)%(7*WFB_ELEMENT_ARRAY_SIZE+1);
			d.ia[w]=sin( 2 * M_PI * 60.0 * ((pnr%2000)*WFB_ELEMENT_ARRAY_SIZE+w) / (2000.0*WFB_ELEMENT_ARRAY_SIZE)  ) *  10 *  400;
			d.ib[w]=sin( 2 * M_PI * 60.0 * ((pnr%2000)*WFB_ELEMENT_ARRAY_SIZE+w) / (2000.0*WFB_ELEMENT_ARRAY_SIZE)  ) * -10 *  400;
			d.ic[w]=2 * M_PI * 1000;
		}
		
		if (sendto(s, &d, sizeof(d), 0, (struct sockaddr*) &si, slen) == -1) {
			die("sendto()");
		}
				printf("Packet# %6d, SendTime: %.6f (%+.6f) ExpTime: %.6f (%+.6f) CurTime: %.6f\n",pnr,
					d.discovery_time/1e9, (d.discovery_time-dprev.discovery_time)/1e9,
					runtime/1e9, exptime/1e9,
					d.dt_begin_UDP_transfer/1e9);
		waitcount=0;
		while ( runtime<exptime ) { nanosleep(&ts_sleep,NULL); runtime=(Timestamp_ns()-startup_time); waitcount++; }
		dprev=d;
	}

	close(s);
	return 0;
}


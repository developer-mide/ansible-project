
#include <stdio.h>
#include <string.h>
#include <stdlib.h> 
#include <unistd.h>
#include <time.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#include "datastream.h"

#define BUFLEN 1472 // 1472 bytes is the maximum UDP payload at the standard MTU of 1500
#define PORT 8888

#define RECV_COUNT (1000) // How many packets to receive, 0 for unlimited
#define STREAMFILE "data.int32"

wfb_UDP_packet d, dprev;

uint64_t Timestamp_ns(void)
{
        struct timespec newTimeVal;
        clock_gettime(CLOCK_MONOTONIC, &newTimeVal);
        uint64_t curr_nanoseconds = (long)newTimeVal.tv_sec * (uint64_t)1000000000 + newTimeVal.tv_nsec;
        return curr_nanoseconds;
}

void die(const char *s)
{
	perror(s);
	exit(1);
}

int main(void)
{
	struct sockaddr_in si_me, si_other;
	
	int s, recv_len;
	socklen_t slen = sizeof(si_other);
	
	//create a UDP socket
	if ((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) { die("socket"); }

	#ifdef STREAMFILE
	FILE *f=fopen(STREAMFILE,"w");
	#endif

	// zero out the structure
	memset((char *) &si_me, 0, sizeof(si_me));	
	si_me.sin_family = AF_INET;
	si_me.sin_port = htons(PORT);
	si_me.sin_addr.s_addr = htonl(INADDR_ANY);
	
	//bind socket to port
	if( bind(s , (struct sockaddr*)&si_me, sizeof(si_me) ) == -1) { die("bind"); }
	
	//keep listening for data
	int print_wait=1;
	for (int pnr=0; (RECV_COUNT==0) || (pnr<RECV_COUNT); pnr++) {
		if (print_wait) {
			printf("Waiting for data...");
			printf(" size expected: %ld ", sizeof(d));
			fflush(stdout);
			print_wait=0;
		}

		//try to receive some data, this is a blocking call
		if ((recv_len = recvfrom(s, &d, sizeof(d), 0, (struct sockaddr *) &si_other, &slen)) == -1) {
			die("recvfrom()");
		}

		uint64_t recv_time = Timestamp_ns();
		if ( strcmp(d.NMEA_msg, dprev.NMEA_msg) != 0 ) {
			printf("size %d, Packet# %6d, Time: %.6f, GPS msg: <%s>\n",recv_len,pnr,recv_time/1e9,d.NMEA_msg);
			print_wait=1;
		} else {
			printf("size %d, Packet# %6d, Header: %8X %8X %8X %8x\n",recv_len,pnr,d.header[0],d.header[1],d.header[2],d.header[3]);
		}

		// Stream Data to disk:
		//   For easy plotting: simple matrix, rows: sample nr, cols: va...in , how many metacolumns?
		//   For efficient storage: extra file with metainfo per WFB page (also for new ringbuffer?)
		#ifdef STREAMFILE
		file_store1 dout[WFB_ELEMENT_ARRAY_SIZE];
		for (int w=0; w<WFB_ELEMENT_ARRAY_SIZE;w++) {
				dout[w].UDP_seq_nr      = d.UDP_seq_nr;
				dout[w].curr_WFB_Index  = d.curr_WFB_Index;
				dout[w].local_WFB_Index = d.local_WFB_Index; // WFB_Index this data should correspond to (the page being read)
				dout[w].retrieval_us    = (int32_t)(d.discovery_time/1000);
				dout[w].dt_create_UDP_packet = d.dt_create_UDP_packet; 
				dout[w].dt_begin_SPI_transfer = d.dt_begin_SPI_transfer; 
				dout[w].dt_end_SPI_transfer = d.dt_end_SPI_transfer;
				dout[w].dt_end_wfb_processing = d.dt_end_wfb_processing;
				dout[w].dt_end_GPS = d.dt_end_GPS;
				dout[w].dt_begin_UDP_transfer = d.dt_begin_UDP_transfer;
				dout[w].prev_end_begin_UDP = d.prev_end_begin_UDP;     
				dout[w].va = d.va[w];
				dout[w].vb = d.vb[w];
				dout[w].vc = d.vc[w];
				dout[w].vx = d.vx[w];
				dout[w].ia = d.ia[w];
				dout[w].ib = d.ib[w];
				dout[w].ic = d.ic[w];
				dout[w].in = d.in[w];
		}
		fwrite(dout,sizeof(dout),1,f);
		#endif

		dprev=d;
	}

	#ifdef STREAMFILE
	fclose(f);
	#endif

	close(s);
	return 0;
}


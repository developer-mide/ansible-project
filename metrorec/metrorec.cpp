
#include <stdio.h>
#include <string.h>
#include <stdlib.h> 
#include <unistd.h> // Also needed for chdir
#include <arpa/inet.h>
#include <sys/socket.h>




#include "datastream.h"
#include "metrobuf.h"

#define BUFLEN 1472 // 1472 bytes is the maximum UDP payload at the standard MTU of 1500
#define PORT 8888

#define RECV_COUNT (0) // How many packets to receive, 0 for unlimited



int main(int argc,char* argv[])
{
	if((argc<3)||(argc>4)) {
		fprintf(stderr,"Usage: %s <absolute_path_to_buffer> <next_chunk_subdir_nr> <nr_of_seconds_per_chunkdir>\n",argv[0]);
		fprintf(stderr,"   Omitting  <nr_of_seconds_per_chunkdir>  will check if bufdir is accessible, and return the chunkdirname\n");
		exit(EINVAL);
	}

	uint64_t chunkdir_seconds,chunkdir_number;

	char *bufdir=argv[1];
	chunkdir_number=atol(argv[2]);

	chdir_errcheck(bufdir);
	if(argc==3) { // Calling metrobuf without nr_of_seconds_per_chunkdir will print the chunk directory name
		chunkdirname(chunkdir_number);
		fprintf(stdout,"%s\n",chunkdir);
		exit(0);
	}

	chunkdir_number--; // Quick fix because on first run through main loop, it will be incremented again
	chunkdir_seconds=atol(argv[3]);

	struct sockaddr_in si_me, si_other;
	
	int s, recv_len;
	socklen_t slen = sizeof(si_other);
	
	//create a UDP socket
	if ((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) { die("socket"); }
	// zero out the structure
	memset((char *) &si_me, 0, sizeof(si_me));	
	si_me.sin_family = AF_INET;
	si_me.sin_port = htons(PORT);
	si_me.sin_addr.s_addr = htonl(INADDR_ANY);
	//bind socket to port
	if( bind(s , (struct sockaddr*)&si_me, sizeof(si_me) ) == -1) { die("bind"); }

	wfb_UDP_packet d, dprev;
	metrorec_meta m, mprev;
	
	//keep listening for data
	int print_wait=1;
	int64_t start_chunk_time=(chunkdir_seconds*-1e9); //Timestamp_ns(); // Will now count from first UDP packet received
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

		m.udp_packet_count = pnr;
		m.udp_recv_time = Timestamp_ns();
		// TODO: monotonic time handling: Use first discovery time and extrapolate from there, UNLESS discrepancy larger than expected
		if ( (d.discovery_time-mprev.sample_monotime > 6000*1000) || // More than 6 ms (12 WFB pages) between samples (e.g. SPI issue),
		     (d.discovery_time-mprev.sample_monotime < 0) ) // or time walked backwards (i.e., microcontroller clock slower than ADE9000 clock)?
			m.sample_monotime=d.discovery_time; // re-set base time reference of "monotonic" time (guarantee monotony w/ clock skew?)
		else m.sample_monotime+=500*1000; // all normal? assume a fixed 500us per WFB page

		if ( strcmp(d.NMEA_msg, dprev.NMEA_msg) != 0 ) {
			printf("size %d, Packet# %6d, Time: %.6f, GPS msg: <%s>\n",recv_len,pnr,m.udp_recv_time/1e9,d.NMEA_msg);
			print_wait=1;
		} else {
			printf("Xsize %d, Packet# %6d, DiscTime: %.6f (%+.6f) RecvTime: %.6f (%+.6f) CurTime: %.6f, Header: %8X %8X %8X %8x\n",recv_len,pnr,
					m.udp_recv_time/1e9, (m.udp_recv_time-mprev.udp_recv_time)/1e9,
					d.discovery_time/1e9, (d.discovery_time-dprev.discovery_time)/1e9,
					m.sample_monotime/1e9,
					d.header[0],d.header[1],d.header[2],d.header[3]);
		}

		if ( (m.udp_recv_time-start_chunk_time) >= (chunkdir_seconds*1e9) ) {
			if (start_chunk_time>0) close_datafiles();
			start_chunk_time=m.udp_recv_time;
			chdir_errcheck(bufdir);
			chunkdirname(++chunkdir_number);
			mkchunkdir(); // Let's consider the code from here...
			chdir_errcheck(chunkdir);
			open_datafiles("w"); // ...to here as atomic for now, and the UDP listener as mutex to prevent simultanous execution
			chdir_errcheck(bufdir);
			update_chunkmeta(chunkdir_number);
		}

		write_datafiles(d,m);

		dprev=d;
		mprev=m;
	}

	close_datafiles();

	close(s);
	return 0;
}


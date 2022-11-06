/*
 metrobuf.h - Common Definitions between Data Stream Receiver (metrorec) and readers of that data (i.e., on-disk buffer format)
 */

#ifndef _METROBUF_H_INCLUDED
#define _METROBUF_H_INCLUDED

#include <stdint.h>

//#include "ADE9000API.h" // As long as this include is only needed for WFB_ELEMENT_ARRAY_SIZE, let's recreate that define instead:
#ifndef WFB_ELEMENT_ARRAY_SIZE
#define WFB_ELEMENT_ARRAY_SIZE (16)
#endif



#include <time.h>

uint64_t Timestamp_ns(void) {
        struct timespec newTimeVal;
        clock_gettime(CLOCK_MONOTONIC, &newTimeVal);
        uint64_t curr_nanoseconds = (long)newTimeVal.tv_sec * (uint64_t)1000000000 + newTimeVal.tv_nsec;
        return curr_nanoseconds;
}

#include <errno.h>
// For mkpath:
#include <sys/stat.h>
#include <sys/types.h>

// datastream.h should only be needed for wfb_UDP_packet, which in turn is needed for write_datafiles
#include "datastream.h"

struct wfb_chan_record { // Data Record Format for single-channel data saved in the on-disk buffer
	int32_t val[WFB_ELEMENT_ARRAY_SIZE];
};
struct wfb_chan_record_differential { // Data Record Format for single-channel data saved in the on-disk buffer
	int32_t val;
	int16_t dval[WFB_ELEMENT_ARRAY_SIZE-1];
};

struct metrorec_meta { // Metadata collected by metrorec (on the Jetson), not coming over UDP
	uint64_t udp_recv_time;    // Jetson Clock Monotonic when this UDP packet was handled in metrorec
	uint32_t udp_packet_count; // Packet counter for this instance of metrorec
	uint64_t sample_monotime;  // Monotonic receive time at frontend (e.g., metrology microcontroller uptime)
};

struct meta1_record { // Data Record Format for the metadata data file in the on-disk buffer
	uint64_t udp_recv_time;    // Jetson Clock Monotonic when this UDP packet was handled in metrorec
	uint64_t discovery_time;   // Time when availability of new wfb page on ADE9000 was discovered
	uint64_t sample_monotime;  // Monotonic receive time at frontend (e.g., metrology microcontroller uptime)
	uint32_t udp_packet_count; // Packet counter for this instance of metrorec
	uint32_t UDP_seq_nr;
	uint8_t curr_WFB_Index;
	uint8_t local_WFB_Index;
};

#define FN_VA "VA.int32"
#define FN_VB "VB.int32"
#define FN_VC "VC.int32"
#define FN_IA "IA.int32"
#define FN_IB "IB.int32"
#define FN_IC "IC.int32"
#define FN_IN "IN.int32"
#define FN_MD "meta.bin"
#define FN_CHUNKMETA     "chunkmeta"
#define FN_CHUNKMETA_TMP "chunkmeta.tmp"

struct chunkmeta_store {
	uint version=1;
	uint chunkdir_number;
};

#define SAMPLES_PER_RECORD (WFB_ELEMENT_ARRAY_SIZE)

FILE *f_VA, *f_VB, *f_VC, *f_IA, *f_IB, *f_IC, *f_IN, *f_MD;
void open_datafiles(const char *mode) {
	f_VA=fopen(FN_VA,mode);
	f_VB=fopen(FN_VB,mode);
	f_VC=fopen(FN_VC,mode);
	f_IA=fopen(FN_IA,mode);
	f_IB=fopen(FN_IB,mode);
	f_IC=fopen(FN_IC,mode);
	f_IN=fopen(FN_IN,mode);
	f_MD=fopen(FN_MD,mode);
}
void close_datafiles() {
	fclose(f_VA);
	fclose(f_VB);
	fclose(f_VC);
	fclose(f_IA);
	fclose(f_IB);
	fclose(f_IC);
	fclose(f_IN);
	fclose(f_MD);
}
#define member_sizeof(type, member)        (sizeof(((type *)0)->member))
#define member_sizeof_wfbarr(type, member) (sizeof(((type *)0)->member)/WFB_ELEMENT_ARRAY_SIZE)
void seek_datafiles(long recordnr) {
	fseek(f_VA,recordnr*SAMPLES_PER_RECORD*member_sizeof_wfbarr(wfb_UDP_packet,va),SEEK_SET);
	fseek(f_VB,recordnr*SAMPLES_PER_RECORD*member_sizeof_wfbarr(wfb_UDP_packet,vb),SEEK_SET);
	fseek(f_VC,recordnr*SAMPLES_PER_RECORD*member_sizeof_wfbarr(wfb_UDP_packet,vc),SEEK_SET);
	fseek(f_IA,recordnr*SAMPLES_PER_RECORD*member_sizeof_wfbarr(wfb_UDP_packet,ia),SEEK_SET);
	fseek(f_IB,recordnr*SAMPLES_PER_RECORD*member_sizeof_wfbarr(wfb_UDP_packet,ib),SEEK_SET);
	fseek(f_IC,recordnr*SAMPLES_PER_RECORD*member_sizeof_wfbarr(wfb_UDP_packet,ic),SEEK_SET);
	fseek(f_IN,recordnr*SAMPLES_PER_RECORD*member_sizeof_wfbarr(wfb_UDP_packet,in),SEEK_SET);
	fseek(f_MD,recordnr*sizeof(meta1_record),SEEK_SET);
}
#include "bufferchannels.h"

void print_fieldnames(FILE *fd) {
	fprintf(fd,"List of field names & numbers: Please refer to bufferchannels.h and bufferchannels.py !\n");
}
// Rename below to MAX_READ_RECORDS?
#define MAX_READ_ENTRIES (256*16*16)   // the ADE9000 can contain 16 * WFB_ELEMENT_ARRAY_SIZE (16) elements
#define MAX_OUTBUFFER_FIELDS (16)
union OutBufferEntry {
	float f;
	int32_t i;
} outbuffer[MAX_READ_ENTRIES*SAMPLES_PER_RECORD*MAX_OUTBUFFER_FIELDS];
long stream_datafiles( bool verbose, int num_fields, int fieldid[], long max_records) {
	meta1_record m[MAX_READ_ENTRIES];
	size_t records_read = fread(&m[0],sizeof(m[0]),max_records,f_MD);
	if (records_read==0) return 0;
	if (verbose)
	fprintf(stderr,"  Read %ld records of size %ld, packets %d to %d, first ts: %.6f  disccovery: %.6f\n",
		records_read,sizeof(m[0]),
		m[0].udp_packet_count,m[records_read-1].udp_packet_count,m[0].udp_recv_time/1e9,m[0].discovery_time/1e9);
	wfb_chan_record d[MAX_READ_ENTRIES];
	//size_t nread=records_read;
	//fread(&d,sizeof(wfb_chan_record),records_read,f_VA);
	#define dread(fh) fread(&d,sizeof(wfb_chan_record),records_read,fh)
	// for loop through record-sample-position (output buffer position):
	#define for_r_s_p()   for (size_t r=0,p=fnr; r<records_read; r++) for (int s=0; s<SAMPLES_PER_RECORD; s++,p+=num_fields)
    for (int fnr=0; fnr<num_fields; fnr++) {
		if(fieldid[fnr]==ade9000_sample_seqnr_32ksps_i32)      {              for_r_s_p() outbuffer[p].i=m[r].UDP_seq_nr*SAMPLES_PER_RECORD+s; }
		if(fieldid[fnr]==ade9000_generic_seqnr_32ksps_f32)     {              for_r_s_p() outbuffer[p].f=m[r].UDP_seq_nr*SAMPLES_PER_RECORD+s; }
		if(fieldid[fnr]==ade9000_sample_monotime_32ksps_i32)   {              for_r_s_p() outbuffer[p].i=m[r].sample_monotime+s*(500000/16); }
		if(fieldid[fnr]==ade9000_generic_monotime_32ksps_f32)  {              for_r_s_p() outbuffer[p].i=m[r].sample_monotime/1000.0+(500*s/16.0); }
		if(fieldid[fnr]==ade9000_voltage_primary_32ksps_f32)   { dread(f_VA); for_r_s_p() outbuffer[p].f=d[r].val[s] / 2000.0;             }
		if(fieldid[fnr]==ade9000_voltage_secondary_32ksps_f32) { dread(f_VB); for_r_s_p() outbuffer[p].f=d[r].val[s] / 2000.0;             }
		if(fieldid[fnr]==ade9000_current_phaseA_32ksps_f32)    { dread(f_IA); for_r_s_p() outbuffer[p].f=d[r].val[s] / 400.0;              }
		if(fieldid[fnr]==ade9000_current_phaseB_32ksps_f32)    { dread(f_IB); for_r_s_p() outbuffer[p].f=d[r].val[s] / 400.0;              }
		if(fieldid[fnr]==ade9000_voltraw_primary_32ksps_i32)   { dread(f_VA); for_r_s_p() outbuffer[p].i=d[r].val[s];                      }
		if(fieldid[fnr]==ade9000_voltraw_secondary_32ksps_i32) { dread(f_VB); for_r_s_p() outbuffer[p].i=d[r].val[s];                      }
		if(fieldid[fnr]==ade9000_voltraw_tertiary_32ksps_i32)  { dread(f_VC); for_r_s_p() outbuffer[p].i=d[r].val[s];                      }
		if(fieldid[fnr]==ade9000_voltraw_metastuff_32ksps_i32) {                        }
		if(fieldid[fnr]==ade9000_curraw_phaseA_32ksps_i32)     { dread(f_IA); for_r_s_p() outbuffer[p].i=d[r].val[s];                      }
		if(fieldid[fnr]==ade9000_curraw_phaseB_32ksps_i32)     { dread(f_IB); for_r_s_p() outbuffer[p].i=d[r].val[s];                      }
		if(fieldid[fnr]==ade9000_curraw_phaseC_32ksps_i32)     { dread(f_IC); for_r_s_p() outbuffer[p].i=d[r].val[s];                      }
		if(fieldid[fnr]==ade9000_curraw_phaseN_32ksps_i32)     { dread(f_IN); for_r_s_p() outbuffer[p].i=d[r].val[s];                      }

		if(fieldid[fnr]==ade9000_udp_seqnr_32ksps_i32)         {              for_r_s_p() outbuffer[p].i=m[r].UDP_seq_nr;                  }
		if(fieldid[fnr]==ade9000_cur_wfb_index_32ksps_i32)     {              for_r_s_p() outbuffer[p].i=m[r].curr_WFB_Index;              }
		if(fieldid[fnr]==ade9000_loc_wfb_index_32ksps_i32)     {              for_r_s_p() outbuffer[p].i=m[r].local_WFB_Index;             }
		if(fieldid[fnr]==ade9000_discovery_time_32ksps_i32)	   {              for_r_s_p() outbuffer[p].i=m[r].discovery_time;              }
    }
	fwrite(&outbuffer[0],sizeof(union OutBufferEntry)*num_fields,records_read*SAMPLES_PER_RECORD,stdout);
	return records_read;
}
/* This is only the initial, most-straight-forward data-buffer organization and write pattern
To store data more efficiently (especially for pilot), the following is in the works:
=> For each WFB (16 samples), store the first value in full resolution, the next 15 as 16-bit delta
   (For a total of 4+15*2 => 34 bytes per WFB, instead of 16*4=64. Can also bundle up 16 wFBs, for 514 instead of 1k)
   or store 24bit RAW (for 48 bit instead of 64)
=> buffer scheme: write N WFB pages to disk at once (and add UDP timeout of 10ms or so to flush)
*/
void write_datafiles(wfb_UDP_packet d, metrorec_meta m) {
		fwrite(d.va,sizeof(d.va),1,f_VA); // TODO: Buffer each data type?
		fwrite(d.vb,sizeof(d.vb),1,f_VB); //       And have write timeouts to flush when no new data arrives?
		fwrite(d.vc,sizeof(d.vc),1,f_VC);
		fwrite(d.ia,sizeof(d.ia),1,f_IA);
		fwrite(d.ib,sizeof(d.ib),1,f_IB);
		fwrite(d.ic,sizeof(d.ic),1,f_IC);
		fwrite(d.in,sizeof(d.in),1,f_IN);

		// Flush all output files _now_, BEFORE writing the metadata store, which is the file to be trailed by readers
		fflush(NULL); // reason: metadata might trail a sample behind, but will _always_ correspond to existing data

		meta1_record md;

		md.discovery_time=d.discovery_time;
		md.UDP_seq_nr=d.UDP_seq_nr;
		md.curr_WFB_Index=d.curr_WFB_Index;
		md.local_WFB_Index=d.local_WFB_Index;
		
		md.udp_packet_count=m.udp_packet_count;
		md.udp_recv_time=m.udp_recv_time;
		md.sample_monotime=m.sample_monotime;
		
		fwrite(&md,sizeof(md),1,f_MD); 
}


void die(const char *errprefix) {
	perror(errprefix);
	exit(1);
}

void chdir_errcheck(const char *dirname) {
	if (chdir(dirname)!=0) {
		fprintf(stderr,"Error: chdir(%s) failed: ", dirname); perror("");
		exit(errno);
	}
}

#define CHUNKDIR_MAXLEN   (10)
#define CHUNKDIR_FORMAT "%010u"
char chunkdir[CHUNKDIR_MAXLEN+1];
void chunkdirname(uint chunkdir_number) {
	snprintf(chunkdir,CHUNKDIR_MAXLEN+1,CHUNKDIR_FORMAT,chunkdir_number);
}
void mkchunkdir() {
	if (mkdir(chunkdir, 0777) != 0 && errno != EEXIST) {
		fprintf(stderr,"Error: mkdir(%s) failed: ",chunkdir); perror("");
		exit(errno);
	}
}
void update_chunkmeta(uint chunkdir_number) {
	chunkmeta_store cms;
	cms.chunkdir_number=chunkdir_number;
	FILE *f;
	f=fopen(FN_CHUNKMETA_TMP,"w");
	fwrite(&cms,sizeof(cms),1,f);
	fclose(f);
	if (rename(FN_CHUNKMETA_TMP,FN_CHUNKMETA)!=0)  {
		fprintf(stderr,"Error: rename(%s,%s) failed: ",FN_CHUNKMETA,FN_CHUNKMETA_TMP); perror("");
		exit(errno);
	}
}
uint read_chunkmeta() { // Todo: repeat until file is found?
	chunkmeta_store cms;
	FILE *f;
	f=fopen(FN_CHUNKMETA,"r");
	if (f==NULL) {
		fprintf(stderr,"Error: fopen(%s) failed: ",FN_CHUNKMETA); perror("");
		exit(errno);
	}
	fread(&cms,sizeof(cms),1,f);
	fclose(f);
	return cms.chunkdir_number;
}

#endif
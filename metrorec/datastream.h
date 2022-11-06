/*
 datastream.h - Common Definitions between Microcontroller Firmware and Data Stream Receiver (metrorec)
 This file is located in metrorec/ , but also included by code outside this directory/repository
    (e.g. TEENSPI, the breadboard firmware, and the STM32Cube firmware)
 */

#ifndef _DATASTREAM_H_INCLUDED
#define _DATASTREAM_H_INCLUDED

#include <stdint.h>

//#include "ADE9000API.h" // As long as this include is only needed for WFB_ELEMENT_ARRAY_SIZE, let's recreate that define instead:
#ifndef WFB_ELEMENT_ARRAY_SIZE
#define WFB_ELEMENT_ARRAY_SIZE (16)
#endif

struct wfb_UDP_packet { // UDP data format, i.e. the data packets coming from Microcontroller to Jetson
	uint32_t header[4];
	uint32_t UDP_seq_nr;
	uint8_t curr_WFB_Index;  // Latest WFB_Index which was completely filled at the time of polling // change to uint8_t ?
	uint8_t local_WFB_Index; // WFB_Index this data should correspond to (the page being read)      // change to uint8_t ?
	uint64_t discovery_time;       // Time when availability of new wfb page on ADE9000 was discovered
	uint32_t dt_create_UDP_packet;    // wfb discovery - time at creation of UDP packet
	uint32_t dt_begin_SPI_transfer;  // wfb discovery - time at beginning of WFB SPI transfer
	uint32_t dt_end_SPI_transfer;  // wfb discovery - time at end of WFB SPI transfer
	uint32_t dt_end_wfb_processing;  // wfb discovery - time at end of WFB data processing
	uint32_t dt_end_GPS;  // wfb discovery - time at end of GPS reading
	uint32_t dt_begin_UDP_transfer;  // wfb discovery - time at sending of UDP packet
	uint32_t prev_end_begin_UDP; // Time to send previous UDP packet in ns
	uint32_t fill[2];
	char GPS_time[16];
	char GPS_date[16];
	char barrier1[16];
	char NMEA_msg[128];
	char barrier2[16];
	int32_t va[WFB_ELEMENT_ARRAY_SIZE];
	int32_t vb[WFB_ELEMENT_ARRAY_SIZE];
	int32_t vc[WFB_ELEMENT_ARRAY_SIZE];
	int32_t vx[WFB_ELEMENT_ARRAY_SIZE]; // We might put metadata in this field
	int32_t ia[WFB_ELEMENT_ARRAY_SIZE];
	int32_t ib[WFB_ELEMENT_ARRAY_SIZE];
	int32_t ic[WFB_ELEMENT_ARRAY_SIZE];
	int32_t in[WFB_ELEMENT_ARRAY_SIZE];
};



struct file_store1 { // Simple flat file format for easy use in matlab, octave etc
	int32_t UDP_seq_nr;
	int32_t curr_WFB_Index;  // Latest WFB_Index which was completely filled at the time of polling
	int32_t local_WFB_Index; // WFB_Index this data should correspond to (the page being read)
	int32_t retrieval_us;
	uint32_t dt_create_UDP_packet;    // wfb discovery - time at creation of UDP packet
	uint32_t dt_begin_SPI_transfer;  // wfb discovery - time at beginning of WFB SPI transfer
	uint32_t dt_end_SPI_transfer;  // wfb discovery - time at end of WFB SPI transfer
	uint32_t dt_end_wfb_processing;  // wfb discovery - time at end of WFB data processing
	uint32_t dt_end_GPS;  // wfb discovery - time at end of GPS reading
	uint32_t dt_begin_UDP_transfer;  // wfb discovery - time at sending of UDP packet
	uint32_t prev_end_begin_UDP; // Time to send previous UDP packet in ns
	int32_t va,vb,vc,vx;
	int32_t ia,ib,ic,in;
};

#endif
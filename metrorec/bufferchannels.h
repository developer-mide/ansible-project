/*
 bufferchannels.h - Names and Documentation of channels provided by the buffer
    This file is also used by buildd_all.sh to create a python file containing these names

    This file is supposed to be the "single source of truth" for channel information
    between the frontend (metrorec) and the python world (via bufferchannels.py)

    We could also reverse the roles, and make the python file the "master" and
    generate these defines from the python file instead.
 */

// Channels of general interest. TODO: generic "seqnr" and "monotime" good enough for testing?
#define ade9000_generic_seqnr_32ksps_f32       0  // Generic Sequence Number of the sample (currently as received by microcontroller)
#define ade9000_generic_monotime_32ksps_f32    2  // Generic Monotonic receive time (currently metrology microcontroller uptime), in uS
#define ade9000_voltage_primary_32ksps_f32    11  // Primary   voltage (usually 240 V for split-phase), calibrated
#define ade9000_voltage_secondary_32ksps_f32  12  // Secondary voltage (usually 120 V for split-phase), calibrated
#define ade9000_current_phaseA_32ksps_f32     14  // Current on leg "A", calibrated - not phase-shift compensated to voltage!
#define ade9000_current_phaseB_32ksps_f32     15  // Current on leg "B", calibrated - not phase-shift compensated to voltage!
// Channels which are usually only used by developers as well as calibration & verification tools, they could change frequently:
#define ade9000_buffer_seqnr_32ksps_i32       90  // Sequence number of the sample, as received by metrorec

#define ade9000_udp_seqnr_32ksps_i32          80  // 
#define ade9000_cur_wfb_index_32ksps_i32      81  // 
#define ade9000_loc_wfb_index_32ksps_i32      82  // 
#define ade9000_discovery_time_32ksps_i32     83  // 

#define ade9000_sample_seqnr_32ksps_i32       91  // Sequence number of the sample, as recorded by frontend (e.g., metrology microcontroller)
#define ade9000_buffer_monotime_32ksps_i32    92  // Monotonic receive time at metrorec (usually jetson uptime), IN NANOSECONDS (int32 wraps about every second)
#define ade9000_sample_monotime_32ksps_i32    93  // Monotonic receive time at frontend (usually metrology microcontroller uptime), IN NANOSECONDS (int32 wraps about every second)
#define ade9000_voltraw_primary_32ksps_i32    21  // raw 24-bit data for ade9000_voltage_primary_32ksps
#define ade9000_voltraw_secondary_32ksps_i32  22  // raw 24-bit data for ade9000_voltage_secondary_32ksps
#define ade9000_voltraw_tertiary_32ksps_i32   23  // raw 24-bit data for ade9000 voltage channel C
#define ade9000_voltraw_metastuff_32ksps_i32  24  // raw 24-bit data for ade9000 voltage channel EMPTY (reserved for meta stuff in TEENSPI)
#define ade9000_curraw_phaseA_32ksps_i32      25  // raw 24-bit data for ade9000_current_phaseA_32ksps
#define ade9000_curraw_phaseB_32ksps_i32      26  // raw 24-bit data for ade9000_current_phaseB_32ksps
#define ade9000_curraw_phaseC_32ksps_i32      27  // raw 24-bit data for ade9000 current channel C
#define ade9000_curraw_phaseN_32ksps_i32      28  // raw 24-bit data for ade9000 current channel N
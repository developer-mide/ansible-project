// stream data out of the ringbuffer
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "metrobuf.h"


int num_fields=1, fieldid[16];
int mode,wait_counter;

// Look into original SPINX/read_ringbuf for more consistency checks

int main(int argc,char* argv[])
{
    char *bufdir;
    if (argc>1) {
        bufdir=argv[1];
        if (bufdir[0]=='l') if (bufdir[1]==0) { print_fieldnames(stdout); exit(0); }
    }

    if(argc<4) {
		fprintf(stderr,"Usage: %s <absolute_path_to_buffer> <mode> <nr_of_samples_into_the_past> [field1 [field2] ... [fieldN]]\n",argv[0]);
        	fprintf(stderr,"  mode 0: quiet, abort on first discontinuity or inconsistency\n");
	        fprintf(stderr,"  mode 1: verbose, report discontinuities and inconsistencies\n");
        print_fieldnames(stderr);
        fprintf(stderr,"To just show the field definitions, use: %s l\n",argv[0]);
		exit(EINVAL);
	}

    mode=atol(argv[2]);
    long past_samples = atol(argv[3]);
    num_fields=argc-4; if (num_fields==0) { num_fields = 1; fieldid[0]=1; } else
	    for (int i=0; i<num_fields; i++) fieldid[i]=atol(argv[i+4]);
    if (mode) fprintf(stderr,"past_samples: %ld num_fields: %d first field: %d\n", past_samples,num_fields,fieldid[0]);

    chdir_errcheck(bufdir);
    uint64_t chunkdir_number=read_chunkmeta()+1;
    long nrs=0, size, nrblocks;

    do {
        chunkdirname(--chunkdir_number);
        if (mode) fprintf(stderr,"chunkdir_number: %ld chunkdir_name: %s   ", chunkdir_number, chunkdir);

        chdir_errcheck(chunkdir); // TBD: Non-existing previous chunkdir could mean not enough samples yet... start at first instead of error?
        open_datafiles("r");
        chdir_errcheck(bufdir);
        //if (mode) fprintf(stderr,"f_MD file descriptor pointer: %p   ", f_MD);

        if (f_MD==NULL) { size=0; } else { fseek(f_MD,0,SEEK_END); size=ftell(f_MD); }
        nrblocks=size/sizeof(meta1_record);
        nrs+=nrblocks*(SAMPLES_PER_RECORD);
        if (mode) fprintf(stderr,"Size of %s: %10ld Blocks: %8ld Total samples: %10ld\n", FN_MD, size, nrblocks, nrs);
    } while (past_samples>nrs);

    long recordnr=(nrs-past_samples)/(SAMPLES_PER_RECORD);
    if (mode) fprintf(stderr,"              Navigate to Block: %8ld  Sample: %10ld \n", recordnr, recordnr*(SAMPLES_PER_RECORD));
    seek_datafiles( recordnr );

    uint64_t cur_chunkdir_number=chunkdir_number;
    while (1) {
        if (stream_datafiles( mode, num_fields, fieldid, MAX_READ_ENTRIES ) != MAX_READ_ENTRIES) {
            if (cur_chunkdir_number != chunkdir_number) {
                cur_chunkdir_number=(++chunkdir_number);
                close_datafiles();
                chunkdirname(chunkdir_number);
                if (mode) fprintf(stderr,"chunkdir_number: %ld chunkdir_name: %s\n", chunkdir_number, chunkdir);
                chdir_errcheck(chunkdir);
                open_datafiles("r"); // How to handle empty directories?
                chdir_errcheck(bufdir);
            } else {
                cur_chunkdir_number=read_chunkmeta(); // Not immediately switching to new set, in case previous chunkdir was still flushing
                // But if we are here and there is no new set, then let's sleep a little
                if (cur_chunkdir_number == chunkdir_number) usleep(1000);
            }
        }
    }

    exit(0);

}


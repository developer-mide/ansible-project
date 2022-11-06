"""SGC metrology module 

@Utilidata

`sgc_metrology` is an example implementation of a python module which can read data from the metrology buffer.

On a live SGC system with running metrorec, this module can actually read
live data from the metrology buffer.

This implementation can also play back pre-recorded test data from a file.

If you want the playback to happen close to the actual acquisition speed, just
install the tool "pv", e.g. on debian/ubuntu-based systems:

```shell
sudo apt install pv
```

and set use_pv to true

"""

import subprocess
import atexit
import time
import numpy as np

import bufferchannels

import logging
import sys

root = logging.getLogger()
root.setLevel(logging.DEBUG)

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
root.addHandler(handler)

proc = None
num_channels = 1

### Settings for Data File Support, not working yet!
use_datafile = False # Data file support isn't working yet, need decision on channel names in data files
cat_binary = "/bin/cat" # for linux-type systems
#cat_binary = ["C:\Windows\System32\cmd.exe","/C","type"] # for windows - work-in-progress, and *cat_binary wasn't a good fit either
use_pv = False # Only works on linux or in cygwin for now
datafile = "./snaps/snapclean_1649968341_jnx30d7.bin"
### End of Settings for Data File Support

readbuf_binary = "./read_metrobuf"
readbuf_dir = "/tmp/buftest/"
attach_binary = "(undefined)"
# Channel names are still preliminary. Also, in the current data files,
# only "ade9000_voltage_secondary_32ksps" and "ade9000_voltage_primary_32ksps" are present,
# and will be returned in exactly that order for now, regardless of the attach file

class SgcMetrologyException(Exception):
        pass

def attach(channels, nr_of_samples_into_the_past):
    """Attach to the SPINX ringbuffer and stream the specified channels, optionally specify nr_of_samples_into_the_past to start with."""

    global proc
    global num_channels
    global attach_binary
    use_shell=False
    if isinstance(channels, str): channels = [ channels ]
    if use_datafile:
        if use_pv:
            attach_binary="cat"
            params=[attach_binary+" "+str(datafile)+" | pv -L 128k -q"]; use_shell=True
        else:
            attach_binary=cat_binary
            params=[cat_binary,str(datafile)]
    else:
        attach_binary=readbuf_binary
        params=[ readbuf_binary, readbuf_dir, "0", str(nr_of_samples_into_the_past) ]
        # consider "nocache" variant for retrieval of very large datasets (more than 50% of RAM to scan through readbuffer)
        for chan in channels: params.append(str(bufferchannels.channel_names[chan]))
    num_channels=len(channels)

    atexit.register(detach)
    proc = subprocess.Popen(params, stdout = subprocess.PIPE, shell=use_shell)


def read(nr_of_samples):
    """Read the next nr_of_samples from the SGC ringbuffer"""

    global proc
    arr = np.frombuffer(proc.stdout.read(nr_of_samples * np.float32().itemsize * num_channels), dtype = np.float32)
    logging.debug(arr)
    if (proc.poll() is not None):
        atexit.unregister(detach)
        raise SgcMetrologyException({"message":attach_binary+" terminated prematurely","exitcode":proc.poll()})
    if (num_channels>1): arr.shape = (nr_of_samples,num_channels) # Don't re-shape for single channels right now, might mess up existing code
    return arr


def detach():
    """Detach from the SGC ringbuffer"""

    global proc
    proc.kill()
    atexit.unregister(detach)
    #print("Detached")


def main():
    """Reading live metrology data."""
    #attach("ade9000_voltage_primary_32ksps",100000)  # Single-Channel attach example
    #attach(["ade9000_sample_seq_nr_32ksps","ade9000_voltage_primary_32ksps"],100000)  # Mutli-channel-attach example
    #attach(["ade9000_voltage_secondary_32ksps",
    #        "ade9000_voltage_primary_32ksps",
    #        "ade9000_voltraw_secondary_32ksps",
    #        "ade9000_voltraw_primary_32ksps",
    #        "ade9000_curraw_phaseA_32ksps",
    #        "ade9000_curraw_phaseB_32ksps"], 10000); 
    
    """Reading recorded metrology data."""
    attach(["ade9000_voltage_primary_32ksps_f32",
            "ade9000_voltage_secondary_32ksps_f32"],
            10000 );
    logging.debug("Attached to waveforms")

    for i in range(40):

        # Get a new batch of voltage data
        bsize = 16000
        logging.debug("Reading batch...")
        batch = read(bsize)

        # Very basic stats (mean and rms)
        logging.debug(i, batch.size, batch.shape, np.mean(batch,axis=0),
                 np.mean(
            batch * batch,axis=0) ** 0.5 )
        np.set_printoptions(formatter={'float': lambda x: "{0:10.3f}".format(x)})
        logging.debug(i, np.mean(batch,axis=0),  np.mean(batch * batch,
                                                 axis=0) **
          0.5 )
        #time.sleep(0.5)

    detach()

if __name__ == "__main__":
    main()

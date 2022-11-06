
# metrorec

Collection of binaries, scripts and code snippets comprising the "metrology receiver & recorder" (metrorec).

# Install

Tested on Ubuntu 18.04 and 20.04 (e.g. VirtualBox VM or NVIDIA Jeton Image)

```
# install essential package(s)
sudo apt install g++

# optional: install recommended packages
sudo apt install tmux python3-numpy

# build
./build_all.sh

# venv setup
python3 -m venv venv
. venv/bin/activate
pip install requirements.txt
```

# Quickstart (Python)

In different terminals (e.g., `tmux`) on the same machine, launch:
1. `metrorec_service.sh`
2. `simstream`
3. `python3 sgc_metrology.py` (example code for streaming two channels and calculate avg & rms)

Or use `sgc_metrology.py` within a python project:
```
import sgc_metrology as metrorec
metrorec.attach(['chan1','chan2'],0) # see bufferchannels.py for channel names
data=metrorec.read(nr_of_samples_to_read)
# process data, see sgc_metrology.main() for example RMS calculation
data=metrorec.read(nr_of_samples_to_read) # can be called mutliple times, e.g. in loop, to get continuos data
metrorec.detach()
```

***


# Overview of key components in order of signal flow

## simstream

binary (C/C++) to send computed data to receiver, useful if no actual metrology board is connected

## metrorec

binary (C/C++) receives UDP packets with metrology data and saves data into on-disk buffer on the jetson.

## read_metrobuf

binary (C/C++ ) to access select data from on-disk buffer and stream to stdout. (Command Line controlled "API")

## sgc_metrology.py

example implementation in Python calling read_metrobuf to process data in python

Software team can use `sgc_metrology.py` or other python code to call `read_metrobuf` to access data inside Utilidata core service Docker.

## bufferchannels.py (and .h)

List of buffer channel names, glues together `read_metrobuf` and the python world.

Auto-created by build process, python world should always have the latest version corresponding to the `read_metrobuf` build.

Auxiliarly and development channel names might change frequently and be added and removed, but the channel names used for the docker core service are expected to be stable (once we agree on a good naming scheme).


# Draft Signal Flow/Process Tree

* Metrology Board (`TEENSPI` / `STMSPI` microcontroller code, or `simstream` for computer-generated data)
* (UDP over ethernet)
* Jetson Host System
    * `metrorec_service.sh` systemd service wrapper
        * `metrorec` receives UDP and writes data & metadata to `/path/accessible/by/docker/`
            * organized in "chunk" sub-directories, a new "chunk" is created every N minutes
        * sub-script: cleans up old "chunks", optional: transfers subset of recorded data to remote location (rsync, rclone, ...)
    * docker-core-service
        * python calls `read_metrobuf`, which reads select data from `/path/accessible/by/docker/`

For testing in absence of a Metrology Board, `simstream` can directly run on the Jetson Host System, or an independent Linux System which can send UDP packages to the Jetson Host system.

For unit tests, for example of the python process within the docker-core-service, `metrorec` and `simstream` can be called stand-alone (without the service wrapper), as long as `metrorec` and `read_metrobuf` reference the same `/path/to/buffer/`, and UDP packets can be sent and received from localhost.

For development or tests where running this set of binaries is not possible or too cumbersome (e.g., when developing on windows systems), `sgc_metrology.py` could be modified to read local files again.

The clean-up and remote-transfer could be an independent service or cron job.  The remote-transfer could be a hook (and should, for example, check for WiFi availability, and in absence of WiFi, do not transfer or only transfer minimal subset of data)

Multiple streams, each in a different sub-directory of the buffer directory and with different "chunk" sizes, could be generated in the near future by a single metrorec process, e.g. when receiving data streams with unrelated sampling rates. `read_metrobuf` can then only stream channels from one of these streams at the same time.

Multiple `metrorec` instances might be possible in the future, each receiving data from a unique metrology subsystem (e.g., on a different UDP port, or directly from SPI when SPINX/Direct SPI capability is an option again with newer kernels and ADI's continued kernel code development, or with the Streaming Processing Engine - SPE - microcontroller inside the Tegra chips)

# On-Disk Data Format

Note that the On-Disk data format, including the directory structure underneath `/path/to/buffer/`, is subject to change without notice for the near future. This is to allow hardware changes, bug fixes,
optimizations for efficient data storage size & remote transfer, new metadata, access patterns etc. Goal is to "freeze" on-disk format for pilots with remote raw data transfer / SSD data recovery,
but if on-disk changes are necessary during the pilot runtime, data format will be properly tagged with a version identifier linking it to the corresponding source release in this git repository.

## General layout of files in /path/to/buffer

* /path/to/buffer/
   * chunkmeta    <--- file containing metadata about the current "chunk" subdirectory being written to
   * 00000000001/ <--- A new "chunk" subdirectory is created every N seconds, each time name increments by one
      * meta.bin    <--- metadata for each dataset of data stored in this chunk directory, includes timestamp for each set of 16 samples
      * IA.int32    <--- actual data file, in this case, all the raw current data from channel "A" in 32-bit integer format
      * VC.int32    <--- another example data file, in this case, raw voltage data from channel "C" in 32-bit integer format
      * IB.f32      <--- optional data file, in this case calibration-scaled current data in 32-bit float format
      * ....

Above folder structure allows removal of older "chunk" directories at any time.

It also allows removal of unnecessary channels (those not of interest to be preserved) at any time on all older directories,
or compress older directories or channels (large lossless compression ratio possible for data not containing anomalies, and even larger possible if small resolution loss is acceptable)

Directories which are transferred to cloud storage successfully for archival reasons can safely be deleted.

Channel files which store the raw data in a delta-compressed format right away might be possible

If disk runs full, the default behavior is to delete the oldest data first. Other partial deletion schemes are possible if useful.



# Remote Raw Data Transfer / SSD Raw Data Recovery

Because I am very familiar with `rsync`, metrorec's example implementation uses `rsync` for now.

For S3 buckets and similar cloud backends, `rclone` might be a viable alternative to `rsync`:

* [Wikipedia - Rclone](https://en.wikipedia.org/wiki/Rclone)
* [Rclone](https://rclone.org/)

(Note: Ubuntu 20.04 provides rclone Version: 1.50.2-2ubuntu0.1 as an apt package)

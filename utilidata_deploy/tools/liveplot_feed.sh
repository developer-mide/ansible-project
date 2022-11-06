#!/bin/bash

#while true; do date ; ./spinx_unity >/dev/null ; done
#while true; do date ; sudo nice -n -19 sudo -u utilidata ./spinx_unity >/dev/null ; done

while true; do
	#killall spinx_unity; sleep 0.01;
	F="../test_live.bin" ; date ; sleep 1; timeout 3 ./read_ringbuf 0 0 >"$F" 
	nice -n 10 octave --no-gui --eval "F='$F'; fid=fopen(F,'r');d=fread(fid,'single');fclose(fid); size(d), save('-ascii',[ F '.tmp' ],'d');" ; mv "$F.tmp" "$F.dat";
done

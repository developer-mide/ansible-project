
%F='./snaps/snap1649268357.bin'; % floating inputs from jnx30d1
%F='./snaps/snap_1649269919_jnx30d5.bin'; % missing samples at ~9000, otherwise clean
%F='./snaps/snap_1649273328_jnx30d5.bin'; % missing samples at ~8000, otherwise clean
%F='./snaps/snap_1649274621_jnx30d4.bin'; % strong data integrity issues
F='snaps/snap_1649276279_jnx30d4.bin'; % medium-to-strong data integrity issues
%F='./snaps/snap_1649343137_jnx30d4.bin'; % Neat and clean
%F='./snaps/snap_1649874546_jnx30d4.bin'; % Neat and clean
%F='./snaps/snap_1649874736_jnx30d4.bin'; % missing samples at ~12000, otherwise clean

%F='snaps/snapclean_1649961921_jnx30d4.bin'; % Some unphysical on _single samples_
%F='snaps/snapclean_1649961926_jnx30d4.bin'; % Some unphysical on _single samples!_
%F='snaps/snapclean_1649962205_jnx30d5.bin'; % Neat and clean
%F='snaps/snapclean_1649962210_jnx30d5.bin'; % Neat and clean
%F='snaps/snapclean_1649962268_jnx30d6.bin'; % Neat and clean
%F='snaps/snapclean_1649962273_jnx30d6.bin'; % Neat and clean
% F='./snaps/snapclean_1649968341_jnx30d7.bin'; % First 10-second dataset, appears clean
%F='./snaps/snapclean_1649971420_jnx30d8.bin'; % Another 10-second dataset from another unit, appears clean
% F='./snaps/snapclean_1650898019_jnx30d4.bin';
% F='./snaps/snapclean_1653323570_jnx30d10.bin'; % A & B were swapped
% F='./snaps/snapclean_1653324061_jnx30d10.bin';

%F='./snaps/snapclean_1653429418_jnx30d10.bin'; % 30 second data from unit 10
%F='./snaps/snapclean_1653430891_jnx30d7.bin'; 

FDIR='./snaps/';
F='snapshot_1654802198_jnx30d10_0.5s_ch1-2.f32'; nch=2;
F='snapshot_1654802194_jnx30d10_0.5s_ch1-2-4-5.f32'; nch=4;
F='snapshot_1654803489_jnx30d10_0.5s_ch1-2-4-5.f32'; nch=4;

fid=fopen([ FDIR F ],'r');
d=fread(fid,[nch, inf],'single');
fclose(fid);

%figure(8);
figure();
hold off;
%plot(diff(d(2,:))); hold on;
%plot(d(2,1:32000)); hold on;
plot(d(2,:)); hold on;
plot(d(1,:));
plot(d(1,:)-d(2,:));
plot(d(3,:));
plot(d(4,:));
legend({ 'Split-Phase', 'V1-to-Neutral', 'V2-to-Neutral', 'Ia', 'Ib' });
xlabel('Sample # @ 32ksps')
ylabel('Voltage (V)');
title(F,'interpreter','none');

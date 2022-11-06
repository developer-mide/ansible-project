

FDIR='./snaps/';
%F='snapshot_1654802198_jnx30d10_0.5s_ch1-2.f32'; nch=2;
F='snapshot_1654803489_jnx30d10_0.5s_ch1-2-4-5.f32'; nch=4;

fid=fopen([ FDIR F ],'r');
d=fread(fid,[nch, inf],'single');
fclose(fid);

figure(); hold off; legstr={};
plot(d(2,:)); hold on;    legstr{end+1}='Split-Phase (V1-to-V2)';
plot(d(1,:));             legstr{end+1}='V1-to-Neutral';
plot(d(1,:)-d(2,:));      legstr{end+1}='V2-to-Neutral';
if (nch>=3) plot(d(3,:)); legstr{end+1}='Ia';  end;
if (nch>=4) plot(d(4,:)); legstr{end+1}='Ib';  end;
%legend({ 'Split-Phase', 'V1-to-Neutral', 'V2-to-Neutral', 'Ia', 'Ib' });
legend(legstr);
xlabel('Sample # @ 32ksps')
ylabel('Voltage (V) or Current (AU)');
title(F,'interpreter','none');

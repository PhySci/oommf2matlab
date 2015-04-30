dt = 2e-11;
freq = 9.07;
sliceY = 10;
freqScale = linspace(-0.5/dt,0.5/dt,2048)/1e9;
[~,ind] = min(abs(ifftshift(freqScale) - freq));
xRange = 96:105;
zRange = 12:19;

YFile =  matfile('D:\Micromagnet\OOMMF\proj\TransducerAPL\center\pulse\matlab\YzFFT.mat');
Yz = abs(YzFile.Yz(ind,xRange,sliceY,zRange));
Phase = angle(YzFile.Yz(ind,xRange,sliceY,zRange));
YzTmp = squeeze(mean(Yz,4));
PhaseTmp = squeeze(mean(Phase,4));

figure();
subplot(211);
    plot(YzTmp,'-*'); title('FFT amplitude');% xlim([1 11]);
    
subplot(212);
    plot(PhaseTmp); title('Phase');
 
function freqSlice(freq)
steps = 16;
dt = 1/(steps*freq);
timeFrames = 512;

yRange = 20:61;
zRange = 1:10;

MzFile = matfile(fullfile(pwd,'Mz.mat'));
arrSize = size(MzFile,'Mz');
Mz = MzFile.Mz(arrSize(1)-timeFrames:arrSize(1),:,yRange,zRange);

Yz = fft2(Mz);
Y = mean(mean(Yz,3),4);
Amp = abs(Y);

Amp = fftshift(Amp,1);
Amp = fftshift(Amp,2);

dx = 0.5; %mkm
waveScale = 2*pi*linspace(-0.5/dx,0.5/dx,arrSize(2));
freqScale = linspace(-0.5/dt,0.5/dt,timeFrames)/1e9;
[~,freqInd] = min(abs(freqScale-freq/1e9));

figure(1);
    imagesc(waveScale,freqScale,log10(Amp/min(Amp(:))));
    axis xy
    xlim([0 6]); ylim([0.5 20]);
  
lambda = 2*pi./waveScale;

slice = Amp(freqInd,:);
figure(2);
    plot(lambda,slice);
    xlim([0 50]);
   
res = [waveScale; slice].'; 
save waveSlice.mat res      
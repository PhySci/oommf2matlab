dt = 2.1186441e-11; % time resolution
dl = 0.5; % spatial resolution
arr = squeeze(mean(res(30:end,:,:),3));
lRange = linspace(-0.5/dl,0.5/dl,size(arr,2));
fRange = linspace(-0.5/dt,0.5/dt,size(arr,1))/1e9;
Y = fftshift(fft(arr,[],2),2);
Mod = abs(Y);

figure(3);
contourf(lRange, fRange, log10(Mod),20);
xlim([0 1e-3]); xlabel('wave number, nm^-^1')
ylim([0 20]); ylabel('Freq, GHz');
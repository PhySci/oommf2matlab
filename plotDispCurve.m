dir = 'D:\Micromagnet\OOMMF\proj\Khitun\waveguide\8\pulse';
MyFile = matfile(strcat(dir,'\My.mat'));
My = MyFile.My(:,:,:,:);
slice = My(:,:,round(0.5*size(My,3)),round(0.5*size(My,4)));
slice = mean(slice,4);
slice = mean(slice,3);

dt = 1e-11;
freqScale = linspace(-0.5/dt,0.5/dt,size(slice,1))/1e9;
dx = 4e-3;
spatialScale = 2*pi*linspace(-0.5/dx,0.5/dx,size(slice,2));
Y = fft2(slice);
Amp = fftshift(abs(Y));
ref = min(Amp(:));
dB = log(Amp/ref);
colormap(jet);
    imagesc(spatialScale,freqScale,dB);
    axis xy;
    xlim([0 300]); xlabel('Wave vector, \mum^-^1')
    ylim([-0.15 25]); ylabel('Freq, GHz');
    t = colorbar('peer',gca);
    set(get(t,'ylabel'),'String', 'FFT intensity, dB');
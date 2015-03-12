function collectBat(inp)

res = averageMag(inp, 5);
% Collect 
clf;
yFirstCell = 1;
yLastCell = 20;

dt = 2e-11;
ystep = 5000e-9;
plotSpecs = false;

freqLimit = [0 10];
ylimits = [1 16];
y = ystep*linspace(yFirstCell,yLastCell,max(ylimits))/1e-6;

%path = 'C:\Micromagnet\OOMMF\proj\Transducer APL\Carl_simulations_20150306\transducer+waveguide\pulse\obj';

%res = collectSliceData(path,...
%                 1:10,... % X range
%                 21:60,... % Y range
%                 1:200,...   % Z range
%                 'save',true,...
%                 'savePath',strcat(path,'\..\'));

% res = collectSliceData(path,...
%                  [1:200],... % X range
%                  [30:50],... % Y range
%                  [9:10],...   % Z range
%                  'save',true,...
%                  'savePath',strcat(path,'\..\'));
% res = permute(res,[2 1 3 4 5]);

%disp('Data was collected');
%pause;
%load('H:\Fedor\Transducer APL\pulse\objcollectData.mat');
freq = linspace(-1/(2*dt),1/(2*dt),size(res,2));

Mx = mean(mean(res(:,:,:,:,1),3),4);
Mz = mean(mean(res(:,:,:,:,3),3),4);  

Yx =  fftshift(abs(fft(Mx,[],2)),2);
Yz =  fftshift(abs(fft(Mz,[],2)),2);
size(Yz)

% plot FFT spectra of slices
for i=1:size(res,1)
  if (plotSpecs)
  handler = figure(1);
  set(handler,'NumberTitle','off');
  set(handler,'Name',strcat('Slice Y = ',num2str(y(i))));
  %subplot(211);
  %  plot(freq,Yx(i,:));
  %  xlabel('Freq,GHz');
  %  xlim([freq freq(xlimits(2))]); 
  %  ylabel('Amp, a.u.'); title('FFT transform of Mx component');
  %subplot(212);
    plot(freq/1e9,Yz(i,:));
    xlabel('Freq,GHz');
    xlim([freqLimit(1) freqLimit(2)]); 
    ylabel('Amp, a.u.'); title('FFT transform of Mz component');
    imgName = strcat('_Slice',num2str(y(i)),'.png');
    saveas(handler, strcat(path,'\',imgName));
  pause;
  end
end
save FFTtransform.mat Yx Yz;

Ypos = y(ylimits(1):ylimits(2));

% plot Mz(y) map 
figure(2);
val = Yz(ylimits(1):ylimits(2),:);
ref = max(min(val(:)),1);
dB = 10*log10(val/ref);
contourf(freq/1e9,Ypos,val );
xlim(freqLimit);
xlabel('Freq, GHz'); ylabel('\mum');
title('Density of FFT transform of Mz projection')
hcb=colorbar('EastOutside');
contourf(freq/1e9,Ypos,dB,20);
colormap(jet); xlim(freqLimit)
xlabel('Freq, GHz'); ylabel('\mum');...
title('Density of FFT transform of Mz projection');
hcb=colorbar('EastOutside');

% plot Mz(y) map 
figure(3);
val = Yx(ylimits(1):ylimits(2),:);
ref = max(min(val(:)),1);
dB = 10*log10(val/ref);
contourf(freq/1e9,Ypos,dB,20);
colormap(jet);
xlim(freqLimit);
xlabel('Freq, GHz'); ylabel('\mum');...
title('Density of FFT transform of Mx projection')
hcb=colorbar('EastOutside');

% plot Mx(y) map
meanMz = mean(Mz,1).';
meanMx = mean(Mx,1).';
meanYz = fftshift(abs(fft(meanMz)));
meanYx = fftshift(abs(fft(meanMx)));
figure(4);
%subplot(211);
plot(freq/1e9,meanYz); ylabel('Mz FFT');
              xlim(freqLimit);
%subplot(212); plot(freq/1e9,meanYx); ylabel('Mx FFT');
%              xlim(freqLimit);
xlabel('Freq, GHz');

freq = freq/1e9;
save FFTfullTrans.mat Yx Yz meanYz meanYx freq

end

function res = averageMag(input, base)
  res =  zeros(ceil(size(input,1)/base-1),size(input,2),size(input,3),size(input,4),size(input,5));
  for i=0:(size(input,1)/base-1)
    res(i+1,:,:,:,:) = mean(input((base*i+1):(base*i+base),:,:,:,:),1);  
  end
end
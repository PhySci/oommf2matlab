dt = 2e-11;
load collectData-newInitState.mat;
freq = linspace(0,1/(2*dt),ceil(size(res,2)/2));

Mx = zeros(size(res,2),1);
Mx = zeros(size(res,2),1);
Yx = zeros(size(res,1),ceil(size(res,2)/2));
Yz = zeros(size(res,1),ceil(size(res,2)/2));


for i=1:size(res,1)
  Mx = mean(mean(squeeze(res(i,:,:,:,1)),3),2);
  Mz = mean(mean(squeeze(res(i,:,:,:,3)),3),2);
  Yx(i,:) = foldFFTSpec(abs(fftshift(fft(Mx))));
  Yz(i,:) = foldFFTSpec(abs(fftshift(fft(Mz))));
  
  clf;
  handler = figure(1);
  set(handler,'NumberTitle','off');
  set(handler,'Name',strcat('Slice Y = ',num2str(params.sliceNumber(i))));
  subplot(211);
    plot(freq/1e9,Yx(i,:)); xlabel('Freq,GHz'); % xlim([0.1 10]);
    ylabel('Amp, a.u.'); title('FFT transform of Mx component');
  subplot(212);
    plot(freq/1e9,Yz(i,:)); xlabel('Freq,GHz'); %xlim([0.1 10]); 
    ylabel('Amp, a.u.'); title('FFT transform of Mz component');
  imgName = strcat('_Slice',num2str(params.sliceNumber(i)),'.png');
  saveas(handler, imgName);  
end
save FFTtransform.mat Yx Yz;
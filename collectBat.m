% Function for collection and plotting of lot of slices of OOMMF files.
% inp - array
function collectBat(inp)
    % Collect
    clf;
    yFirstCell = 1;
    yLastCell = 16;
    viewAlong = 'Y';
    avg = 9;
    dt = 2e-11;
    ystep = 500e-9;
    plotSpecs = true;

    freqLimit = [0.1 10];
    ylimits = [1 80];
    y = ystep*linspace(-10,30,max(ylimits));
    
    
    if (strcmp(viewAlong,'Y'))
        res = permute(inp,[1 3 2 4 5]);
    elseif (strcmp(viewAlong,'X'))
        res = inp;
    end
        
    res = averageMag(res, avg);

    % path = 'D:\Micromagnet\OOMMF\proj\TransducerAPL\center\pulse\result';

    %  res = collectSliceData(path,...
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

    %  disp('Data was collected');
    %  pause;
    %  load('H:\Fedor\Transducer APL\pulse\objcollectData.mat');
    
    
    freq = linspace(-1/(2*dt),1/(2*dt),size(res,1))/1e9;

    Mz = mean(mean(res(:,:,:,:,3),3),4);

    Yz =  matfile('D:\Micromagnet\OOMMF\proj\TransducerAPL\center\pulse\matlab\YzFFT.mat');
    fftshift(abs(fft(Mz,[],1)),1);

    % plot FFT spectra of slices
    if (plotSpecs)
        for i=1:size(Yz,2)
            fig1 = figure(1);
                set(fig1,'NumberTitle','off');
                set(fig1,'Name',strcat('Slice Y = ',num2str(y(i))));
                plot(freq,Yz(:,i));
                xlabel('Freq,GHz'); xlim([freqLimit(1) freqLimit(2)]);
                ylabel('Amp, a.u.');
                title(strcat('FFT transform of Mz component. Slice ',viewAlong,' = ',num2str(y(i)),' \mum'));
                imgName = strcat('_Slice',num2str(y(i)),'.png');
            [fName, errFlag] = generateFileName('.','Slice','png');
            pause;
            print(fig1,'-dpng','-r300',fName);
        
        end
    end
    save FFTtransform.mat Yx Yz;
 
    Ypos = y(ylimits(1):ylimits(2));

    % plot Mz(y,Freq) map
    fig2 = figure(2);
        set(fig2,'Position', [1, 1, 1024, 768]);
        val = Yz(:,ylimits(1):ylimits(2));
        ref = max(min(val(:)),1);
        dB = 10*log10(val);
        
        imagesc(freq,Ypos,val.');
        colormap(flipud(gray));
        
        xlim(freqLimit);
        xlabel('Freq, GHz');
        ylabel(strcat(viewAlong,', \mum'));
        title('Intensity of FFT for M_z projection of magnetization');
        hcb=colorbar('EastOutside');
             
        t = colorbar('peer',gca);
        set(get(t,'ylabel'),'String', 'FFT intensity, a.u.');
        
        [fName, errFlag] = generateFileName('.','SpatialMap','png');
        print(fig2,'-dpng','-r300',fName);
   % save FFTfullTrans.mat Yx meanYx freq

  
  fig3 = figure(3);
       set(fig3,'Position', [1, 1, 1024, 768]);
       meanYz = fftshift(abs(fft(mean(Mz,2),[],1)));
       plot(freq,meanYz);
       xlim(freqLimit);
       xlabel('Freq, GHz');
       title('Intensity of FFT for M_z projection of magnetization');
       
       [fName, errFlag] = generateFileName('.','Total spectra','png');
       print(fig3,'-dpng','-r300',fName);
       
end

function res = averageMag(input, base)
    for i=1:size(input,1)
        input(i,:,:,:,1) = smooth3(squeeze(input(i,:,:,:,1)),'gaussian',base);
        input(i,:,:,:,2) = smooth3(squeeze(input(i,:,:,:,2)),'gaussian',base);
        input(i,:,:,:,2) = smooth3(squeeze(input(i,:,:,:,3)),'gaussian',base);  
    end
    res = input;
end
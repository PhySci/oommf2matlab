% Function for collection and plotting of lot of slices of OOMMF files.
% inp - array of magnetisation. In order to generate the input, use
%    inpFile =  matfile('D:\Micromagnet\OOMMF\proj\TransducerAPL\center\pulse\matlab\YzFFT.mat');
%    inp = YzFile.Yz;  
% 
function collectBat2(Yz)
    % Collect
    path = 'D:\Micromagnet\OOMMF\proj\Khitun\waveguide\500_Oe\pulse';
    
    viewAlong = 'X';
    xRange = 96:105;
    dt = 2e-11;
    
    plotSpecs = false;
    freqLimit = [0.1 15];     
    
    YzFile =  matfile(strcat(path,'\MxFFT.mat'));
    Yz = YzFile.Yx(:,:,:,20:30);  
    
    tmp = load(strcat(path,'\params.mat'));
    obj = tmp.obj;

    xScale=linspace(obj.xmin,obj.xmax,obj.xnodes)/1e-6;
    %xScale=xScale(xRange);
    yScale=linspace(obj.ymin,obj.ymax,obj.ynodes)/1e-6;
    zScale=linspace(obj.zmin,obj.zmax,obj.znodes)/1e-6;
    
    freqScale = linspace(-1/(2*dt),1/(2*dt),size(Yz,1))/1e9;
    [~,freqScaleInd(1)] = min(abs(freqScale-freqLimit(1)));
    [~,freqScaleInd(2)] = min(abs(freqScale-freqLimit(2)));
    freqScale = freqScale(freqScaleInd(1):freqScaleInd(2));
    
    % plot FFT spectra of slices
    if (plotSpecs)
        fig1 = figure(1);
         % waveguide
        annotation('rectangle',[0.7 0.7 0.2 0.2], 'FaceColor',[0 0 1]);
        % transducer
        annotation('rectangle',[0.8 0.6 0.05 0.4], 'FaceColor',[1 0 0]);
        % level
        line = annotation('line',[0 0], [0 0],'Color',[0 1 0],'LineWidth',2);
        
        for i=1:2:size(yScale,2)
            
                set(fig1,'NumberTitle','off');
                set(fig1,'Name',strcat('Slice Y = ',num2str(yScale(i))));
                spec = fftshift(squeeze(mean(mean(Yz(:,:,i,:),2),4)));
                plot(freqScale,spec);
                xlabel('Freq,GHz'); xlim([0.1 20]);
                ylabel('Amp, a.u.');
                title(strcat('FFT transform of Mz component. Slice ',viewAlong,' = ',num2str(yScale(i)),' \mum'));
                
                minLevel = 0.6;
                lineLevel = minLevel + 0.4*((yScale(i)-min(yScale(:)))/(max(yScale(:))-min(yScale(:))));
                set(line,'Position',[0.7 lineLevel 0.2 0]);
                
                
                
            [fName, errFlag] = generateFileName('.','Slice','png');
                 
            ans = input('Save images? "y" - yes','s');    
            if strcmp(ans,'y')
                print(fig1,'-dpng','-r300',fName);
            end        
        end
    end

 
    % plot Mz(y,Freq) map
    if (true)
        fig2 = figure(2);
            %set(fig2,'Position', [1, 1, 1024, 768]);
            Yz = abs(fftshift(Yz,1)); 
            val = squeeze(mean(mean(Yz(freqScaleInd(1):freqScaleInd(2),:,:,1),3),4));
            ref = min(val(:));
            dB = 10*log10(val/ref);

            imagesc(freqScale,xScale,dB.');
            axis xy;
            %xlim([0 15]);
            xlabel('Freq, GHz');
            ylabel(strcat(viewAlong,', \mum'));
            title('Intensity of FFT for M_z projection of magnetization');
            hcb=colorbar('EastOutside');

            t = colorbar('peer',gca);
            set(get(t,'ylabel'),'String', 'FFT intensity, dB');

            [fName, errFlag] = generateFileName('.','SpatialMap','png');
            if (~errFlag)
                print(fig2,'-dpng','-r300',fName);
            else
                disp('Could not save image');
            end    
    
 %  fig3 = figure(3);
 %      set(fig3,'Position', [1, 1, 1024, 768]);
 %      plot(freq,meanYz);
 %      xlim(freqLimit);
 %      xlabel('Freq, GHz');
 %      title('Intensity of FFT for M_z projection of magnetization');
       
 %      [fName, errFlag] = generateFileName('.','Total spectra','png');
 %      print(fig3,'-dpng','-r300',fName);
      end     
       
end

function res = averageMag(input, base)
    for i=1:size(input,1)
        input(i,:,:,:,1) = smooth3(squeeze(input(i,:,:,:,1)),'gaussian',base);
        input(i,:,:,:,2) = smooth3(squeeze(input(i,:,:,:,2)),'gaussian',base);
        input(i,:,:,:,2) = smooth3(squeeze(input(i,:,:,:,3)),'gaussian',base);  
    end
    res = input;
end
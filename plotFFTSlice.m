function plotFFTSlice(dirPath)
    clf;
   % path = 'D:\Micromagnet\OOMMF\proj\TransducerAPL\center\pulse\matlab';
    
    tmp = load(strcat(dirPath,'\params.mat'));
    obj = tmp.obj;
    xScale=linspace(obj.xmin,obj.xmax,obj.xnodes)/1e-6;
    %xScale=xScale(xRange);
    yScale=linspace(obj.ymin,obj.ymax,obj.ynodes)/1e-6;
    zScale=linspace(obj.zmin,obj.zmax,obj.znodes)/1e-6;

    dt = 2e-11;
    fMin = 1;
    fMax = 2047;
    fStep = 2;
    
    freqScale = ifftshift(linspace(-1/(2*dt),1/(2*dt),fMax)/1e9); % numerical values of frequencies
    mFile = matfile(strcat(dirPath,'\Yx.mat'));
    
    spatialSlices = 5;
    YSlice = squeeze(mFile.Yz(:,5,spatialSlices,:));
    Amp = abs(YSlice);
    Phase = angle(YSlice);
  
    fig1=figure(1);
    anno_hdl=annotation('textbox', [0.5,0.9,0.1,0.1]);
    set(anno_hdl,'EdgeColor','none','FontSize',18);
        
    % plot spatial map of FFT
    for freqInd = 1:size(YSlice,1) 
      disp (freqInd)
      freqStr = num2str(abs(freqScale(fMin+fStep*(freqInd-1))),'%10.2f\n');
       % determine maximum value of magnetisation
      M = Amp(freqInd,:,:,:); 
      Mmax = max(M(:)) ;
      MLim = [0 Mmax];
      if true
          
      set(gcf,'Name',strcat('Freq = ',freqStr,' GHz'));
      
      % put frequency value of the figure      
      set(anno_hdl,'String', strcat('Frequency = ',freqStr,' GHz')); 

      
      if size(spatialSlices,1) == 1
                        % plot amplitude map
              subplot(2,1,1);
                  imagesc(yScale,xScale,squeeze(Amp(freqInd,:,:)),MLim);
                  title('Amplitude of FFT');
                  axis xy; hcb=colorbar('EastOutside');
                  set(get(hcb,'ylabel'),'String', 'a.u.');
                  xlabel('Y, \mum'); ylabel('X, \mum'); 

                 % plot phase map   
              subplot(2,1,2);
                  imagesc(yScale,xScale,squeeze(Phase(freqInd,:,:)),[-pi pi]);
                  title('Phase of FFT');
                  axis xy; hcb=colorbar('EastOutside');
                  set(get(hcb,'ylabel'),'String', 'rad.');
                  xlabel('Y, \mum'); ylabel('X, \mum');
      else
          for subPlotInd = 1:size(spatialSlices,2) 
              % plot amplitude map
              subplot(size(spatialSlices,2),2,2*subPlotInd-1);
                  imagesc(yScale,xScale,squeeze(Amp(freqInd,:,:,subPlotInd)),MLim);
                  title('Amplitude of FFT');
                  axis xy; hcb=colorbar('EastOutside');
                  set(get(hcb,'ylabel'),'String', 'a.u.');
                  xlabel('Y, \mum'); ylabel('X, \mum'); 

                 % plot phase map   
              subplot(size(spatialSlices,2),2,2*subPlotInd);
                  imagesc(yScale,xScale,squeeze(Phase(freqInd,:,:,subPlotInd)),[-pi pi]);
                  title('Phase of FFT');
                  axis xy; hcb=colorbar('EastOutside');
                  set(get(hcb,'ylabel'),'String', 'rad.');
                  xlabel('Y, \mum'); ylabel('X, \mum');
          end
      end
      
     
         print(gcf,'-dpng','-r300',strcat(dirPath,'\waveguideSpatialFFT-freq=',freqStr,'.png'));
     end 
   end          
            
end


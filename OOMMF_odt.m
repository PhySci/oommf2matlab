% Class for processing results of OOMMF simulations 
classdef OOMMF_odt < hgsetget % subclass hgsetget
 
 properties
   fName = 'transducerCW.odt'
   colNames
   unitNames
   title
   data
   Mx
   My
   Mz
   B
   Bx
   By
   Bz
   time
   dt = 0
   freqScale
 end
 
 methods
   
     % load odt file and parse content
   function loadFile(obj,varargin)
     p = inputParser;
     p.addParamValue('path','');
     p.parse(varargin{:});
     params = p.Results;
     
     if (isempty(params.path))
       [fName,fPath,~] = uigetfile({'*.odt'});
       params.path = fullfile(fPath,fName);
     end    
     
     fid = fopen(params.path);
     if ((fid == -1))
       disp('File not found');
       return;
     end
     
     obj.fName = params.path;
  
     [IOmess, errnum] = ferror(fid);
     if (errnum ~= 0)
       disp(IOmess);
       return;
     end
  
     format = fgetl(fid);
     if strfind(format,'ODT 1.0') 
       fgetl(fid);
       obj.title = fgetl(fid);
       splitStr = regexp(fgetl(fid), '^# Columns: ','split');
       obj.colNames = parseTextStr(splitStr{1,2});
       splitStr = regexp(fgetl(fid), '^# Units: ','split');
       obj.unitNames = parseTextStr(splitStr{1,2});
       data = zeros(1,size(obj.unitNames,1));
       while (~feof(fid))
         line = fgetl(fid);
         if (isempty(strfind(line,'#')))
           data(end+1,:) = parseDigitalStr(line);
         end
       end
     else
       disp('Unknown format');
     end
     
     if (errnum ~= 0)
       disp(IOmess);
       return;
     else
       disp('File was uploaded');  
     end    
     
     fclose(fid);
     obj.data = data(2:end,:);
     obj.parse;
     obj.calcFreqScale
   end  
   
     % find magnetization projections and time 
   function parse(obj)
     expr = '(mx)|(my)|(mz)|(Simulation time)|(Bx)|(By)|(Bz)|(B)';
     
     for i=1:size(obj.colNames,1)
       nm = obj.colNames{i,1};  
       [token] = regexp(nm,expr,'tokens');
       
       if (~isempty(token{1,1}))
           
         if (strcmp(token{1,1}{1,1}{1,1},'mx'))
           obj.Mx = obj.data(:,i); 
         elseif (strcmp(token{1,1}{1,1}{1,1},'my'))
           obj.My = obj.data(:,i);
         elseif (strcmp(token{1,1}{1,1}{1,1},'mz'))
           obj.Mz = obj.data(:,i);
         elseif (strcmp(token{1,1}{1,1}{1,1},'Simulation time'))
           obj.time = obj.data(:,i);
           obj.dt = mean(diff(obj.time));
         elseif (strcmp(token{1,1}{1,1}{1,1},'Bx'))
           obj.Bx = obj.data(:,i);
         elseif (strcmp(token{1,1}{1,1}{1,1},'By'))
           obj.By = obj.data(:,i);
         elseif (strcmp(token{1,1}{1,1}{1,1},'Bz'))
           obj.Bz = obj.data(:,i);
         elseif (strcmp(token{1,1}{1,1}{1,1},'B'))
           obj.B = obj.data(:,i);
           
         end          
       end
     end
   end
   
    % plot FFT for Mz magnetisation
   function plotZFFT(obj,varargin)
     p = inputParser;
     p.addParamValue('scale','norm',@(x) ismember(x,{'norm','log'}));
     p.addParamValue('saveAs','',@isstr);
     p.addParamValue('freqLim',[0 15],@isnumeric);
     
     p.parse(varargin{:});
     params = p.Results; 
     
     Y = fftshift(abs(fft(obj.Mz(1:end))));
     
     
     if strcmp(params.scale,'norm')
       plot(obj.freqScale/1e9,Y);
     else
       semilogy(obj.freqScale/1e9,Y);  
     end    
     xlabel('Freq, GHz'); 
     xlim([params.freqLim(1) params.freqLim(2)]);
     ylabel('FFT intensity');
     title('FFT of M_z projection');
      
     % save img
     if (~strcmp(params.saveAs,''))
         savefig(strcat(params.saveAs,'.fig'));
         print(gcf,'-dpng',strcat(params.saveAs,'.png'));
     end
     
   end    
     
   % plot FFT for Mx magnetisation
   function plotXFFT(obj,varargin)
     p = inputParser;
     p.addParamValue('scale','norm',@(x) ismember(x,{'norm','log'}));
     p.addParamValue('saveImg',false,@islogical);
     p.addParamValue('freqLim',[0 15],@isnumeric);
     p.parse(varargin{:});
     params = p.Results; 
     
     Y = fftshift(abs(fft(obj.Mx)));
     freq = linspace(-0.5/obj.dt,0.5/obj.dt,size(Y,1))/1e9;
     
     fig1 = figure();
     if strcmp(params.scale,'norm')
       plot(freq,Y);
     else
       semilogy(freq,Y);  
     end    
       xlabel('Freq, GHz'); xlim([0,30]);
       ylabel('FFT intensity');
     
     title(strcat('FFT of M_x projection.'));
     xlim([params.freqLim(1) params.freqLim(2)]);
     
     if (params.saveImg)
       [fName, errFlag] = generateFileName('.','odtXFFT','png');
       print(fig1,'-dpng','-r300',fName);
     end
     
   end
   
   % plot FFT for My magnetisation
   function plotYFFT(obj,varargin)
     p = inputParser;
     p.addParamValue('scale','norm',@(x) ismember(x,{'norm','log'}));
     p.addParamValue('freqLim',[0 15],@isnumeric);
     p.parse(varargin{:});
     params = p.Results; 
     
     Y = fftshift(abs(fft(obj.My)));
     freq = linspace(-0.5/obj.dt,0.5/obj.dt,size(Y,1))/1e9;
     title('FFT of M_y');     
     if strcmp(params.scale,'norm')
       plot(freq,Y);
     else
       semilogy(freq,Y);  
     end
     
     xlabel('Frequency (GHz)','FontSize',12,'FontName','Times'); xlim([0,15]);
     ylabel('FFT intensity (arb. units)', 'FontSize',12,'FontName','Times');
     xlim([params.freqLim(1) params.freqLim(2)]);

   end
   
   % calculate frequency scale 
   function calcFreqScale(obj)
       if (obj.dt>0) && (size(obj.time,1)>0)
           obj.freqScale = linspace(-0.5/obj.dt,0.5/obj.dt,size(obj.time,1));
       end    
   end    
   
   function plotMz(obj,varargin)
       
       p = inputParser;
       p.addParamValue('saveAs','',@isstr);
       p.parse(varargin{:});
       params = p.Results; 
       
       plot(obj.time/1e-9,obj.Mz);
       xlim([0 1.01* obj.time(end)/1e-9]);
       xlabel('Time, ns'); ylabel('M_z, a.u.');
       
       if (~strcmp(params.saveAs,''))
           savefig(strcat(params.saveAs,'.fig'));
           print(gcf,'-dpng',strcat(params.saveAs,'.png'));
       end
   end 
   
   %% plot hysteresis loop from odt file 
   % params:
   %  - proj: projection of magnetization (z is default)
   
   function plotHystLoop(obj,varargin)
       p = inputParser;
       p.addParamValue('proj','z',@(x) any(strcmp(x,{'x','X','y','Y','z','Z'})));
       p.addParamValue('saveAs','',@isstr);
       p.parse(varargin{:});
       params = p.Results;
       
       params.proj = lower(params.proj); 
       
       B = eval(strcat('obj.B',params.proj));
       M = eval(strcat('obj.M',params.proj));
       
       plot(B/100,M,'-b'); grid on
       xlabel('H, kOe'); ylabel('M/M_s');
       xlim([0.0105*min(B(:)) 0.0105*max(B(:))]);
       ylim([-1.05 1.05]);
       
       % save img
       if (~strcmp(params.saveAs,''))
           savefig(strcat(params.saveAs,'.fig'));
           print(gcf,'-dpng',strcat(params.saveAs,'.png'));
       end 
   end    
   
 end
 
end

function res = parseTextStr(str)
  expr = '^\s*(\{[\w:\s\/]*\}|[\w:\/]+)+\s*';
  res ={};
  i = 1;
  str2 = str;
  while (~isempty(str2))
    [token, splitStr] = regexp(str2,expr,'tokens','split');
       res{i,1}= regexprep(token{1,1}, '\{|\}', '') ;
       i=i+1;
       if (~isempty(splitStr{1,1}))
         str2 = splitStr{1,1};
       elseif (~isempty(splitStr{1,2}))
         str2 = splitStr{1,2};
       else
         break;  
       end 
  end
end

function res = parseDigitalStr(str)
  expr = '^\s*(-?[\d.]+e-?[\d]+|-?[\d.]+)\s*';
  res =[];
  str2 = str;
  while (~isempty(str2))
    [token, splitStr] = regexp(str2,expr,'tokens','split');
       res(end+1)=str2double(token{1,1});
       if (~isempty(splitStr{1,1}))
         str2 = splitStr{1,1};
       elseif (~isempty(splitStr{1,2}))
         str2 = splitStr{1,2};
       else
         break;  
       end 
  end
end
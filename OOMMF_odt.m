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
   dt
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
   end  
   
     % find magnetization projections and time 
   function parse(obj)
     expr = '(mx)|(my)|(mz)|(Simulation time)';
     
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
         end          
       end
     end
   end
   
    % plot FFT for Mz magnetisation
   function plotZFFT(obj,varargin)
     p = inputParser;
     p.addParamValue('scale','norm',@(x) ismember(x,{'norm','log'}));
     p.parse(varargin{:});
     params = p.Results; 
     
     Y = fftshift(abs(fft(obj.Mz)));
     freq = linspace(-0.5/obj.dt,0.5/obj.dt,size(Y,1))/1e9;
     
     if strcmp(params.scale,'norm')
       plot(freq,Y);
     else
       semilogy(freq,Y);  
     end    
      xlabel('Freq, GHz'); xlim([0,15]);
      ylabel('FFT intensity');
   end    
     
   % plot FFT for Mx magnetisation
   function plotXFFT(obj,varargin)
     p = inputParser;
     p.addParamValue('scale','norm',@(x) ismember(x,{'norm','log'}));
     p.addParamValue('saveImg',false,@islogical);
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
     
     if (params.saveImg)
       [fName, errFlag] = generateFileName('.','odtXFFT','png');
       print(fig1,'-dpng','-r300',fName);
     end
     
   end
   
   % plot FFT for My magnetisation
   function plotYFFT(obj,varargin)
     p = inputParser;
     p.addParamValue('scale','norm',@(x) ismember(x,{'norm','log'}));
     p.parse(varargin{:});
     params = p.Results; 
     
     Y = fftshift(abs(fft(obj.My)));
     freq = linspace(-0.5/obj.dt,0.5/obj.dt,size(Y,1))/1e9;
     
     if strcmp(params.scale,'norm')
       plot(freq,Y);
     else
       semilogy(freq,Y);  
     end    
      xlabel('Freq, GHz'); xlim([0,15]);
      ylabel('FFT intensity');
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
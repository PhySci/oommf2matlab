% Class for processing results of OOMMF simulations
% It was developed based on experience of using of OOMMF_result
classdef OOMMF_sim < hgsetget % subclass hgsetget
 
 properties
   fName = ''  
   folder = ''; % path to folder with mat files
   meshunit = 'm';
   meshtype = 'rectangular';
   xbase
   ybase
   zbase
   xnodes
   ynodes
   znodes
   xstepsize = 0.001;
   ystepsize = 0.001;
   zstepsize = 0.001;
   xmin = 0;
   ymin = 0;
   zmin = 0;
   xmax = 0.01;
   ymax = 0.01;
   zmax = 0.01;
   dim = 3;
   H
   totalSimTime % total simulation time
   iteration
   memLogFile = 'log.txt';
   dt = 1e-11; % time step of simulation
 end
 
 properties (Access = protected)
     availableProjs = {'x','X','y','Y','z','Z'}; % list of available spatial projections
     staticFile = 'static.stc';
     paramsFile = 'params.mat';
     MxName = 'Mx.mat';
     MyName = 'My.mat';
     MzName = 'Mz.mat';
 end     
 
 methods
   function obj = OOMMF_sim()
         disp('OOMMF_sim object was created');
   end
   
   function [Mx,My,Mz] = loadParams(obj,varargin)
       %% open file and check errors
     availableExts ={'omf', 'ohf', 'stc'};
       
     p = inputParser;
     p.addParamValue('showMemory',false,@islogical);
     p.addParamValue('fileExt','omf',@(x) any(strcmp(x,availableExts)));
     p.parse(varargin{:});
     params = p.Results;
     
     if (~strcmp(obj.fName,''))
       fName = strcat(obj.fName,'.',params.fileExt);
     else
       [fName,fPath,~] = uigetfile({'*.omf'; '*.stc';'*.ohf'});
       fName = fullfile(fPath,fName);  
     end    
     
     fid = fopen(fName);
     if ((fid == -1))
       disp('File not found');
       return;
     end
     
     expr = '^#\s([\w\s:]+):\s([-.0-9e]+)';
     
     [IOmess, errnum] = ferror(fid);
     if (errnum ~= 0)
       disp(IOmess);
       return;
     end
    % read file
     propertiesList = fieldnames(obj);
     line = fgetl(fid); 
     while (isempty(strfind(line,'Begin: Data Binary')))   
       line = fgetl(fid);
       [~, ~, ~, ~, tokenStr, ~, splitStr] = regexp(line,expr);  
       % read parameters
       if (size(tokenStr,1)>0)
       if (size(tokenStr{1,1},2)>1)
          % seek properties
         toks = tokenStr{1,1};
         
         if (strcmp(toks{1,1},'Desc:  Iteration'))
           obj.iteration = str2num(toks{1,2}); 
         elseif (strcmp(toks{1,1},'Desc:  Total simulation time'))
           obj.totalSimTime = str2num(toks{1,2}); 
         else
           for i=1:size(propertiesList,1)
              if(strcmp(propertiesList{i,1},toks{1,1}))
                prop = toks{1,1};
                val = toks{1,2};
              
                %  Is it numerical value?
                [num,status] = str2num(val);
                if (status) % yes, it's numerical
                  set(obj,prop,num) 
                else % no, it's string
                    set(obj,prop,val)
                end    
              end    
           end
         end
       end          
      end    
     end
 
     % determine file format
     format='';
     if (~isempty(strfind(line,'8')))
       format = 'double';
       testVal = 123456789012345.0;
     elseif (~isempty(strfind(line,'4')))
       format = 'single';
       testVal = 1234567.0;
     else
       disp('Unknown format');
       return
     end    
     
    % read first test value
    fTestVal = fread(fid, 1, format, 0, 'ieee-le');
    if (fTestVal == testVal)
      disp('Correct format')
    else
      disp('Wrong format');
      return;
    end
    
    fclose(fid);
    
   end
   
   function [Mx,My,Mz] = loadMagnetisation(obj,varargin)
       %% open file and check errors
     availableExts ={'omf', 'ohf', 'stc'};
     
     p = inputParser;
     p.addParamValue('showMemory',false,@islogical);
     p.addParamValue('fileExt','omf',@(x) any(strcmp(x,availableExts)));
     p.parse(varargin{:});
     params = p.Results;
     
     [pathstr,name,ext] = fileparts(obj.fName);
     
     if (strcmp(name,'') && strcmp(ext,''))
         [fName,fPath,~] = uigetfile({'*.omf'; '*.stc';'*.ohf'});
         fName = fullfile(fPath,fName);  
     elseif (strcmp(ext,''))
         fName = strcat(obj.fName,'.',params.fileExt);
     else
         fName = obj.fName;
     end       
     
     fid = fopen(fName);
     if ((fid == -1))
       disp('File not found');
       return;
     end
     
     expr = '^#\s([\w\s:]+):\s([-.0-9e]+)';
     
     [IOmess, errnum] = ferror(fid);
     if (errnum ~= 0)
       disp(IOmess);
       return;
     end
    % read file
     propertiesList = fieldnames(obj);
     line = fgetl(fid); 
     while (isempty(strfind(line,'Begin: Data Binary')))   
       line = fgetl(fid);  
     end
 
     % determine file format
     format='';
     if (~isempty(strfind(line,'8')))
       format = 'double';
       testVal = 123456789012345.0;
     elseif (~isempty(strfind(line,'4')))
       format = 'single';
       testVal = 1234567.0;
     else
       disp('Unknown format');
       return
     end    
     
    % read first test value
    fTestVal = fread(fid, 1, format, 0, 'ieee-le');
    if (fTestVal == testVal)
      disp('Correct format')
    else
      disp('Wrong format');
      return;
    end   
     
    data = fread(fid, obj.xnodes*obj.ynodes*obj.znodes*obj.dim,...
         format, 0, 'ieee-le');
    
    if (isempty(strfind(fgetl(fid),'# End: Data')) || isempty(strfind(fgetl(fid),'# End: Segment')))
      disp('End of file is incorrect. Something wrong');
      fclose(fid);
      return;
    else    
      fclose(fid);
    end
    
    % Mag(x y z dim)
    maxInd = obj.znodes*obj.ynodes*obj.xnodes;
    
    Mx = data(1:3:size(data,1));
    My = data(2:3:size(data,1));
    Mz = data(3:3:size(data,1));
    
    Mx = reshape(Mx, [obj.xnodes obj.ynodes obj.znodes]);
    My = reshape(My, [obj.xnodes obj.ynodes obj.znodes]);
    Mz = reshape(Mz, [obj.xnodes obj.ynodes obj.znodes]);
    
    if (params.showMemory)
      disp('Memory used:');
      memory
    end
   end
   
   % plot 3D vector plot of magnetisation 
   function plotM3D(obj)
       MagX = squeeze(obj.M(:,:,:,1));
       MagY = squeeze(obj.M(:,:,:,2));
       MagZ = squeeze(obj.M(:,:,:,3));
       if (obj.dim==3)
         [X,Y,Z] = meshgrid(...
             obj.xbase:obj.xstepsize:(obj.xbase+obj.xstepsize*(obj.xnodes-1)),...
             obj.ybase:obj.ystepsize:(obj.ybase+obj.ystepsize*(obj.ynodes-1)),...
             obj.zbase:obj.zstepsize:(obj.zbase+obj.zstepsize*(obj.znodes-1))...
             );
         quiver3(X,Y,Z,MagX,MagY,MagZ);          
       end
   end
   
   % plot vector plot of magnetisation in XY plane
   % z is number of plane
   % should be rewritted 
   function plotMSurfXY(obj,slice,proj,varargin)
     p = inputParser;
     p.addRequired('slice',@isnumeric);
     p.addRequired('proj',@ischar);
     
     p.addParamValue('saveImg',false,@islogical);
     p.addParamValue('saveImgPath','');
     p.addParamValue('colourRange',0,@isnumeric);
     p.addParamValue('showScale',true,@islogical);
     p.addParamValue('xrange',':',@isnumeric);
     p.addParamValue('yrange',':',@isnumeric);
     
     p.parse(slice,proj,varargin{:});
     params = p.Results;
       
     handler = obj.abstractPlot('Z',params.slice,params.proj,...
         'saveImg',params.saveImg,'saveImgPath',params.saveImgPath,...
         'colourRange',params.colourRange,'showScale',params.showScale,...
         'xrange',params.xrange,'yrange',params.yrange);                  
   end
   
   % plot vector plot of magnetisation in XY plane
   % z is number of plane
   function plotMSurfXZ(obj,slice,proj,varargin)
     p = inputParser;
     p.addRequired('slice',@isnumeric);
     p.addRequired('proj',@ischar);
     
     p.addParamValue('saveImg',false,@islogical);
     p.addParamValue('saveImgPath','');
     p.addParamValue('colourRange',0,@isnumerical);
     p.addParamValue('showScale',true,@islogical);
     p.addParamValue('xrange',0,@isnumerical);
     p.addParamValue('yrange',0,@isnumerical);
     
     p.parse(slice,proj,varargin{:});
     params = p.Results;
       
     handler = obj.abstractPlot('Y',params.slice,params.proj,...
         'saveImg',params.saveImg,'saveImgPath',params.saveImgPath,...
         'colourRange',params.colourRange,'showScale',params.showScale);                  
   end
   
   % plot vector plot of magnetisation in XZ plane
   % z is number of planex
   function plotMSurfYZ(obj,slice,proj,varargin)
     p = inputParser;
     p.addRequired('slice',@isnumeric);
     p.addRequired('proj',@ischar);
     
     p.addParamValue('saveImg',false,@islogical);
     p.addParamValue('saveImgPath','');
     p.addParamValue('colourRange',0,@isnumeric);
     p.addParamValue('showScale',true,@islogical);
     p.addParamValue('rotate',false,@islogical);
     p.addParamValue('substract',false,@islogical);
     p.addParamValue('background',0,@isnumeric);
     p.addParamValue('xrange',':',@isnumeric);
     p.addParamValue('yrange',':',@isnumeric);
     
     p.parse(slice,proj,varargin{:});
     params = p.Results;
       
     handler = obj.abstractPlot('X',params.slice,params.proj,...
         'saveImg',params.saveImg,'saveImgPath',params.saveImgPath,...
         'colourRange',params.colourRange,'showScale',params.showScale,...
         'rotate',params.rotate,'substract',params.substract,...
         'background',params.background,'xrange',params.xrange,...
         'yrange',params.yrange); 
   end
   
   % base function for surface plot
   % viewAxis   -  view along: 1 - X axis, 2 - Y axis, 3 - Z axis
   % slice -  slice number
   % proj  -  projection: 1 - Mx, 2 - My, 2 - Mz
   % saveImg  -  save img (booleans)
   % saveImgPath - path to save image 
   function handler = abstractPlot(obj,viewAxis,slice,proj,varargin)
    
     % parse input parameters
     p = inputParser;
     p.addRequired('viewAxis',@ischar);
     p.addRequired('slice',@isnumeric);
     p.addRequired('proj',@ischar);
     p.addParamValue('saveImg', false,@islogical);
     p.addParamValue('saveImgPath','');
     p.addParamValue('colourRange',0,@isnumeric);
     p.addParamValue('showScale',true,@islogical);
     p.addParamValue('xrange',:);
     p.addParamValue('yrange',:);
     p.addParamValue('rotate',false,@islogical);
     p.addParamValue('substract',false,@islogical);
     p.addParamValue('background',0,@isnumeric);
     
     p.parse(viewAxis,slice,proj,varargin{:});
     params = p.Results;
    
     switch (obj.getIndex(params.viewAxis)) 
         case 1
             axis1 = 'Y ';
             axis2 = 'Z ';
         case 2
             axis1 = 'X ';
             axis2 = 'Z ';
         case 3
             axis1 = 'X ';
             axis2 = 'Y ';
         otherwise
             disp('Unknows projection');
             return
     end        
              
    data = obj.getSlice(params.viewAxis,params.slice,params.proj,...
        'range1',params.xrange,'range2',params.yrange);        
    if (params.substract)
       if (prod(size(data) == size(params.background)))
          data = data - params.background; 
       else
          disp('Size of background array mismatches size of image'); 
       end    
    end    
     
    if (params.colourRange == 0)
	   maxM = max(max(data(:)),abs(min(data(:))));
       base = fix(log10(maxM));
       t1 = ceil(maxM/(10^base));
       t2 = 10^base;
       params.colourRange = t1*t2;
    
       if (isnan(params.colourRange))
         params.colourRange = 100;
         disp('Colour range is undefined');
       end
    else
         
    end
    
    G = fspecial('gaussian',[3 3],0.9);
    %G = fspecial('average',7);
    if (params.rotate)
      data =  data.';
      tmp = axis1;
      axis1=axis2;
      axis2=tmp;
    end
        
    Ig = imfilter(data,G,'circular','same','conv');
	handler = imagesc(Ig, [-500 500]);
	axis xy;
    
    colormap(b2r(-params.colourRange,params.colourRange));
    %colormap(copper);
    
	hcb=colorbar('EastOutside');
	set(hcb,'XTick',[-params.colourRange,0,params.colourRange]);
    
    if (params.showScale)
      xlabel(strcat(axis1,'(\mum)'), 'FontSize', 10);
      ylabel(strcat(axis2,' (\mum)'), 'FontSize', 10);
      set(gca,'XTick',[1,...
                     ceil((1+eval(strcat('obj.',lower(axis1),'nodes')))/2),...
                     eval(strcat('obj.',lower(axis1),'nodes'))],...
              'XTickLabel',[eval(strcat('obj.',lower(axis1),'min'))/1e-6,...
                      0.5*(eval(strcat('obj.',lower(axis1),'min'))+eval(strcat('obj.',lower(axis1),'max')))/1e-6,...
                      eval(strcat('obj.',lower(axis1),'max'))/1e-6]);
                  
      set(gca,'YTick',[1,...
                     ceil((1+eval(strcat('obj.',lower(axis2),'nodes')))/2),...
                     eval(strcat('obj.',lower(axis2),'nodes'))],...
              'YTickLabel',[eval(strcat('obj.',lower(axis2),'min'))/1e-6,...
                      0.5*(eval(strcat('obj.',lower(axis2),'min'))+eval(strcat('obj.',lower(axis2),'max')))/1e-6,...
                      eval(strcat('obj.',lower(axis2),'max'))/1e-6]);
    else
      axis([0,size(data,2),0,size(data,1)]);
      xlabel(strcat(axis1,'(cell #)'), 'FontSize', 10);
      ylabel(strcat(axis2,' (cell #)'), 'FontSize', 10);
    end

     % set X limit 
 %   if (~strcmp(params.xrange,':'))
 %     if (params.rotate) 
 %       ylim(params.xrange);
 %     else
 %       xlim(params.xrange);  
 %     end    
 %   end    
    
     % set Y limit 
 %   if (~strcmp(params.yrange,':'))
 %     if (params.rotate) 
 %       xlim(params.yrange);
 %     else
 %       ylim(params.yrange);  
 %     end
 %   end    
    
                  
	set(hcb,'FontSize', 15);
    title(strcat('view along ',viewAxis,' axis, M',params.proj,' projection',...
                  ', simulation time = ',num2str(obj.totalSimTime,'%10.2e'),' s'));
    if (params.saveImg)
      imgName = strcat(params.saveImgPath,'\',...
                       'Image_Along',viewAxis,...
                       '_Slice',num2str(slice),...
                       '_M',lower(params.proj),...
                       '_iter',num2str(obj.iteration),...
                       '.png');
	  saveas(handler, imgName);
    end   
    clear data;
   end
   
     % scan folder, load all *.omf files, save objects
   % path - path to the folder
   % saveObj - save an objects?
   % savePath - path to save objects 
   function scanFolder(obj,path,varargin) 
     % parse input parameters
     p = inputParser;
     p.addRequired('path',@ischar);
     p.addParamValue('deleteFiles', false,@islogical);
     p.addParamValue('showMemory',false,@islogical);
     p.addParamValue('makeFFT',false,@islogical);
     p.addParamValue('fileBase','',@isstr);
     p.addParamValue('savePath','',@isstr);
     p.addParamValue('value','M',@(x) any(strcmp(x,{'M','H'})));
     
     p.parse(path,varargin{:});
     params = p.Results;
     
     if strcmp(params.savePath,'')
         savePath = path;
     else
         savePath = params.savePath; 
     end
     
     % select extension for magnetization (*.omf) or field (*.ohf) files
     if (strcmp(params.value,'M'))
         fileExt = 'omf'; 
     elseif (strcmp(params.value,'H'))
         fileExt = 'ohf';
     else
         disp('Unknown physical value');
         return
     end    
                
     fList = obj.getFilesList(path,params.fileBase,fileExt);     
     file = fList(1);
     [~, fName, ~] = fileparts(file.name);
     obj.fName = strcat(path,'\',fName);
     obj.loadParams('showMemory',params.showMemory,'fileExt',fileExt);
     save(strcat(savePath,'\params.mat'), 'obj');
          
     % evaluate required memory and compare with available space
      % memory required for one time frame 
     oneTimeFrameMemory = 3*8*obj.xnodes*obj.ynodes*obj.znodes;
 
     mem = memory;
     availableSpace = mem.MaxPossibleArrayBytes

     heapSize = min(...
         ceil(0.5*availableSpace/oneTimeFrameMemory),...
         size(fList,1))
          
     % create files and variables   
     XFile = matfile(fullfile(savePath,strcat(params.value,'x.mat')),'Writable',true);
     YFile = matfile(fullfile(savePath,strcat(params.value,'y.mat')),'Writable',true);
     ZFile = matfile(fullfile(savePath,strcat(params.value,'z.mat')),'Writable',true);
          
     % create heap array 
     XHeap = zeros(heapSize,obj.xnodes,obj.ynodes,obj.znodes);
     YHeap = zeros(heapSize,obj.xnodes,obj.ynodes,obj.znodes);
     ZHeap = zeros(heapSize,obj.xnodes,obj.ynodes,obj.znodes);
     
     indHeap = 1;
     fileAmount = size(fList,1); 
     for i=1:fileAmount
         disp (i)
         file = fList(i);
         [~, fName, ~] = fileparts(file.name);
         obj.fName = strcat(path,'\',fName);
         [XHeap(indHeap,:,:,:), YHeap(indHeap,:,:,:), ZHeap(indHeap,:,:,:)] = ...
             obj.loadMagnetisation('fileExt',fileExt);
               
         % write heaps to files
         if (indHeap >= heapSize || i == fileAmount)
             disp('Write to file');
             XFile.Mx((i-indHeap+1):i,1:obj.xnodes,1:obj.ynodes,1:obj.znodes) = XHeap(1:indHeap,1:end,1:end,1:end);
             YFile.My((i-indHeap+1):i,1:obj.xnodes,1:obj.ynodes,1:obj.znodes) = YHeap(1:indHeap,1:end,1:end,1:end); 
             ZFile.Mz((i-indHeap+1):i,1:obj.xnodes,1:obj.ynodes,1:obj.znodes) = ZHeap(1:indHeap,1:end,1:end,1:end);
             indHeap = 1;
         else
             indHeap = indHeap +1;
         end    
         
         if (params.deleteFiles)
             delete(strcat(obj.fName,'.',fileExt));
         end                       
     end
   end
            
   % return slice of space
   % sliceNumber
   % proj 
   % rangeX - array
   % rangeY - array
   % rangeZ - array
   function res = getSlice(obj,viewAxis,sliceNumber,proj,varargin)
     p = inputParser;
     p.addRequired('viewAxis', @(x)any(strcmp(x,{'X','Y','Z',':'})));
     p.addRequired('proj', @(x)any(strcmp(x,{'X','Y','Z',':'})));
     p.addRequired('sliceNumber',@isnumeric);
     p.addParamValue('range1',':',...
          @(x)(strcmp(x,':') ||...
          (isnumeric(x) && (size(x,1)==1) && (size(x,2)==2))...
        ));
     p.addParamValue('range2',':',...
          @(x)(strcmp(x,':') || ...
          (isnumeric(x) && (size(x,1)==1) && (size(x,2)==2))...
        ));
    
     p.parse(viewAxis,proj,sliceNumber,varargin{:});
     params = p.Results;
     params.proj = obj.getIndex(params.proj);
     
    if (isnumeric(params.range1) && (size(params.range1,1)==1) && (size(params.range1,2)==2))
       range1str = strcat(num2str(params.range1(1)),':',num2str(params.range1(2)));
    else
       range1str = ':'; 
    end    

    if (isnumeric(params.range2) && (size(params.range2,1)==1) && (size(params.range2,2)==2))
       range2str = strcat(num2str(params.range2(1)),':',num2str(params.range2(2)));
    else
        range2str = ':';
    end
    
    if (strcmp(params.viewAxis,'X'))
      ind = strcat('params.sliceNumber,',range1str,',',range2str,',params.proj');
    elseif (strcmp(params.viewAxis,'Y'))
      ind = strcat(range1str,',params.sliceNumber,',range2str,',params.proj');  
    elseif (strcmp(params.viewAxis,'Z') )
      ind = strcat(range1str,',',range2str,',params.sliceNumber,params.proj');
    else
      disp('Dimension is incorrect');
      return;
    end
    
    str = strcat('obj.Mraw(',ind,')');
    tmp = eval(str);
    if (ndims(tmp) == 2)
      res = squeeze(tmp).';
    elseif (ndims(tmp) == 3)
      res = squeeze(tmp).';
    elseif (ndims(tmp) == 4)
      res = permute(squeeze(tmp),[2 1 3 4]);  
    else
       disp('Unexpected dimension of array');
       res = false;
    end       
   end
   
   function res = getIndex(obj,symb)
   if (strcmp(symb,'X'))
      res = 1;
   elseif (strcmp(symb,'Y'))
      res = 2;
   elseif (strcmp(symb,'Z'))
      res = 3;
   elseif (strcmp(symb,':'))
      res = ':'; 
   else
      disp('Unknown index');
      return;
   end    
   end
 
   
   function res = getVolume(obj,xrange,yrange,zrange,proj)
     res = obj.Mraw(xrange,yrange,zrange,obj.getIndex(proj));  
   end 
   
   % plot dispersion curve along X axis
   function plotDispersionX(obj,varargin)
       p = inputParser;
       p.addParamValue('xRange',0,@isnumeric);
       p.addParamValue('yRange',0,@isnumeric);
       p.addParamValue('zRange',0,@isnumeric);
       p.addParamValue('scale',''); % <-------- TODO
       p.addParamValue('freqLimit',[0 50], @isnumeric);
       p.addParamValue('waveLimit',[0 700],@isnumeric);
       p.addParamValue('proj','z',@(x)any(strcmp(x,obj.availableProjs)));
       p.addParamValue('saveAs','',@isstr);
       p.addParamValue('saveMatAs','',@isstr);
       p.addParamValue('interpolate',false,@islogical);
       
       p.parse(varargin{:});
       params = p.Results;
       
       params.proj = lower(params.proj);
       
       % read file of parameters
       simParams = obj.getSimParams;
       
       MFile = matfile(fullfile(obj.folder,strcat('M',params.proj,'FFT.mat')));
       mSize = size(MFile,strcat('Y',params.proj));
       
       % process input range parameters
       if (params.xRange == 0)
           params.xRange = [1 mSize(2)];
       end    
       
       if (params.yRange == 0)
           params.yRange = [1 mSize(3)];
       end    
       
       if (params.zRange == 0)
           params.zRange = [1 mSize(4)];
       end
       
       freqScale = obj.getWaveScale(simParams.dt,mSize(1))/1e9; 
       [~,freqScaleInd(1)] = min(abs(freqScale-params.freqLimit(1)));
       [~,freqScaleInd(2)] = min(abs(freqScale-params.freqLimit(2)));
       freqScale = freqScale(freqScaleInd(1):freqScaleInd(2));
       
       
       if (strcmp(params.proj,'z'))
           FFTres = MFile.Yz(freqScaleInd(1):freqScaleInd(2),params.xRange(1):params.xRange(2),...
               params.yRange(1):params.yRange(2),...
               params.zRange(1):params.zRange(2));
       elseif (strcmp(params.proj,'x'))
           FFTres = MFile.Yx(freqScaleInd(1):freqScaleInd(2),params.xRange(1):params.xRange(2),...
               params.yRange(1):params.yRange(2),...
               params.zRange(1):params.zRange(2));   
       elseif (strcmp(params.proj,'y'))
           FFTres = MFile.Yy(freqScaleInd(1):freqScaleInd(2),params.xRange(1):params.xRange(2),...
               params.yRange(1):params.yRange(2),...
               params.zRange(1):params.zRange(2));
       else
           disp('Unknown projection');
           return
       end    

       waveVectorScale = 2*pi*obj.getWaveScale(simParams.xstepsize/1e-6,mSize(2));
       [~,waveVectorInd(1)] = min(abs(waveVectorScale-params.waveLimit(1)));
       [~,waveVectorInd(2)] = min(abs(waveVectorScale-params.waveLimit(2)));
       waveVectorScale = waveVectorScale(waveVectorInd(1):waveVectorInd(2));       
              
       
       Y(:,:,:,:) = fft(FFTres,[],2);
       clearvars FFTres;
       Amp = mean(mean(abs(Y),4),3);
       Amp = fftshift(abs(Amp),2);
       clearvars Y;
              
       Amp = Amp(:,waveVectorInd(1):waveVectorInd(2));
       ref = min(Amp(find(Amp(:))));
       dB = log10(Amp/ref);
       % plot image
       
       % interpolate
       if (params.interpolate)
           waveNew = linspace(min(waveVectorScale),max(waveVectorScale),50*size(waveVectorScale,2));
           freqNew = linspace(min(freqScale),max(freqScale),2*size(freqScale,2));

           [waveGrid,freqGrid]=ndgrid(waveVectorScale,freqScale);
           [waveGridNew,freqGridNew]=ndgrid(waveNew,freqNew);

           F = griddedInterpolant(waveGrid,freqGrid,dB.','spline');
           dB = F(waveGridNew,freqGridNew).';
           
           waveVectorScale = waveNew;
           freqScale = freqNew;
       end
       
       % plot image
       imagesc(waveVectorScale,freqScale,dB);
            
       colormap(jet); axis xy;
       xlabel('Wave vector k_x, rad\mum^-^1');   ylabel('Frequency, GHz');
       xlim([min(waveVectorScale) max(waveVectorScale)]);
       t = colorbar('peer',gca);
       set(get(t,'ylabel'),'String', 'FFT intensity, dB');
       
       
       
       % save img
       if (~strcmp(params.saveAs,''))
           savefig(strcat(params.saveAs,'.fig'));
           print(gcf,'-dpng',strcat(params.saveAs,'.png'));
       end
       
       % save data to mat file
       if (~strcmp(params.saveMatAs,''))
           fName = strcat(params.saveMatAs,'.mat');
           save(fName,'waveNew','freqNew','dBNew'); 
       end
       
       
   end 
   
   % plot spatial map of FFT distribution for a given frequency
   function plotFFTSliceZ(obj,varargin)
       
       p = inputParser;
       p.addParamValue('freq',0,@isnumeric);
       p.addParamValue('zSlice',5,@isnumeric);
       p.addParamValue('xRange',0,@isnumeric);
       p.addParamValue('yRange',0,@isnumeric);
       p.addParamValue('scale','log', @(x) any(strcmp(x,{'norm','log'})));
       p.addParamValue('saveAs','',@isstr);
       
       p.parse(varargin{:});
       params = p.Results;
              
       % load parameters
       simParams = obj.getSimParams;
       
       % assign file of FFT of Mz
       MzFFTFile = matfile(fullfile(obj.folder,'MzFFT.mat'));
       MzFFTSize = size(MzFFTFile,'Yz');
       
       % process range parameters
       if (params.xRange  == 0)
           params.xRange(1) = 1;
           params.xRange(2) = MzFFTSize(2);
       end    
       
       if (params.yRange  == 0)
           params.yRange(1) = 1;
           params.yRange(2) = MzFFTSize(3);
       end    
              
       % calculate scales
       xScale = linspace(simParams.xmin,simParams.xmax,simParams.xnodes)/1e-6;
       xScale = xScale(params.xRange(1):params.xRange(2));  

       yScale=linspace(simParams.ymin,simParams.ymax,simParams.ynodes)/1e-6;
       yScale = yScale(params.yRange(1):params.yRange(2));  
       
       freqScale = getWaveScale(simParams.dt,MzFFTSize(1))/1e9;
       shiftFreqScale = ifftshift(freqScale);
       [~,freqInd] = min(abs(shiftFreqScale-params.freq));
       
       fftSlice = MzFFTFile.Yz(freqInd,params.xRange(1):params.xRange(2),...
           params.yRange(1):params.yRange(2),params.zSlice);
       
       if (size(fftSlice,4)>1)
           fftSlice = mean(fftSlice,4);
       end
       
       fftSlice = squeeze(fftSlice);
       Amp = abs(fftSlice);
       Phase = angle(fftSlice);

       % plot amplitude map
       figure(1);
       subplot(2,1,1);
           if strcmp(params.scale,'log')
               ref = min(Amp(find(Amp(:))));
               if (isempty(ref))
                   ref = 1;
               end    
               imagesc(xScale,yScale,log10(Amp.'/ref));
               hcb =colorbar('EastOutside');
               cbunits('dB');
           else
               imagesc(xScale,yScale,log10(Amp.'));
               hcb = colorbar('EastOutside');
               cbunits('a.u.');
           end    
           title('Amplitude of FFT');
           axis xy;
           ylabel('Y, \mum'); xlabel('X, \mum');
           colormap(jet);
           freezeColors;
           cbfreeze;
           

       % plot phase map   
       subplot(2,1,2);

          imagesc(xScale,yScale,Phase.',[-pi pi]);
          title('Phase of FFT');
          axis xy;
          colorbar('EastOutside');
          cblabel('rad.');
          ylabel('Y, \mum'); xlabel('X, \mum');
          colormap(hsv);  
          
       % save figure
       if (~strcmp(params.saveAs,''))
           savefig(strcat(params.saveAs,'.fig'));
           print(gcf,'-dpng',strcat(params.saveAs,'.png'));
       end
       
       
   end 
   
    % plot spatial map of FFT distribution for a given frequency
   function plotFFTSliceY(obj,varargin)
       p = inputParser;
   
       p.addParamValue('freq',0,@isnumeric);
       p.addParamValue('ySlice',3,@isnumeric);
       p.addParamValue('zRange',:,@isnumeric);
       p.addParamValue('scale','log', @(x) any(strcmp(x,{'norm','log'})));
       p.addParamValue('saveAs','',@isstr);
       
       p.parse(varargin{:});
       params = p.Results;
       
       % load parameters
       simParams = obj.getSimParams;

       xScale=linspace(simParams.xmin,simParams.xmax,simParams.xnodes)/1e-6;
       yScale=linspace(simParams.ymin,simParams.ymax,simParams.ynodes)/1e-6;
       
       zScale= linspace(simParams.zmin,simParams.zmax,simParams.znodes)/1e-6;
       zScale = zScale(params.zRange(1):params.zRange(2));
       
       % assign file of FFT of Mz
       FFTFile = matfile(fullfile(obj.folder,'MyFFT.mat'));
       
       FFTSize = size(FFTFile,'Yy');
       % create freq Scale
       freqScale = obj.getWaveScale(obj.dt,FFTSize(1))/1e9;
       shiftFreqScale = ifftshift(freqScale);
       [~,freqInd] = min(abs(shiftFreqScale-params.freq));
       
       fftSlice = squeeze(FFTFile.Yy(freqInd,:,params.ySlice(1),params.zRange(1):params.zRange(2)));
       
       
       if (size(fftSlice,3)>1)
           fftSlice = squeeze(mean(fftSlice,3));
       end   
       
       
       Amp = abs(fftSlice);
       Phase = angle(fftSlice);
       
       % plot amplitude map
       figure(1);
       subplot(2,1,1);
           if strcmp(params.scale,'log')
               ref = min(Amp(find(Amp(:))));
               if (isempty(ref))
                   ref = 1;
               end    
               imagesc(xScale,zScale,log10(Amp.'/ref));
               hcb =colorbar('EastOutside');
               cbunits('dB');
           else
               imagesc(xScale,zScale,log10(Amp.'));
               hcb = colorbar('EastOutside');
               cbunits('a.u.');
           end    
           title('Amplitude of FFT');
           axis xy;
           ylabel('Z, \mum'); xlabel('X, \mum');
           colormap(jet);
           freezeColors;
           cbfreeze;
           

       % plot phase map   
       subplot(2,1,2);

          imagesc(xScale,zScale,Phase.',[-pi pi]);
          title('Phase of FFT');
          axis xy;
          colorbar('EastOutside');
          cblabel('rad.');
          ylabel('Z, \mum'); xlabel('X, \mum');
          colormap(hsv);  
          
       % save figure
       if (~strcmp(params.saveAs,''))
           savefig(strcat(params.saveAs,'.fig'));
           print(gcf,'-dpng',strcat(params.saveAs,'.png'));
       end    
       
       
   end 
   
   
   function plotFFTsliceCommon(obj,freqScale,waveScale,xlabel,ylabel,data,varargin)
       p = inputParser;
       p.addParamValue('freq',0,@isnumeric);
       p.addParamValue('ySlice',3,@isnumeric);
       p.addParamValue('zRange',:,@isnumeric);
       p.addParamValue('scale','log', @(x) any(strcmp(x,{'norm','log'})));
       p.addParamValue('saveAs','',@isstr);
       p.parse(varargin{:});
       params = p.Results;
       
       
   end    
   
   % plot dependence of FFT intensity on frequency
   function plotFFTIntensity(obj,varargin)
       
       p = inputParser;
       p.addParamValue('label','',@isstr);
       p.addParamValue('scale','norm', @(x) any(strcmp(x, {'norm','log'})));
       p.parse(varargin{:});
       params = p.Results;
       
       FFTFile = matfile('MzFFT.mat'); 
       FFT = FFTFile.Yz(:,:,20:61,1:11);
       Y = mean(mean(mean(FFT,4),3),2);
       Amp = abs(fftshift(Y));
       
       freqScale = obj.getWaveScale(obj.dt,size(Amp,1))/1e9;
       if (strcmp(params.scale,'norm'))
           plot(freqScale,Amp);
       else
           semilogy(freqScale,Amp);
       end
       xlim([0 20]); xlabel('Frequency, GHz');
       ylabel('FFT intensity, a.u.');
       imgName = generateFileName('.','FFTintens','png');
       title(params.label);
       print(gcf,'-dpng',imgName);
   end
   
   % make movie
   function makeMovie(obj,varargin)
       
       p = inputParser;
       p.addParamValue('xRange',:,@isnumeric);
       p.addParamValue('zSlice',10,@isnumeric);
       p.addParamValue('timeFrames',100,@isnumeric);
       p.addParamValue('yRange',22:60,@isnumeric);
       p.addParamValue('colourRange',6000);
       p.addParamValue('fName','',@isstr);
       
       p.parse(varargin{:});
       params = p.Results;
       
       G = fspecial('gaussian',[3 3],0.9);
       
       MzFile = matfile('Mz.mat');
       Mz = squeeze(MzFile.Mz(end-params.timeFrames : end,:,params.yRange,params.zSlice));
       
       if strcmp(params.fName,'')
           videoFile = generateFileName(pwd,'movie','mp4');
       else
           videoFile = fullfile(pwd,strcat(params.fName,'.avi'));
       end    
       writerObj = VideoWriter(videoFile);
       writerObj.FrameRate = 10;
       open(writerObj);
       
       % load parameters
       % calculate axis
       simParams = obj.getSimParams;
              
       xScale = linspace(simParams.xmin,simParams.xmax,simParams.xnodes)/1e-6;
       yScale = linspace(simParams.ymin,simParams.ymax,simParams.ynodes)/1e-6;
       yScale = yScale(params.yRange);
       
       fig=figure(1);
       for timeFrame = 1:size(Mz,1)
           Ig = imfilter(squeeze(Mz(timeFrame,:,:)).',G,'circular','same','conv');
           handler = imagesc(xScale,yScale,Ig);
           axis xy;
           xlabel('X, \mum'); ylabel('Y, \mum'); 
           writeVideo(writerObj,getframe(fig));
 
           colormap(b2r(-params.colourRange,params.colourRange));
           %colormap(copper);
     
           hcb=colorbar('EastOutside');
           set(hcb,'XTick',[-params.colourRange,0,params.colourRange]);
       end   
       
       close(writerObj);
   end    
   
   % make GIF animation
   function makeGIF(obj,varargin)
       p = inputParser;
       p.addParamValue('xRange',:,@isnumeric);
       p.addParamValue('zSlice',10,@isnumeric);
       p.addParamValue('timeFrames',48,@isnumeric);
       p.addParamValue('yRange',26:56,@isnumeric);
       p.addParamValue('colourRange',6000);
       p.addParamValue('fName','',@isstr);
       
       p.parse(varargin{:});
       params = p.Results;
       
       G = fspecial('gaussian',[3 3],0.9);
       
       MzFile = matfile('Mz.mat');
       Mz = squeeze(MzFile.Mz(end-params.timeFrames : end,:,params.yRange,params.zSlice));
       
       % normalization
       cLims = [min(Mz(:)) max(Mz(:))];
       
       if strcmp(params.fName,'')
           gifFile = generateFileName(pwd,'movie','gif');
       else
           gif = fullfile(pwd,strcat(params.fName,'.gif'));
       end    
       
       % load parameters
       simParams = obj.getSimParams;

       % calculate axis
       xScale = linspace(simParams.xmin,simParams.xmax,simParams.xnodes)/1e-6;
       yScale = linspace(simParams.ymin,simParams.ymax,simParams.ynodes)/1e-6;
       yScale = yScale(params.yRange);
       
       fig=figure(1);
       set(fig, 'Position', [100, 500, 1000, 250]);
       
       for timeFrame = 1:size(Mz,1)
           Ig = imfilter(squeeze(Mz(timeFrame,:,:)).',G,'circular','same','conv');
           handler = imagesc(xScale,yScale,Ig,cLims);
           axis xy; xlabel('X, \mum'); ylabel('Y, \mum');
           %colormap(b2r(-params.colourRange,params.colourRange));
           colormap(copper);
           hcb=colorbar('EastOutside');
           set(hcb,'XTick',[-params.colourRange,0,params.colourRange]);
           drawnow
           frame = getframe(1);
           im = frame2im(frame);
           [imind,cm] = rgb2ind(im,256);
           set(gca,'position',[0 0 1 1],'units','normalized')
           if (timeFrame == 1)
              imwrite(imind,cm,gifFile,'gif', 'Loopcount',inf);
           else
              imwrite(imind,cm,gifFile,'gif','WriteMode','append');
           end
              imwrite(imind,cm,strcat('Img-',num2str(timeFrame),'.png'),'png',...
                  'XResolution',300,'YResolution',300);
           
           % print(gcf,'-dpng',strcat('Img-',num2str(timeFrame),'.png'),'-r600');
           
       end   
     
   end    
   
   % perform FFT transformation from time to frequency domain
   % save results to files
   % PARAMS
   %    folder - where take the files (path)
   %    background - substract background (boolean) 
   function makeFFT(obj,folder,varargin)
       
       p = inputParser;
       p.addRequired('folder',@isdir);
       p.addParamValue('background',true,@islogical);
       p.parse(folder,varargin{:});
       params = p.Results;
       
       % substract backgroung
       if (params.background)
          [Mx,My,Mz] = obj.getStatic(params.folder);
       end    

       % process Mx projection
       disp('Mx');
       MFile = matfile(fullfile(folder,'Mx.mat'));
       FFTFile = matfile(fullfile(folder,'MxFFT.mat'),'Writable',true);
       arrSize = size(MFile,'Mx');
       arrSize(1) = 1024;
       centerInd = floor(0.5*arrSize(1));
       
       for xInd = 1:arrSize(2)
	       disp(num2str(xInd));
           tmp = MFile.Mx(1:arrSize(1),xInd,1:arrSize(3),1:arrSize(4));
           if (params.background)
               disp('Substract background');
               for timeInd = 1:arrSize(1)
                   tmp(timeInd,:,:,1) = tmp(timeInd,:,:,1) - Mx(zInd,:,:); 
               end
           end

           disp('FFT');
           tmp = fft(tmp,[],1);
           disp('Write');

           FFTFile.Yx(1:centerInd,xInd,1:arrSize(3),1:arrSize(4)) = tmp(centerInd+1:end,:,:,:);
           tmp = tmp(1:centerInd,:,:,:);
           FFTFile.Yx(centerInd+1:arrSize(1),xInd,1:arrSize(3),1:arrSize(4)) = tmp; 
       end
       
       % process My projection
       disp('My');
       MFile = matfile(fullfile(folder,'My.mat'));
       FFTFile = matfile(fullfile(folder,'MyFFT.mat'),'Writable',true);
       
       for xInd = 1:arrSize(2)
	       disp(num2str(xInd));
           tmp = MFile.My(1:arrSize(1),xInd,1:arrSize(3),1:arrSize(4));
           if (params.background)
               disp('Substract background');
               for timeInd = 1:arrSize(1)
                   tmp(timeInd,:,:,1) = tmp(timeInd,:,:,1) - My(zInd,:,:); 
               end
           end

           disp('FFT');
           tmp = fft(tmp,[],1);
           disp('Write');

           FFTFile.Yy(1:centerInd,xInd,1:arrSize(3),1:arrSize(4)) = tmp(centerInd+1:end,:,:,:);
           tmp = tmp(1:centerInd,:,:,:);
           FFTFile.Yy(centerInd+1:arrSize(1),xInd,1:arrSize(3),1:arrSize(4)) = tmp; 
       end
       
       % process Mz projection
       disp('Mz');
       MFile = matfile(fullfile(folder,'Mz.mat'));
       FFTFile = matfile(fullfile(folder,'MzFFT.mat'),'Writable',true);
       
       for xInd = 1:arrSize(2)
	       disp(num2str(xInd));
           tmp = MFile.Mz(1:arrSize(1),xInd,1:arrSize(3),1:arrSize(4));
           if (params.background)
               disp('Substract background');
               for timeInd = 1:arrSize(1)
                   tmp(timeInd,:,:,1) = tmp(timeInd,:,:,1) - Mz(zInd,:,:); 
               end
           end

           disp('FFT');
           tmp = fft(tmp,[],1);
           disp('Write');

           FFTFile.Yz(1:centerInd,xInd,1:arrSize(3),1:arrSize(4)) = tmp(centerInd+1:end,:,:,:);
           tmp = tmp(1:centerInd,:,:,:);
           FFTFile.Yz(centerInd+1:arrSize(1),xInd,1:arrSize(3),1:arrSize(4)) = tmp; 
       end
       
       
       
   end
   
   function plotYFreqMap(obj,varargin)
       
       p = inputParser;
       p.addParamValue('freqRange',[0.1 20],@isnumeric);
       p.parse(varargin{:});
       params = p.Results;
       
       simParams = obj.getSimParams;
              
       YzFile = matfile('MzFFT.mat');
       arrSize = size(YzFile,'Yz');
       
       freqScale = obj.getWaveScale(obj.dt,arrSize(1))/1e9; 
       [~,freqScaleInd(1)] = min(abs(freqScale-params.freqRange(1)));
       [~,freqScaleInd(2)] = min(abs(freqScale-params.freqRange(2)));
       freqScale = freqScale(freqScaleInd(1):freqScaleInd(2));
       
       yScale = linspace(simParams.ymin,simParams.ymax,simParams.ynodes)/1e-6;
       
       
       Y = YzFile.Yz(freqScaleInd(1):freqScaleInd(2),191:210,:,18:19);
       Y = squeeze(mean(mean(Y,4),2));
       Amp = abs(Y);
       
       imagesc(freqScale,yScale,log10(Amp/min(Amp(:))).');
       axis xy
       xlabel('Frequency, GHz');   ylabel('y, \mum');
       
       t = colorbar('peer',gca);
       set(get(t,'ylabel'),'String', 'FFT intensity, dB');
       
   end    
   
   %% plot dependence of intencity on wavelength for given frequency
   % incomplete method
   function plotFreqSlice(obj,freq,varargin)
       p = imputParser;
       p.addRequired('freq',@isnumeric);
       p.addParamValue('xRange',[1 200],@isnumeric);
       p.addParamValue('yRange',[20 61],@isnumeric);
       p.addParamValue('zRange',[1 10],@isnumeric);
       p.parse(freq,varargin{:});
       params = p.Results;
       
       tmp = load(fullfile(pwd,'params.mat'));
       simParams = tmp.obj;
       
   end    
   
   
   %% plot amplitude and phase of modes in (y,z) coordinates
   %for given frequency and Kx wave number
   function plotFreqXWaveSlice(obj,freq,kx,varargin)
       
       p = inputParser;
       p.addRequired('freq',@isnumeric);
       p.addRequired('kx',@isnumeric);
       p.addParamValue('yRange',[81 120],@isnumeric);
       p.addParamValue('zRange',:,@isnumeric);
       p.addParamValue('saveAs','',@isstr);
       p.addParamValue('proj','z',@(x)any(strcmp(x,obj.availableProjs)));
       
       p.parse(freq,kx,varargin{:});
       params = p.Results;
       params.proj = lower(params.proj);
       
       % load file of parameters
       simParams = obj.getSimParams;
       
       if (strcmp(params.proj,'z'))
           FFTfile = matfile(fullfile(pwd,'MzFFT.mat'));
           arrSize = size(FFTfile,'Yz');
       elseif (strcmp(params.proj,'y'))
           FFTfile = matfile(fullfile(pwd,'MyFFT.mat'));
           arrSize = size(FFTfile,'Yy');
       elseif (strcmp(params.proj,'x'))
           FFTfile = matfile(fullfile(pwd,'MxFFT.mat'));
           arrSize = size(FFTfile,'Yx');
       else
           disp('Unknown projection');
           return
       end
       
       freqScale = obj.getWaveScale(simParams.dt,arrSize(1))/1e9;
       [~,freqInd] = min(abs(freqScale - params.freq));
       
       kxScale = 2*pi*obj.getWaveScale(simParams.xstepsize*1e6,arrSize(2)); 
       [~,kxInd] = min(abs(kxScale - params.kx));
       
       if (strcmp(params.proj,'z'))
           Yt = squeeze(FFTfile.Yz(freqInd,:,params.yRange(1):params.yRange(2),:));
       elseif (strcmp(params.proj,'y'))
           Yt = squeeze(FFTfile.Yy(freqInd,:,params.yRange(1):params.yRange(2),:));
       elseif (strcmp(params.proj,'x'))
           Yt = squeeze(FFTfile.Yx(freqInd,:,params.yRange(1):params.yRange(2),:));
       else
           disp('Unknown projection');
           return
       end
       
       Ytx = fft(Yt,[],1);
       Ytx = fftshift(Ytx,1);
       
       YtxSlice = squeeze(Ytx(kxInd,:,:));
       
       Amp = abs(YtxSlice);
       Phase = angle(YtxSlice);
       figure();
       subplot(211);
           imagesc(Amp.',[0 max(Amp(:))]);
           axis xy
           xlabel('Y'); ylabel('Z');
           obj.setDbColorbar();
           colormap(flipud(gray));
           freezeColors;
           cbfreeze;
           title(['\nu = ',num2str(params.freq),' GHz, k_x = ',num2str(params.kx),...
               '\mum, M_',params.proj,' projection'],'FontSize',14,'FontName','Times');
       
       subplot(212);
           imagesc(Phase.',[-pi pi]);
           axis xy
           xlabel('Y'); ylabel('Z');
           colorbar('EastOutside');
           cblabel('rad.');
           colormap(hsv);
      
       
           
       
              % save img
       if (~strcmp(params.saveAs,''))
           fName = strcat(params.saveAs,'_f',num2str(params.freq),'GHz_k',...
               num2str(params.kx),'mum_M',params.proj);
           savefig(strcat(fName,'.fig'));
           print(gcf,'-dpng',strcat(fName,'.png'));
       end    
       
   end 
   
   %% calculate out-of-plane and in-plane components of dynamical magnetization
   % params :
   %     normalAxis - direction of out-of-plane components
   %
   function calcDynamicComponents(obj,varargin)
       
       p = inputParser;
       p.addParamValue('normalAxis','z',@(a) any(strcmp(x,obj.availableProjs)));
       p.addParamValue('xRange',0,@isnumeric);
       p.addParamValue('yRange',0,@isnumeric);
       p.addParamValue('zRange',0,@isnumeric);
       p.parse(varargin{:});
       params = p.Results;

       params.normalAxis = lower(params.normalAxis);
       
       % load file of parameters
       obj = obj.getSimParams;
       
       % process spatial ranges
       if (params.xRange==0)
           params.xRange = 1:obj.xnodes;
       end    
       if (params.yRange==0)
           params.yRange = 1:obj.ynodes;
       end
       if (params.zRange==0)
           params.zRange = 1:obj.znodes;
       end
       
       % load file of static configuration
       [MxStatic,MyStatic,MzStatic] = obj.getStatic(obj.folder);
       
       InpX = zeros(obj.xnodes,obj.ynodes,obj.znodes);
       InpY = zeros(obj.xnodes,obj.ynodes,obj.znodes);
       
       InpX = sqrt((MyStatic(params.xRange,params.yRange,params.zRange).^2)./...
                 (MxStatic(params.xRange,params.yRange,params.zRange).^2+...
                  MyStatic(params.xRange,params.yRange,params.zRange).^2));
       InpY = sqrt((MxStatic(params.xRange,params.yRange,params.zRange).^2)./...
             (MxStatic(params.xRange,params.yRange,params.zRange).^2+...
             MyStatic(params.xRange,params.yRange,params.zRange).^2));
       % calculate coordinates of normal plane for every points

       % load magnetization
       MxFile = matfile(obj.MxName);
       MyFile = matfile(obj.MyName);
       MzFile = matfile(obj.MzName);
       timeFrames = size(MxFile,'Mx',1);
       
       % initialize array of in-plane magnetization 
       Minp = zeros(timeFrames,obj.xnodes,obj.ynodes,obj.znodes);
                   
                   
       for timeStep = 1:timeFrames
           disp(timeStep);
           Mx = squeeze(MxFile.Mx(timeStep,params.xRange,...
                           params.yRange,params.zRange));
           My = squeeze(MyFile.My(timeStep,params.xRange,...
                           params.yRange,params.zRange));
           Minp(timeStep,params.xRange,params.yRange,params.zRange) = ...
                 Mx.*InpX+My.*InpY;
       end    
       
       save('Minp.mat','Minp');
       
       % go throught all timeFrames
       % calculate dynamic components
       % save dynamic components
       % select time range, not spatial
   end    
   % END OF PUBLIC METHODS
 end
 
 %% PROTECTED METHODS  
 methods (Access = protected)
   
   
   %% return 1D array of frequencies or wavelengths FFT transformation
   %  from "-0.5/delta" to "-0.5/delta" with "Frames" steps 
   % "delta" is time or spatial step, determines lowest and highest values
   % "Frames" is amount of counts
   % should be protected
   function res = getWaveScale(obj,delta,Frames)
       if (mod(Frames,2) == 1)
           res = linspace(-0.5/delta,0.5/delta,Frames);
       else
           dx = 1/(delta*Frames);
           res = linspace(-0.5/delta-dx,0.5/delta,Frames);
       end    
   end    
   
   %% set colorbar for imagesc
   % should be protected
   function setDbColorbar(obj)
       t = colorbar('peer',gca);
       set(get(t,'ylabel'),'String', 'FFT intensity, dB');
   end
   
   %% read file of parameters
   % return parameters of simulation
   % should be protected
   function res = getSimParams(obj)
       tmp = load(fullfile(obj.folder,obj.paramsFile));
       obj = tmp.obj;
       res = tmp.obj;
   end
   
   %% read file of static magnetization
   % return three arrays [Mx,My,Mz]
   function [Mx,My,Mz] = getStatic(obj,folder)
       if (exist(fullfile(folder,obj.staticFile),'file') ~= 2)
           disp('No background file has been found');
           return
       end
       obj.fName = obj.staticFile;
       [Mx,My,Mz] = obj.loadMagnetisation('fileExt','stc');
   end    
   
   function writeMemLog(obj,comment)
       res = memory;  
       fid = fopen(obj.memLogFile,'a');
       data = clock;
       str = strcat(num2str(data(3)),'-',num2str(data(2)),'-',num2str(data(1)),...
          '   ',num2str(data(4)),':',num2str(data(5)));
       fprintf(fid,str);
       fprintf(fid,strcat('MaxPossibleArrayBytes :', num2str(res.MaxPossibleArrayBytes),' \n'));
       fprintf(fid,strcat('MemAvailableAllArrays :',num2str(res.MemAvailableAllArrays),' \n'));
       fprintf(fid,strcat('MemUsedMATLAB :',num2str(res.MemUsedMATLAB),' \n'));
       fclose(fid);
   end
   
   % get Mx projection of magnetisation
   function Mx = getMx(time,x,y,z)
       File = matfile(obj.MxName);
       Mx = File.Mx(time,x,y,z)
   end  
   
   % get My projection of magnetisation
   function My = getMy(time,x,y,z)
       File = matfile(obj.MyName);
       My = File.My(time,x,y,z)
   end  
   
   % get Mz projection of magnetisation
   function Mz = getMz(time,x,y,z)
       File = matfile(obj.MyName);
       Mz = File.Mz(time,x,y,z)
   end
   
    %scan folder %path% and select all %ext% files
   function fList = getFilesList(obj,path,fileBase,ext)
     if (isdir(path))
       if length(fileBase)  
           fList = dir(strcat(path,'\',fileBase,'*.',ext));
       else
           pth = strcat(path,'\*.',ext);
           fList = dir(pth);
       end    
     else
       disp('Incorrect folder path');
       return;
     end
     
     if (size(fList,1) == 0)
       disp('No suitable files');
       return;
     end
   end
   
 % END OF PRIVATE METHODS
 end
 
 % END OF CLASS
end 


  %% create red-blue color map 
 function newmap = b2r(cmin_input,cmax_input)
%BLUEWHITERED   Blue, white, and red color map.
%   this matlab file is designed to draw anomaly figures, the color of
%   the colorbar is from blue to white and then to red, corresponding to 
%   the anomaly values from negative to zero to positive, respectively. 
%   The color white always correspondes to value zero. 
%   
%   You should input two values like caxis in matlab, that is the min and
%   the max value of color values designed.  e.g. colormap(b2r(-3,5))
%   
%   the brightness of blue and red will change according to your setting,
%   so that the brightness of the color corresponded to the color of his
%   opposite number
%   e.g. colormap(b2r(-3,6))   is from light blue to deep red
%   e.g. colormap(b2r(-3,3))   is from deep blue to deep red
%
%   I'd advise you to use colorbar first to make sure the caxis' cmax and cmin
%
%   by Cunjie Zhang
%   2011-3-14
%   find bugs ====> email : daisy19880411@126.com
%  
%   Examples:
%   ------------------------------
%   figure
%   peaks;
%   colormap(b2r(-6,8)), colorbar, title('b2r')
%   


%% check the input
if nargin ~= 2 ;
   disp('input error');
   disp('input two variables, the range of caxis , for example : colormap(b2r(-3,3))')
end

if cmin_input >= cmax_input
    disp('input error')
    disp('the color range must be from a smaller one to a larger one')
end

%% control the figure caxis 
lims = get(gca, 'CLim');   % get figure caxis formation
caxis([cmin_input cmax_input])

%% color configuration : from blue to light blue to white untill to red

red_top     = [1 0 0];
white_middle= [1 1 1];
blue_bottom = [0 0 1];

%% color interpolation 

color_num = 250;   
color_input = [blue_bottom;  white_middle;  red_top];
oldsteps = linspace(-1, 1, length(color_input));
newsteps = linspace(-1, 1, color_num);  

%% Category Discussion according to the cmin and cmax input

%  the color data will be remaped to color range from -max(abs(cmin_input,abs(cmax_input)))
%  to max(abs(cmin_input,abs(cmax_input))) , and then squeeze the color
%  data in order to make suere the blue and red color selected corresponded
%  to their math values

%  for example :
%  if b2r(-3,6) ,the color range is from light blue to deep red ,
%  so that the color at -3 is light blue while the color at 3 is light red
%  corresponded

%% Category Discussion according to the cmin and cmax input
% first : from negative to positive
% then  : from positive to positive
% last  : from negative to negative

newmap_all = NaN(size(newsteps,2),3);
if (cmin_input < 0)  &&  (cmax_input > 0) ;  
    
    
    if abs(cmin_input) < cmax_input 
         
        % |--------|---------|--------------------|    
      % -cmax      cmin       0                  cmax         [cmin,cmax]
      %    squeeze(colormap(round((cmin+cmax)/2/cmax),size(colormap)))
 
       for j=1:3
           newmap_all(:,j) = min(max(transpose(interp1(oldsteps, color_input(:,j), newsteps)), 0), 1);
       end
       start_point = round((cmin_input+cmax_input)/2/cmax_input*color_num);
       newmap = squeeze(newmap_all(start_point:color_num,:));
       
    elseif abs(cmin_input) >= cmax_input
        
         % |------------------|------|--------------|    
       %  cmin                0     cmax          -cmin         [cmin,cmax]
       %    squeeze(colormap(round((cmin+cmax)/2/cmax),size(colormap)))       
       
       for j=1:3
           newmap_all(:,j) = min(max(transpose(interp1(oldsteps, color_input(:,j), newsteps)), 0), 1);
       end
       end_point = round((cmax_input-cmin_input)/2/abs(cmin_input)*color_num);
       newmap = squeeze(newmap_all(1:end_point,:));
    end
    
       
elseif cmin_input >= 0

       if lims(1) < 0 
           disp('caution:')
           disp('there are still values smaller than 0, but cmin is larger than 0.')
           disp('some area will be in red color while it should be in blue color')
       end
        % |-----------------|-------|-------------|    
      % -cmax               0      cmin          cmax         [cmin,cmax]
      %    squeeze(colormap(round((cmin+cmax)/2/cmax),size(colormap)))
 
       for j=1:3
           newmap_all(:,j) = min(max(transpose(interp1(oldsteps, color_input(:,j), newsteps)), 0), 1);
       end
       start_point = round((cmin_input+cmax_input)/2/cmax_input*color_num);
       newmap = squeeze(newmap_all(start_point:color_num,:));

elseif cmax_input <= 0

       if lims(2) > 0 
           disp('caution:')
           disp('there are still values larger than 0, but cmax is smaller than 0.')
           disp('some area will be in blue color while it should be in red color')
       end
       
         % |------------|------|--------------------|    
       %  cmin         cmax    0                  -cmin         [cmin,cmax]
       %    squeeze(colormap(round((cmin+cmax)/2/cmax),size(colormap)))       

       for j=1:3
           newmap_all(:,j) = min(max(transpose(interp1(oldsteps, color_input(:,j), newsteps)), 0), 1);
       end
       end_point = round((cmax_input-cmin_input)/2/abs(cmin_input)*color_num);
       newmap = squeeze(newmap_all(1:end_point,:));
end
 end
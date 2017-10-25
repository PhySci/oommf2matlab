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
   M
   totalSimTime % total simulation time
   iteration
   memLogFile = 'log.txt';
   dt = 1e-11; % time step of simulation
 end
 
 properties (Access = protected)
     % list of available spatial projections
     availableProjs = {'x','X','y','Y','z','Z','inp'};
     
     % list of available extention of magnetisation files
     availableExts = {'omf', 'ohf', 'stc', 'ovf'};
     availableFiles = {'*.omf'; '*.ohf'; '*.stc'; '*.ovf'};
     availableValues = {'M','H','Heff','Hdemag'};
     staticFile = 'static.stc';
     paramsFile = 'params.mat';
     MxName = 'Mx.mat';
     MyName = 'My.mat';
     MzName = 'Mz.mat';
     
 end     
 % public methods
 methods
    
   % Constructor of the class  
   function obj = OOMMF_sim()    
       disp('OOMMF_sim object was created');
   end
   
   % Load only parameters from file
   function loadParams(obj,varargin)
       %% open file and check errors
     p = inputParser;
     p.addParamValue('fileExt','omf',@(x) any(strcmp(x,obj.availableExts)));
     p.parse(varargin{:});
     params = p.Results;
     
     [pathstr,name,ext] = fileparts(obj.fName);
     
     if (strcmp(name,'') && strcmp(ext,''))
         [fName,fPath,~] = uigetfile({'*.omf'; '*.ohf'; '*.stc'; '*.ovf'});
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
    
    fclose(fid);
    
   end
   
   % Load only magnetisation from file
   function [Mx,My,Mz] = loadMagnetisation(obj,varargin)
       %% open file and check errors
     p = inputParser;
     p.addParamValue('showMemory',false,@islogical);
     p.addParamValue('fileExt','omf',@(x) any(strcmp(x,obj.availableExts)));
     p.parse(varargin{:});
     params = p.Results;
     
     [pathstr,name,ext] = fileparts(obj.fName);
     
     if (strcmp(name,'') && strcmp(ext,''))
         [fName,fPath,~] = uigetfile({'*.omf'; '*.ohf'; '*.stc'; '*.ovf'});
         obj.fName = fullfile(fPath,fName);  
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
     % bootle neck
 
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
    if (fTestVal ~= testVal)
      disp('Wrong format');
      return;
    end   
     
    data = fread(fid, obj.xnodes*obj.ynodes*obj.znodes*obj.dim,...
         format, 0, 'ieee-le');
    
    line = fgetl(fid); 
    if (isempty(strfind(line ,'# End: Data')) && isempty(strfind(line,'# End: Segment')))
      disp('End of file is incorrect. Something wrong');
      fclose(fid);
     % return;
    else    
      fclose(fid);
    end
        
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
   
   % Load only magnetisation from file
   function valArr = loadMonoVal(obj,varargin)
       %% open file and check errors
     p = inputParser;
     p.addParamValue('showMemory',false,@islogical);
     p.addParamValue('fileExt','omf',@(x) any(strcmp(x,obj.availableExts)));
     p.parse(varargin{:});
     params = p.Results;
     
     [pathstr,name,ext] = fileparts(obj.fName);
     
     if (strcmp(name,'') && strcmp(ext,''))
         [obj.fName,fPath,~] = uigetfile({'*.omf'; '*.ohf'; '*.stc'; '*.ovf'});
         fName = fullfile(fPath,obj.fName);  
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
     
    data = fread(fid, obj.xnodes*obj.ynodes*obj.znodes,...
         format, 0, 'ieee-le');
    
    if (isempty(strfind(fgetl(fid),'# End: Data')) || isempty(strfind(fgetl(fid),'# End: Segment')))
      disp('End of file is incorrect. Something wrong');
      fclose(fid);
      return;
    else    
      fclose(fid);
    end
        
    valArr = reshape(data, [obj.xnodes obj.ynodes obj.znodes]);
    
    if (params.showMemory)
      disp('Memory used:');
      memory
    end
   end
   
   % Load one file (parameters and data)
   function loadSingleFile(obj)
       [fName,fPath,~] = uigetfile(obj.availableFiles);
       obj.fName = fullfile(fPath,fName);
       obj.loadParams;
       [Mx,My,Mz] = obj.loadMagnetisation;
       obj.M = cat(4,Mx,My,Mz);
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
   
   % Plot vector plot of magnetisation in XY plane
   % z is number of plane
   % should be rewritted 
   function plotMSurfXY(obj,varargin)
     p = inputParser;
     p.addParamValue('slice',1,@isnumeric);
     p.addParamValue('proj',@ischar);
     
     p.addParamValue('saveAs','',@isstr);
     p.addParamValue('colourRange',0,@isnumeric);
     p.addParamValue('xRange',0,@isnumeric);
     p.addParamValue('yRange',0,@isnumeric);
     p.addParamValue('timeFrame',1,@isnumeric);
     
     p.parse(varargin{:});
     params = p.Results;
       
     mFile = matfile('Mz.mat');
     sizeArr = size(mFile,'M');
     
     obj.getSimParams();
     
     if (params.xRange == 0)
         params.xRange = [1 sizeArr(2)];
     end    
     
     if (params.yRange == 0)
         params.yRange = [1 sizeArr(3)];
     end    
     
     % read data
     data = squeeze(mFile.M(params.timeFrame,params.xRange(1):params.xRange(2),...
         params.yRange(1):params.yRange(2),params.slice)).';
     data0 = squeeze(mFile.M(2040,params.xRange(1):params.xRange(2),...
         params.yRange(1):params.yRange(2),params.slice)).';
     data = data - data0;
     
     % filtering
     winSize = 20;
     G = fspecial('gaussian',[winSize winSize],0.9);
     data = imfilter(data,G,'circular','same','conv');
     
     % calculate scales
     xScale = linspace(obj.xmin,obj.xmax,obj.xnodes);
     xScale = xScale(params.xRange(1):params.xRange(2))*1e6;
     
     yScale = linspace(obj.ymin,obj.ymax,obj.ynodes);
     yScale = yScale(params.yRange(1):params.yRange(2))*1e6;
     
     % plot data
     imagesc(xScale,yScale,data);
     axis xy equal
     xlim([xScale(1) xScale(end)]); ylim([yScale(1) yScale(end)]);
     %colorbar();
     set(gca,'FontSize',16,'FontName','Times','FontWeight','bold');
     xlabel('x (\mum)','FontSize',20); ylabel('y (\mum)','FontSize',20); 
     
     % save image
     obj.savePlotAs(params.saveAs,gcf);
   end
   
   % plot vector plot of magnetisation in XY plane
   % z is number of plane
   function plotMSurfXZ(obj,varargin)
       
       % parse input values and parameters
       p = inputParser;
       p.addParamValue('slice',1,@isnumeric);
       p.addParamValue('proj','Y',@(x)any(strcmp(x,obj.availableProjs)));
       p.addParamValue('saveAs','',@isstr);
       p.addParamValue('colourRange',0,@isnumerical);
       p.addParamValue('showScale',true,@islogical);
       p.addParamValue('xrange',0,@isnumerical);
       p.addParamValue('yrange',0,@isnumerical);
       
       p.parse(varargin{:});
       params = p.Results;
       
       params.proj = lower(params.proj);
       
       % select desired projection of magnetization
       switch params.proj
           case 'x'
               projID = 1;
           case 'y'
               projID = 2;
           case 'z'
               projID = 3;
           otherwise
               disp('Unknown projection');
               return;
       end
       M = squeeze(obj.M(:,params.slice,:,projID));
       
       % calculate spatial scales
       
       xScale = linspace(obj.xmin,obj.xmax,obj.xnodes)/1e-6;
       yScale = linspace(obj.zmin,obj.zmax,obj.znodes)/1e-6;
       

       imagesc(xScale,yScale,M.'/1e3);
       axis xy;
           xlabel('x (\mum)','FontSize',14,'FontName','Times');
           ylabel('z (\mum)','FontSize',14,'FontName','Times');
           t = colorbar('peer',gca);
           set(get(t,'ylabel'),'String','M_S (kA/m)','FontSize',14,'FontName','Times');
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
     p.addParameter('deleteFiles', false,@islogical);
     p.addParameter('showMemory',false,@islogical);
     p.addParameter('makeFFT',false,@islogical);
     p.addParameter('fileBase','',@isstr);
     p.addParameter('fileExt','',@isstr);
     p.addParameter('value','M',@(x) any(strcmp(x,{'M','H'})));
     % folder to save results
     p.addParameter('destination','.',@(x) exist(x,'dir')==7);
     
     p.parse(path,varargin{:});
     params = p.Results;
     
          
     % select extension for magnetization (*.omf) or field (*.ohf) files
     if (isempty(params.fileExt) && strcmp(params.value,'M'))
         params.fileExt = 'omf'; 
     elseif (isempty(params.fileExt) && strcmp(params.value,'H'))
         params.fileExt = 'ohf';
     elseif (isempty(params.fileExt))
         disp('Unknown physical value');
         return
     end
     
     profile on
                
     fList = obj.getFilesList(path,params.fileBase,params.fileExt);     
     file = fList(1);
     [~, fName, ~] = fileparts(file.name);
     obj.fName = strcat(path,filesep,fName);
     obj.loadParams('fileExt',params.fileExt);
     save(strcat(params.destination,filesep,'params.mat'), 'obj');
          
     % evaluate required memory and compare with available space
      % memory required for one time frame 
     oneTimeFrameMemory = 3*8*obj.xnodes*obj.ynodes*obj.znodes*obj.dim;
     availableSpace = obj.getMemory();
    
     heapSize = min(ceil(availableSpace/oneTimeFrameMemory),size(fList,1))
          
     % create files and variables   
     XFile = matfile(fullfile(params.destination,strcat(params.value,'x.mat')),'Writable',true);
     YFile = matfile(fullfile(params.destination,strcat(params.value,'y.mat')),'Writable',true);
     ZFile = matfile(fullfile(params.destination,strcat(params.value,'z.mat')),'Writable',true);
      
     
     % create heap array
     XHeap = zeros(heapSize,obj.xnodes,obj.ynodes,obj.znodes);
     YHeap = zeros(heapSize,obj.xnodes,obj.ynodes,obj.znodes);
     ZHeap = zeros(heapSize,obj.xnodes,obj.ynodes,obj.znodes);
     
     indHeap = 1;
     fileAmount = size(fList,1);
     
     for fInd=1:fileAmount
         file = fList(fInd);
         [~, fName, ~] = fileparts(file.name);
         obj.fName = strcat(path,filesep,fName);
         [XHeap(indHeap,:,:,:), YHeap(indHeap,:,:,:), ZHeap(indHeap,:,:,:)] = ...
             obj.loadMagnetisation('fileExt',params.fileExt);
               
         % write heaps to files
         if (indHeap >= heapSize || fInd == fileAmount)
             heapStart = (fInd-indHeap+1);
             heapEnd = fInd;
             switch (params.value)
                 case 'M'    
                    disp(['Write to file. Last file is number ', num2str(fInd)]);
                    
                    if (obj.xnodes ==1)  % purpose of this if-else structure is correst writing of 2D system with one singleton dimension
                        XFile.M(heapStart:heapEnd,1,1:obj.ynodes,1:obj.znodes) = cast(XHeap(1:indHeap,1:end,1:end,1:end),'single');
                        YFile.M(heapStart:heapEnd,1,1:obj.ynodes,1:obj.znodes) = cast(YHeap(1:indHeap,1:end,1:end,1:end),'single'); 
                        ZFile.M(heapStart:heapEnd,1,1:obj.ynodes,1:obj.znodes) = cast(ZHeap(1:indHeap,1:end,1:end,1:end),'single');    
                    elseif (obj.ynodes ==1)
                        XFile.M(heapStart:heapEnd,1:obj.xnodes,1,1:obj.znodes) = cast(XHeap(1:indHeap,1:end,1:end,1:end),'single');
                        YFile.M(heapStart:heapEnd,1:obj.xnodes,1,1:obj.znodes) = cast(YHeap(1:indHeap,1:end,1:end,1:end),'single'); 
                        ZFile.M(heapStart:heapEnd,1:obj.xnodes,1,1:obj.znodes) = cast(ZHeap(1:indHeap,1:end,1:end,1:end),'single');
                    elseif (obj.znodes ==1)
                        XFile.M(heapStart:heapEnd,1:obj.xnodes,1:obj.ynodes) = cast(XHeap(1:indHeap,1:end,1:end,1:end),'single');
                        YFile.M(heapStart:heapEnd,1:obj.xnodes,1:obj.ynodes) = cast(YHeap(1:indHeap,1:end,1:end,1:end),'single'); 
                        ZFile.M(heapStart:heapEnd,1:obj.xnodes,1:obj.ynodes) = cast(ZHeap(1:indHeap,1:end,1:end,1:end),'single');
                    else
                        XFile.M(heapStart:heapEnd,1:obj.xnodes,1:obj.ynodes,1:obj.znodes) = cast(XHeap(1:indHeap,1:end,1:end,1:end),'single');
                        YFile.M(heapStart:heapEnd,1:obj.xnodes,1:obj.ynodes,1:obj.znodes) = cast(YHeap(1:indHeap,1:end,1:end,1:end),'single'); 
                        ZFile.M(heapStart:heapEnd,1:obj.xnodes,1:obj.ynodes,1:obj.znodes) = cast(ZHeap(1:indHeap,1:end,1:end,1:end),'single');
                    end       
                    indHeap = 1;
                 case 'H'    
                    disp('Write to file');
                    XFile.H(heapStart:heapEnd,1:obj.xnodes,1:obj.ynodes,1:obj.znodes) = XHeap(1:indHeap,1:end,1:end,1:end);
                    YFile.H(heapStart:heapEnd,1:obj.xnodes,1:obj.ynodes,1:obj.znodes) = YHeap(1:indHeap,1:end,1:end,1:end); 
                    ZFile.H(heapStart:heapEnd,1:obj.xnodes,1:obj.ynodes,1:obj.znodes) = ZHeap(1:indHeap,1:end,1:end,1:end);
                    indHeap = 1;
                 otherwise
                     disp('Unknpwn physical value');
                     return
             end        
         else
             indHeap = indHeap +1;
         end    
         
         if (params.deleteFiles)
             delete(strcat(obj.fName,'.',params.fileExt));
         end                       
     end
     
     %obj.sendNote('Phy-Effort','ScanFolder is finished');
     
     profsave
     profile viewer
     
     %obj.sendNote('OOMMF_sim','Method: scan folder. Status: finished.')
     
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
    
   function plotDispersion(obj,varargin)
       % plot dispersion curve along X axis
       % params:
       %  - xRange is range of selected cells along X axis
       %  - yRange is range of selected cells along Y axis
       %  - zRange is range of selected cells along Z axis
       %  - scale is determine mormal or log scale of plotted map
       %  - freqLimit is range of evaluated frequencies
       %  - waveLimit is range of evaluated wavevectors
       %  - proj is projection of magnetization which will be used
       %  - saveAs is name of produced *.fig and *.png files
       %  - saveMatAs is name of *.mat file for saving of data
       %  - interpolate is logical value. True for interpolation of the dispersion curve
       %  - direction is spatial direction along which dispersion will be calculated
       %  - normalize is determine
       
       p = inputParser;
       p.addParamValue('xRange',0,@isnumeric);
       p.addParamValue('yRange',0,@isnumeric);
       p.addParamValue('zRange',0,@isnumeric);
       p.addParamValue('freqLimit',[0 50], @isnumeric);
       p.addParamValue('waveLimit',[0 700],@isnumeric);
       p.addParamValue('proj','z',@(x)any(strcmp(x,obj.availableProjs)));
       p.addParamValue('saveAs','',@isstr);
       p.addParamValue('saveMatAs','',@isstr);
       p.addParamValue('interpolate',false,@islogical);
       p.addParamValue('direction','X',@(x)any(strcmp(x,obj.availableProjs)));
       p.addParamValue('scale','log',@(x) any(strcmp(x,{'log','norm'})));
       p.addParamValue('normalize',true,@islogical);
       p.addParamValue('windowFunc',false,@islogical);
       p.addParamValue('value','M',@(x) any(strcmp(x,{'H','M','Heff','Hdemag'})));
       p.addParamValue('zAverage',false,@islogical); %average frequency-domain FFT along z axis
       
       % process incomming parameters
       p.parse(varargin{:});
       params = p.Results;
       params.proj = lower(params.proj);
       params.direction = lower(params.direction);
       
 
       % read file of simulation parameters
       obj.getSimParams;
       
       switch params.value
           case 'M'
               MFile = matfile(fullfile(obj.folder,strcat('M',params.proj,'FFT.mat')));              
           case 'H'
               MFile = matfile(fullfile(obj.folder,strcat('H',params.proj,'FFT.mat')));
           case 'Heff'
               MFile = matfile(fullfile(obj.folder,strcat('Heff_',params.proj,'FFT.mat')));
           case 'Hdemag'
               MFile = matfile(fullfile(obj.folder,strcat('Hdemag',params.proj,'FFT.mat')));
       end
       
       mSize = size(MFile,'Y');
       
       % fix for 2D systems
       if (numel(mSize) == 3)
           mSize(4) = 1;
       end     
       
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
       
       freqScale = obj.getWaveScale(obj.dt,mSize(1))/1e9; 
       [~,freqScaleInd(1)] = min(abs(freqScale-params.freqLimit(1)));
       [~,freqScaleInd(2)] = min(abs(freqScale-params.freqLimit(2)));
       freqScale = freqScale(freqScaleInd(1):freqScaleInd(2));
       
       
       if (strcmp(params.proj,'z'))
           FFTres = MFile.Y(freqScaleInd(1):freqScaleInd(2),params.xRange(1):params.xRange(2),...
               params.yRange(1):params.yRange(2),...
               params.zRange(1):params.zRange(2));
       elseif (strcmp(params.proj,'x'))
           FFTres = MFile.Y(freqScaleInd(1):freqScaleInd(2),params.xRange(1):params.xRange(2),...
               params.yRange(1):params.yRange(2),...`
               params.zRange(1):params.zRange(2));   
       elseif (strcmp(params.proj,'y'))
           FFTres = MFile.Y(freqScaleInd(1):freqScaleInd(2),params.xRange(1):params.xRange(2),...
               params.yRange(1):params.yRange(2),...
               params.zRange(1):params.zRange(2));
       elseif (strcmp(params.proj,'inp'))
           FFTres = MFile.Y(freqScaleInd(1):freqScaleInd(2),params.xRange(1):params.xRange(2),...
               params.yRange(1):params.yRange(2),...
               params.zRange(1):params.zRange(2));    
       else
           disp('Unknown projection');
           return
       end
              
       % average along OZ axis 
       if params.zAverage
           FFTres = mean(FFTres,4);
       end    
       
       % apply window function
       if params.windowFunc
           repSize = size(FFTres);
           
           if (strcmp(params.direction,'x'));
               repSize = size(FFTres);
               
               % calculate window function
               windVecX = hanning(repSize(2),'periodic');
               windVecXarr = permute(windVecX,[4 1 2 3]);
               repSize(2) = 1;
               windArr = repmat(windVecXarr,repSize);
               FFTres = FFTres.*windArr;
               windArr = [];
               
               repSize = size(FFTres);
               windVecY = hanning(repSize(3),'periodic');
               windVecYarr = permute(windVecY,[3 4 1 2]);
               repSize(3) = 1;
               windArr = repmat(windVecYarr ,repSize);
               FFTres = FFTres.*windArr;

           elseif (strcmp(params.direction,'y'))
               windSize = repSize(3);
               repSize(3) = 1; 
           elseif (strcmp(params.direction,'z'))
               windSize = repSize(4);
               repSize(4) = 1; 
           end
           
       end    
       
       % calculate FFT and wave vector scale
       if (strcmp(params.direction,'x'))           
           Y(:,:,:,:) = fft(FFTres,[],2);
           clearvars FFTres;
           Amp = mean(mean(abs(Y),4),3);
           Amp = fftshift(abs(Amp),2);
           clearvars Y;
           waveVectorScale = 2*pi*obj.getWaveScale(obj.xstepsize/1e-6,mSize(2));
           directionLabel = 'x';
       elseif (strcmp(params.direction,'y'))
           Y(:,:,:,:) = fft(FFTres,[],3);
           clearvars FFTres;
           Amp = mean(mean(abs(Y),4),2);
           Amp = fftshift(abs(Amp),3);
           clearvars Y;
           waveVectorScale = 2*pi*obj.getWaveScale(obj.ystepsize/1e-6,mSize(3));
           directionLabel = 'y';
       elseif (strcmp(params.direction,'z'))
           Y(:,:,:,:) = fft(FFTres,[],4);
           clearvars FFTres;
           Amp = squeeze(mean(mean(abs(Y),2),3));
           Amp = fftshift(abs(Amp),2);
           clearvars Y;
           waveVectorScale = 2*pi*obj.getWaveScale(obj.zstepsize/1e-6,mSize(4));
           directionLabel = 'z';
       end
       
       [~,waveVectorInd(1)] = min(abs(waveVectorScale-params.waveLimit(1)));
       [~,waveVectorInd(2)] = min(abs(waveVectorScale-params.waveLimit(2)));
       waveVectorScale = waveVectorScale(waveVectorInd(1):waveVectorInd(2));       

              
       Amp = Amp(:,waveVectorInd(1):waveVectorInd(2));
       
       if (strcmp(params.scale,'log'))
           if (params.normalize)
               ref = min(Amp(find(Amp(:))));
           else 
               ref = 1;
           end    
           res = log10(Amp/ref);
       else
           if (params.normalize)
               res = (Amp - min(Amp(:)));
               res = Amp/max(Amp(:));
           else 
               res = Amp;
           end
           
       end
       
       % plot image
       
       % interpolate
       if (params.interpolate)
           waveNew = linspace(min(waveVectorScale),max(waveVectorScale),50*size(waveVectorScale,2));
           freqNew = linspace(min(freqScale),max(freqScale),2*size(freqScale,2));

           [waveGrid,freqGrid]=ndgrid(waveVectorScale,freqScale);
           [waveGridNew,freqGridNew]=ndgrid(waveNew,freqNew);

           F = griddedInterpolant(waveGrid,freqGrid,res.','spline');
           res = F(waveGridNew,freqGridNew).';
           
           waveVectorScale = waveNew;
           freqScale = freqNew;
       end
       
       % plot image
       imagesc(waveVectorScale,freqScale,res);
            
       colormap(jet); axis xy;
       set(gca,'FontSize',16,'FontName','Times');
       xlabel(strcat('Wave vector k_',directionLabel,' (rad/\mum)'));
       ylabel('Frequency (GHz)');
       xlim([min(waveVectorScale) max(waveVectorScale)]);
       
       
       t = colorbar('peer',gca);
       if (strcmp(params.scale,'log'))
           set(get(t,'ylabel'),'String', 'FFT intensity (dB)');
       else
           set(get(t,'ylabel'),'String', 'Intensity (arb. units)');
       end    
       
       % save img
       obj.savePlotAs(params.saveAs,gcf);       

       % save data to mat file
       if (~strcmp(params.saveMatAs,''))
           fName = strcat(params.saveMatAs,'.mat');
           Amp = res;
           save(fName,'waveVectorScale','freqScale','Amp'); 
       end
   end
      
   function plotFFTSliceZ(obj,varargin)
       % Plot spatial map of FFT distribution for a given frequency
       % params:
       %  - freq is desired frequency of FFT
       %  - zSlice is desired Z slice of FFT
       %  - xRange & yRange are ranges of X and Y coordinates
       %  - scale is scale of plots (norm, log)
       %  - rotate is bool valus allows  rotating of images
       %  - saveAs is name of output *.png and *.fig files
       
       p = inputParser;
       p.addParamValue('freq',0,@isnumeric);
       p.addParamValue('zSlice',1,@isnumeric);
       p.addParamValue('xRange',0,@isnumeric);
       p.addParamValue('yRange',0,@isnumeric);
       p.addParamValue('scale','log', @(x) any(strcmp(x,{'norm','log'})));
       p.addParamValue('saveAs','',@isstr);
       p.addParamValue('rotate',false,@islogical);
       p.addParamValue('proj','z',@(x)any(strcmp(x,obj.availableProjs)));
       
       p.parse(varargin{:});
       params = p.Results;
       params.proj = lower(params.proj);
              
       % load parameters
       obj.getSimParams;
       
       % assign file of FFT of Mz
       % select projections
       
       switch params.proj
           case 'x'
               FFTFile = matfile(fullfile(obj.folder,'MxFFT.mat'));
           case 'y'
               FFTFile = matfile(fullfile(obj.folder,'MyFFT.mat'));
           case 'z'
               FFTFile = matfile(fullfile(obj.folder,'MzFFT.mat'));
           case 'inp'
               FFTFile = matfile(fullfile(obj.folder,'MinpFFT.mat'));
           otherwise
               disp('Unknown projection');
               return
       end        
               
       arrSize = size(FFTFile,'Y');
       
       % process range parameters
       if (params.xRange  == 0)
           params.xRange(1) = 1;
           params.xRange(2) = arrSize(2);
       end    
       
       if (params.yRange  == 0)
           params.yRange(1) = 1;
           params.yRange(2) = arrSize(3);
       end    
              
       % calculate scales
       xScale = linspace(obj.xmin,obj.xmax,obj.xnodes)/1e-6;
       xScale = xScale(params.xRange(1):params.xRange(2));  

       yScale=linspace(obj.ymin,obj.ymax,obj.ynodes)/1e-6;
       yScale = yScale(params.yRange(1):params.yRange(2));  
       
       freqScale = obj.getWaveScale(obj.dt,arrSize(1))/1e9;
       [~,freqInd] = min(abs(freqScale-params.freq));
       
       fftSlice = FFTFile.Y(freqInd,params.xRange(1):params.xRange(2),...
           params.yRange(1):params.yRange(2),params.zSlice);
       
       if (size(fftSlice,4)>1)
           fftSlice = mean(fftSlice,4);
       end
       
       fftSlice = squeeze(fftSlice);
       if params.rotate
           Amp = abs(fftSlice).';
           Phase = angle(fftSlice).';
           xLabelStr = 'X, \mum';
           yLabelStr = 'Y, \mum';
           
           % exchange of axis labels
           tmp = yScale;
           yScale = xScale;
           xScale  = tmp;
           
       else
           Amp = abs(fftSlice);
           Phase = angle(fftSlice);
           xLabelStr = 'Y, \mum';
           yLabelStr = 'X, \mum';
       end    

       % plot amplitude map
       
      
       fg1 = figure(1);
       clf(fg1)
       ref = min(Amp(find(Amp(:))));

       if strcmp(params.scale,'log')
           if (isempty(ref))
               ref = 1;
           end    
           imagesc(yScale,xScale,log10(Amp/ref));
           colorbar('EastOutside');
           colormap(flipud(gray));
           %cbfreeze(flipud(gray))
           %cblabel('dB');
       else
           imagesc(yScale,xScale,Amp);
           axis xy equal;
           colorbar('EastOutside');
           colormap(flipud(gray));
           %cbfreeze(flipud(gray))
           %cblabel('arb. units');
       end    
       title(['Amplitude of FFT, \nu=' num2str(params.freq) 'GHz, slice ' num2str(params.zSlice)]);
       axis xy equal; 
       xlabel(xLabelStr); ylabel(yLabelStr);
       %freezeColors;
       %cbfreeze;
       xlim([min(yScale) max(yScale)]);
       ylim([min(xScale) max(xScale)]);


       % plot phase map   
       fg2 = figure(2);
       imagesc(yScale,xScale,Phase,[-pi pi]);
       title(['Phase of FFT, \nu=' num2str(params.freq) 'GHz, slice ' num2str(params.zSlice)]);

       axis xy equal; colormap(hsv);
       colorbar('EastOutside'); cblabel('rad.');
       xlabel(xLabelStr); ylabel(yLabelStr);
       xlim([min(yScale) max(yScale)]);
       ylim([min(xScale) max(xScale)]);
          
       
       % save figure
       obj.savePlotAs(params.saveAs,fg1,'suffix','-amp');     
       obj.savePlotAs(params.saveAs,fg2,'suffix','-phase');
   end 
   
   function plotFFTSliceY(obj,varargin)
       % plot spatial map of FFT distribution for a given frequency
       % parameters
       %       freq - desired frequency
       %       rotate - rotate the image (false)
       
       p = inputParser;
       p.addParamValue('freq',0,@isnumeric);
       p.addParamValue('ySlice',2,@isnumeric);
       
       p.addParamValue('xRange',0,@isnumeric);
       p.addParamValue('yRange',0,@isnumeric);
       p.addParamValue('zRange',0,@isnumeric);
       
       p.addParamValue('scale','log', @(x) any(strcmp(x,{'norm','log'})));
       p.addParamValue('saveAs','',@isstr);
       p.addParamValue('proj','z',@(x)any(strcmp(x,obj.availableProjs)));
       
       p.addParamValue('rotate',false,@islogical);
       p.addParamValue('gaussWin',0,@isnumeric);
       p.addParamValue('value','M',@(x) any(strcmp(x,{'H','M'})));
            
       p.parse(varargin{:});
       params = p.Results;
       
       % load parameters
       obj.getSimParams;

       params.proj=lower(params.proj);

       % assign file of FFT of Mz
       switch params.value
           case 'M'
               FFTFile = matfile(fullfile(obj.folder,strcat('M',params.proj,'FFT.mat')));    
           case 'H'
               FFTFile = matfile(fullfile(obj.folder,strcat('H',params.proj,'FFT.mat')));
       end        
       arrSize = size(FFTFile,'Y');

       % process parameters
       if (~params.xRange)
           params.xRange = [1 arrSize(2)];
       end
       
       if (~params.yRange)
           params.yRange = [1 arrSize(3)];
       end    

       if (~params.zRange)
           params.zRange = [1 arrSize(4)];
       end
       

       
       xScale=linspace(obj.xmin,obj.xmax,obj.xnodes)/1e-6;
       xScale = xScale(params.xRange(1):params.xRange(2));
       
       %yScale=linspace(obj.ymin,obj.ymax,obj.ynodes)/1e-6;
       %yScale = yScale(params.yRange(1):params.yRange(2));
             
       zScale= linspace(obj.zmin,obj.zmax,obj.znodes)/1e-6;
       zScale = zScale(params.zRange(1):params.zRange(2));
       
       % create freq Scale
       freqScale = obj.getWaveScale(obj.dt,arrSize(1))/1e9;
       [~,freqInd] = min(abs(freqScale-params.freq));
       
       switch params.proj
           case 'x'
               fftSlice = squeeze(FFTFile.Y(freqInd,...
                   params.xRange(1):params.xRange(2),...
                   params.ySlice,...
                   params.zRange(1):params.zRange(2)));
           case 'y'
               fftSlice = squeeze(FFTFile.Y(freqInd,...
                   params.xRange(1):params.xRange(2),...
                   params.ySlice,...
                   params.zRange(1):params.zRange(2)));
           case 'z'
               fftSlice = squeeze(FFTFile.Y(freqInd,...
                   params.xRange(1):params.xRange(2),...
                   params.ySlice,...
                   params.zRange(1):params.zRange(2)));
           otherwise
               disp('Unknown projection');
               return
       end
       
       if strcmp(params.value,'H')
           fftSlice = fftSlice*1e4;
       end    
       
       % apply Gauss window function
       if params.gaussWin >0
           [X,Y] = meshgrid(-params.gaussWin:1:params.gaussWin,-params.gaussWin:1:params.gaussWin);
           R = sqrt(X.^2+Y.^2);
           G = pdf('norm',R,0,0.5*params.gaussWin);
           fftSlice = conv2(fftSlice,G,'same');
       end    
       
       if (size(fftSlice,3)>1)
           Amp = squeeze(mean(abs(fftSlice),2));
           Phase = squeeze(mean(angle(fftSlice),2));
       else
           Amp = squeeze(abs(fftSlice));
           Phase = squeeze(angle(fftSlice));
       end
       
       if params.rotate
           xScaleName = 'z (\mum)';
           yScaleName = 'x, (\mum)';  
       else
           Amp = Amp.';
           Phase = Phase.';
           tmp = xScale;
           xScale = zScale;
           zScale = tmp;
           xScaleName = 'x (mm)';
           yScaleName = 'z (\mum)';
       end
       
       % plot amplitude map
       fg1 = figure(1);

           if strcmp(params.scale,'log')
               ref = min(Amp(find(Amp(:))));
               if (isempty(ref))
                   ref = 1;
               end
               val = log10(Amp);
               imagesc(zScale/1e3,xScale,val,[0 abs(max(val(:)))]);
               hcb =colorbar('EastOutside');
               obj.setDbColorbar('Spectral density (dB)');
           else
               imagesc(zScale/1e3,xScale,Amp,[0 max(Amp(:))]);
               hcb = colorbar('EastOutside');
               obj.setDbColorbar('Spectral density (arb. units)');
           end
           colormap(flipud(gray));

          % title(['Spectral density of FFT, \nu = ' num2str(params.freq) ' GHz'],...
          %     'FontSize',20,'FontName','Times');
           axis xy; 
           xlabel(xScaleName,'FontSize',18,'FontWeight','bold','FontName','Times');
           ylabel(yScaleName,'FontSize',18,'FontWeight','bold','FontName','Times'); 
           set(gca,'FontSize',16,'FontWeight','bold','FontName','Times');
           
           
           % define size of the figure
           pos = get(fg1,'position');
           set(fg1,'position',[pos(1),pos(1),1000,400])
           set(fg1, 'PaperPosition', [0 0 20 8]);
            % save figure
           if ~isempty(params.saveAs)
                obj.savePlotAs(strcat(params.saveAs,'-amp'),gcf); 
           end    
           
       fg2 = figure(2);
           imagesc(zScale/1e3,xScale,Phase);
          % title(['Phase of FFT, \nu = ' num2str(params.freq) ' GHz'],...
          %     'FontSize',20,'FontName','Times');
           axis xy; colorbar('EastOutside');
           %cblabel('rad.');
           colormap(hsv);
           xlabel(xScaleName); ylabel(yScaleName); 
           obj.setDbColorbar('Phase (rad)');
           set(gca,'FontSize',16,'FontWeight','bold','FontName','Times');
           xlabel(xScaleName,'FontSize',18,'FontWeight','bold','FontName','Times');
           ylabel(yScaleName,'FontSize',18,'FontWeight','bold','FontName','Times'); 
           % define size of the figure
           pos = get(fg2,'position');
           set(fg2,'position',[pos(1),pos(1),1000,400])
           set(fg2, 'PaperPosition', [0 0 20 8]);
         
           % save figure
           if ~isempty(params.saveAs)
               obj.savePlotAs(strcat(params.saveAs,'-phase'),gcf); 
           end
           
       fg3 = figure(3);
           mod = Amp;
           mod(isinf(mod)) = 0;
           sliceAbs = mean(mod);
           
           plot(zScale/1e3,sliceAbs);
           xlabel(xScaleName); xlim([min(zScale/1e3) max(zScale/1e3)])
           ylabel('Average SD (arb. units)');
           set(gca,'FontSize',16,'FontWeight','bold','FontName','Times');
           xlabel(xScaleName,'FontSize',18,'FontWeight','bold','FontName','Times');
           ylabel(yScaleName,'FontSize',18,'FontWeight','bold','FontName','Times'); 
           % define size of the figure
           pos = get(fg3,'position');
           set(fg3,'position',[pos(1),pos(1),1000,400])
           set(fg3, 'PaperPosition', [0 0 20 8]);
         
           % save figure
           if ~isempty(params.saveAs)
               obj.savePlotAs(strcat(params.saveAs,'-powerAbs'),gcf); 
           end
           
       save data.mat Amp Phase sliceAbs    
   end 
     
   % plot average dependence of FFT intensity on frequency
   % The absolute value of FFT coefficients are averaged over volume.
   % params:
   %    scale - log or norm scale of the output dependence (norm)
   %    proj  - desirable projection of magnetization (@TODO, is broken)
   %    xRange, yRange, zRange - spatial range of region of interest
   %    saveAs - name of the output images file
   function plotFFTIntensity(obj,varargin)
       
       p = inputParser;
       
       p.addParamValue('label','',@isstr);
       p.addParamValue('scale','norm', @(x) any(strcmp(x, {'norm','log'})));
       p.addParamValue('proj','z',@(x)any(strcmp(x,obj.availableProjs)));
       p.addParamValue('xRange',0,@isnumeric);
       p.addParamValue('yRange',0,@isnumeric);
       p.addParamValue('zRange',0,@isnumeric);
       p.addParamValue('saveAs','',@isstr);
       p.addParamValue('freqLimit',[0 25],@isnumeric);
       p.addParamValue('saveMatAs','',@isstr);
       
       p.parse(varargin{:});
       params = p.Results;
       
       FFTFile = matfile('MzFFT.mat'); 
       
       mSize = size(FFTFile,'Y');
       % process input range parameters
       if (params.xRange == 0)
           params.xRange = [1 mSize(2)];
       end    
       
       if (params.yRange == 0)
           params.yRange = [1 mSize(3)];
       end    
       
       if (params.zRange == 0)
           if (length(mSize) < 4)
               params.zRange = [1 1];
           else    
               params.zRange = [1 mSize(4)];
           end
       end
       
       obj.getSimParams;
       % calculate desirable range of freqeuncy
       freqScale = obj.getWaveScale(obj.dt,mSize(1))/1e9; 
       [~,freqScaleInd(1)] = min(abs(freqScale-params.freqLimit(1)));
       [~,freqScaleInd(2)] = min(abs(freqScale-params.freqLimit(2)));
       freqScale = freqScale(freqScaleInd(1):freqScaleInd(2));
       
       
       FFT = FFTFile.Y(freqScaleInd(1):freqScaleInd(2),...
           params.xRange(1):params.xRange(2),...
           params.yRange(1):params.yRange(2),...
           params.zRange(1):params.zRange(2));
       if (length(mSize) == 4)            
           Amp = (mean(mean(mean(abs(FFT),4),3),2));
       elseif (length(mSize) == 3)
           Amp = (mean(mean(abs(FFT),3),2));
       end    
       
       if (strcmp(params.scale,'norm'))
           plot(freqScale,Amp);
           ylabel('Spectral density (arb. units)','FontSize',18,'FontName','Times','FontWeight','bold');
       else
           semilogy(freqScale,Amp);
           ylabel('Spectral density (dB)','FontSize',18,'FontName','Times','FontWeight','bold');
       end
       xlim(params.freqLimit); xlabel('Frequency (GHz)','FontSize',18,'FontName','Times','FontWeight','bold');
       %num2clip([freqScale(find(freqScale>=0)).' Amp(find(freqScale>=0))]);
       
       set(gca,'FontSize',18,'FontName','Times','FontWeight','bold');
       % save figure
       obj.savePlotAs(params.saveAs,gcf);
       
       if ~strcmp(params.saveMatAs,'')
           save(strcat(params.saveMatAs,'.mat'),freqScale,Amp)
       end     
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
       Mz = squeeze(MzFile.M(end-params.timeFrames : end,:,params.yRange,params.zSlice));
       
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
       obj.getSimParams;
              
       xScale = linspace(obj.xmin,obj.xmax,obj.xnodes)/1e-6;
       yScale = linspace(obj.ymin,obj.ymax,obj.ynodes)/1e-6;
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
   
   function makeFFT(obj,folder,varargin)
   % perform FFT transformation from time to frequency domain
   % save results to files
   % PARAMS
   %    folder - where take the files (path)
   %    background - substract background (boolean)
   %    useGPU - use GPU (boolean)
   
       p = inputParser;

       p.addParameter('background',true,@islogical);       
       p.addParameter('chunk',false,@islogical);
       % point out desired projections for processing
       p.addParameter('proj','xyz',@isstr);
       p.addParameter('windFunc',false,@islogical);
       p.addParameter('value','M',@(x) any(strcmp(x,obj.availableValues)));
       % folder to save results
       p.addParameter('destination','.', @(x) exist(x,'dir')==7);
       % folder to read data from 
       p.addParameter('source','.', @(x) exist(x,'dir')==7);
              
       p.parse(folder,varargin{:});
       params = p.Results;
       
       obj.getSimParams;
       
       % load magnetization ground state
       if (params.background)
          try
              [MxStatic,MyStatic,MzStatic] = obj.getStatic(params.source);
          catch err
              disp('Can not load background configuration');
              disp(err)
              return
          end    
       else
           MxStatic = [];
           MyStatic = [];
           MzStatic = [];
       end
       disp('Write');
       
       %% select file prefix 
       switch params.value
           case 'M'
               filePrefix = 'M';
               value = 'M';
           case 'H'
               filePrefix = 'H';
               value = 'H';
           case 'Hdemag'
               filePrefix = 'Hdemag_';
               value = 'H';
           case 'Heff'
               filePrefix = 'Heff_';
               value = 'H';
           otherwise
               disp('Unknown value');
               return;
       end        
       
       %% initialize input and output files
       if ~isempty(strfind(params.proj,'x'))
           XFile = matfile(fullfile(params.source,[filePrefix,'x.mat']));
           arrSize = size(XFile,value);
           FFTxFile = matfile(fullfile(params.destination,[filePrefix,'xFFT.mat']),'Writable',true);
       end
       
       if ~isempty(strfind(params.proj,'y'))
           YFile = matfile(fullfile(params.source,[filePrefix,'y.mat']));
           arrSize = size(YFile,value);
           FFTyFile = matfile(fullfile(params.destination,[filePrefix,'yFFT.mat']),'Writable',true);
       end
       
       if ~isempty(strfind(params.proj,'z'))
           ZFile = matfile(fullfile(params.source,[filePrefix,'z.mat']));
           arrSize = size(ZFile,value);
           FFTzFile = matfile(fullfile(params.destination,[filePrefix,'zFFT.mat']),'Writable',true);
       end
       
       if ~isempty(strfind(params.proj,'inp'))
           InpFile = matfile(fullfile(params.source,[filePrefix,'inp.mat']));
           arrSize = size(InpFile,value);
           FFTinpFile = matfile(fullfile(params.destination,[filePrefix,'inpFFT.mat']),'Writable',true);
       end

       % fix for 2D systems
       % @TODO, probably, it does not work.
       if numel(arrSize) ==3
           arrSize(4) = 1;
       end    

              
       %% process chunk
       disp('FFT');

       if (numel(arrSize)==3)
           zStep = 1;
           chunkAmount = 1;
       elseif (params.chunk)
           zStep = 3;
           chunkAmount = ceil(arrSize(4)/zStep);
       else     
           zStep = arrSize(4);
           chunkAmount = 1;
       end
       
       %% create matrix of window function
       if params.windFunc
           windVec = hanning(arrSize(1),'periodic');
           windArr = repmat(windVec,[1 arrSize(2:3) zStep]);
       else
           windArr = [];
       end
       
       %% Process 2D systems
       if (arrSize(4)==1)
           if ~isempty(strfind(params.proj,'x'))
               disp('Mx');
               Mx = XFile.M(1:arrSize(1),1:arrSize(2),1:arrSize(3));
               FFTxFile.Y = fftshift(obj.calcFFT(Mx,MxStatic,windArr),1);
               clear Mx
           end
           
           if ~isempty(strfind(params.proj,'y'))
               disp('My');
               My = YFile.M(1:arrSize(1),1:arrSize(2),1:arrSize(3));
               FFTyFile.Y = fftshift(obj.calcFFT(My,MxStatic,windArr),1);
               clear My
           end
           
           if ~isempty(strfind(params.proj,'z'))
               disp('Mz');
               Mz = ZFile.M(1:arrSize(1),1:arrSize(2),1:arrSize(3));
               FFTzFile.Y = fftshift(obj.calcFFT(Mz,MzStatic,windArr),1);
               clear Mz
           end
           
           if ~isempty(strfind(params.proj,'inp'))
               disp('Minp');
               Minp = InpFile.M(1:arrSize(1),1:arrSize(2),1:500);
               FFTinpFile.Y(1:arrSize(1),1:arrSize(2),1:500) =...
                       fftshift(obj.calcFFT(Minp,[],windArr),1);
               Minp = InpFile.M(1:arrSize(1),1:arrSize(2),501:1000);
               FFTinpFile.Y(1:arrSize(1),1:arrSize(2),501:1000) =...
                       fftshift(obj.calcFFT(Minp,[],windArr),1);
               clear Minp
           end
           
       else
       
       for chunkInd = 1:chunkAmount
           zStart = (chunkInd-1)*zStep+1
           zEnd   = min(chunkInd*zStep,obj.znodes)
                     
           if ~isempty(strfind(params.proj,'x'))
               % process Mx projection
               disp('Mx');
               
               Mx = obj.getArrVariable(params.value,XFile,arrSize,zStart,zEnd);
               
               if params.background
                   tmp = obj.calcFFT(Mx,MxStatic(:,:,zStart:zEnd),windArr);
               else
                   tmp = obj.calcFFT(Mx,[],windArr);
               end    
               clear Mx
                
               obj.writeFFTfile(tmp, FFTxFile, zStart, zEnd);
               
           end
           
           if ~isempty(strfind(params.proj,'y'))
               % process My projection
               disp('My');
               My = obj.getArrVariable(params.value, YFile,arrSize,zStart,zEnd);
               
               tmp = obj.calcFFT(My,MyStatic(:,:,zStart:zEnd),windArr);
               clear My
               
               % write results of calculation to file
               disp('Write');
               
               obj.writeFFTfile(tmp, FFTyFile, zStart, zEnd);
               
           end
           
           if ~isempty(strfind(params.proj,'z'))
               % process Mz projection
               disp('Mz');               
               Mz = obj.getArrVariable(params.value, ZFile,arrSize,zStart,zEnd);
                              
               if params.background
                   tmp = obj.calcFFT(Mz,MzStatic(:,:,zStart:zEnd),windArr);
               else
                   tmp = obj.calcFFT(Mz,[],windArr);
               end    
               %clear Mz
               
               % write results of calculation to file               
               obj.writeFFTfile(tmp, FFTzFile, zStart, zEnd);
                  
           end
           
           if ~isempty(strfind(params.proj,'inp'))
               % process Minp projection
               disp('Minp');

               Minp = InpFile.M(1:arrSize(1),1:arrSize(2),1:arrSize(3),zStart:zEnd);
               tmp = obj.calcFFT(Minp,[],windArr);
               clear Minp
               
               % write results of calculation to file
               obj.writeFFTfile(tmp, FFTyFile, zStart, zEnd);
               
           end
       end
       end
       %obj.sendNote('OOMMF_sim','Method: make FFT. Status: finished.')
   end
  
   function plotYFreqMap(obj,varargin)
     % plot distribution of FFT intensity of Y component of magnetisation
     % in coordinates (Yaxis - Frequency)
     % parameters:
     %   - freqLimit is desired range of frequency 
     %   - xRange, yRange, zRange are border of interesting area
       
       p = inputParser;
       p.addParamValue('freqLimit',[0.1 20],@isnumeric);
       p.addParamValue('xRange',0,@isnumeric);
       p.addParamValue('yRange',0,@isnumeric);
       p.addParamValue('zRange',0,@isnumeric);
       p.addParamValue('scale','log',@(x) any(strcmp(x,{'log','norm'})));
       p.addParamValue('proj','z');
       p.addParamValue('saveAs','',@isstr);
       
       p.parse(varargin{:});
       params = p.Results;
       
       obj.getSimParams;
              
       YzFile = matfile('MzFFT.mat');
       arrSize = size(YzFile,'Yz');
       
       % process input parameters
       if (params.xRange == 0)
           params.xRange = [1 arrSize(2)];
       end
       
       if (params.yRange == 0)
           params.yRange = [1 arrSize(3)];
       end
       
       if (params.zRange == 0)
           params.zRange = [1 arrSize(4)];
       end
       
       freqScale = obj.getWaveScale(obj.dt,arrSize(1))/1e9; 
       [~,freqScaleInd(1)] = min(abs(freqScale-params.freqLimit(1)));
       [~,freqScaleInd(2)] = min(abs(freqScale-params.freqLimit(2)));
       freqScale = freqScale(freqScaleInd(1):freqScaleInd(2));
       
       yScale = linspace(obj.ymin,obj.ymax,obj.ynodes)/1e-6;
       
       
       Y = YzFile.Yz(freqScaleInd(1):freqScaleInd(2),...
                     params.xRange(1):params.xRange(2),...
                     params.yRange(1):params.yRange(2),...
                     params.zRange(1):params.zRange(2));
                 
       Amp = squeeze(mean(mean(abs(Y),4),2));
       
       if (strcmp(params.scale,'log'))
           Amp = log10(Amp/min(Amp(:))).';
       end    
       
       imagesc(freqScale,yScale,Amp);
       axis xy
       xlabel('Frequency (GHz)');   ylabel('y (\mum)');
       colormap(jet);
       
       t = colorbar('peer',gca);
       set(get(t,'ylabel'),'String', 'FFT intensity, dB');
       
       obj.savePlotAs(params.saveAs,gcf);       
   end    
      
   
  function res = plotFreqWaveSlice(obj,freq,k,varargin)
   % plot amplitude and phase of modes in (y,z) coordinates
   %for given frequency and k wave number
   % PARAMS
   %   freq - frequency of interest
   %    
   
       p = inputParser;
       % region of interest
       p.addRequired('freq',@isnumeric);
       p.addRequired('k',@isnumeric);
       p.addParamValue('direction','z',@(x)any(strcmp(x,obj.availableProjs)));
       p.addParamValue('proj','z',@(x)any(strcmp(x,obj.availableProjs)));
       
       % range of spatial limits
       p.addParamValue('xRange','',@isnumeric)
       p.addParamValue('yRange','',@isnumeric);
       p.addParamValue('zRange','',@isnumeric);
       
       % output params
       p.addParamValue('saveAs','',@isstr);
       
       p.parse(freq,k,varargin{:});
       
       % process input parameters
       params = p.Results;

       % load parameters of simulation
       obj.getSimParams;
       
       params.proj = lower(params.proj);
       params.direction = lower(params.direction);
       
       % process ranges
       if isempty(params.xRange)
           params.xRange = [1 obj.xnodes];
       end
       
       if isempty(params.yRange)
           params.yRange = [1 obj.ynodes];
       end
       
       if isempty(params.zRange)
           params.zRange = [1 obj.znodes];
       end
       
       % get required projection of magnetization
       if (strcmp(params.proj,'z'))
           FFTfile = matfile(fullfile(pwd,'MzFFT.mat'));
           arrSize = size(FFTfile,'Y');
       elseif (strcmp(params.proj,'y'))
           FFTfile = matfile(fullfile(pwd,'MyFFT.mat'));
           arrSize = size(FFTfile,'Y');
       elseif (strcmp(params.proj,'x'))
           FFTfile = matfile(fullfile(pwd,'MxFFT.mat'));
           arrSize = size(FFTfile,'Y');
       elseif (strcmp(params.proj,'inp'))
           FFTfile = matfile(fullfile(pwd,'MinpFFT.mat'));
           arrSize = size(FFTfile,'Yinp');    
       else
           disp('Unknown projection');
           return
       end
       
       freqScale = obj.getWaveScale(obj.dt,arrSize(1))/1e9;
       [~,freqInd] = min(abs(freqScale - params.freq));
              
       % select required region of FFT file
       
           Yt = squeeze(FFTfile.Y(freqInd,...
               params.xRange(1):params.xRange(2),...
               params.yRange(1):params.yRange(2),...
               params.zRange(1):params.zRange(2)));
 
       
       % perform FFT along desired spatial direction
       if (strcmp(params.direction,'x'))
           % calculate wave scale
           kScale = 2*pi*obj.getWaveScale(obj.xstepsize*1e6,arrSize(2)); 
           [~,kInd] = min(abs(kScale - params.k));
           
           % calculate FFT along spatial direction and find required slice 
           Yts = fft(Yt,[],1);
           Yts = fftshift(Yts,1);     
           YtsSlice = squeeze(Yts(kInd,:,:));
           
           % axis labels
           axis1Label = 'Y (\mum)';
           axis2Label = 'X (\mum)';
           
           % axis scale
           axis2Scale = linspace(params.yRange(1)*obj.ystepsize,...
                                 params.yRange(2)*obj.ystepsize,...
                                 params.yRange(2)-params.yRange(1)+1)/1e-6;
                             
           axis1Scale = linspace(params.zRange(1)*obj.zstepsize,...
                                 params.zRange(2)*obj.zstepsize,...
                                 params.zRange(2)-params.zRange(1)+1)/1e-6;
       elseif (strcmp(params.direction,'y'))
           kScale = 2*pi*obj.getWaveScale(obj.ystepsize*1e6,arrSize(3)); 
           [~,kInd] = min(abs(kScale - params.k));
           
           Yts = fft(Yt,[],2);
           Yts = fftshift(Yts,2);     
           YtsSlice = squeeze(Yts(:,kInd,:));
           
           axis1Label = 'X';
           axis2Label = 'Z';
       elseif (strcmp(params.direction,'z'))
           % calculate wave scale
           kScale = 2*pi*obj.getWaveScale(obj.zstepsize*1e6,arrSize(4)); 
           [~,kInd] = min(abs(kScale - params.k));
           
           % calculate FFT along spatial direction and find required slice 
           Yts = fft(Yt,[],3);
           Yts = fftshift(Yts,3);     
           YtsSlice = squeeze(Yts(:,:,kInd));
           
           % axis labels
           axis1Label = 'Y (\mum)';
           axis2Label = 'X (\mum)';
           
           % axis scale
           axis1Scale = linspace(params.xRange(1)*obj.xstepsize,...
                                 params.xRange(2)*obj.xstepsize,...
                                 params.xRange(2)-params.xRange(1)+1)/1e-6;
                             
           axis2Scale = linspace(params.yRange(1)*obj.ystepsize,...
                                 params.yRange(2)*obj.ystepsize,...
                                 params.yRange(2)-params.yRange(1)+1)/1e-6;                  
       else
           disp('Unknown direction');
           return
       end    
       
       
       % plot results
       Amp = abs(YtsSlice);
       Amp = log10(Amp/min(nonzeros(Amp(:))));
       Phase = angle(YtsSlice);
       
       fig1 = figure(1);
           imagesc(axis2Scale,axis1Scale,Amp.',[0 max(Amp(:))]);
           axis xy
           xlabel(axis2Label); ylabel(axis1Label);
           obj.setDbColorbar('');
           colormap(flipud(gray));
           title(['\nu = ',num2str(params.freq),' GHz, k = ',num2str(params.k),...
               '\mum, M_',params.proj,' projection'],'FontSize',14,'FontName','Times');

        fig2 = figure(2);
           imagesc(axis2Scale,axis1Scale,Phase.',[-pi pi]);
           axis xy
           xlabel(axis2Label); ylabel(axis1Label);
           colorbar('EastOutside');
           colormap(hsv);
           title(['\nu = ',num2str(params.freq),' GHz, k = ',num2str(params.k),...
               '\mum, M_',params.proj,' projection'],'FontSize',14,'FontName','Times');
           
      %fig2 = figure(2);
      %    meanAmp = mean(Amp,1);
      %    meanPhase = mean(Phase,1);
      %    res = meanAmp;
      %    subplot(211);
      %        plot(axis2Scale,meanAmp);
      %         title(['\nu = ',num2str(params.freq),' GHz, k = ',num2str(params.k),...
      %             '\mum, M_',params.proj,' projection'],'FontSize',14,'FontName','Times');
      %        xlabel(axis2Label); ylabel('Amplitude (arb. u.)')

            
      %    subplot(212);
      %        meanPhase(find(meanPhase<0)) = meanPhase(find(meanPhase<0))+2*pi;
      %        plot(axis2Scale,meanPhase);
      %        xlabel(axis2Label); ylabel('Phase (rad)');
      %
      
      %fig3 = figure(3);
      %    x = Amp(1,:).*cos(Phase(1,:)); 
      %    y = Amp(1,:).*sin(Phase(1,:)); 

      %    subplot(211);
      %        plot(axis2Scale,x);
      %        xlabel(axis1Label); ylabel('Amplitude (arb. u.)');
      %    subplot(212);
      %        plot(axis2Scale,y);
      %        xlabel(axis1Label); ylabel('Amplitude (arb. u.)');
              
      %    save branch4.mat Amp Phase    

       % save img
       if (~strcmp(params.saveAs,''))
           fName = strcat(params.saveAs,'_f',num2str(params.freq),'GHz_k',...
               num2str(params.k),'mum_M',params.proj);
           
           obj.savePlotAs(strcat(fName,'-amp'),fig1);
           obj.savePlotAs(strcat(fName,'-phase'),fig2);
       end    
       
  end
   
   %% calculate out-of-plane and in-plane components of dynamical magnetization
   % params :
   %     normalAxis - direction of out-of-plane components
   %
   function calcDynamicComponents(obj,varargin)
       
       p = inputParser;
       p.addParamValue('normalAxis','z',@(a) any(strcmp(a,obj.availableProjs)));
       p.addParamValue('xRange',0,@isnumeric);
       p.addParamValue('yRange',0,@isnumeric);
       p.addParamValue('zRange',0,@isnumeric);
       p.parse(varargin{:});
       params = p.Results;

       params.normalAxis = lower(params.normalAxis);
       
       % load file of parameters
       obj.getSimParams;
       
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
       
       switch params.normalAxis
           case 'z'
               InpX = zeros(obj.xnodes,obj.ynodes,obj.znodes);
               InpY = zeros(obj.xnodes,obj.ynodes,obj.znodes);
               
               InpX = sqrt((MyStatic.^2)./(MxStatic.^2+MyStatic.^2));
               InpY = sqrt((MxStatic.^2)./(MxStatic.^2+MyStatic.^2));
               % calculate coordinates of normal plane for every points
               
               % load magnetization
               MxFile = matfile(obj.MxName);
               MyFile = matfile(obj.MyName);
               MzFile = matfile(obj.MzName);
               mFile = matfile('Minp.mat','Writable',true);
               timeFrames = size(MxFile,'M',1);
               
               chunckSize = 128;
               for timeId = 1:chunckSize:timeFrames
                   % loop along chunks
                   timeStart = timeId;
                   timeEnd = min(timeId+chunckSize-1,timeFrames);
                   timeRange = (timeStart:timeEnd).';
                   
                   disp('read');
                   Mx = MxFile.M(timeRange,params.xRange,params.yRange,params.zRange);
                   My = MyFile.M(timeRange,params.xRange,params.yRange,params.zRange);
                   % initialize array of in-plane magnetization
                   Minp = zeros(size(timeRange,1),obj.xnodes,obj.ynodes,obj.znodes);
                   
                   disp('parfor')
                   parfor timeStep = 1:size(timeRange,1)
                       disp(timeStep+timeStart);
                       Minp(timeStep,:,:,:) = ...
                           squeeze(Mx(timeStep,:,:,:)).*InpX+...
                           squeeze(My(timeStep,:,:,:)).*InpY;
                   end
                   
                   disp('save')
                   if (size(Minp,4) >1)
                       mFile.M(timeRange,params.xRange,params.yRange,params.zRange) = Minp;
                   else
                       mFile.M(timeRange,params.xRange,params.yRange) = Minp;
                   end    
               end
       end
         
   end 
   
   %% Interpolation of time dependence
   function interpTimeDependence(obj, varargin)
       % Interpolatation of time dependences for non-regular time step
       
       % read input patameters
       p = inputParser;
       p.addParamValue('tableFile','table.txt',@isstr);
       p.addParamValue('value','M',@(x) any(strcmp(x,{'M','H'})));
       p.parse(varargin{:});
       params = p.Results;
       
       obj.getSimParams();
       
       tableData=[];
       % read tableFile, get time scale
       try
           table = importdata(params.tableFile)
           tableData = table.data;
       catch err
           disp(err.message);
           return
       end
       
       % load projection of magnetisation
       timeScaleOld = tableData(:,1); % original time scale
       timeScaleNew = linspace(timeScaleOld(1),timeScaleOld(end),size(timeScaleOld,1)).';
       %parpool(8);
       
       % interpolate
       switch params.value
           case 'M' 
               %obj.interpArray(matfile('Mz.mat'), matfile('MzInterp.mat'), timeScaleOld, timeScaleNew);
               obj.interpArray(matfile('Minp.mat'), matfile('MinpInterp.mat'), timeScaleOld, timeScaleNew);
               %obj.interpArray(matfile('Mx.mat'), matfile('MxInterp.mat'), 'Mz', timeScaleOld, timeScaleNew);
               %obj.interpArray(matfile('My.mat'), matfile('MyInterp.mat'), 'Mz', timeScaleOld, timeScaleNew);
           case 'H'
               MFile = matfile('Hx.mat');
               OutMFile = matfile('HxInterp.mat');
               OutMFile.Mx = obj.interpArray(MFile.Hx, timeScaleOld, timeScaleNew)
               
               MFile = matfile('Hy.mat');
               OutMFile = matfile('HyInterp.mat');
               OutMFile.My = obj.interpArray(MFile.Hy, timeScaleOld, timeScaleNew)
               
               MFile = matfile('Hz.mat');
               OutMFile = matfile('HzInterp.mat');
               OutMFile.Mz = obj.interpArrayPar(MFile.Hz, timeScaleOld, timeScaleNew)
           otherwise
               disp('Unknown physical value');
       end
       
   end
   
   %% Plot surface of magnetizaion amplitude in coordinate-time axes
   % Useful for visualization of propagation of spin waves
   % Params:
   %     zSlice - number of XY plane for which we look on
   %     
   %     startTime - first time point to display (ns)
   function plotWaveSurf(obj,varargin)
       % read input patameters
       
       p = inputParser;
       p.addParamValue('zSlice',1,@isnumeric);
       p.addParamValue('ySlice',1,@isnumeric);
       p.addParamValue('limit',0,@isnumeric);
       p.addParamValue('saveAs','',@isstr);
       p.addParamValue('startTime',0,@isnumeric);
       
       p.parse(varargin{:});      
       params = p.Results;
       
       obj.getSimParams();
       
       timeInd = ceil(params.startTime*(1e-9)/obj.dt);
       
       if (timeInd == 0)
           timeInd = 1;
       end    
       
       MFile = matfile('Mz.mat');
       data = MFile.M(timeInd:end,:,params.ySlice,params.zSlice);
       xScale = linspace(obj.xmin,obj.xmax,obj.xnodes)/1e-6;
       timeScale = linspace(obj.dt*timeInd,obj.dt*(size(data,1)+timeInd),size(data,1))/1e-9;
       
       if params.limit ==0
           params.limit = max(abs(data(:)));
       end
       
       imagesc(xScale,timeScale,data,[-params.limit params.limit]);
       set(gca,'FontName','Times','FontSize',16,'FontWeight','bold');
       colormap(jet); colorbar();
       axis xy
       xlabel('X (\mum)'); ylabel('Time (ns)')
       
        obj.savePlotAs(params.saveAs,gcf);
   end
   
   %% plot slice of magnetization along OX axis and spatial FFT  
   % params:
   %     ySlice    - number of slice along OY axis
   %     zSlice    - number of slice along OZ axis
   %     timeFrame - number of time frame
   %     saveAs    - name of output graphical files
   function plotLinSlice(obj,varargin)
       p = inputParser;
       
       p.addParamValue('ySlice',[10 20],@isnumeric);
       p.addParamValue('zSlice',1,@isnumeric);
       p.addParamValue('timeFrame',984,@isnumeric);
       p.addParamValue('saveAs','',@isstr);
       p.addParamValue('saveMatAs','',@isstr);
       p.addParamValue('baseline',true,@islogical);
       p.addParamValue('complex',false,@islogical);
       
       % experimental parameters
       spotSize = 400e-9; % nm
       halfT = 2; % half period of oscillations (in timeFrames)
       
       p.parse(varargin{:});      
       params = p.Results;      
       obj.getSimParams();
       
       mFile = matfile('Mz');
       M1 = squeeze(mFile.M(params.timeFrame,:,params.ySlice(1):params.ySlice(2),params.zSlice)-...
                     mFile.M(1,:,params.ySlice(1):params.ySlice(2),params.zSlice));
                 
       M2 = squeeze(mFile.M(params.timeFrame-halfT,:,params.ySlice(1):params.ySlice(2),params.zSlice)-...
                     mFile.M(1,:,params.ySlice(1):params.ySlice(2),params.zSlice));
       
       % subtract baseline
       if params.baseline
           M1 = M1 - mean(M1(:));
           M2 = M2 - mean(M2(:));
       end    
       
       % Gauss window along OY axis
       gaussWidth = floor(spotSize/obj.ystepsize);
       w1= window(@gausswin,gaussWidth);
       w1 = w1/sum(w1); % normalize window function
       for xInd = 1:size(M1,1)
           M1(xInd,:) = conv(M1(xInd,:),w1,'same');
           M2(xInd,:) = conv(M2(xInd,:),w1,'same');
       end    
       M1 = mean(M1,2);
       M2 = mean(M2,2);
       
       % Gauss window along OX axis
       gaussWidth = floor(spotSize/obj.xstepsize);
       w2= window(@gausswin,gaussWidth);
       w2 = w2/sum(w2);  % normalize window function
       M1 = conv(M1,w2,'same');
       M2 = conv(M2,w2,'same');
              
       % Gauss window along OX axis
       gaussWidth = floor(spotSize/obj.xstepsize);
       w2= window(@gausswin,gaussWidth);
       w2 = w2/sum(w2);
       M1 = conv(M1,w2,'same');
       M2 = conv(M2,w2,'same');
       
       xScale = linspace(obj.xmin,obj.xmax,obj.xnodes)/1e-6;     
       kScale = obj.getWaveScale(obj.xstepsize,obj.xnodes)*1e-6;
       
       amp1 = abs(fftshift(fft(M1(:))));
       amp2 = abs(fftshift(fft(M2(:))));
       % plot results
       
       kMax = 2;
       if params.complex
           MComplex = M1 + j*M2;
           ampComplex = abs(fftshift(fft(MComplex(:))));
           subplot(3, 1, 1);
               plot(xScale,M1,'-r',xScale,M2,'-g','LineWidth',1);
               xlabel('x (\mum)','FontSize',14,'FontName','Times','FontWeight','bold');
               ylabel('M_z (A/m)','FontName','Times','FontWeight','bold')
               xlim([min(xScale) max(xScale)]);
               
               minM = min(min(M1), min(M2));
               maxM = max(max(M1), max(M2));
               ylim([minM, maxM]);               
               legend('M(t)','M(t-T/2)','location','South');
               

           subplot(3, 1, 2:3);
               plot(kScale,amp1,'-r',kScale,amp2,'-g',kScale,ampComplex,'-b','LineWidth',1.5);
               xlim([-kMax kMax]);
               xlabel('k (\mum ^-^1)','FontSize',14,'FontName','Times','FontWeight','bold')
               ylabel('FFT intensity (arb. u.)','FontSize',14,'FontName','Times','FontWeight','bold')
               legend('M(t)','M(t-T/2)','M(t)+j*M(t-T/2)');
       else
           subplot(2, 1, 1);
               plot(xScale,[M1,M2]);
               xlabel('x (\mum)','FontSize',14,'FontName','Times','FontWeight','bold');
               ylabel('M_z (A/m)','FontName','Times','FontWeight','bold')
               xlim([min(xScale) max(xScale)]);
           
           subplot(2, 1, 2);
               plot(2*pi*kScale,[amp1,amp2]);
               xlim([0 kMax]);
               xlabel('k (rad/\mum)','FontSize',14,'FontName','Times','FontWeight','bold')
               ylabel('FFT intensity (arb. u.)','FontSize',14,'FontName','Times','FontWeight','bold')
       end
               
       obj.savePlotAs(params.saveAs,gcf);
       
       % save data to mat file
       if (~strcmp(params.saveMatAs,''))
           fName = strcat(params.saveMatAs,'.mat');
           save(fName,'xScale','M','kScale','amp'); 
       end
       
   end    
       
   
   function convertFormat(obj)
       
       if (exist('Mz.mat'))
           mfile = matfile('Mz.mat','Writable',true);
           mfile.M = mfile.Mz;
           mfile.Mz = [];
       end
       
       if (exist('My.mat'))
           mfile = matfile('My.mat','Writable',true);
           mfile.M = mfile.My;
           mfile.My = [];
       end
       
       if (exist('Mx.mat'))
           mfile = matfile('Mx.mat','Writable',true);
           mfile.M = mfile.Mx;
           mfile.Mx = [];
       end
       
   end
   
   % return OX scale
   function res = getXScale(obj)
       res = linspace(obj.xmin,obj.xmax,obj.xnodes); 
   end 
   
   %return OY scale 
   function res = getYScale(obj)
       res = linspace(obj.ymin,obj.ymax,obj.ynodes); 
   end
   
   %return OZ scale
   function res = getZScale(obj)
       res = linspace(obj.zmin,obj.zmax,obj.znodes); 
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
   function setDbColorbar(obj,text)
       t = colorbar('peer',gca);
       if isempty(text)
           text = 'Spectral density (dB)';
       end   
       set(get(t,'ylabel'),'String',text,'FontSize',16,'FontName','Times');
   end
   
   %% read file of parameters
   % return parameters of simulation
   % should be protected
   function res = getSimParams(obj)
       tmp2 = load(fullfile(obj.folder,obj.paramsFile));
       tmp = tmp2.obj;
       % make a normal rewritting of parameters
       propList = properties('OOMMF_sim');
       for propInd = 1:size(propList,1)
           propName = propList(propInd);
           set(obj,propName,get(tmp,propName));
       end    
   end
   
   %% read file of static magnetization
   % return three arrays [Mx,My,Mz]
   function [Mx,My,Mz] = getStatic(obj,folder)
       if (exist(fullfile(folder,obj.staticFile),'file') ~= 2)
           disp('No background file has been found');
           return
       else 
           obj.fName = obj.staticFile;
           [Mx,My,Mz] = obj.loadMagnetisation('fileExt','stc');
       end
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
     
    %scan folder %path% and select all %ext% files
   function fList = getFilesList(obj,path,fileBase,ext)
     if (isdir(path))
       if length(fileBase)  
           fList = dir(strcat(path,filesep,fileBase,'*.',ext));
       else
           pth = strcat(path,filesep,'*.',ext);
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
   
   % interpolate array along 1st dimension
   %    inpArr - input file 4D array
   %    outArr - output file 4D array
   %    oldScale - original scale of sampling
   %    newScale - new scale of sampling
   
   function interpArray(obj,inpArr,outArr,oldScale, newScale)
       tmp = zeros(obj.xnodes*obj.znodes,size(oldScale,1));
       outArr.M = single.empty(0,0,0,0);
       
       for yInd = 1:obj.ynodes
           inpData3 = reshape(shiftdim(inpArr.M(:,:,yInd,:),1),...
               [obj.xnodes*obj.znodes, size(oldScale,1)]);
           
           parfor ind = 1:size(inpData3,1)
               tmp(ind,:) = cast(interp1(oldScale,...
                       squeeze(inpData3(ind,:)),newScale),'single');
           end
           
           tmp2 = reshape(tmp,[obj.xnodes,1,obj.znodes,size(oldScale,1)]);
           outArr.M(1:size(oldScale,1),1:obj.xnodes,yInd,1:obj.znodes) = shiftdim(tmp2,3); 
       end    

   end   
   
   % save current plot
   function savePlotAs(obj,varargin)
       p = inputParser;
       p.addRequired('fName',@isstr);
       p.addRequired('handle');
       p.addParameter('suffix','',@isstr);
       
       p.parse(varargin{:});      
       params = p.Results;
       
       if (~strcmp(params.fName,''))
           savefig(params.handle,strcat(params.fName,params.suffix,'.fig'));
           print(params.handle,'-dpng',strcat(params.fName,params.suffix,'.png'));
       end
   end 
   
   % return available memory
   % function developed for platform compatibility
   function mem = getMemory(obj)
       platform = computer();
       switch platform
           
           case 'GLNXA64'
               [~,meminfo] = system('cat /proc/meminfo');
               [tokens] = regexp(meminfo,'MemFree:\s*(\d+)\s','tokens');
               mem = str2double(tokens{1}{1})*1e3;
           
           case 'PCWIN64'
               tmp = memory;
               mem = tmp.MaxPossibleArrayBytes;
           otherwise
               mem = 1e3;
               disp('Unknown platform. Please, fix the bag');
       end    
               
   end 
   
   % calculate FFT along first dimension of the input array
   % parameters:
   %     arr - input array
   %     background - static configuration 
   %     wind - array of window function
   function res = calcFFT(obj,input,background,window)
       % subtract background
       if ~isempty(background)
           disp('Substract background');
           for timeInd = 1:size(input,1)
               k = input(timeInd,:,:,:);
               kSz = size(k);
               input(timeInd,:,:,:) = reshape(k,kSz(2:end)) - background;
           end
       end
       
       % calculate FFT
       disp('FFT');
       if ~isempty(window)
           res = fft(input.*window,[],1);
       else
           res = fft(input,[],1);
       end
   end
   
   % Return array from mat file 
   %  params:  
   %    value - "M" or "H"
   %    fileHandler - handler of file to read from
   %    arrSize     - size of array to read which
   %    zStart, zEnd  - initial and final coordinate of the array to read 
   function res = getArrVariable(obj,value, fileHandler,arrSize,zStart,zEnd)
       switch value
           case 'M'
               res = fileHandler.M(1:arrSize(1),1:arrSize(2),1:arrSize(3),zStart:zEnd);
           case 'H'
               res = fileHandler.H(1:arrSize(1),1:arrSize(2),1:arrSize(3),zStart:zEnd);
           case 'Heff'
               res = fileHandler.H(1:arrSize(1),1:arrSize(2),1:arrSize(3),zStart:zEnd);
           case 'Hdemag'
               res = fileHandler.H(1:arrSize(1),1:arrSize(2),1:arrSize(3),zStart:zEnd);
       end
   end
   
   % Write results of FFT transformation to mat file.
   % The function was written to replace build-in "fftshift" function
   %   Params:
   %     data - array to save
   %     fileHandler - handler of the file to save in
   %     zStart,zEnd - initial and final coordinate along OZ axis
   function writeFFTfile(obj, data, fileHandler, zStart, zEnd)
       disp('Save FFT to file')
       arrSize = size(data);
       if mod(arrSize(1),2) % odd amount of frequency bins
           c = data((ceil(0.5*arrSize(1))+1):arrSize(1),1:arrSize(2),1:arrSize(3),:);
           % FIX: if array is empty, it should be complex empty array
           if (zStart ==1) && ~any(nonzeros(c))
               fileHandler.Y(1:floor(0.5*arrSize(1)),1:arrSize(2),1:arrSize(3),zStart:zEnd) = complex(c);
           else
               fileHandler.Y(1:floor(0.5*arrSize(1)),1:arrSize(2),1:arrSize(3),zStart:zEnd) = c;
           end
           fileHandler.Y(ceil(0.5*arrSize(1)):arrSize(1),1:arrSize(2),1:arrSize(3),zStart:zEnd) =...
               data(1:ceil(0.5*arrSize(1)),1:arrSize(2),1:arrSize(3),:);
           
       else % even amount of frequency bins
           c = data((0.5*arrSize(1)+1):arrSize(1),1:arrSize(2),1:arrSize(3),:);
           % FIX: if array is empty, it should be complex empty array
           if (zStart ==1) && ~any(nonzeros(c))
               fileHandler.Y(1:0.5*arrSize(1),1:arrSize(2),1:arrSize(3),zStart:zEnd) = complex(c);
           else
               fileHandler.Y(1:0.5*arrSize(1),1:arrSize(2),1:arrSize(3),zStart:zEnd) = c;
           end
           fileHandler.Y((0.5*arrSize(1)+1):arrSize(1),1:arrSize(2),1:arrSize(3),zStart:zEnd) = ...
               data(1:0.5*arrSize(1),1:arrSize(2),1:arrSize(3),:);
       end
   end    
   
  
 % END OF PRIVATE METHODS
 end
 
 %%Static Methods 
 methods(Static)
     
     function sendNote(title,msg)
       try
           fid = fopen('api.key');
           APIkey = fgetl(fid);
           fclose(fid);
       catch Err
           error('sendNote:openFile','Can not open file')
       end
       
       p = Pushbullet(APIkey);
       p.pushNote([],title,msg)
   end
 end
 % End of static methods 
 
 % END OF CLASS
end

% Class for processing results of OOMMF simulations 
classdef OOMMF_result < hgsetget % subclass hgsetget
 
 properties
   fName = 'fname'; % name of file(-s), which contains results
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
   Mraw
   H
   totalSimTime % total simulation time
   iteration
   memLogFile = 'log.txt';
 end
 
 methods
   function obj = OOMMF_result()
         disp('OOMMF_result object was created');
   end
   
   function loadMFile(obj,varargin)
       %% open file and check errors
     fName = strcat(obj.fName,'.omf'); 
     fid = fopen(fName);
     if ((fid == -1))
       disp('File not found');
       return;
     end
     
     p = inputParser;
     p.addParamValue('showMemory',false,@islogical);
     p.parse(varargin{:});
     params = p.Results;
     
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
    Mraw = reshape(data,[obj.dim obj.znodes*obj.ynodes*obj.xnodes]);
    Mraw = permute(Mraw,[2 1]); % <-- fine
    obj.Mraw = reshape(Mraw, [obj.xnodes, obj.ynodes, obj.znodes, obj.dim]);
    data =[];
    Mraw = [];
    if (params.showMemory)
      disp('Memory used:');
      memory
    end  
    disp('OMF file has been read. Size of data array is:')
    disp(size(obj.Mraw));
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
   function handler = plotMSurfXY(obj,slice,proj,varargin)
     p = inputParser;
     p.addRequired('slice',@isnumeric);
     p.addRequired('proj',@ischar);
     
     p.addParamValue('saveImg',false,@islogical);
     p.addParamValue('saveImgPath','');
     p.addParamValue('colourRange',0,@isnumerical);
     p.addParamValue('showScale',true,@islogical);
     
     p.parse(slice,proj,varargin{:});
     params = p.Results;
       
     handler = obj.abstractPlot('Z',params.slice,params.proj,...
         'saveImg',params.saveImg,'saveImgPath',params.saveImgPath,...
         'colourRange',params.colourRange,'showScale',params.showScale);                  
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
     p.addParamValue('colourRange',0,@isnumerical);
     p.addParamValue('showScale',true,@islogical);
     
     p.parse(slice,proj,varargin{:});
     params = p.Results;
       
     handler = obj.abstractPlot('X',params.slice,params.proj,...
         'saveImg',params.saveImg,'saveImgPath',params.saveImgPath,...
         'colourRange',params.colourRange,'showScale',params.showScale); 
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
              
    data = obj.getSlice(params.viewAxis,params.slice,params.proj);
     
    if (params.colourRange == 0)
	   maxM = max(max(data(:)),abs(min(data(:))));
       base = fix(log10(maxM));
       t1 = ceil(maxM/(10^base));
       t2 = 10^(base-2);
       params.colourRange = t1*t2;
    
       if (isnan(params.colourRange))
         params.colourRange = 100;
         disp('Colour range is undefined');
       end
    else
         
    end
    
    G = fspecial('gaussian',[9 9],0.2);
    Ig = imfilter(data,G,'circular','same','conv');
	handler = imagesc(Ig);
	axis xy;
    colormap(b2r(-params.colourRange,params.colourRange));
	hcb=colorbar('EastOutside');
	set(hcb,'XTick',[-params.colourRange,0,params.colourRange])
    
    if (params.showScale)
     % axis([eval(strcat('obj.',lower(axis1),'min')),...
     %       eval(strcat('obj.',lower(axis1),'max')),...
     %       eval(strcat('obj.',lower(axis2),'min')),...
     %       eval(strcat('obj.',lower(axis2),'max'))]);
      xlabel(strcat(axis1,'(\mum)'), 'FontSize', 10);
      ylabel(strcat(axis2,' (\mum)'), 'FontSize', 10);
    else
      axis([0,size(data,2),0,size(data,1)]);
      xlabel(strcat(axis1,'(cell #)'), 'FontSize', 10);
      ylabel(strcat(axis2,' (cell #)'), 'FontSize', 10);
    end    
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
                  
	set(hcb,'FontSize', 15);
    title(strcat('view along ',viewAxis,' axis, M',params.proj,' projection',...
                  ', simulation time = ',num2str(obj.totalSimTime,'%10.2e'),' s'));
    if (params.saveImg)
      imgName = strcat(params.saveImgPath,'\',...
                       'Image_Along',viewAxis,...
                       '_Slice',num2str(slice),...
                       '_M',symb(proj),...
                       '_iter',num2str(obj.iteration),...
                       '.png');
	  saveas(handler, imgName);
    end   
    clear data;
   end
   
   % scan folder, load all *.omf files, save objects and images
   % path - path to the folder
   % projs - array of projections of magnetisation, string: "X", "Y", "Z"
   % or "XY", "XYZ" etc.
   % saveObj - save an objects?
   % savePath - path to save objects 
   function scanMFolder(obj,path,projStr,varargin)
            
     fList = getFilesList(path,'omf'); 
     expr = '([xX]?)([Yy]?)([Zz]?)';
     tokenStr = regexp(projStr,expr,'tokens');
     
     % parse input parameters
     p = inputParser;
     p.addRequired('path',@ischar);
     p.addRequired('projStr',@ischar);
     p.addParamValue('deleteFiles', @islogical);
     p.addParamValue('saveObj',false,@islogical);
     p.addParamValue('savePath','');
     p.addParamValue('showMemory',false,@islogical);
     p.addParamValue('makeMovie',false,@islogical);
     
     p.parse(path,projStr,varargin{:});
     params = p.Results;
     
     if (params.makeMovie)
         aviobj = avifile('movie.avi','compression','None','fps',5);
         Frames = [];
     end
     
     for i=1:size(fList,1)
       file = fList(i);
       [~, fName, ~, ~] = fileparts(file.name);
       pt = strcat(path,'\',fName);
       obj.fName = pt;
       obj.loadMFile('showMemory',params.showMemory);
       
       if (params.deleteFiles)
           delete(strcat(pt,'.omf'));
       end    
      
       % plot images
       if (size(tokenStr,1) == 1 && size(tokenStr,2)==1)
         toks = tokenStr{1,1};  
         if (length(toks{1,1}) == 1)    
           obj.plotMSurfXY(1,1,true);
           Frames(end+1) = getframe(gcf);
         end
         if (length(toks{1,2}) == 1)
           obj.plotMSurfXY(1,2,true);
           Frames(end+1) = getframe(gcf);
         end
         if (length(toks{1,3}) == 1)
           obj.plotMSurfXY(1,3,true);
           Frames(end+1) = getframe(gcf);
         end
       end
       
       % save object
       if (params.saveObj)
         fNameObj = strcat(params.savePath,fName,'.mat');   
         save(fNameObj, 'obj');   
       end
              
     end
     
     if (params.makeMovie)
       movie2avi(Frames, strcat(params.savePath,'\','spinWaves.avi'))
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
 
   %scan folder %path% and select all %ext% files
   function fList = getFilesList(obj,path,ext)
     if (isdir(path))   
       fList = dir(strcat(path,'\*.',ext));
     else
       disp('Incorrect folder path');
       return;
     end
     
     if (size(fList,1) == 0)
       disp('No suitable files');
       return;
     end
   end
   
   function res = getVolume(obj,xrange,yrange,zrange,proj)
     res = obj.Mraw(xrange,yrange,zrange,obj.getIndex(proj));  
   end    
 
 end
end    

 
 
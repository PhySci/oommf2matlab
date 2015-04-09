function res = collectSliceData(path,rangeX,rangeY,rangeZ,varargin)
 % collectSliceData(path,rangeX,rangeY,rangeZ,varargin) collect data from *mat files located in directory "path"
 % rangeX, rangeY, rangeZ are required parameters.
 % "proj" is projection of magnetisation. Allowed value is {X,Y,Z}
 % "showMemory" is logical value
 % "save" - save results as an object
 % "savePath" - path to save object
 % "extractStatic" & "staticDataFile" are variables for substraction of
 % background magnetisation 
 
 p = inputParser;
 p.addRequired('path',@isdir);
 p.addRequired('rangeX',@isnumeric);
 p.addRequired('rangeY',@isnumeric);
 p.addRequired('rangeZ',@isnumeric);


 p.addParamValue('proj', ':',@(x)any(strcmp(x,{'X','Y','Z',':'})));
 p.addParamValue('showMemory',false,@islogical);
 
 p.addParamValue('save',false,@islogical);
 p.addParamValue('savePath','.',@isdir)

 p.addParamValue('extractStatic',false,@islogical);
 p.addParamValue('staticDataFile','');

 p.parse(path,rangeX,rangeY,rangeZ,varargin{:});
 params = p.Results;

  % prepare data for extracting of static magnetisation
 if (params.extractStatic)
   tmp = load(params.staticDataFile);
   staticDataObj = tmp.omf;
   staticData = staticDataObj.getVolume(params.rangeX,params.rangeY,...
                      params.rangeZ,':');
 end


 obj = OOMMF_result;
 params.proj = obj.getIndex(params.proj);

 fList = obj.getFilesList(path,'mat');
 res = zeros(size(fList,1),...
                  size(params.rangeX,2),...
                  size(params.rangeY,2),...
                  size(params.rangeZ,2),3);
 
 % scan folder             
 for i=1:size(fList,1)
   disp(i);
   fPath = strcat(path,'\',fList(i).name);
   if (strcmp(fPath,params.staticDataFile))
       continue;
   end    
   space = load(fPath);
   obj = space.obj;
   tmp = obj.getVolume(params.rangeX,params.rangeY,...
                      params.rangeZ,':');
   if (params.extractStatic)
     res(i,:,:,:,:) = tmp-staticData;
   else
     res(i,:,:,:,:) = tmp;  
   end    

 end

 if (params.save)
   path = strcat(params.savePath,'collectData.mat');   
   save(path, 'res', 'params');  
 end    

end 
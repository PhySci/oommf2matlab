function FullFFT(path,varargin)
% full FFT transformation of results of micromagnetic simulation
% path is path to OOMMF results, converted to *.mat files
% What parameters would be required?
% substraction of background

    p = inputParser;
    p.addRequired('path',@isdir);
    p.addParamValue('fileBase','',@isstr)
    
    p.parse(path,varargin{:});
    params = p.Results;
    
    
    obj = OOMMF_result;   
    fList = obj.getFilesList(path,params.fileBase,'mat');
    
    % determine size of arrays
    tmp = load(strcat(path,'\',fList(1).name));
    obj = tmp.obj;
    
    %MxArr = zeros(size(fList,1),obj.xnodes,obj.ynodes,obj.znodes);
    %MyArr = zeros(size(fList,1),obj.xnodes,obj.ynodes,obj.znodes);
    %MzArr = zeros(size(fList,1),obj.xnodes,obj.ynodes,obj.znodes);
    
    %MxArr(1,:,:,:) = obj.Mraw(:,:,:,1); 
    %MyArr(1,:,:,:) = obj.Mraw(:,:,:,2);
    %MzArr(1,:,:,:) = obj.Mraw(:,:,:,3);
    
    %for fInd = 2:size(fList,1)
    %    fPath = strcat(path,'\',fList(fInd).name);
    %    tmp = load(fPath);
    %    MxArr(fInd,:,:,:) = tmp.obj.Mraw(:,:,:,1); 
    %    MyArr(fInd,:,:,:) = tmp.obj.Mraw(:,:,:,2);
    %    MzArr(fInd,:,:,:) = tmp.obj.Mraw(:,:,:,3);
    %    disp(fInd);
    %end
    %disp('All files have been loaded');
    %save res.mat MxArr MyArr MzArr
    load res.mat
    
    disp('Start Mx FFT');
    Yx = fft(MxArr);
    disp('Save Mx FFT');
    save YxFFT.mat Yx
    Yx=[];
    MxArr = [];

    disp('Start My FFT');
    Yy = fft(MyArr);
    disp('Save My FFT');
    save YyFFT.mat Yy
    Yy=[];
    MyArr = [];
    
    disp('Start Mz FFT');
    Yz = fft(MzArr);
    disp('Save Mz FFT');
    save YzFFT.mat Yz
    Yz=[];
    MzArr = [];
    
end
        
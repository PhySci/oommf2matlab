%% Scan folder, search objects, plot Z projection of magnetisation
% make a movie
function makeMovie(varargin)

  p = inputParser;
  p.addParamValue('path','.',@isdir);
  p.parse(varargin{:})
  params = p.Results;
  
  path = params.path;
  
  ext = 'mat';
  fList = dir(strcat(path,'\*.',ext));
  
  videoFile = generateFileName(path,'movie','mp4') 
 
  writerObj = VideoWriter(videoFile);
  writerObj.FrameRate = 10;
  open(writerObj);

  fig=figure(1);
  res=zeros(size(fList,1),200,80);
  for fNum=size(fList,1)-100:size(fList,1)
    clf;
    fPath = strcat(path,'\',fList(fNum).name);
    tmp = load(fPath);
    obj = tmp.obj;
    obj.plotMSurfXY(10,'Z','showScale', true, 'saveImg',true,...
    'saveImgPath',path,'colourRange',6000,...
    'showScale',true, 'yRange',[25 55]);
    writeVideo(writerObj,getframe(fig));
    % res(fNum,:,:) = obj.getSlice('X',10,'X');
  end
  close(writerObj);
  save sliceCollect.mat res;
end
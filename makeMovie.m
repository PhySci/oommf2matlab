%% Scan folder, search objects, plot Z projection of magnetisation
% make a movie
function makeMovie(path,background)
 %  path = 'C:\Micromagnet\OOMMF\proj\Transducer APL\Carl_simulations_20150306\transducer+waveguide\pulse\obj\';
  videoFileName = 'test';
  ext = 'mat';
  fList = dir(strcat(path,'\*.',ext));

  videoFile = fullfile(path,strcat(videoFileName,'.mp4'));
  writerObj = VideoWriter(videoFile);
  writerObj.FrameRate = 10;
  open(writerObj);

  fig=figure(1);
  res=zeros(size(fList,1),200,80);
  for fNum=1:size(fList,1)
    clf;
    fPath = strcat(path,'\',fList(fNum).name);
    tmp = load(fPath);
    obj = tmp.obj;
    obj.plotMSurfYZ(10,'X','showScale', true, 'saveImg',true,...
    'saveImgPath',path,'rotate',true,...
    'colourRange',300,...
    'showScale',true,'xrange',[27 55]    );
    writeVideo(writerObj,getframe(fig));
    res(fNum,:,:) = obj.getSlice('X',10,'X');
  end
  close(writerObj);
  save sliceCollect.mat res;
end
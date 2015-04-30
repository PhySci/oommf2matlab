% Function for processing of results of pulse excitations
% and plotting of dispersion curve
function dispersionCurve(res,varargin)
    
 
  xRange = 1:200;
  yRange = 30:50;
  zRange = 1:10;
  
  dt = 2e-11; % time resolution
  dl = 0.5; % spatial resolution
  
  p = inputParser;

  p.addParamValue('scanFolder',false,@islogical);
  p.addParamValue('scanPath','.',@isdir);
  p.addParamValue('extractStatic',false,@islogical);
  p.addParamValue('extractStaticFile','');
  p.parse(varargin{:});
  
  params = p.Results;
  
  
  if (params.scanFolder)
      res = scanFolder(params.scanPath,xRange,yRange,zRange);
  elseif (isempty(res))
      disp('No input data');
      return;
  end
  
  if (params.extractStatic)
      load(params.extractStaticFile);
      staticMag = omf.getVolume(xRange,yRange,zRange,':');
      for i = 1:size(res,1)
        m1 = squeeze(res(i,:,:,:,:));
        m2 = staticMag;
        res(i,:,:,:,:) = m1 - m2;
      end  
  end
    
    %path = 'D:\Micromagnet\OOMMF\proj\TransducerAPL\center\pulse\result'; 
  % 'D:\Micromagnet\OOMMF\proj\TransducerAPL\Carl_simulations_20150306\transducer+waveguide\pulse\obj';

  
  Arr =  res(:,:,:,:,:);
  averArr = squeeze(mean(mean(Arr,3),4));
  
  Mz = averArr(:,:,3);
  
  G1 = fspecial('gaussian',[5 5],0.5);
  G2 = fspecial('gaussian',[5 5],0.5);
 
  % Mz = imfilter(Mz,G1,'circular','same','conv');
  % average of input data along three dimensions 
  lRange = linspace(-0.5/dl,0.5/dl,size(Mz,2));
  fRange = linspace(-0.5/dt,0.5/dt,size(Mz,1))/1e9;
  
  Yz = fft2(Mz);
  ModZ = abs(Yz);
  ModZ = fftshift(ModZ,1);
  ModZ = fftshift(ModZ,2);
  
  
  fig1 = figure(1);
      set(fig1,'Position', [1, 1, 1024, 768]);

      ModZ1 = imfilter(ModZ,G2,'replicate','same','conv');
      %contourf(lRange,fRange,log(ModZ1),20);
      imagesc(lRange,fRange,10*log10(ModZ1/min(ModZ1(:))));
      %colormap(flipud(gray));
      colormap(jet);
      axis xy
      xlim([0 1]); xlabel('wave number, nm^-^1')
      ylim([0 15]); ylabel('Freq, GHz');
      t = colorbar('peer',gca);
      set(get(t,'ylabel'),'String', 'FFT intensity, dB');
  
  [fName, errFlag] = generateFileName('.','dispersionCurve','png');
  print(fig1,'-dpng','-r300',fName);
  
  % figure(2);
  % ModZ2 = fold(ModZ);
  % ModZ2 = imfilter(ModZ2,G2,'replicate','same','conv');
  % contourf(lRange(ceil(length(lRange))+1:end),fRange(ceil(length(fRange)):end), log(ModZ2),20);
  % colormap(flipud(gray));
  % xlim([0 1]); xlabel('wave number, nm^-^1')
  % ylim([1 10]); ylabel('Freq, GHz');
end

% Scan folder and get slice 
function res = scanFolder(path,xRange,yRange,zRange) 
  obj = OOMMF_result;
  fList = obj.getFilesList(path,'mat');
  res = zeros(size(fList,1),length(xRange),...
               length(yRange),length(zRange),3);
  for i=1:size(fList,1)
       disp(i);
       fPath = strcat(path,'\',fList(i).name);
       space = load(fPath);
       obj = space.obj;
       res(i,:,:,:,:) = obj.getVolume(xRange,yRange,zRange,':'); 
    %    mesh{i} = obj;
  end
    save dispCurve.mat res; % mesh
end

% fold images
function output = fold(input)
  center = ceil(0.5*size(input));
  a1 = rot90(rot90(input(1:center(1),1:center(2))));
  a2 = flipud(input(1:center(1),center(2)+1:end));
  a3 = fliplr(input(center(1)+1:end,1:center(2)));
  a4 = input(center(1)+1:end,center(2)+1:end); % <-- main
  output = a4+a3+a2+a1; 
end 
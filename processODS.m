function processODS()
  % read ODS scan data, calculate FFT spectra
  % plot and save images
  [fName,fPath,~] = uigetfile({'*.txt'});
  if (fName == 0)
      return
  end    
  fullName = fullfile(fPath,fName);
  
  res = readDataFile(fullName).';
  readParamsFile(fullName);
  
  % convert X scale from distance to time
  time = 2*(res(:,1) - min(res(:,1)))/3e2; % m
  dT = mean(diff(time)); 
  freq = linspace(-0.5/dT,0.5/dT,size(time,1)).';
   
  linFit = fit(time,res(:,2),'poly1');
  background = linFit.p1*time + linFit.p2;
  
  
  AI7correct = res(:,2) - background;
  Y = fftshift(abs(fft(AI7correct)));
 
 figure(1);
     plot(time,AI7correct,'-r');
     xlim([time(1) time(end)]);
     title(fName); xlabel('Delay, ns.'); ylabel('Signal, V');

 [pathstr,fName,ext] = fileparts(fName); 
 h2 = figure(2);   
    subplot(211);
      plot(time,AI7correct,'-r');
      xlim([time(1) time(end)]);
      title(fName); xlabel('Delay, ns.'); ylabel('Signal, V');
      set(gca, 'Position', [0.05 0.59 0.92 0.36]);
    subplot(212);
      plot(freq, Y); title('FFT');
      xlim([0 20]); xlabel('Freq, GHz');
      ylabel('FFT intensity');
      set(gca, 'Position', [0.05 0.08 0.92 0.36]);     
 % copy data to clipboard
 num2clip([freq(find(freq>=0)) Y(find(freq>=0))]);
 %num2clip([time AI7correct]);
 
 %save
 savefig(h2,strcat(fName,'.fig'));
 print(gcf,'-dpng',strcat(fName,'.png'));
 
 
end

% Read file and return array of data 
function res = readDataFile(fPath)
  fid = fopen(fPath);
  errorMsg = ferror(fid);
  if (~strcmp(errorMsg,''))
      disp(errorMsg);
      return;
  end    
  res=[];
  while (~feof(fid))
    str = fgetl(fid);
    [tmp, ~, errmsg] = sscanf(str, '%e');
    if (~strcmp(errmsg,''))
      disp('A problem occured with file reading');
      disp(errmsg);
      return;
    end    
    res = cat(2,res,tmp);
  end
  fclose(fid);
end

% Read file of parameters and print all information on the screen
function readParamsFile(fPath)
  % add "-i" suffix to name of file
  [pathstr,name,ext] = fileparts(fPath);
  name = strcat(name,'-i',ext);
  fPath = fullfile(pathstr,name);
  
  % open and read file
  fid = fopen(fPath);
  errorMsg = ferror(fid);
  if (~strcmp(errorMsg,''))
      disp(errorMsg);
      return;
  end
  disp(' ');
  disp(name);
  while (~feof(fid))
    disp(fgetl(fid));  
  end
  fclose(fid);
end
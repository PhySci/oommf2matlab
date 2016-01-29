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
 
  Ch1 = res(:,4);
  Ch2 = res(:,5);
  
  % convert X scale from distance to time
  time = 2*(res(:,1) - min(res(:,1)))/3e2; % m
  dT = abs(mean(diff(time))); 
  freq = linspace(-0.5/dT,0.5/dT,size(time,1)).';
   
  Spec = fftshift(abs(fft(Ch1+i*Ch2)));
 
  h1 = figure(1);
  subplot(211);
      plot(time,Ch1,'-r',time,Ch2,'-g');
      xlim([min(time) max(time)]);
      title(fName); xlabel('Delay, ns.'); ylabel('Signal, V');

      [pathstr,fName,ext] = fileparts(fName); 
 
  subplot(212);
      plot(freq, Spec); title('FFT');
      xlim([0 50]); xlabel('Freq, GHz');
      ylabel('FFT intensity');
      %set(gca, 'Position', [0.05 0.08 0.92 0.36]);     
 % copy data to clipboard
 %num2clip([freq(find(freq>=0)) Y(find(freq>=0))]);
 %num2clip([time AI7correct]);
 
 %save
 %savefig(h2,strcat(fName,'.fig'));
 %print(gcf,'-dpng',strcat(fName,'.png'));
 
 
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
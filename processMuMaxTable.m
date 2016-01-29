function processMuMaxTable
    fName = 'table.txt';
    
    % open and read file
    try
        fid = fopen(fName);
        header = fgetl(fid);
        data = [];
        while ~feof(fid)
          data = [data; cell2mat(textscan(fgetl(fid),'%f32')).'];
        end    
    catch err
        disp (err);
    end    
    time = double(data(:,1));
    rawMx = data(:,2);
    rawMy = data(:,3);
    rawMz = data(:,4);
    
    % interpolation of time dependences
    timeScale = linspace(min(time),max(time),size(time,1));
    Mx = interp1(time,double(rawMx),timeScale);
    My = interp1(time,double(rawMy),timeScale);
    Mz = interp1(time,double(rawMz),timeScale);
    
    %dt = mean(diff(time))
    dt = (max(time)-min(time))/size(time,1) 
    freqScale = linspace(-0.5/dt,0.5/dt,size(time,1))/1e9;
    SpecX = fftshift(abs(fft(Mx)));
    SpecZ = fftshift(abs(fft(Mz)));
    
    figure(1);
        subplot(211); plot(time,Mx);
        subplot(212); plot(time,Mz);
        
   figure(2);
        plot(freqScale,[SpecX; SpecZ]);
        xlim([0 6]);
         
   figure(3);
        plot(Mx,Mz);
     
end


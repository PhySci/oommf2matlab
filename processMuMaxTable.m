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
    fclose(fid);
    time = double(data(:,1));
    rawMx = data(:,2);
    rawMy = data(:,3);
    rawMz = data(:,4);
    Bx = data(:,6);
    By = data(:,7);
    Bz = data(:,8);
    
    
    size(time,1)
    % interpolation of time dependences
    timeScale = linspace(min(time),max(time),size(time,1)).';
    Mx = interp1(time,double(rawMx),timeScale);
    Mz = interp1(time,double(rawMz),timeScale);
    
    %dt = mean(diff(time))
    dt = (max(time)-min(time))/size(time,1);
    freqScale = linspace(-0.5/dt,0.5/dt,size(time,1))/1e9;
    %winFunc = hamming(size(time,1));
    winFunc = rectwin(size(time,1));
    
    SpecX = fftshift(abs(fft(Mx.*winFunc)));
    SpecZ = fftshift(abs(fft(Mz.*winFunc)));
    
    fg1 = figure(1);
        subplot(211);
            plot(time/1e-9,Mx,'-r');
            xlabel('Time (ns)','FontSize',14,'FontName','Times');
            ylabel('M_x','FontSize',14,'FontName','Times');
            xlim([0 time(end)/1e-9]); legend('M_x');
        
        subplot(212);
            plot(time/1e-9,Mz,'-g');
            xlabel('Time (ns)','FontSize',14,'FontName','Times');
            ylabel('M_z','FontSize',14,'FontName','Times');
            xlim([0 time(end)/1e-9]);  legend('M_y')
        
        legend('M_x')
        savefig(fg1,'MT.fig');
        print(fg1,'-dpng','-r600','MT.png');

            
   fg2 = figure(2);
        semilogy(freqScale,[SpecX SpecZ]);
        xlim([0 7]); xlabel('Frequency (GHz)','FontSize',14,'FontName','Times');
        ylabel('Spectral density (arb. units)','FontSize',14,'FontName','Times');
        legend('M_x','M_z');
        
        print(fg2,'-dpng','-r600','logSpec.png'); 
        savefig(fg2,'logSpec.fig');
   
   fg3 = figure(3);
        subplot(211);
            plot(freqScale,SpecX);
            xlim([0 7]); legend('M_x')
            xlabel('Frequency (GHz)','FontSize',14,'FontName','Times');
            ylabel('Spectral density (arb. units)','FontSize',14,'FontName','Times');

        subplot(212); plot(freqScale,SpecZ);
            plot(freqScale,SpecZ);
            xlim([0 7]); legend('M_z')
            xlabel('Frequency (GHz)','FontSize',14,'FontName','Times');
            ylabel('Spectral density (arb. units)','FontSize',14,'FontName','Times');
        
        print(fg3,'-dpng','-r600','linSpec.png');
        savefig(fg3,'linSpec.fig');     
           
end


classdef Kerr_ODS < hgsetget
    %Kerr_ODS - matlab class for processing of time-resolved (ODS) signals
    %   Detailed explanation goes here
    
    properties
        
        fName = '';
        
        % arrays of signal 
        Chanel1 = 0;
        Chanel2 = 0;
        Monitor1 = 0;
        Monitor2 = 0;
        FFTspec = 0; % Fourier spectrum
        
        % params
        dt = 0;
        freqScale = 0;
        lengthScale = 0;
        timeScale = 0;
        position = [0 0 0];
        waitTime = 0; 
    end
    
    properties (Access = protected)
    end    
    
    methods
        
        % create object
        function obj = Kerr_ODS
            disp('Kerr_ODS object was created');
        end    
        
        % open new file file
        function open(obj)
            obj.fName = '';
            if obj.load() 
                obj.makeFFT();
                obj.plot();
            end
        end
        
        % load file
        function suc = load(obj)
           if isempty(obj.fName)   
              [fName,fPath,~] = uigetfile({'*.h5';'*.txt'});
              if (fName == 0)
                  suc = false;
                  return
              end
              suc = true;
              fullName = fullfile(fPath,fName);
              obj.fName = fullName;
           end
          
          [~,~,ext] = fileparts(fName); 

          if strcmp(ext,'.txt')
              res = obj.readDataFile().';
              %readParamsFile(fullName);
          elseif strcmp(ext,'.h5')
              %h5disp(obj.fName);
              obj.position = h5readatt(obj.fName,'/','Position');
              obj.waitTime = h5readatt(obj.fName,'/','time_wait_(ms) ');
              res = h5read(obj.fName,'/Signal').';
          end

          obj.lengthScale = res(:,1);
          obj.Chanel1 = res(:,4);
          obj.Chanel2 = res(:,5);
          obj.Monitor1 = res(:,2);
          obj.Monitor2 = res(:,3);
          
          obj.calcFreqScale();         
        end    
        
        % calculate FFT spectra of the signal
        function makeFFT(obj,windFunc)
            %windArr = hamming(size(obj.Chanel1,1));
            windArr = rectwin(size(obj.Chanel1,1));
            
            signal = windArr.*(obj.Chanel1+i*obj.Chanel2); 
            obj.FFTspec = fftshift(abs(fft(signal)));
        end    
        
        % scan folder, calculate FFT for every file and average FFT spectra
        function FFTspec = scanFolder(obj)
            
            fList = dir(fullfile(pwd,'*.txt'));
            if (size(fList)==0)
                disp('Files havent been found');
                return;
            end
            
            FFTspecArr = [];
            for fInd = 1:size(fList)
                obj.fName = fullfile(pwd,fList(fInd).name);
                obj.load();
                obj.makeFFT();
                obj.plot();
                FFTspecArr(:,fInd) = obj.FFTspec;
            end

            FFTspec = mean(FFTspecArr,2);
            
            h2 = figure(2);
                plot(obj.freqScale,FFTspec);
                xlabel('Frequency (GHz)','FontSize',14,'FontName','Times');
                ylabel('FFT intensity (arb. units)','FontSize',14,'FontName','Times');
                xlim([0 20]);
        end 
        
        % plot signal and FFT spectra
        function plot(obj,varargin)
            
            p = inputParser();
            p.addParamValue('saveAs','',@isstring);
            p.parse(varargin{:});
            params = p.Results;

            hf = figure();
            subplot(211);
                plot(obj.timeScale,obj.Chanel1,'-r',obj.timeScale,obj.Chanel2,'-b');
                xlim([min(obj.timeScale) max(obj.timeScale)]);
                title(obj.fName);
                xlabel('Delay (ns)','FontSize',14,'FontName','Times');
                ylabel('Signal (V)','FontSize',14,'FontName','Times');
                legend('Chanel 1','Chanel 2');
                
            subplot(212);
                semilogy(obj.freqScale, obj.FFTspec); title('FFT');
                %xlim([0 20]);
                xlabel('Frequency (GHz)','FontSize',14,'FontName','Times');
                ylabel('FFT intensity (arb. units)','FontSize',14,'FontName','Times');
                
            [pathstr,fName,ext] = fileparts(obj.fName);
            savefig(hf,strcat(fName,'-hamming.fig'));
            print(hf,'-dpng','-r600',strcat(fName,'-hamming.png'));
        end 
        
        function sinFit(obj,varargin)
            sinFunc  = @(b,x) (b(1)*sin(b(4)+2*pi*x/b(3))+b(2));
            fitRes = nlinfit(obj.lengthScale,obj.Chanel1,sinFunc,[1, 1,80,0.1]); %,...
            amp1 = fitRes(1);
            bias1 = fitRes(2);
            period1 = fitRes(3);
            shift1 = fitRes(4);
            yFit = amp1*sin(shift1+2*pi*obj.lengthScale/period1)+bias1;
            plot(obj.lengthScale,obj.Chanel1,'xr',obj.lengthScale,yFit,'-g')
        end    
        
    end
    
    methods (Access = protected)
        
        % Read file and return array of data 
        function res = readDataFile(obj)
          fid = fopen(obj.fName);
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
        function readParamsFile(obj,fPath)
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
        
        function calcFreqScale(obj)
            obj.timeScale = 2*(obj.lengthScale - min(obj.lengthScale))/3e2; % m
            obj.dt = abs(mean(diff(obj.timeScale)));
            obj.freqScale = linspace(-0.5/obj.dt,0.5/obj.dt,size(obj.timeScale,1)).';
        end
        
    end  
    
end


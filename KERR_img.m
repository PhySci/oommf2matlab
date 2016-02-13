% Class for processing of results of Kerr imaging
%
classdef KERR_img < hgsetget
    
    properties
        fName = '' % file name
        xNodes = 50
        yNodes = 50
        xStart = 0 % mkm
        xStop = 10 % mkm
        yStart = 0 % mkm
        yStop = 10 % mkm
        ref  % array of reflectivity
        kerr % array of Kerr data
        
        % monitors' values
        Monitor1 = []
        Monitor2 = []
        
        % reflectivities' values
        Reflect1 = []
        Reflect2 = []
        
        % Kerr rotation values
        Kerr1 = []
        Kerr2 = []
        
        % file suffixes
        
    end
    
    methods
        
        function obj = KERR_img
            disp('KERR_img object was created');
        end
        
        % choose the file, processing of the file name
        function open(obj)
            [fName,fPath,~] = uigetfile({'*.txt'});
            
            % try to parse the file name using regular expression
            expr = '^([\w-]+)-(m1|m2|c1l1|c2l1|c1l2|c2l2|p|sig)(.txt)';
            [~, ~, ~, ~, tokenStr, ~, splitStr] = regexp(fName,expr);
            if (size(tokenStr,1)>0)
                if (size(tokenStr{1,1},2)>1)
                    % seek properties
                    toks = tokenStr{1,1};
                    obj.fName = toks{1};
                end
            end
            
            obj.loadFile();
            obj.plotMonitors();
        end    
            
        % load data from files
        function loadFile(obj, varargin)
            
            p = inputParser;
            p.addParamValue('test','');
     
            p.parse(varargin{:});
            params =  p.Results;
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%% 
            %  Read  params  file    %
            %%%%%%%%%%%%%%%%%%%%%%%%%%
            pFileName = strcat(obj.fName,'-p.txt');          
            [pFileId,errMsg] = fopen(pFileName); % reflectivity file name
            if (pFileId <0)
                disp('Reading of parameters');
                disp(errMsg);
            else
                expr = '^([\w_()]+)\s([-.0-9e]+)';
                while ~feof(pFileId)              
                    line = fgetl(pFileId);
                    [~, ~, ~, ~, tokenStr, ~, splitStr] = regexp(line,expr);
                   if (length(tokenStr) == 1 && length(tokenStr{1,1}) == 2) 
                       switch tokenStr{1,1}{1}
                           case 'x_step_number'
                               obj.xNodes = str2double(tokenStr{1,1}{2});
                           case 'x_start_(um)'
                               obj.xStart = str2double(tokenStr{1,1}{2});
                           case 'x_stop_(um)'
                               obj.xStop = str2double(tokenStr{1,1}{2});

                           case 'y_step_number'
                               obj.yNodes = str2double(tokenStr{1,1}{2});
                           case 'y_start_(um)'
                               obj.yStart = str2double(tokenStr{1,1}{2});
                           case 'y_stop_(um)'
                               obj.yStop = str2double(tokenStr{1,1}{2});                           
                       end        
                   end    
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%% 
            % Read reflectivity file %
            %%%%%%%%%%%%%%%%%%%%%%%%%%

            
            %%%%%%%%%%%%%%%%%%%%%%%%%% 
            % Read Kerr file         %
            %%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%
            % Read monitor files     %
            %%%%%%%%%%%%%%%%%%%%%%%%%%
            m1FileName = strcat(obj.fName,'-m1.txt');
            m2FileName = strcat(obj.fName,'-m2.txt');

            obj.Monitor1 = obj.readFile(m1FileName);
            obj.Monitor2 = obj.readFile(m2FileName);
        end    
        
        % plot reflectivity image
        function plotRef(obj)
            if (length(obj.ref(:)) < 1 )
                disp('No reflectivity data');
                return;
            end    
            
            imagesc(obj.getXScale,obj.getYScale,obj.ref);
            %axis xy;
            colormap(copper);
            xlabel('X,\mum'); ylabel('Y,\mum');
            title(strcat('Reflectivity .',obj.fName));
        end    
         
        % plot Kerr data
        
        function plotKerr(obj)
            if (length(obj.kerr(:)) < 1 )
                disp('No Kerr data');
                return;
            end    
            
            imagesc(obj.getXScale,obj.getYScale,obj.kerr);
            axis xy; colormap(copper);
            xlabel('X,\mum'); ylabel('Y,\mum');
            title(strcat('Kerr rotation ',obj.fName));
        end
        
        function plotMonitors(obj)
            xScale = obj.getXScale();
            yScale = obj.getYScale();
            
            Signal = sqrt(obj.Monitor1.^2+obj.Monitor2.^2);
            fg1 = figure(1);
            imagesc(xScale,yScale,Signal);
            axis xy; axis equal
            xlabel('X (\mum)','FontSize',14,'FontName','Times');
            ylabel('Y (\mum)','FontSize',14,'FontName','Times');
            axis xy equal;
            xlim([min(xScale) max(xScale)]);
            ylim([min(yScale) max(yScale)]);
            colormap(copper)
            print(fg1,'-dpng','-r600',strcat(obj.fName,'-m.png'));
        end    
        
        function res = getXScale(obj)
           res = linspace(obj.xStart,obj.xStop,obj.xNodes);  
        end
        
        function res = getYScale(obj)
           res = linspace(obj.yStart,obj.yStop,obj.yNodes);  
        end
         
    end
    
    methods (Access = protected)
        
        function res = readFile(obj,fName)
            res = [];
            try
                fid = fopen(fName);
                if (fid < 0)
                    disp('File not found');
                    return
                end    
                while ~feof(fid)
                    res =[res sscanf(fgetl(fid),'%f')];
                end
                fclose(fid);
            catch Err
                disp(Err);
            end
        end
    end    
end


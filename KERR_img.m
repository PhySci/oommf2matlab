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
    end
    
    methods
        
        function obj = KERR_img
            disp('KERR_img object was created');
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
            pFileName = strcat(obj.fName,'-i.txt');          
            [pFileId,errMsg] = fopen(pFileName); % reflectivity file name
            if (pFileId <0)
                disp('Reading of parameters');
                disp(errMsg);
                return
            end
            
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
            
            %%%%%%%%%%%%%%%%%%%%%%%%%% 
            % Read reflectivity file %
            %%%%%%%%%%%%%%%%%%%%%%%%%%
            rFileName = strcat(obj.fName,'-r.txt'); 
            [rFileId,errMsg] = fopen(rFileName); % reflectivity file name
            if (rFileId <0)
                disp(errMsg);
                return
            end
            
            A = fscanf(rFileId,'%f');
            fclose(rFileId);
            obj.ref = reshape(A,obj.xNodes,obj.yNodes);
            disp('Reflectivity file was upload');
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%% 
            % Read Kerr file         %
            %%%%%%%%%%%%%%%%%%%%%%%%%%
            kFileName = strcat(obj.fName,'-k.txt'); 
            [kFileId,errMsg] = fopen(kFileName); % reflectivity file name
            
            if (kFileId <0)
                disp('No Kerr image was found');
            else          
                A = fscanf(kFileId,'%f');
                fclose(kFileId);
                obj.kerr = reshape(A,obj.xNodes,obj.yNodes);
                disp('Kerr file was upload');
            end    
            
            
        end    
        
        % plot reflectivity image
        function plotRef(obj)
            if (length(obj.ref(:)) < 1 )
                disp('No reflectivity data');
                return;
            end    
            
            imagesc(obj.getXScale,obj.getYScale,obj.ref);
            axis xy;
            colormap(copper);
        end    
         
        % plot Kerr data
        
        function plotKerr(obj)
            if (length(obj.kerr(:)) < 1 )
                disp('No Kerr data');
                return;
            end    
            
            imagesc(obj.getXScale,obj.getYScale,obj.kerr);
            axis xy;
            colormap(copper);
        end
        
        function res = getXScale(obj)
           res = linspace(obj.xStart,obj.xStop,obj.xNodes);  
        end
        
        function res = getYScale(obj)
           res = linspace(obj.yStart,obj.yStop,obj.yNodes);  
        end
        
    end
    
    
end


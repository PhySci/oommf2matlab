function readHdf
    fName = '160308-focus-a.h5';
    info = h5info(fName);
    h5disp(fName);
    
    
    % scan datasets
    datasets = info.Datasets;
    if size(datasets,1)>0
        for datasetInd = 1:size(datasets,1)
            switch datasets(datasetInd).Name
                case 'Focus measure'
                    FM = h5read(fName,'/Focus measure');
                    figure(1);
                    plot(FM(find(FM(:,1)>0),1),FM(find(FM(:,1)>0),2));
                    xlabel('Focus distance (\num)');
                    ylabel('Focus measure (arb. units)');
                    
                otherwise
                    disp('Unkwon dataset was found')
            end        
        end    
    end    
    
    imgGroup = h5info(fName,'/images');
    
    % read images
    if (size(imgGroup.Groups,1)>0)
        for imgInd = 1:size(imgGroup.Groups,1)
            groupName = imgGroup.Groups(imgInd).Name;
            xMin = h5readatt(fName,groupName,'Initial x');
            xMax = h5readatt(fName,groupName,'Final x');
            xSteps = h5readatt(fName,groupName,'x steps');
            yMin = h5readatt(fName,groupName,'Initial y');
            yMax = h5readatt(fName,groupName,'Final y');
            ySteps = h5readatt(fName,groupName,'y steps');
            xScale = linspace(xMin,xMax,xSteps+1);
            yScale = linspace(yMin,yMax,ySteps+1);
            
            figure(1);
            info =  h5info(fName,groupName);
            Names = info.Datasets;
            for datasetInd = 1:size(Names,1)
                dataset = Names(datasetInd);
                switch dataset.Name
                    case 'monitor1'
                        m1(imgInd,:,:) = h5read(fName,strcat(groupName,'/monitor1'));
                    case 'monitor2'
                        m2(imgInd,:,:) = h5read(fName,strcat(groupName,'/monitor2'));
                    case 'kerr1'
                        k1(imgInd,:,:) = h5read(fName,strcat(groupName,'/kerr1'));
                    case 'kerr2'
                        k2(imgInd,:,:) = h5read(fName,strcat(groupName,'/kerr2'));
                end
            end    
            
            
           
        end
    end
    
    
    % read focus measure
    
    
    
    % normalize images
    if exist('m1') && exist('m2') 
        monLim = [min(min(m1(:)),min(m2(:))) max(max(m1(:)),max(m2(:)))];
    end   
    if exist('k')
        kerrLim = [min(min(k1(:)),min(k2(:))) max(max(k1(:)),max(k2(:)))];
    end
    
    
    
    for imgInd = 1:size(m1,1)
        if exist('k')
            clf();
            subplot(221);
                imagesc(xScale,yScale,squeeze(m1(imgInd,:,:)),monLim);
                axis xy equal;
                xlabel('x (\mum)','FontSize',14,'FontName','Times');
                ylabel('y (\mum)','FontSize',14,'FontName','Times');
                xlim([min(xScale) max(xScale)]);
                ylim([min(yScale) max(yScale)]);
                title('Monitor 1','FontSize',14,'FontName','Times');
                colorbar('peer',gca,'location','WestOutside');
                
            
            subplot(222);
                imagesc(xScale,yScale,squeeze(m2(imgInd,:,:)),monLim);
                axis xy equal;
                xlabel('x (\mum)','FontSize',14,'FontName','Times');
                ylabel('y (\mum)','FontSize',14,'FontName','Times');
                xlim([min(xScale) max(xScale)]);
                ylim([min(yScale) max(yScale)]);
                title('Monitor 2','FontSize',14,'FontName','Times');
                t = colorbar('peer',gca);
                set(get(t,'ylabel'),'FontSize',12,'FontName','Times','String', 'Voltage');
                
            subplot(223);
                imagesc(xScale,yScale,squeeze(k1(imgInd,:,:)),kerrLim);
                axis xy equal;
                xlabel('x (\mum)','FontSize',14,'FontName','Times');
                ylabel('y (\mum)','FontSize',14,'FontName','Times');
                xlim([min(xScale) max(xScale)]);
                ylim([min(yScale) max(yScale)]);
                title('Kerr 1','FontSize',14,'FontName','Times');
                colorbar('peer',gca,'location','WestOutside');

            subplot(224);
                imagesc(xScale,yScale,squeeze(k2(imgInd,:,:)),kerrLim);
                axis xy equal;
                xlabel('x (\mum)','FontSize',14,'FontName','Times');
                ylabel('y (\mum)','FontSize',14,'FontName','Times');
                xlim([min(xScale) max(xScale)]);
                ylim([min(yScale) max(yScale)]);
                title('Kerr 2','FontSize',14,'FontName','Times');
                t = colorbar('peer',gca);
                set(get(t,'ylabel'),'FontSize',12,'FontName','Times','String', 'Voltage');

                colormap(jet)
            print(gcf,'-dpng',strcat(num2str(imgInd),'.png')) 
        else
            figure();
            figTitle = [fName, ' Monitor 1. Focus distance is ',num2str(FM(imgInd,1)),' \mum,',...
                        'focus measure is ',num2str(FM(imgInd,2))];
            imagesc(xScale,yScale,squeeze(m1(imgInd,:,:)),monLim);
            axis xy square;
            xlabel('x (\mum)','FontSize',14,'FontName','Times');
            ylabel('y (\mum)','FontSize',14,'FontName','Times');
            xlim([min(xScale) max(xScale)]);
            ylim([min(yScale) max(yScale)]);
            title(figTitle,'FontSize',14,'FontName','Times');
            colorbar('peer',gca);
            print(gcf,'-dpng',strcat(fName,'-',num2str(imgInd),'.png'))     
        end    
    end
    
end
function readHdf
    fName = '160228-IMG';
    info = h5info(fName);
    h5disp(fName);
    
    imgGroup = h5info(fName,'/images');
    
    if (size(imgGroup.Groups,1)>0)
        for imgInd = 1:size(imgGroup.Groups,1)
            groupName = imgGroup.Groups(imgInd).Name;
            xMin = h5readatt(fName,groupName,'Initial x');
            xMax = h5readatt(fName,groupName,'Final x');
            xSteps = h5readatt(fName,groupName,'x steps');
            ySteps = h5readatt(fName,groupName,'Initial y');
            yMax = h5readatt(fName,groupName,'Final y');
            yMin = h5readatt(fName,groupName,'y steps');
            xScale = linspace(xMin,xMax,xSteps+1);
            yScale = linspace(yMin,yMax,ySteps+1);
            
            figure(1);
            m1(imgInd,:,:) = h5read(fName,strcat(groupName,'/monitor1'));
            m2(imgInd,:,:) = h5read(fName,strcat(groupName,'/monitor2'));
            k1(imgInd,:,:) = h5read(fName,strcat(groupName,'/kerr1'));
            k2(imgInd,:,:) = h5read(fName,strcat(groupName,'/kerr2'));
        end
    end    
    
    monLim = [min(min(m1(:)),min(m2(:))) max(max(m1(:)),max(m2(:)))];
    kerrLim = [min(min(k1(:)),min(k2(:))) max(max(k1(:)),max(k2(:)))];
    
    for imgInd = 1:size(m1,1)    
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
    end
    
end
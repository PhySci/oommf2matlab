% calculate spatial distribution of magnetic field around infinite wire
% with constant electrical current 
function plotHFieldWire
  clf;
  c = 1;
  x = linspace(-1,1,51);
  y = linspace(-1,1,51);
  [X,Y]=meshgrid(x,y);
  Bx = c*(Y./(X.^2+Y.^2));
  By = c*(-X./(X.^2+Y.^2));
  disp(Bx(26,27));
  disp(By(26,27));
  figure(1)
    quiver(x,y,c*Bx,c*By);
    xlim([-0.5 0.5]);
    ylim([-0.5 0.5]);
    title('Vector map of field');
  figure(2);
    subplot(211); plot(x,Bx(50,:)); xlabel('x'); ylabel('Bx');
    title('Spatial components of magnetic field');
    subplot(212); plot(x,By(50,:)); xlabel('x'); ylabel('By');
end 
  
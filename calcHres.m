function calcHres
H = linspace(0,1000,100);
Ms = 1e4/(4*pi);

% sphere
Nx = 4*pi/3;
Ny = 4*pi/3;
Nz = 4*pi/3;
w(1,:) = getFreq(H, Ms, Nx, Ny, Nz);

% plate, "out-of-plane"
  Nx = 0;
  Ny = 0;
  Nz = 4*pi;
  w(2,:) = getFreq(H, Ms, Nx, Ny, Nz);

% plate, "in-plane"
  Nx = 0; 
  Ny = 4*pi;
  Nz = 0;
  w(3,:) = getFreq(H, Ms, Nx, Ny, Nz);
  
% rod, along long axis  
  Nx = 2*pi; 
  Ny = 2*pi;
  Nz = 0;
  w(4,:) = getFreq(H, Ms, Nx, Ny, Nz);

% rod, perpendicular long axis
  Nx = 2*pi; 
  Ny = 0;
  Nz = 2*pi;
  w(5,:) = getFreq(H, Ms, Nx, Ny, Nz);

  
  plot(H/1000,w(1:4,:)/1e9); xlabel('H, kOe'); ylabel('Freq, GHz');
  legend('No anisotropy',...
         'Plate, out of plane','Plate, in plane');
         %'Rod, along','Rod, perpendicular'

  ylim([0 15]);
end

function freq = getFreq(H, Ms, Nx, Ny, Nz)
gamm = 1.76e7;
freq = (gamm *sqrt((H+(Nx-Nz)*Ms).*(H+(Ny-Nz)*Ms)))/(2*pi);
end
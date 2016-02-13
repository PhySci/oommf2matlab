function testFGen
    fg = fieldGen();
    fg.writeFile();
    
    sim = OOMMF_sim;
    sim.fName = 'testGieldGen.ovf';
    sim.loadParams();
    [Hx,Hy,Hz] = sim.loadMagnetisation();
    
    figure(4);
    imagesc(squeeze(Hx(:,1,:)).'); axis xy; title('Hx');
    colorbar();
    
    figure(5);
    imagesc(squeeze(Hy(:,1,:)).'); axis xy; title('Hy');
    colorbar();
    
    figure(6);
    imagesc(squeeze(Hz(:,1,:)).'); axis xy; title('Hz');
    colorbar();
end
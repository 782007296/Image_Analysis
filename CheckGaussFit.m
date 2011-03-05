
%% CheckGaussFit


mRNAchn1 = handles.mRNAchn1;

dot_rad = 12;
h = hs; w=ws;

T = false(h,w); 
center_pix = floor(h*(w/2+.5)); % have to start somewhere
T(center_pix) = 1; 
T2 = imdilate(T,strel('square',dot_rad)); 
all_pix = 1:h*w;
Neib1 = all_pix(T2==1)-center_pix; 



 
for z = 15% 1:Zs
    tic
    rna_x1 = DotData{z}(:,1);%  = centRNA1(RNA_in1(:,1),1);       
    rna_y1 = DotData{z}(:,2); % centRNA1(RNA_in1(:,1),2);
    rna_lin = round(rna_y1)+round(rna_x1)*h;
    I2 = Im{1,z}{mRNAchn1}( xp1:xp2,yp1:yp2 ); 
    
        Ds = length(rna_lin);
        Ps = length(Neib1);
        
        dotI = NaN*zeros(Ds,Ps); 
        for i=1:Ds % for all dots in the layer
          
          Neibs = rna_lin(i) + Neib1;  % linear indices of all neighboring pixels.  
          Neibs = Neibs(Neibs>-1); 
          
%            T = false(h,w); 
%           T(Neibs) = 1;
%           I = uint16(zeros(h,w,3));
%           I(:,:,1) = 2*I2;
%           I(:,:,2) = uint16(2^13*T);
%           x = round(rna_x1(i));
%           y = round(rna_y1(i));
          
%            hf  = figure(1); clf; set(hf,'position',[200,200,900,900]);
%            imshow( I );                
%          hold on; plot(rna_x1,rna_y1,'co');
%          hold on; plot(x,y,'yo');
%          set(hf,'position',[200,200,900,900]);
%           pause(1);
  
          
          try 
          dotI(i,:) = I2(Neibs);
          catch err
             disp(err.message);  
          end
        end

    x= linspace(0,16,20);
        figure(2); clf; 
        allpix = hist(log2(double(I2(:))),x);
        dotpix = hist(log2(dotI(:)),x); 
        bar(x,allpix,'FaceColor','b'); hold on;
        bar(x,dotpix,'FaceColor','r'); alpha(.7); xlim([0,16]);
        
        x = linspace(0,2^14,100); 
         figure(3); clf; 
        allpix = hist((double(I2(:))),x);
        dotpix = hist((dotI(:)),x); 
        bar(x,allpix,'FaceColor','b','EdgeColor','b'); hold on;
        bar(x,dotpix,'FaceColor','r','EdgeColor','r'); alpha(.7); xlim([0,max(x)]);
        legend('intensities, all pixels','intensities, dot pixels'); 
        set(gcf,'color','k');
        
toc
disp('layer finished');
end

figure(1); clf;   imagesc(I2); colormap hot;                
      hold on; plot(rna_x1,rna_y1,'co');


%%
nullerr = zeros(1,Ds); 
doterr = zeros(1,Ds); 
   Ex = fspecial('gaussian',dot_rad,3); 
   Ex = Ex-min(Ex(:)) ;
   Ex = Ex./(max(Ex(:)));
    figure(8); clf; imagesc(Ex);

   
for i=1:Ds
mydot = dotI(i,:);

%mydot = In2(451:460,451:460); mydot = double(mydot(:));

    mydot = mydot - min(mydot(:));
    mydot = mydot./max(mydot);
    mydot = reshape(mydot,dot_rad,dot_rad);
    figure(9); clf; imagesc(mydot);
   
    pause(.01);
    
  DE = (Ex - mydot).^2; % error;
%   figure(8); clf; imagesc(DE);
%   colorbar; caxis([0,1]); 
   doterr(i) = mean(DE(:));
   
   nullerr(i) = mean((rand(dot_rad^2,1) - Ex(:)).^2);
    
   
end
    x = linspace(0,.3,30);
    de =  hist(doterr,x); 
    ne =  hist(nullerr,x); 
    figure(7); clf; bar(x,de,'FaceColor','b','EdgeColor','b'); hold on; 
    bar(x,ne,'FaceColor','r','EdgeColor','r');  alpha(.7);
    legend('Gaussian MSE for dots','Gaussian MSE for random');
    set(gcf,'color','k');
    
    
    
    
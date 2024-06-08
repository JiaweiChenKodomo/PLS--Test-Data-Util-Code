function plotKlems2(klems_vec, addPatch, rangeMax, rangeMin)
% Let's reuse this script from Alex to plot the Klems basis. Jiawei.
% In this code, the klems basis data is projected onto a plane. 

% klems_vec: the 145 * 1 vector of the readings in the Klems basis.
% addPatch: if ==1, add the patch number to the figure. 

% Author: Alex R. Mead
% Date: May 2016

% R - matrix(n,m) with the pixel's radius value in polar coordinates
% THETA - matrix(n,m) with the pixel's theta value in polar coordinates 
% klems - matrix(n,m) with the klems basis path number for each pixel

if ~exist('addPatch', 'var')
    addPatch = 1;
end

if ~exist('rangeMax', 'var')
    rangeMax = max(klems_vec);
end

if ~exist('rangeMin', 'var')
    rangeMin = min(klems_vec);
end

% Picture height and width:
% (These can be adjusted and will change the produced headers.)
%Y = 1280;
%X = 1920;
%rad = 605; % roughly the fisheye lens radius in pixels: rad ~= Y/2
Y = 480;
X = 720;
rad = 227;
% Must calculate the focual length in pixels. This is the projection
% equation for a equi-solid angle, circular fisheye lens expressing the
% focal length in terms of the radius and pixel distance at that radius.
fpixel = rad/(2*sind(90/2));

xShift = X/2;
yShift = Y/2;

% Create x and y matrices for the pixels
xBase = [0:1:X-1];
%x = repmat(xBase,Y,1);
%yBase = [0:1:Y-1]';
%y = repmat(yBase,1,X);
yBase = [0:1:Y-1];
[x, y] = meshgrid(xBase, yBase);

% Shift the x and y matrices to align the origin as the center of the photo
% measurement.
x = x-xShift; 
%y = y-yShift+3; % Slighlty more shifting down that half way. A product of visual inspection of the picture.
y = y-yShift;

% Convert from cartesian to polar coordinates. These are now the base theta
% and rho values for the associated pixels in the matrices position
[theta, rho] = cart2pol(x,y);

% Process rho and theta for proper orientations
% rho: must zero out pixels not in fisheye exposure
for i=1:Y
    for j=1:X
        if rho(i,j)>rad
           rho(i,j)=-1; 
        end
    end
end
% theta: must make all thetas in [0,2*pi]
for i=1:Y
    for j=1:X
        if theta(i,j)<0
           theta(i,j) = theta(i,j) + 2*3.1415; 
        end
    end
end

% Write rho and theta to file
%csvwrite('theta.csv',theta);
%csvwrite('rho.csv',rho);

% Populate the Rinner, Router, thetaStart, thetaEnd
Rinner = zeros(1,145);
Router = zeros(1,145);
thetaStart = zeros(1,145);
thetaEnd = zeros(1,145);

% Some holder constants
segments = [1,8,16,20,24,24,24,16,12];
starts = [1,2,10,26,46,70,94,118,134];
stops = [1,9,25,45,69,93,117,133,145];

% 'angles' is precisely what needs changing, it is then implemented in lines 101 and 102 in the Rinner and Router calculations.  
%angles = [0,5/90,15/90,25/90,35/90,45/90,55/90,65/90,75/90,90/90];
ang = [0,5,15,25,35,45,55,65,75,90];
angles = (2*fpixel*sind(ang/2))/rad;% This is the corrected value

% Loop through each ring
for j=1:1:9
   % Ring Specific constants
   segs = segments(j);
   segArc = 2*pi/segs;
   start = starts(j);
   %stop = stops(j);
   
   for i=1:1:segs
      patch = start+(i-1);
      Rinner(patch)=angles(j)*rad;
      Router(patch)=angles(j+1)*rad;
      thetaStart(patch)=-(segArc/2)+segArc*(i-1)+pi;
      thetaEnd(patch)=-(segArc/2)+segArc*(i)+pi;
      
      if(thetaStart(patch)>2*pi)
          thetaStart(patch) = thetaStart(patch)-2*pi;
      end
      if(thetaEnd(patch)>2*pi)
          thetaEnd(patch) = thetaEnd(patch)-2*pi;
      end
   end
    
end

% Make a klems basis specifier
klems = zeros(Y,X) + rangeMax;

% This loop assigns the klems value to each pixel explicitly
%Check klems basis readings
for k = 1:145
    for i=1:Y
        for j=1:X
           if(thetaStart(k)<=theta(i,j) && theta(i,j)<thetaEnd(k))
               if(Rinner(k)<=rho(i,j) && rho(i,j)<Router(k))
                   klems(i,j) = klems_vec(k);                   
               end
           end
           if(thetaStart(k)>thetaEnd(k))
              if((thetaStart(k)<=theta(i,j)&&theta(i,j)<2*pi)||(0<=theta(i,j)&&theta(i,j)<thetaEnd(k)))
                  if(Rinner(k)<=rho(i,j) && rho(i,j)<Router(k))
                      klems(i,j) = klems_vec(k);                      
                  end
              end
           end
        end
    end
end

% Display the klems patches here

%fig1 = figure;
%hold on;
%set(fig1, 'units','centimeters','pos',[1 1 24 18])

%title('Klems Patches');
xlabel('x');ylabel('y');
surf(1:X,1:Y,klems,'Linestyle','none');
%pcolor(1:X,1:Y,klems);
colormap('hot')
caxis([rangeMin, rangeMax]);
axis([0 X 0 Y ])

%view_z = -1; % This outputs the same projection as fig. 15-4 (b) in the WINDOW Technical report.
%view([0,0,view_z]);
%view([0,0,1]);
colorbar;

if (addPatch)
    z_no = max(max(klems)) * view_z;
    for k = 1:145
        r_no = (Rinner(k) + Router(k)) / 2;
        theta_no = (thetaStart(k) + thetaEnd(k)) / 2;
        if theta_no < thetaStart(k)
            theta_no = theta_no + pi;
        end
        [x_no, y_no] = pol2cart(theta_no, r_no);
        text(x_no + xShift, y_no + yShift, z_no, num2str(k));
    end
end

end
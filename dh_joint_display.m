clearvars
clc
format short



%%%%%%   Connection to Rasperry Pi Server   %%%%%%

%add current path to python to load client
if count(py.sys.path, pwd) == 0
    insert(py.sys.path,int32(0),pwd);
end

%import client from python
client = py.importlib.import_module('client').client();

%start the client and connect to server
t0 = client.start();

%%%%%%   Initial Set Up of Data   %%%%%%

%Variable Defeintion
%syms th2 th3 th4 d1

a1 = 0;        %change depending on length from one joint to another
a2 = 0;
a3 = 1;
a4 = 1;

d1 = .25;       %only d1 changes depending on length from base to first joint
d2 = 0;
d3 = 0;
d4 = 0;

alp1 = -90;   %Alpha Values do not change
alp2 = 90;
alp3 = 0;
alp4 = 0;

th1 = 0;    %Theta1 will always be 0
th2 = -90;
th3 = 0;
th4 = 0;
 

%THIS SECTION OF CODE HAS BEEN COMMENTED OUT AS IT WAS DEEMED UNNECESSARY
% %Rotation Matrix Construction
% Ar1 = [cosd(th1) -sind(th1)*cosd(alp1) sind(th1)*sind(alp1) a1*cosd(th1);...
%       sind(th1) cosd(th1)*cosd(alp1) -cosd(th1)*sind(alp1) a1*sind(th1);...
%       0 sind(alp1) cosd(alp1) d1;...
%       0 0 0 1];
%   
% Ar2 = [cosd(th2) -sind(th2)*cosd(alp2) sind(th2)*sind(alp2) a2*cosd(th2);...
%       sind(th2) cosd(th2)*cosd(alp2) -cosd(th2)*sind(alp2) a2*sind(th2);...
%       0 sind(alp2) cosd(alp2) d2;...
%       0 0 0 1];
%   
% Ar3 = [cosd(th3) -sind(th3)*cosd(alp3) sind(th3)*sind(alp3) a3*cosd(th3);...
%       sind(th3) cosd(th3)*cosd(alp3) -cosd(th3)*sind(alp3) a3*sind(th3);...
%       0 sind(alp3) cosd(alp3) d3;...
%       0 0 0 1];
%   
% Ar4 = [cosd(th4) -sind(th4)*cosd(alp4) sind(th4)*sind(alp4) a4*cosd(th4);...
%       sind(th4) cosd(th4)*cosd(alp4) -cosd(th4)*sind(alp4) a4*sind(th4);...
%       0 sind(alp4) cosd(alp4) d4;...
%       0 0 0 1];
%   
% %Origin Matrix Defenition
% o0 = zeros(4,4);
% o1 = Ar1;
% o2 = Ar1*Ar2;
% o3 = Ar1*Ar2*Ar3;
% o4 = Ar1*Ar2*Ar3*Ar4;
% 
% %Origin Coordinate Definition
% xyz0 = [0 0 0];
% xyz1 = [o1(1,4) o1(2,4) o1(3,4)];
% xyz2 = [o2(1,4) o2(2,4) o2(3,4)];
% xyz3 = [o3(1,4) o3(2,4) o3(3,4)];
% xyz4 = [o4(1,4) o4(2,4) o4(3,4)];
% 
% %Produce Coordinates of points in form readable by plot3
% xdata = [xyz0(1) xyz1(1) xyz2(1) xyz3(1) xyz4(1)];
% ydata = [xyz0(2) xyz1(2) xyz2(2) xyz3(2) xyz4(2)];
% zdata = [xyz0(3) xyz1(3) xyz2(3) xyz3(3) xyz4(3)];
%END UNNECESSARY CODE BLOCK

%Initail Plotting Datat
xdata = zeros(1,5);
ydata = zeros(1,5);
zdata = zeros(1,5);
kdata = ones(1, 160)*180;
tdata = zeros(1, 160);

%set up large figure
figure('Position', [100, 100, 1200, 600])

%plot data in three dimentions
subplot(1,2,1)
fig1 = plot3(xdata, ydata, zdata, 'b-o');
xlabel('x')
ylabel('y')
zlabel('z')
axis([-2, 2, -2, 2, 0, 4])
grid on

%plot knee angle
subplot(1,2,2)
fig2 = plot(tdata, kdata, 'r-');
grid on
ylim([-90,90])
xlabel('t')
ylabel('knee angle')


%%%%%%   Update Data   %%%%%

%set data sources to update graph properly
fig1.XDataSource = 'xdata';
fig1.YDataSource = 'ydata';
fig1.ZDataSource = 'zdata';
fig2.XDataSource = 'tdata';
fig2.YDataSource = 'kdata';

%set Loop to update data
%loop while running
running = true;
while running
    %get Femur data from python client
    %Femur Data is pulled from Lower IMU Sensor, with Red LED
    x1 = client.get('rf', 0);
    y1 = client.get('rf', 1);
    z1 = client.get('rf', 2);

    %get data from python client
    %Tibia Data is pulled from Upper IMU Sensor, with Green LED
    x2 = client.get('rt', 0);
    y2 = client.get('rt', 1);
    z2 = client.get('rt', 2);
    
    th1 = 0;    %Theta1 will always be 0
    th3 = z1;  %Adjust values with data from RaspPi once angles are isolated
    th2 = -x1-90;
    th4 = z2-z1;
    
    %Calculate Knee Angle from Above Angle Values
    knee = th4;
    
    % Reproduce Rotation Matrix Construction
    Ar1 = [cosd(th1) -sind(th1)*cosd(alp1) sind(th1)*sind(alp1) a1*cosd(th1);...
          sind(th1) cosd(th1)*cosd(alp1) -cosd(th1)*sind(alp1) a1*sind(th1);...
          0 sind(alp1) cosd(alp1) d1;...
          0 0 0 1];
  
    Ar2 = [cosd(th2) -sind(th2)*cosd(alp2) sind(th2)*sind(alp2) a2*cosd(th2);...
          sind(th2) cosd(th2)*cosd(alp2) -cosd(th2)*sind(alp2) a2*sind(th2);...
          0 sind(alp2) cosd(alp2) d2;...
          0 0 0 1];
  
    Ar3 = [cosd(th3) -sind(th3)*cosd(alp3) sind(th3)*sind(alp3) a3*cosd(th3);...
          sind(th3) cosd(th3)*cosd(alp3) -cosd(th3)*sind(alp3) a3*sind(th3);...
          0 sind(alp3) cosd(alp3) d3;...
          0 0 0 1];
  
    Ar4 = [cosd(th4) -sind(th4)*cosd(alp4) sind(th4)*sind(alp4) a4*cosd(th4);...
          sind(th4) cosd(th4)*cosd(alp4) -cosd(th4)*sind(alp4) a4*sind(th4);...
          0 sind(alp4) cosd(alp4) d4;...
          0 0 0 1];
  
    % Reproduce Origin Matrix Defenition
    o0 = zeros(4,4);
    o1 = Ar1;
    o2 = Ar1*Ar2;
    o3 = Ar1*Ar2*Ar3;
    o4 = Ar1*Ar2*Ar3*Ar4;
    
    % Reproduce Origin Coordinate Definition
    xyz0 = [0 0 0];
    xyz1 = [o1(1,4) o1(2,4) o1(3,4)];
    xyz2 = [o2(1,4) o2(2,4) o2(3,4)];
    xyz3 = [o3(1,4) o3(2,4) o3(3,4)];
    xyz4 = [o4(1,4) o4(2,4) o4(3,4)];

    % Reproduce Produce Coordinates of points in form readable by plot3
    xdata = [xyz0(1) xyz1(1) xyz2(1) xyz3(1) xyz4(1)];
    ydata = [xyz0(2) xyz1(2) xyz2(2) xyz3(2) xyz4(2)];
    zdata = [xyz0(3) xyz1(3) xyz2(3) xyz3(3) xyz4(3)];
    tdata = [tdata(2:length(tdata)), client.get('t') - t0];
    kdata = [kdata(2:length(kdata)), knee];
    
    %try to update and draw to figure
    try
        refreshdata(fig1, 'caller')
        refreshdata(fig2, 'caller')
        pause(0.050)
        
    %stop client and loop if figure has been closed
    catch
        client.stop()
        running = false;
    end
end



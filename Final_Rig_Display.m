%clear workspace
clc
clearvars

%initialize data
xdata = [0, 0, 0, 0, 0, 0];
ydata = [-.25, -.25, -.25, .25, .25, .25];
zdata = [0, 1, 2, 2, 1, 0];

%log data into one matrix
data_log = [0, 180];

%set up large figure
figure('Position', [100, 100, 700, 700])

%plot data in three dimentions
subplot(1,1,1)
fig1 = plot3(xdata, ydata, zdata, 'b-o');
xlabel('x')
ylabel('y')
zlabel('z')
axis([-2, 2, -2, 2, 0, 4])
grid on


%set data sources to update 3D plot
fig1.XDataSource = 'xdata';
fig1.YDataSource = 'ydata';
fig1.ZDataSource = 'zdata';

%add current path to python to load client
if count(py.sys.path, pwd) == 0
    insert(py.sys.path,int32(0),pwd);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
end

%import client from python
client = py.importlib.import_module('client').client();

%start the client and get start time in seconds from epoch
t0 = client.start();

%loop while running
running = true;
while running
    
    %get data from python client
    t = client.get('t');
    x1 = client.get('rf', 0);
    y1 = client.get('rf', 1);
    z1 = client.get('rf', 2);
    x2 = client.get('rt', 0);
    y2 = client.get('rt', 1);
    z2 = client.get('rt', 2);
 
    %calculate rotation matrix for each data value
    rx1 = [1, 0, 0; 0, cosd(x1), -sind(x1); 0, sind(x1), cosd(x1)];
    ry1 = [cosd(y1), 0, sind(y1); 0, 1, 0; -sind(y1), 0, cosd(y1)];
    rz1 = [cosd(z1), -sind(z1), 0; sind(z1), cosd(z1), 0; 0, 0, 1];
    
    %calculate rotation matrix for vector 2
    rx2 = [1, 0, 0; 0, cosd(x2), -sind(x2); 0, sind(x2), cosd(x2)];
    ry2 = [cosd(y2), 0, sind(y2); 0, 1, 0; -sind(y2), 0, cosd(y2)];
    rz2 = [cosd(z2), -sind(z2), 0; sind(z2), cosd(z2), 0; 0, 0, 1];
    
    %calculate vector 1 for left femur
    lfv = [1,0,0;0,0,1;0,-1,0]*rx1*ry1*rz1*[0;0;-1];

    %calculate vector 2 for right femur
    rfv = [0;0;-1];%rx2*ry2*rz2*[0;0;-1];
    
    %update 3D plot data
    xdata = [0, 0, 0, 0, lfv(1), rfv(1)+lfv(1)];
    ydata = [-.25, -.25, -.25, .25, .25+lfv(2), .25+rfv(2)+lfv(2)];
    zdata = [0, 1, 2, 2, 2+lfv(3), 2+rfv(3)+lfv(3)];

    
    %try to update and draw to figure
    try
        %refresh plot data and drawnow using pause
        refreshdata(fig1, 'caller')
        pause(0.050)
        
    %stop client and loop if figure has been closed
    catch
        %stop everything and output data log
        client.stop()
        running = false;
        disp(data_log);
    end
end
%clear workspace
clc
clearvars

%initialize data
xdata = [0, 0, 0, 0, 0, 0];
ydata = [0, 1, 2, 2, 1, 0];
zdata = [-.25, -.25, -.25, .25, .25, .25];

%log data into one matrix
data_log = [0, 180];

%set up large figure
figure('Position', [100, 100, 700, 700])

%plot data in three dimentions
subplot(1,1,1)
fig1 = plot3(zdata, xdata, ydata, 'b-o');
xlabel('z')
ylabel('x')
zlabel('y')
axis([-2, 2, -2, 2, 0, 4])
grid on

%set data sources to update 3D plot
fig1.XDataSource = 'zdata';
fig1.YDataSource = 'xdata';
fig1.ZDataSource = 'ydata';

%add current path to python to load client
if count(py.sys.path, pwd) == 0
    insert(py.sys.path,int32(0),pwd);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
end

%import client from python
client = py.importlib.import_module('client').client();

%start the client and get start time in seconds from epoch
t0 = client.start(); 

%initialize data for data recording, add titles to columns
row_count = 1;
syms time rfemurx rfemury rfemurz lfemurx lfemury lfemurz rtibiax rtibiay rtibiaz ltibiax ltibiay ltibiaz torsox torsoy torsoz
data_matrix = [' ' , time, rfemurx, rfemury, rfemurz, lfemurx, lfemury, lfemurz, rtibiax, rtibiay, rtibiaz, ltibiax, ltibiay, ltibiaz, torsox, torsoy, torsoz];

%loop while running
running = true;
while running
    
    %get data from python client
    t = client.get('t');
    x1 = client.get('rf', 0);
    y1 = client.get('rf', 1);
    z1 = client.get('rf', 2);
    x2 = client.get('lf', 0);
    y2 = client.get('lf', 1);
    z2 = client.get('lf', 2);
    x3 = 0;
    y3 = 0;
    z3 = 0;
    x4 = 0;
    y4 = 0;
    z4 = 0;
    x5 = 0;
    y5 = 0;
    z5 = 0;

    %calculate rotation matrix for each data value
    rx1 = [1, 0, 0; 0, cosd(x1), -sind(x1); 0, sind(x1), cosd(x1)];
    ry1 = [cosd(y1), 0, sind(y1); 0, 1, 0; -sind(y1), 0, cosd(y1)];
    rz1 = [cosd(z1), -sind(z1), 0; sind(z1), cosd(z1), 0; 0, 0, 1];
    
    %calculate rotation matrix for vector 2
    rx2 = [1, 0, 0; 0, cosd(x2), -sind(x2); 0, sind(x2), cosd(x2)];
    ry2 = [cosd(y2), 0, sind(y2); 0, 1, 0; -sind(y2), 0, cosd(y2)];
    rz2 = [cosd(z2), -sind(z2), 0; sind(z2), cosd(z2), 0; 0, 0, 1];
    
    %calculate rotation matrix for vector 3
    rx3 = [1, 0, 0; 0, cosd(x3), -sind(x3); 0, sind(x3), cosd(x3)];
    ry3 = [cosd(y3), 0, sind(y3); 0, 1, 0; -sind(y3), 0, cosd(y3)];
    rz3 = [cosd(z3), -sind(z3), 0; sind(z3), cosd(z3), 0; 0, 0, 1];
           
    %calculate rotation matrix for vector 3
    rx4 = [1, 0, 0; 0, cosd(x4), -sind(x4); 0, sind(x4), cosd(x4)];
    ry4 = [cosd(y4), 0, sind(y4); 0, 1, 0; -sind(y4), 0, cosd(y4)];
    rz4 = [cosd(z4), -sind(z4), 0; sind(z4), cosd(z4), 0; 0, 0, 1];
        
    %calculate rotation matrix for vector 3
    rx5 = [1, 0, 0; 0, cosd(x5), -sind(x5); 0, sind(x5), cosd(x5)];
    ry5 = [cosd(y5), 0, sind(y5); 0, 1, 0; -sind(y5), 0, cosd(y5)];
    rz5 = [cosd(z5), -sind(z5), 0; sind(z5), cosd(z5), 0; 0, 0, 1];

    %calculate vector 1 for left femur
    lfv = rx1*rz1*[0;1;0];

    %calculate vector 2 for right femur
    rfv = rx1*rz2*[0;1;0];
    
    %calcualte vector 3 for left tibia
    ltv = rx3*rz3*[0;1;0];
    
    %calculate vector 4 for right tibia
    rtv = rx4*rz4*[0;1;0];
    
    %calculate vector 5 for torso
    tv = rx5*rz5*[0;1;0];    
       
    %update 3D plot data
    xdata = [rfv(1)+rtv(1), rfv(1), 0, 0, lfv(1), lfv(1)+ltv(1)];
    ydata = [2-rfv(2)-rtv(2), 2-rfv(2), 2, 2, 2-lfv(2), 2-lfv(2)-ltv(2)];
    zdata = [.25+rfv(3)+rtv(3), .25+rfv(3), .25, -.25, -.25+lfv(3), -.25+lfv(3)+lfv(3)];
    
    %Concactinate new data pull to data matrix
    next_row = [row_count, t x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, x5, y5, z5];
    data_matrix = [data_matrix; next_row];
    row_count = row_count+1;
    
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
%clear workspace
clc
clearvars

%make unit vector for limbs
u = [0;1;0];

%initialize data
xdata = [0, 0, 0];
ydata = [0, 1, 2];
zdata = [0, 0, 0];
kdata = 0;
tdata = 0;

%log data into one matrix
data_log = [0, 180];

%set up large figure
figure('Position', [200, 200, 1200, 500])

%plot data in three dimentions
subplot(1,2,1)
fig1 = plot3(zdata, xdata, ydata, 'b-o');
xlabel('z')
ylabel('x')
zlabel('y')
axis([-2, 2, -2, 2, 0, 4])
grid on

%plot knee angle
subplot(1,2,2)
fig2 = plot(tdata, kdata, 'r-');
grid on
axis([-10, 0, -100, 100])
xlabel('t - t_f')
ylabel('Knee Angle')

%set data sources to update 3D plot
fig1.XDataSource = 'zdata';
fig1.YDataSource = 'xdata';
fig1.ZDataSource = 'ydata';

%set data sources for knee angle plot
fig2.XDataSource = 'tdata';
fig2.YDataSource = 'kdata';

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

    %calculate vector 1
    v1 = rx1*rz1*u;

    %calculate vector 2
    v2 = rx2*rz2*u;
    
    %calculate angle of knee from vectors
    knee = acosd(dot(v1,v2)/norm(v1)/norm(v2));

    %add data to log
    data_log = [data_log; [t-t0, knee]];
    
    %update 3D plot data
    xdata = [0, v1(1), v2(1)+v1(1)];
    ydata = [0, v1(2), v2(2)+v1(2)];
    zdata = [0, v1(3), v2(3)+v1(3)];
    
    %update knee plot data
    tdata = data_log(1 + end - min(end, 200):end, 1) - t + t0;
    kdata = data_log(1 + end - min(end, 200):end, 2);
    
    %try to update and draw to figure
    try
        %refresh plot data and drawnow using pause
        refreshdata(fig1, 'caller')
        refreshdata(fig2, 'caller')
        pause(0.050)
        
    %stop client and loop if figure has been closed
    catch
        %stop everything and output data log
        client.stop()
        running = false;
        disp(data_log);
    end
end
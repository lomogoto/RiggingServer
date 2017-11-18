%clear workspace
clc
clearvars

%add current path to python to load client
if count(py.sys.path, pwd) == 0
    insert(py.sys.path,int32(0),pwd);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
end

%import client from python
client = py.importlib.import_module('client').client();

%start the client and get start time in seconds from epoch
t0 = client.start();

%make unit vector for limbs
u = [0;1;0];

%initialize data
xdata = [0, 0, 0];
ydata = [0, 1, 2];
zdata = [0, 0, 0];
kdata = ones(1, 160)*180;
tdata = zeros(1, 160);

%set up large figure
figure('Position', [100, 200, 1500, 750])

%plot data in three dimentions
subplot(1,2,1)
fig1 = plot3(xdata, ydata, zdata, 'b-o');
xlabel('x')
ylabel('y')
zlabel('z')
axis([-2, 2, -2, 2, -2, 2])
grid on

%plot knee angle
subplot(1,2,2)
fig2 = plot(tdata, kdata, 'r-');
grid on
ylim([0,180])
xlabel('t')
ylabel('Knee Angle')

%set data sources to update graph properly
fig1.XDataSource = 'xdata';
fig1.ZDataSource = 'ydata';
fig1.YDataSource = 'zdata';
fig2.XDataSource = 'tdata';
fig2.YDataSource = 'kdata';

%add text info
text = uicontrol('Style', 'text', 'HorizontalAlignment', 'left', 'Position', [10, 10, 200, 20]);

%loop while running
running = true;
while running
    %get data from python client
    x = client.get('rf', 0)*pi/180;
    y = client.get('rf', 1)*pi/180;
    z = client.get('rf', 2)*pi/180;

    %calculate rotation matrix for each data value
    rx = [1, 0, 0; 0, cos(x), -sin(x); 0, sin(x), cos(x)];
    ry = [cos(y), 0, sin(y); 0, 1, 0; -sin(y), 0, cos(y)];
    rz = [cos(z), -sin(z), 0; sin(z), cos(z), 0; 0, 0, 1];

    %calculate vector 1
    v1 = rz*ry*rx*u;

    %get data from python client
    x = client.get('rt', 0)*pi/180;
    y = client.get('rt', 1)*pi/180;
    z = client.get('rt', 2)*pi/180;

    %calculate rotation matrix for each data value
    rx = [1, 0, 0; 0, cos(x), -sin(x); 0, sin(x), cos(x)];
    ry = [cos(y), 0, sin(y); 0, 1, 0; -sin(y), 0, cos(y)];
    rz = [cos(z), -sin(z), 0; sin(z), cos(z), 0; 0, 0, 1];

    %calculate vector 2
    v2 = rz*ry*rx*u;
    
    %calculate angle of knee from vectors
    knee = 180 - acos(dot(v1,v2)/norm(v1)/norm(v2))*180/pi;

    %update data
    xdata = [0, v1(1), v2(1)+v1(1)];
    ydata = [0, v1(2), v2(2)+v1(2)];
    zdata = [0, v1(3), v2(3)+v1(3)];
    tdata = [tdata(2:length(tdata)), client.get('t') - t0];
    kdata = [kdata(2:length(kdata)), knee];
    
    %try to update and draw to figure
    try
        %set(text, 'String', strjoin(['Knee: ', string(knee)]))
        refreshdata(fig1, 'caller')
        refreshdata(fig2, 'caller')
        pause(0.050)
        
    %stop client and loop if figure has been closed
    catch
        client.stop()
        running = false;
    end
end
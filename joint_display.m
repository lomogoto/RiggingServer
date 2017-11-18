%clear workspace
clc
clearvars

%add current path to python to load client
if count(py.sys.path, pwd) == 0
    insert(py.sys.path,int32(0),pwd);
end

%import client from python
client = py.importlib.import_module('client').client();

%start the client and connect to server
client.start()

%make unit vector for limbs
u = [0;1;0];

%initialize data
xdata = [0, 0, 0];
ydata = [0, 0, 0];
zdata = [0, 1, 2];

%plot data in three dimentions
fig = plot3(xdata, ydata, zdata, 'b-o');
xlabel('x')
ylabel('y')
zlabel('z')
axis([-2, 2, -2, 2, -2, 2])
grid on

%set data sources to update graph properly
fig.XDataSource = 'xdata';
fig.YDataSource = 'ydata';
fig.ZDataSource = 'zdata';

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

    %update data
    xdata = [0, v1(1), v2(1)+v1(1)];
    ydata = [0, v1(2), v2(2)+v1(2)];
    zdata = [0, v1(3), v2(3)+v1(3)];
    
    %calculate angle of knee from vectors
    knee = 180 - acos(dot(v1,v2)/norm(v1)/norm(v2))*180/pi;
    
    %try to update and draw to figure
    try
        %set(text, 'String', strjoin(['Knee: ', string(knee)]))
        refreshdata(fig, 'caller')
        drawnow limitrate
        
    %stop client and loop if figure has been closed
    catch
        client.stop()
        running = false;
    end
end
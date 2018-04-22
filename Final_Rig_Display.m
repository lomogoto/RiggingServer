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
    rfx = client.get('rf', 0);
    rfy = client.get('rf', 2);
    rfz = 0;
    
    rtx = client.get('rt', 1);
    rty = client.get('rt', 2);
    rtz = 0;
 
    lfx = -client.get('lf', 0);
    lfy = client.get('lf', 2);
    lfz = 0;
    
    ltx = -client.get('lt', 1);
    lty = client.get('lt', 2);
    ltz = 0;
    
    %calculate rotation matrix for each data value
    Rrfx = [1, 0, 0; 0, cosd(rfx), -sind(rfx); 0, sind(rfx), cosd(rfx)];
    Rrfy = [cosd(rfy), 0, sind(rfy); 0, 1, 0; -sind(rfy), 0, cosd(rfy)];
    Rrfz = [cosd(rfz), -sind(rfz), 0; sind(rfz), cosd(rfz), 0; 0, 0, 1];
    
    %calculate rotation matrix for vector 2
    Rrtx = [1, 0, 0; 0, cosd(rtx), -sind(rtx); 0, sind(rtx), cosd(rtx)];
    Rrty = [cosd(rty), 0, sind(rty); 0, 1, 0; -sind(rty), 0, cosd(rty)];
    Rrtz = [cosd(rtz), -sind(rtz), 0; sind(rtz), cosd(rtz), 0; 0, 0, 1];
    
    %calculate rotation matrix for each data value
    Rlfx = [1, 0, 0; 0, cosd(lfx), -sind(lfx); 0, sind(lfx), cosd(lfx)];
    Rlfy = [cosd(lfy), 0, sind(lfy); 0, 1, 0; -sind(lfy), 0, cosd(lfy)];
    Rlfz = [cosd(lfz), -sind(lfz), 0; sind(lfz), cosd(lfz), 0; 0, 0, 1];
    
    %calculate rotation matrix for vector 2
    Rltx = [1, 0, 0; 0, cosd(ltx), -sind(ltx); 0, sind(ltx), cosd(ltx)];
    Rlty = [cosd(lty), 0, sind(lty); 0, 1, 0; -sind(lty), 0, cosd(lty)];
    Rltz = [cosd(ltz), -sind(ltz), 0; sind(ltz), cosd(ltz), 0; 0, 0, 1];
    
    %calculate vectors
    rf = Rrfx*Rrfy*Rrfz*[0;0;-1];
    rt = Rrtx*Rrty*Rrtz*[0;0;-1];
    lf = Rlfx*Rlfy*Rlfz*[0;0;-1];
    lt = Rltx*Rlty*Rltz*[0;0;-1];
    
    %update 3D plot data
    xdata = [rf(1)+rt(1), rf(1), 0, 0, lf(1), lf(1)+lt(1)];
    ydata = [rf(2)+rt(2)-0.25, rf(2)-0.25, -0.25, 0.25, lf(2)+0.25, lf(2)+lt(2)+0.25];
    zdata = [rf(3)+rt(3)+2, rf(3)+2, 2, 2, lf(3)+2, lf(3)+lt(3)+2];

    
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
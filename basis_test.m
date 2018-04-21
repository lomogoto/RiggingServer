a = [0.1;0.5;-1];
m = [2;0;0];

%identity when x faces north and z faces up (a = [0;0;-1] and m = [1;0;0])
z = -a/norm(a);
x = m-z*dot(z,m);
x = x/norm(x);
y = cross(z, x);

R = [x,y,z];
disp(R);
disp(R*[0;1;0]);

sy = norm([R(1,1); R(2,2)]);

if sy > 1e-6
    alpha = atan2(R(3,2), R(3,3));
    beta = atan2(-R(3,1), sy);
    gamma = atan2(R(2,1), R(1,1));
else
    alpha = atan2(-R(2,3), R(2,2));
    beta = atan2(-R(3,1), sy);
    gamma = 0;
end

disp(alpha*180/pi)
disp(beta*180/pi)
disp(gamma*180/pi)
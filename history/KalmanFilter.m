function out = KalmanFilter(y)
% Kalman Filter
persistent A M Q R x P Init

% Initialize
if isempty(Init)
  Init = 1;
  A = [ 1 1;
        0 1 ];
  M = [ 1 0 ]; 
  Q = [ 100 0 ;
        0  100];
  R = 10;
  x = [ 0 y ]';
  P = 100 * eye(2);
end

% Predict
xp = A * x;
Pp = A * P * A' + Q;

% Update
K = Pp * M' / ( M * Pp * M' + R);
x = xp + K * (y - M * xp);
P = Pp - K * M * Pp;   

% ouput
out = x;

end
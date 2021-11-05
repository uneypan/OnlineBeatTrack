function out = KalmanFilterforPDA(y,bta)
    % Kalman Filter
    persistent A M Q R x P Init
    
    % Initialize
    if isempty(Init)
      Init = 1;
      A = [ 1 1;
            0 1 ];
      M = [ 1 0 ]; 
      Q = [ 1000 0 ;
            0  400];
      R = 1;
      x = [ 0 y ]';
      P = 10 * eye(2);
    end
    
    % Predict
    xp = A * x;

    Pp = A * P * A' + Q;
    
    % Update
    K = Pp * M' / ( M * Pp * M' + R);

    x = xp + K * sum((y - M * xp) .* bta);

    P0 = ( eye(2) - K * M ) * Pp;

    yh = y - M * xp;

    Ph = K * ( sum( bta * (yh * yh') ) - yh * yh' )  * K';

    P = ( 1 - sum(bta) ) * Pp + sum(bta) * P0 + Ph;  
    
    % ouput
    out = [x ,P] ;
    

    end
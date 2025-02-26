function [T,Y,info] = Trapezoidal_AdaptiveStep( ...
                 funJac,tspan,n,y0,abstol,reltol,type,varargin)

switch type
    case 'asymptotic'
        ki = 1/3; kp = 0;
    case 'PI'
        ki = 0.4/3; kp = 0.3/3;
end
% Controller parameters
epstol = 0.8;
facmin = 0.1;
facmax = 5.0;

% Set tolerance and max number of iterations for the solver
tol = 1.0e-8;
maxit = 100;

% Trapezoidal method
Y = y0;
T(1) = tspan(1);

% Compute initial step size
hn = (tspan(2)-tspan(1))/(n-1);

% Information for testing
funeval = 0;
hvec = [];
rvec = [];

while T(end) < tspan(2)
    
    % Size of last step
    if T(end)+hn > tspan(2)
        hn = tspan(2) - T(end);
    end
    
    f = feval(funJac,T(end),Y(:,end),varargin{:});
    funeval = funeval + 1;
    rp = epstol;
    
    AcceptStep = false;
    while ~ AcceptStep
        h = hn;
        
        % Step size h
        
        % Compute explicit Euler and use it as initial value
        yinit = Y(:,end) + h*f;

        % Solve implicit equation
        [Y1,funevalN] = NewtonsTrapezoidal(funJac, ...
                     T(end),Y(:,end),h,yinit,tol,maxit,varargin{:});
        funeval = funeval + funevalN;
        % Step size h/2
        
        hm = 0.5*h;
        Tm = T(end) + hm;
        
        % Compute first half step
        yinit = Y(:,end) + hm*f;
        [Ym,funevalN] = NewtonsTrapezoidal(funJac,...
             T(end),Y(:,end),hm,yinit,tol,maxit,varargin{:});
       
        % Compute second half step
        fm = feval(funJac,Tm,Ym,varargin{:});
        funeval = funeval + funevalN + 1;
        yinit = Ym + hm*fm;
        [Yhat,funevalN] = NewtonsTrapezoidal(funJac,...
               Tm,Ym,hm,yinit,tol,maxit,varargin{:});
        funeval = funeval + funevalN;
        % Error estimation
        e = Y1 - Yhat;
        r = max(abs(e)./max(abstol,abs(Yhat).*reltol));
        
        % Check conditon
        AcceptStep = r <=1;
        
        % step size controller (Asymptotic or second order PI)
        hn = max(facmin,min((epstol/r)^ki*(rp/r)^kp,facmax))*h;
        rp = r;
    
    end
    
    hvec(end+1) = h;
    rvec(end+1) = r;
    T(end+1) = T(end)+h;    
    Y(:,end+1) = Yhat;
    
end
Y = Y';
info.funeval = funeval;
info.naccept = length(T);
info.nreject = length(hvec) - length(T) + 1;
info.hvec = hvec;
info.rvec = rvec;
end
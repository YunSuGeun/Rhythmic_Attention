%% --- helper: t0 시점까지의 조건부 로그우도(θ full) ---
function ll = singleLogLik(t0, y, X, Mdl_template, theta)
    % 1) 파라미터 분할
    p      = numel(Mdl_template.AR);
    q      = numel(Mdl_template.MA);
    k_beta = size(X,2);
    
    ar_c   = theta(1:p);
    ma_c   = theta(p+1:p+q);
    b_c    = theta(p+q+1:p+q+k_beta);
    v_c    = theta(end);

    % 2) 모형 복사 후 삽입
    M2     = Mdl_template;
    M2.AR  = num2cell(ar_c);
    M2.MA  = num2cell(ma_c);
    M2.Beta      = b_c(:);
    M2.Variance  = v_c;
    
    % 3) 데이터를 t0-m+1..t0 로 잘라서 infer 호출
    m     = max(p,q);
    Ysub  = y((t0-m+1):t0);
    Xsub  = X((t0-m+1):t0, :);
    
    % **주의**: 이 호출이 invertibility 에러를 내면,
    %           eps0 값을 줄이거나 try-catch 로 우회해야 합니다.
    e     = infer(M2, Ysub, 'X', Xsub);
    e_t   = e(end);

    % 4) 단시점 로그우도
    ll    = -0.5*( log(2*pi*v_c) + (e_t^2)/v_c );
end

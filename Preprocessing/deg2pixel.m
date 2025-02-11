
function pixel = deg2pixel(deg,varargin)

% convert visual angle into monitor's pixel

 

%% argument check

options = struct('monitorSize',   [40.6,30.4], 'eyeDistance',   60);    % eye distance 60cm   % horizontal 40.6cm, vertical 30.4cm

optionNames = fieldnames(options);

if mod(length(varargin),2) == 1

    error('Please provide propertyName/propertyValue pairs')

end

for pair = reshape(varargin,2,[])    % pair is {propName; propValue}

    if any(strcmp(pair{1}, optionNames))

        options.(pair{1}) = pair{2};

    else

        error('%s is not a recognized parameter name', pair{1})

    end

end

 

%%

%env = get(0, 'screensize');
env = [1, 1, 1024, 768] ;

%ratio = [env(3)/options.monitorSize(1),env(4)/options.monitorSize(2)];

ratio = sqrt(sum(env(3:4).^2))/sqrt(sum(options.monitorSize.^2));

pixel = round(options.eyeDistance*tand(deg).*ratio);

 

end
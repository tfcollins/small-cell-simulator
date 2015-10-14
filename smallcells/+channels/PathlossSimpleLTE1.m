classdef PathlossSimpleLTE1 < handle
    % Pathloss Class for LTE with gaussian fading and LOS condition
    %
    % If not in LOS 1 wall is added to pathloss value and loss formula
    % slighly changes as well
    %
    % TODO: check what units distance has to be in
    %       GET LWALL Value
    %
    % Model from: http://ieeexplore.ieee.org/lpdocs/epic03/wrapper.htm?arnumber=6868315
    %
    properties (Constant)
        Lwall = 5;
    end
    
    methods
        function obj = PathlossSimpleLTE1()
            
        end
        % Get pathloss from distance
        function pl = GetPathloss(obj,distance,type)
            
            %distance = distance*0.001;
            
            if strcmpi(type,'Signal')
                % No walls
                pl = 28 + 35*log10(distance);
            else % strcmpi(type,'Interference')
                % Through walls
                pl = 38.5 + 20*log10(distance) + obj.Lwall;
            end
            
        end
    end
    
end


classdef PathlossSimpleLTE1 < handle
    % Pathloss Class for LTE with gaussian fading and LOS condition
    %
    % If not in LOS 1 wall is added to pathloss value and loss formula
    % slighly changes as well
    %
    % TODO: check what units distance has to be in
    %       GET LWALL Value
    
    properties (Constant)
        Lwall = 10;
    end
    
    methods
        function obj = PathlossSimpleLTE1()
            
        end
        % Get pathloss from distance
        function pl = GetPathloss(obj,distance,type)
            
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


classdef Generic < handle
    % Generic Traffic Class
    %
    % This is basically a bernoulli trial for traffic generation
    
    properties
        TTIRef = 0;
        TransmitProbability = 1;
        PacketSize = 320; % Bits
    end
    
    
    properties (Constant)
        TTIDuration = 0.001; % (seconds) Equal to 2 PRBs in time
    end
    
    methods
        % Constructor
        function obj = Generic(tp)
            obj.TransmitProbability = tp;
        end
        
        % Call for evolution of UE's traffic
        function BitsToTransmit = TTIUpdate(obj)
            
            % Update time
            obj.TTIRef = obj.TTIRef + obj.TTIDuration;
            
            % Do we need to transmit
            if rand<obj.TransmitProbability
                BitsToTransmit = obj.PacketSize;
            else
                BitsToTransmit = 0;
            end

        end
    end
    
end


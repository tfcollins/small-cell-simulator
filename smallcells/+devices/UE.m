classdef UE < handle & matlab.mixin.SetGet
    % UE Class
    
    properties
        Position = [0,0]; % on map
        PositionRefENB = [0,0]; % 2D place on map in reference to eNB
        AntennaGain = 0;  % dBi
        ChannelSINRdB
        UsingChannels     % Integer array
        Traffic         % Traffic model object
        PacketQueue     % Array of integers, equal to packet size in bits
        PacketDelays    % Array of integers, equal to number of TTI's packet has been in queue
    end
    
    methods
        % Constructor
        function obj = UE()
            
        end
        % Add Packet to queue
        function AddPacket(obj,bits)
            % Expand Queue
            obj.PacketQueue = [obj.PacketQueue,bits];
            % Expand Queue Delay
            obj.PacketDelays = [obj.PacketDelays,0];
        end
        % Add Packet to queue
        function RemovePacket(obj)
            % Delete element Queue
            obj.PacketQueue = obj.PacketQueue(2:end);
            % Delete element Queue Delay
            obj.PacketDelays = obj.PacketDelays(2:end);
        end
        % Add Packet to queue
        function SingleAddPacket(obj,bits)
            % Expand Queue
            obj.PacketQueue = bits;
            % Expand Queue Delay
            obj.PacketDelays = 0;
        end
    end
    
end


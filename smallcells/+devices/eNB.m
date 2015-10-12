classdef eNB < handle & matlab.mixin.SetGet
    % eNB Class:
    
    properties
        Position = [0,0];       % 2D place on map
        TxPower = 20;           % dBm
        AntennaType = 'omni';   % Doesnt do anything yet
        AntennaGain = 2;        % dBi
        Bandwidth = 10e6;       % Hertz
        CenterFreq = 1.8e9;     % Hertz
        ChannelsInUse           % Integer Array of channels UEs are using
        LicensedChannels = 1:12; % Array of channels we can use
        UEs                      % Array of UE objectes
        UEIndex = 1;            % Index currently addressing UE, used to keep things fair
        MeanSubchannelSINR      % SINR at each active subchannel, averaged over UEs
        GameModel               % Only used in game theory simulations, usually a struct
    end
    
    methods
        % Constructor
        function obj = eNB()
            
        end
        % Set Channels For UE
        function obj = SetUEChannels(obj,ue,channels)
           
            obj.UEs(ue).UsingChannels = channels;
            % Update used channels
            currentChannels = [];
            for ue = 1:length(obj.UEs)
                currentChannels = [currentChannels, obj.UEs(ue).UsingChannels]; %#ok<AGROW>
            end
            obj.ChannelsInUse = unique(currentChannels);
            
        end
        % Place UE manually with relation to eNB
        function PlaceUE(obj,ue,PositionINRefENB)
            obj.UEs(ue).PositionRefENB = PositionINRefENB;
            obj.UEs(ue).Position = PositionINRefENB+obj.Position;
        end
        
        % Place UE uniformly around attached eNB
        function obj = PlaceUEsUniformly(obj,radius)
            
            % Place UEs uniformly around eNB with a radius
            numUEs = length(obj.UEs);
            t = 2*pi*rand(numUEs,1);
            u = 2*rand(numUEs,1);
            if u>1
                r = 2-u;
            else
                r = u;
            end
            Positions = radius/2.*[r.*cos(t), r.*sin(t)];
            % Save positions
            for ue=1:numUEs
                PlaceUE(obj,ue,Positions(ue,:));
            end
        end
        
        % Increment all packets by 1 TTI
        function UpdatePacketDelays(obj)
           
            for UE=1:length(obj.UEs)
                obj.UEs(UE).PacketDelays =...
                    obj.UEs(UE).PacketDelays + obj.UEs(UE).PacketDelays>0;
                
            end
        end
        % Pick channels randomly (used really for testing)
        function PickRandomChannels(obj,numChannels)
            
            % Shuffle possible channels
            shuffledChannels = randperm(length(obj.LicensedChannels));
            % Pick subset
            obj.ChannelsInUse = shuffledChannels(1:numChannels);
            % Let all UEs to use all these channels
            for UE = 1:length(obj.UEs)
                obj.UEs(UE).UsingChannels = obj.ChannelsInUse;
            end
        end
    end
end

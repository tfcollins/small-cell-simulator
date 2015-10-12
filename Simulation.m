classdef Simulation < handle
    % Simulation Class
    
    properties
        eNBs                % Array of eNB objects
        MapDims = [1,1];
        MaxUEsOfAnyENB = 0;
        Duration = 10; % (seconds)
        PathlossModel
        ChannelPowerHistory % Dimensions (time,eNB,channel)
        AvailableChannels = 1:12;
    end
    % Constants
    properties (Constant)
       TTIDuration = 0.001; 
    end
    % Private Properties
    properties(Access = protected)
        DistancesUE2eNB  % UE to eNB Distance [eNB, UE]
        Pathlosses % UE to eNB Pathloss [eNB, UE]
    end
    
    methods
        % Constructor
        function obj = Simulation()
            % Set generic model
            obj.PathlossModel = channels.PathlossSimpleLTE1;
        end
        % Create array of eNB objects
        function obj = AddeNBs(obj,numENB)
            
            eNBsTemp(1,numENB) = devices.eNB();
            for x=1:numENB
                eNBsTemp(x) = devices.eNB;
            end
            obj.eNBs = eNBsTemp;
            
        end
        % Attach same number of UE's to each eNB
        function obj = AddUEToEach(obj,numUEs)
            
            for x=1:length(obj.eNBs)
                UEsTemp(1,numUEs) = devices.UE(); %#ok<AGROW>
                for y=1:numUEs
                    UEsTemp(y) = devices.UE;
                end
                obj.eNBs(x).UEs = UEsTemp;
            end
            
        end
        % Get Distance from 2D Positions
        function distance = GetDistance(~,Position1,Position2)
            
            diff = Position1 - Position2;
            distance = sqrt(sum(diff.^2));% TODO: CHECK THIS IS WORKING
            if distance<=0
                error('UE placed too close to eNB');
            end
            
        end
        % Update SINR for each channel
        function UpdateSINRPerChannel(obj,eNBofUE,UE)
        
           channelSet = obj.eNBs(eNBofUE).UEs(UE).UsingChannels;
           % Cycle through channels used by UE
           for chan=1:length(channelSet)
               obj.eNBs(eNBofUE).UEs(UE).ChannelSINRdB(chan) = ...
               	GetSINRForUE(obj,eNBofUE,UE,channelSet(chan));
           end 
        end
        % Calculate SINR at each UE of each eNB
        function sinr = GetSINRForUE(obj,eNBofUE,UE,Channel)
            
            % Check channel being  used
            if sum(obj.eNBs(eNBofUE).UEs(UE).UsingChannels==Channel)==0
                warning('UE is not using channel');
                sinr = [];
                return
            end
            
            % Target UE Position
            uePosition = obj.eNBs(eNBofUE).UEs(UE).Position;
            
            % Distance between UE and eNB
            distance = GetDistance(obj,uePosition,obj.eNBs(eNBofUE).Position);

            % Get signal power
            
            % Fading is zero mean with variance ...
            variance = sqrt(4); % dB
            FadingLoss = variance*randn;
            FadingLoss = 0; %FIX LATER
            
            % Link budget
            sigPowerReceived = ...
                  obj.eNBs(eNBofUE).TxPower ...
                + obj.eNBs(eNBofUE).AntennaGain ...
                - obj.PathlossModel.GetPathloss(distance,'Signal') ...
                - FadingLoss ...
                + obj.eNBs(eNBofUE).UEs(UE).AntennaGain;
            
            % Interference Power
            interferencePower = 0;
            for eNB = 1:length(obj.eNBs)
                
                % Check if the other are using the channel
                eNBusingChannel = sum(obj.eNBs(eNB).ChannelsInUse==Channel)>0;
                
                if (eNB~=eNBofUE) && (eNBusingChannel)
                    
                    % Distance between UE and eNB
                    distance = GetDistance(obj,uePosition,obj.eNBs(eNB).Position);
                    
                    % Fading is zero mean with variance ...
                    variance = sqrt(4); % dB
                    FadingLoss = variance*randn;
                    FadingLoss = 0; % TODO: Fix later
                    
                    % Link budget
                    interferencePower = interferencePower ...
                        + obj.eNBs(eNB).TxPower ...
                        + obj.eNBs(eNB).AntennaGain ...
                        - obj.PathlossModel.GetPathloss(distance,'Interference') ...
                        - FadingLoss ...
                        + obj.eNBs(eNB).UEs(UE).AntennaGain;
                end
            end
            
            % Thermal noise
            thermalNoise = -174+10*log10(obj.eNBs(eNB).Bandwidth); % TODO: Relook this up
            
            
            % Convert from dBm to Linear (Watts)
            sigPowerReceivedLin = 10^((sigPowerReceived)/10);
            interferencePowerLin = 10^((interferencePower)/10);
            thermalNoiseLin = 10^((thermalNoise)/10);
                        
            % Calculate SINR
            if interferencePower==0
            sinrLin = sigPowerReceivedLin/( thermalNoiseLin );
            else
            sinrLin = sigPowerReceivedLin/( interferencePowerLin + thermalNoiseLin );
            end
            
            % Convert back to dB
            sinr = 10*log10(sinrLin);
        end
        % Get all SINR for UE's
        function UpdateSINRForUEs(obj)
        
            for eNB = 1:length(obj.eNBs)
               for UE = 1:length(obj.eNBs(eNB).UEs)
                   % Get SINR for UE
                   UpdateSINRPerChannel(obj,eNB,UE);
                   %obj.eNBs(eNB).UEs(UE).SINRdB = GetSINRForUE(obj,eNB,UE);
               end
            end
        end
        % Show geographically where everyone is placed
        function ShowMap(obj,showSINR)

            for eNB = 1:length(obj.eNBs)
                % Mark eNB
                xy = obj.eNBs(eNB).Position;
                if eNB==1
                plot(xy(1),xy(2),'r.','MarkerSize',30)
                else
                hold on;
                plot(xy(1),xy(2),'r.','MarkerSize',30)
                hold off;
                end
                for UE = 1:length(obj.eNBs(eNB).UEs)
                    % Mark eNB
                    xy = obj.eNBs(eNB).UEs(UE).Position;
                    hold on;
                    plot(xy(1),xy(2),'b.','MarkerSize',25)
                    if showSINR
                        for chan=1:length(obj.eNBs(eNB).UEs(UE).UsingChannels)
                            sinrdb = obj.eNBs(eNB).UEs(UE).ChannelSINRdB(chan);
                            text(xy(1)+0.1,xy(2)-0.2*chan,['SINRdB: ',num2str(sinrdb,'%10.2f')]);
                        end
                    end
                    hold off;
                end
            end
            legend('eNB','UE');
            axis([0 obj.MapDims(1) 0 obj.MapDims(2)]);
            grid on;
            xlabel('meters');ylabel('meters');
        end
        % Helper to get upper limit on attached UEs
        function GetMaxUEsOfAnyeNB(obj)
            
            numENBs = length(obj.eNBs);
            maxUEs = 0;
            for x=1:numENBs
                if (length(obj.eNBs(x).UEs)>maxUEs)
                    maxUEs = length(obj.eNBs(x).UEs);
                end
            end
            obj.MaxUEsOfAnyENB = maxUEs;
            
        end
        % Get indexes of eNBs with UEs that have PacketQueue>0
        function activeENBs = GetActiveENBs(obj)
            
            activeENBs = [];
            for eNB=1:length(obj.eNBs)
                active = false;
                for UE=1:length(obj.eNBs(eNB).UEs)
                    % Check if non zero queue size
                    if (~isempty(obj.eNBs(eNB).UEs(UE).PacketQueue))
                        active = true;
                    end
                end
                if active
                    activeENBs = [activeENBs, eNB]; %#ok<AGROW>
                end
            end
        end
        % Clear all UE's PacketQueues
        function activeENBs = ClearActiveENBs(obj)
            
            activeENBs = [];
            for eNB=1:length(obj.eNBs)
                for UE=1:length(obj.eNBs(eNB).UEs)
                    % clear queues
                    obj.eNBs(eNB).UEs(UE).PacketQueue = [];
                    obj.eNBs(eNB).UEs(UE).PacketDelays = [];
                end
            end
        end
                
        % Set on all eNBs
        function SetAlleNBs(obj,property,value)
            
            for eNB = 1:length(obj.eNBs)
                set(obj.eNBs(eNB),property,value);
            end
        end
        
        % Save current eNB channel selections and power levels
        function SaveChannels(obj)
           
            % Gather selections
            hist = zeros(length(obj.eNBs),length(obj.AvailableChannels));
            for eNB=1:length(obj.eNBs)
                hist(eNB,obj.eNBs(eNB).ChannelsInUse) = 1;% FIX LATER TO HAVE POWER LEVELS
            end
            
            % Add to history (3D matrix)
            if isempty(obj.ChannelPowerHistory)
                obj.ChannelPowerHistory = hist;
            else
                obj.ChannelPowerHistory(:,:,end+1) = hist;
            end
        end
        
    end % Methods
end
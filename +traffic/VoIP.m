classdef VoIP < handle
    % VoIP Class
    %
    % Technical Info:
    % - VoIP Adaptive Multi-Rate (AMR) 12.2 codec
    % - QoS: user is said to be in "outage" if less than 98% of speech
    % frames are delivered successfully within 50ms air interface delay. 
    %
    %
    % References:
    % [1] http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=4526107
    % [2] R1-070674-LTE
    %
    % Notes/Ideas:
    % Use linear programming to solve maximum number of calls that can be
    % supported by eNB
    
    properties
        TTIRef = 0;
        CurrentState = 'Silent';
    end
    
    
    properties (Constant)
        TalkingPacketPeriods = 0.020; % (seconds) Periods between packet generation during actively talking states
        SilencePacketPeriods = 0.160 % (seconds) Periods between packet generation during not actively talking states
        
        TTIDuration = 0.001; % (seconds) Equal to 2 PRBs in time
        
        TalkingPacketBits = 40*8; % [2]
        SilencePacketBits = 15*8; % [2]
    end
    
    methods
        % Constructor
        function obj = VoIP()
            
            % Randomly select starting state
            possibleStates = ['Silent','Talking'];
            obj.CurrentState = possibleStates(randi([1,length(possibleStates)]));
            
        end
        
        function BitsToTransmit = TTIUpdate(obj)
            
            % Update time
            obj.TTIRef = obj.TTIRef + obj.TTIDuration;
            
            % Do we need to transmit
            BitsToTransmit = 0;
            if strcmpi(obj.CurrentState,'Silent')
                
                if mod(obj.TTIRef,obj.SilencePacketPeriods)<obj.TTIDuration
                    BitsToTransmit = obj.SilencePacketBits;
                end
                
            else
                if mod(obj.TTIRef,obj.TalkingPacketPeriods)<obj.TTIDuration
                    BitsToTransmit = obj.TalkingPacketBits;
                end
                    
            end
            
            % Transition state (This will happen rarely)
            
            
        end
    end
    
end


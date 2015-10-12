function [RATime,TxTime] = RunSimulationOFDMA_RR(sim,TransmitProbability,DataPacketSize,testThroughput,debug)


%% Startup

% Assign traffic types to each UE for downlink
for eNB=1:length(sim.eNBs)
    
    for UE=1:length(sim.eNBs(eNB).UEs)
        % Assign traffic types
        sim.eNBs(eNB).UEs(UE).Traffic = traffic.Generic(TransmitProbability);
    end
    
end

% Update commonly used values
sim.GetMaxUEsOfAnyeNB(); % Used for indexing

%% Run
mcs = utils.MCS; % MCS utility class
mcsIndex = 1; % Static MCS value
numChannels = length(sim.eNBs(1).LicensedChannels); % same for all in this case

% Counters to determine durations in states
RATime = 0;
TxTime = 0;

State = 'RandomAccess'; % Initial state
usersInTheGame = [];

% Evolve over time
for TTI = 0:sim.TTIDuration:sim.Duration
    
    % Status Info
    if mod(TTI/sim.TTIDuration,1000)<1
    disp(['TTI: ',num2str(TTI)]);
    end
    
    switch State
        % In this state eNB will randomly pick a channel.  The highest
        % channel selected will win and have access to the entire channel
        % for a fixed amount of time.  If there is a tie then the tied
        % users will choose again.  This is repeated until only a single
        % eNB remains
        case 'RandomAccess'
            
            % Update time in state
            % Since bandwidht remains fixed it will take longer to transmit
            % a reservation packet
            RATime = RATime + numChannels;
            
            % Reset all UEs Packet Queues to zeros, this simulation
            % requires no memory
            sim.ClearActiveENBs();
            
            % Update UEs and determine if the have packets at eNB that need to be
            % transmitted
            for eNB=1:length(sim.eNBs)
                for UE=1:length(sim.eNBs(eNB).UEs)
                    % Update traffic model to see if UE has data
                    bits = sim.eNBs(eNB).UEs(UE).Traffic.TTIUpdate();
                    % Add new packet to UE's queue
                    if bits>0
                        sim.eNBs(eNB).UEs(UE).SingleAddPacket(bits);
                    end
                end
            end
            
            % Initialize players
            if isempty(usersInTheGame)
                % Get list of eNBs that have traffic
                usersInTheGame = sim.GetActiveENBs();
            end
            
            % Randomly select subchannels uniformly
            selections = randi([1 numChannels],1,length(usersInTheGame));
            
            % Determine who chose best
            maxScore = max(selections);
            usersInTheGame = usersInTheGame(maxScore==selections);
            
            % Done with phase?
            if length(usersInTheGame)==1
                if debug
                    disp(['eNB ',num2str(usersInTheGame),' Won RA Game']);
                end
                % Define user with full access
               TransmittingENB = usersInTheGame;
               % Reset full channel access duration
               TransmittingTimeLeft = DataPacketSize; % TTIs
               %UEIndex = 1;
               State = 'Transmitting'; 
            end
            
        case 'Transmitting'
            
            % Update time in state
            TxTime = TxTime + 1;
            
            % Decrement channel access duration
            TransmittingTimeLeft = TransmittingTimeLeft - 1;
            
            % Reset allowed users to play RandomAccess
            if TransmittingTimeLeft<1
                usersInTheGame = [];
               State = 'RandomAccess'; 
            end
            
            % Below is for measuring packet queue and throughput
            % NOT USED FOR SIMULATION BASE ON PAPER
            if testThroughput
                % Determine max resources in TTI
                AvailablePRBs =...
                    mcs.TotalPRBs(sim.eNBs(TransmittingENB).Bandwidth,sim.TTIDuration);
                allocatePRBs = 0;
                
                % Get required PRBs per user
                for UE = 1:length(sim.eNBs(TransmittingENB).UEs)
                    % Update UE index
                    index= UE; %sim.eNBs(TransmittingENB).UEIndex % TODO
                    
                    % Pack bits into smallest amount of PRBs that we can
                    % Work through queue
                    if AvailablePRBs>0
                        [AvailablePRBs,allocatePRBs] = ProcessUE(...
                            sim.eNBs(TransmittingENB).UEs(index)...
                            ,AvailablePRBs,allocatePRBs,mcsIndex,mcs);
                    end
                    %disp(['Allocated blocks: ',num2str(allocatePRBs), ' By UE ',num2str(UE)]);
                end % Loop over UEs
                if debug
                    disp(['Allocated blocks: ',num2str(allocatePRBs), ' By eNB ',num2str(TransmittingENB)]);
                end
            end
    end

end

%%

end

function [AvailablePRBs,allocatePRBs] = ProcessUE(workingUE,AvailablePRBs,allocatePRBs,mcsIndex,mcs)

BitsToPutInPRB = 0;

for p=1:length(workingUE.PacketQueue)
    bits = workingUE.PacketQueue(1);% Process top packet
    
    if mcs.NeededPRBs(mcsIndex,bits+BitsToPutInPRB)>1
        % Too many bits for same PRB, lets close this
        % PRB and see if we can pack another
        
        % Have enough room?
        if AvailablePRBs>=mcs.NeededPRBs(mcsIndex,bits)
            workingUE.RemovePacket();
            AvailablePRBs = AvailablePRBs - 1;
            allocatePRBs = allocatePRBs + 1;
            BitsToPutInPRB = bits;
        else
            break; % out of resources
        end
    else
        % Can pack into same PRB
        if (p==length(workingUE.PacketQueue))
            % Last packet in queue
            workingUE.RemovePacket();
            AvailablePRBs = AvailablePRBs - 1;
            allocatePRBs = allocatePRBs + 1;
        else
            % Not the last packet, may be able to fit
            % more
            workingUE.RemovePacket();
            BitsToPutInPRB = BitsToPutInPRB + bits;
        end
    end
end

end

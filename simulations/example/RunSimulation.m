function [collisions,chances] = RunSimulation(sim)

%% Startup
for eNB=1:length(sim.eNBs)
    
    for UE=1:length(sim.eNBs(eNB).UEs)
        % Assign traffic types
        sim.eNBs(eNB).UEs(UE).Traffic = traffic.VoIP;
        
        % Assign traffic start times (in subframes aka 2 PRBs)
        sim.eNBs(eNB).UEs(UE).Traffic.TTIRef = ...
            randi([1,99])*sim.eNBs(eNB).UEs(UE).Traffic.TTIDuration;
    end
    
end

% Update commonly used values
sim.GetMaxUEsOfAnyeNB();

%% Run
Transmitting = zeros(length(sim.eNBs),sim.MaxUEsOfAnyENB);
PRBsPerENB = zeros(length(sim.eNBs),1);
mcs = MCS; % MCS utility class
mcsIndex = 1;
numChannels = length(sim.eNBs(1).LicensedChannels);

collisions = 0;
chances = 0;

for TTI = 0:sim.TTIDuration:sim.Duration
    
    % Update UEs and determine if the have packets at eNB that need to be
    % transmitted
    for eNB=1:length(sim.eNBs)
        for UE=1:length(sim.eNBs(eNB).UEs)
            % Update traffic model to see if UE has data
            Transmitting(eNB,UE) = sim.eNBs(eNB).UEs(UE).Traffic.TTIUpdate();
        end
    end
    TransmittingENBs = sum(Transmitting,2)>0;
    
    % Determine how many subchannels are needed by each eNB
    for eNB=1:length(sim.eNBs)
        if TransmittingENBs(eNB)>0
           PRBsPerENB(eNB) = ceil(mcs.NeededPRBs(mcsIndex, TransmittingENBs(eNB)));
        end
    end
    
    % Randomly choose subchannels based on PRB requirements
    channelSelections = zeros(length(sim.eNBs),numChannels);
    for eNB=1:length(sim.eNBs)
        channels = sim.eNBs(eNB).LicensedChannels;
        % Shuffle
        sChannels = channels(randperm(length(channels)));
        % Get subset and create bitmap
        %channelSelections(eNB,1:PRBsPerENB(eNB)) = sChannels(1:PRBsPerENB(eNB))>0;
        channelSelections(eNB,sChannels(1:PRBsPerENB(eNB))) = 1;
    end
    %disp(channelSelections);
    collisions = collisions + sum(sum(channelSelections)>1);
    chances = chances + sum(sum(channelSelections)>0);
end

%% 

end




function  RunSimulation_GameTheory(sim)

% Update commonly used values
sim.GetMaxUEsOfAnyeNB();

% Max number of subchannels eNB's are allowed to pick
numChannels = 3;

%% Run

% Iterate Through Game Theory Rounds
for TTI = 0:sim.TTIDuration:sim.Duration
    
    % Update strategy based on SINR history
    for eNB=1:length(sim.eNBs)
        sim.eNBs(eNB).PickRandomChannels(numChannels);
    end
    
    % Update SINR measurements at the UEs attached to each eNB
    %if TTI~=0
        sim.UpdateSINRForUEs();
    %end
    
    % Average over UE SINR subchannels to get single SINR per subchannel
    % vector
    sim.GetMeanSubchannelSINRs();
    
    % Update observations of round
    sim.SaveChannels();
    
    % View subchannel power levels network wide
    sim.ViewSubchannels();
    
end

%% 

end


function DetermineENBCapacity(eNB,SubchannelBandwidth,SINR)

eNBCapacity = 0;
% Cycle through active subchannels
for sc=1:length(eNB.ChannelsInUse)
    eNBCapacity = eNBCapacity + SubchannelBandwidth*log2(1+SINR);
end

end

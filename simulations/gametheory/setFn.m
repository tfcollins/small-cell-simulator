function setFn(sim,MaxSubchannels)

% Fn is simply the SINR of the received signal without interference,
% only thermal noise

% Determine Fn for each eNB assuming 1 UE attached
UE = 1;
for eNB = 1:length(sim.eNBs)
    
    SINRdB = [];
    for subchannel = 1:MaxSubchannels
       SINRdB = [SINRdB, sim.GetSINRForUE(eNB,UE,MaxSubchannels,'InterferenceNotIncluded')]; %#ok<AGROW>
    end
    
    ChannelBandwidth = sim.eNBs(eNB).Bandwidth/...
                length(sim.eNBs(eNB).LicensedChannels);
    
    % SINR to achievable rate
    R = ChannelBandwidth*log2(1+SINRdB);
    
    % Sum rates
    sim.eNBs(eNB).GameModel.Fn = sum(R);
    
end

end
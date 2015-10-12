function  RunSimulation_GameTheory(sim)

% Update commonly used values
sim.GetMaxUEsOfAnyeNB();

numChannels = 3; % Channel subset

%% Run

for TTI = 0:sim.TTIDuration:sim.Duration
    
    % Game Theory Round
    
    % Update strategy based on history
    for eNB=1:length(sim.eNBs)
        sim.eNBs(eNB).PickRandomChannels(numChannels);
    end
    
    % Update observations of round
    sim.SaveChannels();
    
end

%% 

end




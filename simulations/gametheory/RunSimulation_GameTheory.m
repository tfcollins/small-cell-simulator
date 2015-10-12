function  RunSimulation_GameTheory(sim,Kn)

% Update commonly used values
sim.GetMaxUEsOfAnyeNB();

% Max number of subchannels eNB's are allowed to pick
numChannels = Kn;

%% Run
% Initialize some things

% Update strategy based on SINR history
for eNB=1:length(sim.eNBs)
    sim.eNBs(eNB).PickRandomChannels(numChannels);
end


% Iterate Through Game Theory Rounds
for TTI = 0:sim.TTIDuration:sim.Duration
    
    
    % Update SINR measurements at the UEs attached to each eNB
    sim.UpdateSINRForUEs();
    
    % Average over UE SINR subchannels to get single SINR per subchannel
    % vector
    sim.GetMeanSubchannelSINRs();
    
    % Update utility
    UpdateUtilities(sim);
    
    % Save utilities of round
    
    % Update Personalities
    UpdatePersonalities(sim)
    
    % Update Mixed Stategies Qn
    UpdateStrategies(sim);
    
    % Pick new stategies
    
    % Update observations of round
    sim.SaveChannels();
    
    % View subchannel power levels network wide
    sim.ViewSubchannels();
    
end

%% 

end


%% Personality updating algorithm
function UpdatePersonalities(sim)

for eNB = 1:length(sim.eNBs)
    
    % Get game relevant values
    LastChannelSelections =...
        squeeze(sim.ChannelPowerHistory(end-1,eNB,:)); % Dimensions (time,eNB,channel)
    CurrentChannelSelections =...
        squeeze(sim.ChannelPowerHistory(end,eNB,:)); % Dimensions (time,eNB,channel)
    LastUtility = sim.eNBs(eNB).GameModel.Utilies(end-1);
    CurrentUtility = sim.eNBs(eNB).GameModel.Utilies(end);
    
    % Extract Constants
    beta = sim.eNBs(eNB).GameModel.beta;
    Fn = sim.eNBs(eNB).GameModel.Fn;
    epsilon = sim.eNBs(eNB).GameModel.epsilon;
    
    % Update personalities
    if strcmpi(sim.eNBs(eNB).GameModel.Personality,'conservative')
        
        if isequal(LastChannelSelections,CurrentChannelSelections) &&...
                isequal(LastUtility,CurrentUtility)
            sim.eNBs(eNB).GameModel.Personality = 'conservative';
        else
            % SAME
            pC = epsilon^(1-(CurrentUtility/Fn)^beta);
            pR = 1 - pC;
            if pR>pC
                sim.eNBs(eNB).GameModel.Personality = 'radical';
            else
                sim.eNBs(eNB).GameModel.Personality = 'conservative';
            end
        end
    else
        % SAME
        pC = epsilon^(1-(CurrentUtility/Fn)^beta);
        pR = 1 - pC;
        if pR>pC
            sim.eNBs(eNB).GameModel.Personality = 'radical';
        else
            sim.eNBs(eNB).GameModel.Personality = 'conservative';
        end
    end
    
end

end

%% Calculate Utility
function UpdateUtilities(sim)

for eNB = 1:length(eNBs)
    
    Utility = 0;
    
    % Sum capacities over channels to get utilites
    for chan = 1:length(sim.eNBs(eNB).ChannelsInUse)
        Utility = Utility + Bandwidth*...
            log2(1 + eNB.MeanSubchannelSINR(chan));
    end
    
    % Save new utility to history
    sim.eNBs(eNB).GameModel.Utilies = ...
        [sim.eNBs(eNB).GameModel.Utilies; Utility];
    
end

end


%% Update mixed strategies UDSA
function UpdateStrategies(sim)

w = ceil(length(sim.eNBs)*1.2); % Bigger than N (# users)

for eNB=1:length(sim.eNBs)

    if strcmpi(sim.eNBs(eNB).GameModel.Personality,'radical')
       
        % Make all strategies are equally likely
        indexes = 1:length(sim.eNBs(eNB).LicensedChannels);
        sim.eNBs(eNB).GameModel.Qn(indexes) = ...
            1/length(sim.eNBs(eNB).GameModel.StrategyCounter);
        
    else
        % Choose strageties not chosen in previous round
        indexes = 1:length(sim.eNBs(eNB).LicensedChannels);
        previouslyChosen = sim.eNBs(eNB).ChannelsInUse;
        indexes(previouslyChosen) = [];
        
        sim.eNBs(eNB).GameModel.Qn(indexes)...
            = sim.eNBs(eNB).GameModel.epsilon^w/...
            (length(sim.eNBs(eNB).GameModel.StrategyCounter)-1);
        
        sim.eNBs(eNB).GameModel.Qn(previouslyChosen)...
            = 1-sim.eNBs(eNB).GameModel.epsilon^w;
        
    end
end


end

%% Make channel choices
function UpdateCurrentStrategy(sim)

for eNB = 1:length(sim.eNBs)

    % Probability vector
    P = sim.eNBs(eNB).GameModel.Qn;
    % Strategy Indexes
    X = 1:length(sim.eNBs(eNB).StrategyCounter);
    % Randomly pick strategy
    ChosenStrategyIndex = X(find(rand<cumsum(P),1,'first'));
    % Set current strategy
    sim.eNBs(eNB).GameModel.PossibleStrategies(ChosenStrategyIndex);

end

end






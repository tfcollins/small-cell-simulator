function  RunSimulation_GameTheory(sim,Kn)

% Update commonly used values
sim.GetMaxUEsOfAnyeNB();

% Max number of subchannels eNB's are allowed to pick
numChannels = Kn;

%% Run
% Initialize some things

% Update strategy based on SINR history and setup history
for eNB=1:length(sim.eNBs)
    sim.eNBs(eNB).GameModel.Utilies = [0,0];
    sim.eNBs(eNB).GameModel.StrategyIndexes = [1,1]; %FIX LATER
    sim.eNBs(eNB).PickRandomChannels(numChannels);
end




% Iterate Through Game Theory Rounds
for TTI = 0:sim.TTIDuration:sim.Duration
    
    
    % Update SINR measurements at the UEs attached to each eNB
    sim.UpdateSINRForUEs();
    
    % Average over UE SINR subchannels to get single SINR per subchannel
    % vector
    sim.GetMeanSubchannelSINRs();
    
    % Update and ave utilities of round
    UpdateUtilities(sim);
    
    % Update Personalities, these historically dont need to be kept
    UpdatePersonalities(sim)
    
    % Update counter
    UpdateCounter(sim);
    
    % Update Mixed Stategies Qn vector
    UpdateStrategies(sim);
    
    % Pick new stategies
    UpdateCurrentStrategy(sim);
    
    % Update observations of round
    sim.SaveChannels();
    
    % View subchannel power levels network wide
    % sim.ViewSubchannels();
    ViewCounts(sim);
    
end

%% 

end


%% Personality updating algorithm
function UpdatePersonalities(sim)

for eNB = 1:length(sim.eNBs)
    
    % Get game relevant values
    LastChannelSelections = sim.eNBs(eNB).GameModel.StrategyIndexes(end-1);
    CurrentChannelSelections = sim.eNBs(eNB).GameModel.StrategyIndexes(end);
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
            disp('radical');
            sim.eNBs(eNB).GameModel.Personality = 'radical';
        else
            sim.eNBs(eNB).GameModel.Personality = 'conservative';
        end
    end
    
end

end

%% Calculate Utility
function UpdateUtilities(sim)

for eNB = 1:length(sim.eNBs)
    
    Utility = 0;
    
    % Sum capacities over channels to get utilites
    for chan = 1:length(sim.eNBs(eNB).ChannelsInUse)
        Utility = Utility + sim.eNBs(eNB).Bandwidth/length(sim.eNBs(eNB).LicensedChannels)*...
            log2(1 + sim.eNBs(eNB).MeanSubchannelSINR(chan));
    end
    
    % Save new utility to history
    sim.eNBs(eNB).GameModel.Utilies = ...
        [sim.eNBs(eNB).GameModel.Utilies, Utility];
    
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
    X = 1:length(sim.eNBs(eNB).GameModel.StrategyCounter);
    
    % Randomly pick strategy
    ChosenStrategyIndex = X(find(rand<cumsum(P),1,'first'));
    
    % Convert strategy index to channel selection
    vec = sim.eNBs(eNB).GameModel.PossibleStrategies(ChosenStrategyIndex,:);
    indexes = 1:length(sim.eNBs(eNB).LicensedChannels);
    sim.eNBs(eNB).ChannelsInUse = indexes(vec==1);
    
    % Save strategy index to history
    sim.eNBs(eNB).GameModel.StrategyIndexes = ...
        [sim.eNBs(eNB).GameModel.StrategyIndexes, ChosenStrategyIndex];

end

end

% Update Strategy counter
function UpdateCounter(sim)

for eNB = 1:length(sim.eNBs)

    if strcmpi(sim.eNBs(eNB).GameModel.Personality,'conservative')
        
        index = sim.eNBs(eNB).GameModel.StrategyIndexes(end);
        
        sim.eNBs(eNB).GameModel.StrategyCounter(index) = ...
            sim.eNBs(eNB).GameModel.StrategyCounter(index) + 1;
        
    end
    
end

end

% View tally on each strategy by eNBs
function ViewCounts(sim)

% rows are groups of bars == subchannel
% columns == eNB

% Build input to bargraph
tally = zeros(length(sim.eNBs(1).GameModel.StrategyCounter),length(sim.eNBs));

for eNB = 1:length(sim.eNBs)
    tally(:,eNB) =...
        sim.eNBs(eNB).GameModel.StrategyCounter;
end
% Plot
bar(tally);
xlabel('strategy Index');
ylabel('Counts');
% Create legend
leg = {};
for eNB = 1:length(sim.eNBs)
    leg = {leg{:},['eNB=',num2str(eNB)]};
end

legend(leg);
drawnow;
pause(0.1);

end



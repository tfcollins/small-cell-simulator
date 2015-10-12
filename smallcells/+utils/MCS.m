classdef MCS < handle
    % MCS Lookup information
    
    properties
        % 4-bit MCS and 0 index does not count for anything
        ModulationOrder = [2*ones(6,1); 4*ones(3,1); 6*ones(6,1)];
        % 36.212, section 5.3.2
        Coderates = ([78 120 193 308 449 602 378 490 616 466 567 666 772 873 948]./1024).';
        SubcarriersPerPRB = 12;
        OFDMSymbolsPerPRB = 7;
        % Bandwidths
        Bandwidths = [1.4,3,5,10,15,20].*1e6;
        PRBsPerBandwidth = [6,15,25,50,75,100];
    end
    
    methods
        function PRBs = NeededPRBs(obj,mcsIndex,bitsToPack)
           % Determine bits per resource block with current MCS
            bitsPerResourceElement = obj.ModulationOrder .* obj.Coderates;
            ResourceElementsPerPRB = obj.SubcarriersPerPRB .* obj.OFDMSymbolsPerPRB;
            bitsPerPRB = floor(ResourceElementsPerPRB * bitsPerResourceElement);
            
            PRBs = bitsToPack/bitsPerPRB(mcsIndex);
            
            % % Calculate PRBs needed for given number of bits
            % requiredPRBsPerFrame = bitsPerFrame./bitsPerPRB;
            % PRBS = ceil(requiredPRBsPerFrame(mcsIndex));
        end
        % Get all possible PRBs that could be transmitted
        function totalPRBs = TotalPRBs(obj,reqBandwidth,duration)
        
            [~,index] = find(obj.Bandwidths==reqBandwidth);
            if (length(index)~=1) 
                error('Incorrect bandwidth choosen');
            end
            
            % UE during a subframe (1 ms) are 2 PRBs with one PRB in each slot of the subframe
            
            PRBDuration = 0.0005; % seconds;
            PRBsPerSecond = obj.PRBsPerBandwidth(index)/PRBDuration;
            
            totalPRBs = duration*PRBsPerSecond;
            
        end
        % Convert PRBs to bits
    end
    
end


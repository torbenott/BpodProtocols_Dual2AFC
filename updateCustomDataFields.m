function updateCustomDataFields
global BpodSystem
global TaskParameters
%% OutcomeRecord
% Searches for state names and not number, so won't be affected by
% modifications in state matrix
ndxOutcome = find(strcmp('rewarded_Lin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}) |...
    strcmp('rewarded_Rin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}) |...
    strcmp('unrewarded_Lin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}) |...
    strcmp('unrewarded_Rin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}) |...
    strcmp('broke_fixation',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end})); % States of interest
if any(ismember(ndxOutcome,BpodSystem.Data.RawData.OriginalStateData{end}))
    BpodSystem.Data.Custom.OutcomeRecord(end) = ndxOutcome(ismember(ndxOutcome,BpodSystem.Data.RawData.OriginalStateData{end}));
    if strcmp('rewarded_Lin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.Custom.OutcomeRecord(end)))
        BpodSystem.Data.Custom.ChoiceLeft(end) = 1;
        BpodSystem.Data.Custom.ChoiceCorrect(end) = 1;
    elseif strcmp('rewarded_Rin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.Custom.OutcomeRecord(end)))
        BpodSystem.Data.Custom.ChoiceLeft(end) = 0;
        BpodSystem.Data.Custom.ChoiceCorrect(end) = 1;
    elseif strcmp('unrewarded_Lin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.Custom.OutcomeRecord(end)))
        BpodSystem.Data.Custom.ChoiceLeft(end) = 1;
        BpodSystem.Data.Custom.ChoiceCorrect(end) = 0;
    elseif strcmp('unrewarded_Rin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.Custom.OutcomeRecord(end)))
        BpodSystem.Data.Custom.ChoiceLeft(end) = 0;
        BpodSystem.Data.Custom.ChoiceCorrect(end) = 0;
    elseif strcmp('broke_fixation',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.Custom.OutcomeRecord(end)))
        BpodSystem.Data.Custom.FixBroke(end) = true;
        BpodSystem.Data.Custom.TrialValid(end) = false;
    end
    if any(strcmp('skipped_feedback',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.RawData.OriginalStateData{end})))
        BpodSystem.Data.Custom.TrialValid(end) = false;
        BpodSystem.Data.Custom.Feedback(end) = false;        
    end
end
if any(strncmp('water_',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.RawData.OriginalStateData{end}),6))
    BpodSystem.Data.Custom.Rewarded(end) = true;
end
if any(strcmp('odor_delivery',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.RawData.OriginalStateData{end})))
    BpodSystem.Data.Custom.OST(end) = diff(BpodSystem.Data.RawEvents.Trial{end}.States.odor_delivery);
end
if ~BpodSystem.Data.Custom.FixBroke(end)
    BpodSystem.Data.Custom.FeedbackTime(end) = diff(BpodSystem.Data.RawEvents.Trial{end}.States.(BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}{BpodSystem.Data.Custom.OutcomeRecord(end)}));
end
if BpodSystem.Data.Custom.BlockTrial(end) >= TaskParameters.GUI.BlockTable.BlockLen(TaskParameters.GUI.BlockTable.BlockNumber...
        ==BpodSystem.Data.Custom.BlockNumber(end))
    BpodSystem.Data.Custom.BlockNumber(end+1) = BpodSystem.Data.Custom.BlockNumber(end) + 1;
    BpodSystem.Data.Custom.BlockTrial(end+1) = 1;
else
    BpodSystem.Data.Custom.BlockNumber(end+1) = BpodSystem.Data.Custom.BlockNumber(end);
    BpodSystem.Data.Custom.BlockTrial(end+1) = BpodSystem.Data.Custom.BlockTrial(end) + 1;
end
BpodSystem.Data.Custom.RewardMagnitude(end+1,:) = TaskParameters.GUI.RewardAmount*[TaskParameters.GUI.BlockTable.RewL(BpodSystem.Data.Custom.BlockNumber(end)),...
    TaskParameters.GUI.BlockTable.RewR(BpodSystem.Data.Custom.BlockNumber(end))];
BpodSystem.Data.Custom.OutcomeRecord(end+1) = nan;
BpodSystem.Data.Custom.ChoiceLeft(end+1) = NaN;
BpodSystem.Data.Custom.ChoiceCorrect(end+1) = NaN;
BpodSystem.Data.Custom.Rewarded(end+1) = false;
BpodSystem.Data.Custom.FixBroke(end+1) = false;
BpodSystem.Data.Custom.FixDur(end) = diff(BpodSystem.Data.RawEvents.Trial{end}.States.stay_Cin);
BpodSystem.Data.Custom.FixDur(end+1) = NaN;
BpodSystem.Data.Custom.OST(end+1) = NaN;
BpodSystem.Data.Custom.TrialValid(end+1) = true;
BpodSystem.Data.Custom.Feedback(end+1) = true;
BpodSystem.Data.Custom.FeedbackTime(end+1) = NaN;

if numel(BpodSystem.Data.Custom.OutcomeRecord) > numel(BpodSystem.Data.Custom.OdorFracA) - 5
    switch TaskParameters.GUIMeta.TrialSelection.String{TaskParameters.GUI.TrialSelection}
        case 'Flat'
            TaskParameters.GUI.OdorTable.OdorProb = ones(size(TaskParameters.GUI.OdorTable.OdorProb));
        case 'Manual'
            
        case 'Competitive'
            ndxValid = or(BpodSystem.Data.Custom.TrialValid,BpodSystem.Data.Custom.Feedback==0)';
            for iStim = TaskParameters.GUI.OdorTable.OdorFracA'
                ndxOdor = BpodSystem.Data.Custom.OdorFracA(1:numel(BpodSystem.Data.Custom.Rewarded)) == iStim;
                if sum(ndxOdor&ndxValid) >= 8
                    TaskParameters.GUI.OdorTable.OdorProb(iStim == TaskParameters.GUI.OdorTable.OdorFracA) = ...
                        sum(BpodSystem.Data.Custom.Rewarded(ndxOdor&ndxValid)==0)/sum(ndxOdor&ndxValid);
                else
                    TaskParameters.GUI.OdorTable.OdorProb(iStim == TaskParameters.GUI.OdorTable.OdorFracA) = 0.5;
                end
            end
            if any(TaskParameters.GUI.OdorTable.OdorProb==0)
                TaskParameters.GUI.OdorTable.OdorProb(TaskParameters.GUI.OdorTable.OdorProb==0) = ...
                    min(TaskParameters.GUI.OdorTable.OdorProb(TaskParameters.GUI.OdorTable.OdorProb>0))/2;                
            end
        case 'BiasCorrecting' % Favors side with fewer rewards. Contrast drawn flat & independently.
            ndxCorrect = BpodSystem.Data.Custom.Rewarded(1:end-1) == 1; ndxCorrect = ndxCorrect(:);
            oldOdorID = BpodSystem.Data.Custom.OdorID(1:numel(ndxCorrect)); oldOdorID = oldOdorID(:);
            TaskParameters.GUI.OdorTable.OdorProb(TaskParameters.GUI.OdorTable.OdorFracA<50) = 1-sum(oldOdorID==2 & ndxCorrect)/sum(ndxCorrect);
            TaskParameters.GUI.OdorTable.OdorProb(TaskParameters.GUI.OdorTable.OdorFracA>50) = 1-sum(oldOdorID==1 & ndxCorrect)/sum(ndxCorrect);            
    end
    TaskParameters.GUI.OdorTable.OdorProb = TaskParameters.GUI.OdorTable.OdorProb/sum(TaskParameters.GUI.OdorTable.OdorProb);
    newFracA = randsample(TaskParameters.GUI.OdorTable.OdorFracA,10,1,TaskParameters.GUI.OdorTable.OdorProb);
    newOdorID =  2 - double(newFracA > 50);
    newOdorPair = ones(1,10);
    BpodSystem.Data.Custom.OdorFracA = [BpodSystem.Data.Custom.OdorFracA; newFracA];
    BpodSystem.Data.Custom.OdorID = [BpodSystem.Data.Custom.OdorID, newOdorID];
%     BpodSystem.Data.Custom.OdorContrast = [BpodSystem.Data.Custom.OdorContrast, newOdorContrast];
    BpodSystem.Data.Custom.OdorPair = [BpodSystem.Data.Custom.OdorPair, newOdorPair];
    clear newFracA newOdor* oldOdorID
end
%% Olfactometer banks
BpodSystem.Data.Custom.OdorA_bank = TaskParameters.GUI.OdorA_bank;
BpodSystem.Data.Custom.OdorB_bank = TaskParameters.GUI.OdorB_bank;
%% Delays
if TaskParameters.GUI.StimDelayAutoincrement
    if BpodSystem.Data.Custom.FixBroke(end-1)
        BpodSystem.Data.Custom.StimDelay(end+1) = max(TaskParameters.GUI.StimDelayMin,...
            BpodSystem.Data.Custom.StimDelay(end)-TaskParameters.GUI.StimDelayDecr);
    else
        BpodSystem.Data.Custom.StimDelay(end+1) = min(TaskParameters.GUI.StimDelayMax,...
            BpodSystem.Data.Custom.StimDelay(end)+TaskParameters.GUI.StimDelayIncr);
    end
else
    if ~BpodSystem.Data.Custom.FixBroke(end-1)
        BpodSystem.Data.Custom.StimDelay(end+1) = random('unif',TaskParameters.GUI.StimDelayMin,TaskParameters.GUI.StimDelayMax);
    else
        BpodSystem.Data.Custom.StimDelay(end+1) = BpodSystem.Data.Custom.StimDelay(end);
    end
end
TaskParameters.GUI.StimDelay = BpodSystem.Data.Custom.StimDelay(end);

if TaskParameters.GUI.FeedbackDelayAutoincrement
    if ~BpodSystem.Data.Custom.Feedback(end-1)
        BpodSystem.Data.Custom.FeedbackDelay(end+1) = max(TaskParameters.GUI.FeedbackDelayMin,...
            BpodSystem.Data.Custom.FeedbackDelay(end)-TaskParameters.GUI.FeedbackDelayDecr);
    else
        BpodSystem.Data.Custom.FeedbackDelay(end+1) = min(TaskParameters.GUI.FeedbackDelayMax,...
            BpodSystem.Data.Custom.FeedbackDelay(end)+TaskParameters.GUI.FeedbackDelayIncr);
    end
    TaskParameters.GUI.FeedbackDelay = BpodSystem.Data.Custom.FeedbackDelay(end);
else
%     ATTEMPT TO GRAY OUT FIELDS
%     if ~strcmp('edit',TaskParameters.GUIMeta.FeedbackDelay.Style)
%         TaskParameters.GUIMeta.FeedbackDelay.Style = 'edit';
%     end
    BpodSystem.Data.Custom.FeedbackDelay(end+1) = TaskParameters.GUI.FeedbackDelayMax;
    TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMax;
end
%display(BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.RawData.OriginalStateData{end}))

end

% function BlockLen = drawBlockLen(TaskParameters)
% BlockLen = 0;
% while BlockLen < TaskParameters.GUI.blockLenMin || BlockLen > TaskParameters.GUI.blockLenMax
%     BlockLen = ceil(exprnd(sqrt(TaskParameters.GUI.blockLenMin*TaskParameters.GUI.blockLenMax)));
% end
% end
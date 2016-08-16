function MainPlot(AxesHandles, Action, varargin)
global nTrialsToShow %this is for convenience
global BpodSystem

switch Action
    case 'init'
        %% Outcome
        %initialize pokes plot
        nTrialsToShow = 90; %default number of trials to display
        
        if nargin >=3  %custom number of trials
            nTrialsToShow =varargin{1};
        end
        axes(AxesHandles.HandleOutcome);
        %         Xdata = 1:numel(SideList); Ydata = SideList(Xdata);
        %plot in specified axes
        BpodSystem.GUIHandles.OutcomePlot.OdorFracA = line(1:numel(BpodSystem.Data.Custom.OdorFracA),BpodSystem.Data.Custom.OdorFracA/100, 'LineStyle','none','Marker','o','MarkerEdge','b','MarkerFace','b', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCircle = line(1,0.5, 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCross = line(1,0.5, 'LineStyle','none','Marker','+','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.CumRwd = text(1,1,'0mL','verticalalignment','bottom','horizontalalignment','center');
        BpodSystem.GUIHandles.OutcomePlot.Correct = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','g', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.Incorrect = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','r','MarkerFace','r', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.BrokeFix = line(-1,0.5, 'LineStyle','none','Marker','d','MarkerEdge','b','MarkerFace','none', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.NoFeedback = line(-1,0.5, 'LineStyle','none','Marker','o','MarkerEdge','none','MarkerFace','w', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.NoResponse = line(-1,[0 1], 'LineStyle','none','Marker','x','MarkerEdge','b','MarkerFace','none', 'MarkerSize',6);
        set(AxesHandles.HandleOutcome,'TickDir', 'out','XLim',[0, nTrialsToShow],'YLim', [-.25, 1.25], 'YTick', [0 1],'YTickLabel', {'Right','Left'}, 'FontSize', 16);
        xlabel(AxesHandles.HandleOutcome, 'Trial#', 'FontSize', 18);
        hold(AxesHandles.HandleOutcome, 'on');
        %% Psyc
        BpodSystem.GUIHandles.OutcomePlot.Psyc = line(AxesHandles.HandlePsyc,[5 95],[.5 .5], 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace','k', 'MarkerSize',6);
        AxesHandles.HandlePsyc.YLim = [-.05 1.05];
        AxesHandles.HandlePsyc.XLim = 100*[-.05 1.05];
        AxesHandles.HandlePsyc.XLabel.String = '% odor A'; % FIGURE OUT UNIT
        AxesHandles.HandlePsyc.YLabel.String = '% choice A';
        AxesHandles.HandlePsyc.Title.String = 'Psychometric';
        %% Trial rate
        hold(AxesHandles.HandleTrialRate,'on')
        BpodSystem.GUIHandles.OutcomePlot.TrialRate = line(AxesHandles.HandleTrialRate,[0],[0], 'LineStyle','-','Color','k'); %#ok<NBRAK>
        AxesHandles.HandleTrialRate.XLabel.String = 'Time (min)'; % FIGURE OUT UNIT
        AxesHandles.HandleTrialRate.YLabel.String = 'nTrials';
        AxesHandles.HandleTrialRate.Title.String = 'Trial rate';
        %% Stimulus delay
        hold(AxesHandles.HandleFix,'on')
        AxesHandles.HandleFix.XLabel.String = 'Time (ms)';
        AxesHandles.HandleFix.YLabel.String = 'trial counts';
        AxesHandles.HandleFix.Title.String = 'Pre-stimulus delay';
        %% OST histogram
        hold(AxesHandles.HandleOST,'on')
        AxesHandles.HandleOST.XLabel.String = 'Time (ms)';
        AxesHandles.HandleOST.YLabel.String = 'trial counts';
        AxesHandles.HandleOST.Title.String = 'Odor sampling time';
        %% Feedback Delay histogram
        hold(AxesHandles.HandleFeedback,'on')
        AxesHandles.HandleFeedback.XLabel.String = 'Time (ms)';
        AxesHandles.HandleFeedback.YLabel.String = 'trial counts';
        AxesHandles.HandleFeedback.Title.String = 'Feedback delay';
    case 'update'
        %% Outcome
        iTrial = varargin{1};
        [mn, mx] = rescaleX(AxesHandles.HandleOutcome,iTrial,nTrialsToShow); % recompute xlim
        
        set(BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCircle, 'xdata', iTrial+1, 'ydata', .5);
        set(BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCross, 'xdata', iTrial+1, 'ydata', .5);
        set(BpodSystem.GUIHandles.OutcomePlot.OdorFracA, 'xdata', mn:numel(BpodSystem.Data.Custom.OdorFracA), 'ydata',BpodSystem.Data.Custom.OdorFracA(mn:end)/100);
        
        %Plot past trials
%         if any(~isnan(OutcomeRecord))
            indxToPlot = mn:iTrial;
            %Cumulative Reward Amount
            R = BpodSystem.Data.Custom.RewardMagnitude;
            ndxRwd = BpodSystem.Data.Custom.Rewarded;
            C = zeros(size(R)); C(BpodSystem.Data.Custom.ChoiceLeft==1&ndxRwd,1) = 1; C(BpodSystem.Data.Custom.ChoiceLeft==0&ndxRwd,2) = 1;
            R = R.*C;
            set(BpodSystem.GUIHandles.OutcomePlot.CumRwd, 'position', [iTrial+1 1], 'string', ...
                [num2str(sum(R(:))/1000) ' mL']);
            clear R C
            %Plot Rewarded
%             ndxRwd = ismember(OutcomeRecord(indxToPlot), find(strncmp('rewarded',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end},8)));
            Xdata = indxToPlot(ndxRwd);
            Ydata = BpodSystem.Data.Custom.OdorFracA(indxToPlot); Ydata = Ydata(ndxRwd)/100;
            set(BpodSystem.GUIHandles.OutcomePlot.Correct, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Unrewarded
            ndxUrd = BpodSystem.Data.Custom.Rewarded==0;
            Xdata = indxToPlot(ndxUrd);
            Ydata = BpodSystem.Data.Custom.OdorFracA(indxToPlot); Ydata = Ydata(ndxUrd)/100;
            set(BpodSystem.GUIHandles.OutcomePlot.Incorrect, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Broken Fixation
            ndxBroke = BpodSystem.Data.Custom.FixBroke;
            Xdata = indxToPlot(ndxBroke); Ydata = ones(1,sum(ndxBroke))*.5;
            set(BpodSystem.GUIHandles.OutcomePlot.BrokeFix, 'xdata', Xdata, 'ydata', Ydata);
            %Plot NoFeedback trials
            ndxNoFeedback = ~BpodSystem.Data.Custom.Feedback;
            Xdata = indxToPlot(ndxNoFeedback);
            Ydata = BpodSystem.Data.Custom.OdorFracA(indxToPlot); Ydata = Ydata(ndxNoFeedback)/100;
            set(BpodSystem.GUIHandles.OutcomePlot.NoFeedback, 'xdata', Xdata, 'ydata', Ydata);
%         end
        %% Psyc
        OdorFracA = BpodSystem.Data.Custom.OdorFracA(1:numel(BpodSystem.Data.Custom.ChoiceLeft));
        stimSet = unique(OdorFracA);
        BpodSystem.GUIHandles.OutcomePlot.Psyc.XData = stimSet;
        psyc = nan(size(stimSet));
        for iStim = 1:numel(stimSet)
            ndxStim = OdorFracA == stimSet(iStim);
            ndxNan = isnan(BpodSystem.Data.Custom.ChoiceLeft(:));
            psyc(iStim) = nansum(BpodSystem.Data.Custom.ChoiceLeft(ndxStim)/sum(ndxStim&~ndxNan));
        end
        BpodSystem.GUIHandles.OutcomePlot.Psyc.YData = psyc;
        %% Trial rate
        BpodSystem.GUIHandles.OutcomePlot.TrialRate.XData = (BpodSystem.Data.TrialStartTimestamp-min(BpodSystem.Data.TrialStartTimestamp))/60;
        BpodSystem.GUIHandles.OutcomePlot.TrialRate.YData = 1:numel(BpodSystem.Data.Custom.ChoiceLeft)-1;
        %% Stimulus delay
        cla(AxesHandles.HandleFix)
        BpodSystem.GUIHandles.OutcomePlot.HistBroke = histogram(AxesHandles.HandleFix,BpodSystem.Data.Custom.FixDur(BpodSystem.Data.Custom.FixBroke)*1000);
        BpodSystem.GUIHandles.OutcomePlot.HistBroke.BinWidth = 50;
        BpodSystem.GUIHandles.OutcomePlot.HistBroke.EdgeColor = 'none';
        BpodSystem.GUIHandles.OutcomePlot.HistBroke.FaceColor = 'r';
        BpodSystem.GUIHandles.OutcomePlot.HistFix = histogram(AxesHandles.HandleFix,BpodSystem.Data.Custom.FixDur(~BpodSystem.Data.Custom.FixBroke)*1000);
        BpodSystem.GUIHandles.OutcomePlot.HistFix.BinWidth = 50;
        BpodSystem.GUIHandles.OutcomePlot.HistFix.FaceColor = 'b';
        BpodSystem.GUIHandles.OutcomePlot.HistFix.EdgeColor = 'none';
        %% OST
        cla(AxesHandles.HandleOST)
        BpodSystem.GUIHandles.OutcomePlot.HistOSTbroke = histogram(AxesHandles.HandleOST,BpodSystem.Data.Custom.OST*1000);
        BpodSystem.GUIHandles.OutcomePlot.HistOSTbroke.BinWidth = 50;
        %% Feedback delay
        cla(AxesHandles.HandleFeedback)
        BpodSystem.GUIHandles.OutcomePlot.HistNoFeed = histogram(AxesHandles.HandleFeedback,BpodSystem.Data.Custom.FeedbackTime(~BpodSystem.Data.Custom.Feedback)*1000);
        BpodSystem.GUIHandles.OutcomePlot.HistNoFeed.BinWidth = 100;
        BpodSystem.GUIHandles.OutcomePlot.HistNoFeed.EdgeColor = 'none';
        BpodSystem.GUIHandles.OutcomePlot.HistNoFeed.FaceColor = 'r';
        %BpodSystem.GUIHandles.OutcomePlot.HistNoFeed.Normalization = 'probability';
        BpodSystem.GUIHandles.OutcomePlot.HistFeed = histogram(AxesHandles.HandleFeedback,BpodSystem.Data.Custom.FeedbackTime(BpodSystem.Data.Custom.Feedback)*1000);
        BpodSystem.GUIHandles.OutcomePlot.HistFeed.BinWidth = 100;
        BpodSystem.GUIHandles.OutcomePlot.HistFeed.EdgeColor = 'none';
        BpodSystem.GUIHandles.OutcomePlot.HistFeed.FaceColor = 'b';
%         BpodSystem.GUIHandles.OutcomePlot.HistFeed.Normalization = 'probability';
end

end

function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
set(AxesHandle,'XLim',[mn-1 mx+1]);
end



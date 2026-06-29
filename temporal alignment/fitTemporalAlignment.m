function results = fitTemporalAlignment(results, prevFits)

if nargin < 2
    prevFits = [];
end

lognorm = @(A,mu,sigma,x) ...
    A./(x.*sigma*sqrt(2*pi)) .* exp(-(log(x)-mu).^2./(2*sigma^2));

for ii = 1:length(results)

    name = results(ii).name;
    t = results(ii).t(:);
    y = results(ii).smooth(:);
    fit_result = [];
    t_roi = [];
    y_roi = [];
    x_peak = [];
    t1 = [];
    t2 = [];

    fprintf('\nProcessing: %s\n', name);

    % =====================================================
    % LOAD PREVIOUS FIT
    % =====================================================
    prev = [];
    for k = 1:length(prevFits)
        if strcmp(prevFits(k).name, name)
            prev = prevFits(k);
            break;
        end
    end
    % =====================================================
    % FIGURE SETUP (ALWAYS SHOW SOMETHING)
    % =====================================================
    figure(2); clf; hold on; box on;

    plot(t, results(ii).raw,'k');
    plot(t, y,'b','LineWidth',1.5);

    % =====================================================
    % IF PREVIOUS EXISTS → SHOW IT
    % =====================================================
    if ~isempty(prev) && isfield(prev,'fit') && isfield(prev,'t_roi')
        plot(prev.t_roi, prev.fit(prev.t_roi),'r','LineWidth',2);
        xline(prev.x_peak,'--r');
        title([name ' (previous fit)'],'Interpreter','none');
    else
        % =====================================================
        % AUTO FIT (NO PREV)
        % =====================================================
        [~, peak] = max(y);
        win = 25;

        t1 = max(1, peak - win);
        t2 = min(length(t), peak + win);

        t_roi = t(t1:t2);
        y_roi = y(t1:t2);

        t_roi = t_roi(:);
        y_roi = y_roi(:);

        start = [max(y_roi), log(mean(t_roi)), std(log(t_roi))];

        ft = fittype(lognorm, ...
            'independent','x', ...
            'coefficients',{'A','mu','sigma'});

        fit_result = fit(t_roi, y_roi, ft, 'StartPoint', start);

        x_peak = round(exp(fit_result.mu - fit_result.sigma^2));

        plot(t_roi, fit_result(t_roi),'r','LineWidth',2);
        xline(x_peak,'--r');

        title(name,'Interpreter','none');
    end

    drawnow;
    % =====================================================
    % DECISION LOOP
    % =====================================================
    done = false;

    while ~done

        choice = questdlg( ...
            'Accept, edit ROI or skip?', ...
            'Decision', ...
            'Accept','Edit ROI','Skip','Accept');

        switch choice

            % =========================
            % ACCEPT (use prev or current)
            % =========================
            case 'Accept'

                results(ii).skip = false;

                if ~isempty(prev)
                    % use prev if exists
                    fit_result = prev.fit;
                    t_roi = prev.t_roi;
                    x_peak = prev.x_peak;
                    t1 = prev.interval(1);
                    t2 = prev.interval(2);
                end

                results(ii).interval = [t1 t2];
                results(ii).fit = fit_result;
                results(ii).x_peak = x_peak;
                results(ii).y_peak = fit_result(x_peak);
                results(ii).t_roi = t_roi;

                done = true;

            % =========================
            % SKIP
            % =========================
            case 'Skip'

                results(ii).skip = true;
                results(ii).interval = [];
                results(ii).fit = [];
                results(ii).x_peak = [];
                results(ii).y_peak = [];
                results(ii).t_roi = [];

                done = true;

            % =========================
            % EDIT ROI (manual loop)
            % =========================
            case 'Edit ROI'

                [~, peak] = max(y);
                win = 25;

                t1_auto = max(1, peak - win);
                t2_auto = min(length(t), peak + win);

                figure(2); clf; hold on; box on;

                plot(t, results(ii).raw,'k');
                plot(t, y,'b','LineWidth',1.5);

                roi = drawrectangle('Position',[t1_auto 0 t2_auto-t1_auto max(y)]);
                wait(roi);

                pos = roi.Position;

                t1 = max(1, round(pos(1)));
                t2 = min(length(t), round(pos(1)+pos(3)));

                t_roi = t(t1:t2);
                y_roi = y(t1:t2);

                t_roi = t_roi(:);
                y_roi = y_roi(:);

                start = [max(y_roi), log(mean(t_roi)), std(log(t_roi))];

                ft = fittype(lognorm, ...
                    'independent','x', ...
                    'coefficients',{'A','mu','sigma'});

                fit_result = fit(t_roi, y_roi, ft, 'StartPoint', start);

                x_peak = round(exp(fit_result.mu - fit_result.sigma^2));

                hold on;
                plot(t_roi, fit_result(t_roi),'r','LineWidth',2);
                xline(x_peak,'--r');

                drawnow;
        end
    end

    % =====================================================
    % FINAL SAFETY CHECK
    % =====================================================
    % if isempty(fit_result) && ~isempty(prev)
    %     fit_result = prev.fit;
    %     t1 = prev.interval(1);
    %     t2 = prev.interval(2);
    %     x_peak = prev.x_peak;
    %     t_roi = prev.t_roi;
    % end

    % =====================================================
    % STORE
    % =====================================================

    if ~isfield(results(ii),'skip')
        results(ii).skip = false;
    end

    % save('fit_results.mat','results');
end
end
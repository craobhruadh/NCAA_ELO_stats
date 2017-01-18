
% function CalculateGlicko()
% -----------------------
% Main function - call all other stuff.
% 
% Currently all of the data is stored in a hash table, a global variable
% called "eloMap".
% 
% For more info look at: http://en.wikipedia.org/wiki/Glicko_rating_system
% 
% Data taken here:
% http://stats.ncaa.org/team/inst_team_list?sport_code=MBB&division=1
function CalculateGlicko()
tic
    global eloMap

    eloMap = containers.Map('UniformValues', false);
%     eloMap = containers.Map('KeyType','char','ValueType','double');
%     filename_schools = 'teamlist.txt';
    filename_WLrecord = 'allstats.txt';
       
%     LoadSchools(filename_schools)
    
    ReadWLrecord(filename_WLrecord);
    
    OutputRankings();
   toc
   clear all;
end




% function LoadSchools()
% ----------------------
% Read a text file of strings, and load them into a hashtag, which Matlab
% supports as of 2010.  For more info look at:
% http://www.mathworks.com/help/matlab/map-containers.html
% function LoadSchools(filename)
%     global eloMap
%     
%     
%     
%     fid = fopen(filename, 'r');
%     
%     while ~feof(fid)
%         nextline = fgetl(fid);
%         nextline = strrep(nextline, '.', '');
%         % Start with elo of 1000, like the fide chess
%         eloMap(nextline)= 1000.0; 
%     end
%     fclose(fid);
%     
% end

function ReadWLrecord(filename)
    global eloMap
    fid = fopen(filename, 'r');
    count = 0;
    
    is_first_date = true;
    start_date = -1;

    while ~feof(fid)
        nextline = strtrim(fgetl(fid));
        count = count+1;
        if ~strcmpi(nextline, '') % Make sure you don't read empty strings
            % Considering dates maybe worthwhile but currently it isn't
            % considered - ignore lines with dates
            if (strcmpi(nextline(1), '<'))  % If there is a new date
                date = strrep(nextline, '<', '');
                date = strrep(date, '<', '');
                date = strtok(date, ' ');
                current_date = datenum(date);
                
                if (is_first_date)
                   start_date = current_date;
                   is_first_date = false;
                end
                
                disp(['***Processing data from ' datestr(current_date)])
            else  % Entire this into the record
                first_team = nextline;
                second_team = fgetl(fid); % First assumption - they come in pairs on subsequent lines
                count = count+1;
                calculateELO(first_team, second_team,  current_date)
                
                if (mod(count, 1000) == 0) 
                    disp(num2str(count))
                end
            end
        end
    end
    

    fclose(fid)
    
    
end



% function calculateELO
% ---------------------
% Math done here.
% 
% For more info look at: http://en.wikipedia.org/wiki/Elo_rating_system

function calculateELO(first, second,  current_date)
    global eloMap
    
 	N = 400;  % Number used by 
    K = 32;  % According to wikipedia K is set to 32 for weaker players and 16 for masters
    
    [first_name, first_score] = ParseLine(first);
    [second_name, second_score] = ParseLine(second);

    
    if first_score > second_score
        first_outcome = 1.0;
        second_outcome = 0.0;
disp([first_name ' defeated ' second_name] );      
    else if first_score < second_score 
        first_outcome = 0.0;
        second_outcome = 1.0;
disp([second_name ' defeated ' first_name] );      

        else % it's a draw 
            first_outcome = 0.5;
            second_outcome= 0.5;
disp([first_name ' and ' second_name ' tied!'] );      
            
        end
        
    end
    
    first_oldScore = eloMap(first_name).rating;
    second_oldScore = eloMap(second_name).rating;
    [first_newscore, first_deviation] = CalculateNewRating(first_name, first_outcome, first_oldScore, second_oldScore, current_date);
    [second_newscore, second_deviation] = CalculateNewRating(second_name, second_outcome, second_oldScore, first_oldScore, current_date);


disp(['   ' first_name ' adjusted from ' num2str(first_oldScore) ' to ' num2str(first_newscore) ' with deviation ' num2str(first_deviation)]);
disp(['   ' second_name ' adjusted from ' num2str(second_oldScore) ' to ' num2str(second_newscore) ' with deviation ' num2str(second_deviation)]);

end



function [new_rating, RD_prime] = CalculateNewRating(key, outcome, old_rating, opponent_rating, current_date)
    global eloMap
    
    % The constant c is a bit arbitrary, number of "time units", in this
    % case days, for a team to return to initial uncertainty of 350.
    % Currently this is set to 100 days, but I don't have a great reason
    % for doing this.
    %
    % For example, if the standard value is 50 and it takes 100 days before
    % one sets the RD back to 350, then c is:
    % c = sqrt((350^2 - 50^2)/100) = 34.6
    thisElement = eloMap(key);
    
    if thisElement.last_time ~= -1 % Only calculate this if it isn't the first time
        time = current_date - thisElement.last_time;
        c = 34.6;
        oldRD = thisElement.deviation;
    
        RD = min( sqrt(oldRD^2 + c^2*time) , 350);
    else
        RD = 350;
    end
    
    
    thisElement.last_time = current_date;     
    
    % There is a version of this that can be done for a sequence of games.
    % Currently not implemented
    q = log(10) / 400;
    g_RD = 1.0 / sqrt(1 + (3 * q^2 * RD^2) / (pi^2) );  
    
    expected_value = 1.0 / (1 + 10^(g_RD * (old_rating - opponent_rating) / (-400)) );
    
    d_squared = 1.0 / (q^2 * g_RD^2 * expected_value * (1-expected_value));
    
    new_rating = old_rating + (q / (1/RD^2 + 1/d_squared)) * g_RD * (outcome-expected_value);
    
    thisElement.rating = new_rating;
    
    % The above RD was calculated to account for increasing uncertainty of
    % player over a period of non-observation.  Now calculate new RD after
    % the games
    RD_prime = sqrt((1 / RD^2 + 1 / d_squared)^(-1) );
    thisElement.deviation = RD_prime;
    
    numGames = thisElement.numGames + 1;
    thisElement.numGames = numGames;
    
    eloMap(key) = thisElement;
end

% function ParseLine()
% --------------------
% Simple string handling, designed to read the format of the team W/L
% record text file
function [team_name, score] = ParseLine(nextline)
    global eloMap
    temp = findstr('(', nextline);
    
    if (isempty(temp))  
        % if there isn't a parenthesis?  Example: 
        % Champion Bapt.	 36
        ind = findstr(nextline, ' ');
        team_name = nextline(1:ind);
        score = str2num(nextline(ind:end));
        
    else
        % Typical case, assume parenthesis is a good delineater
        % Example: 
        % Savannah St. (5-4)	 45

        [team_name, remainder]  = strtok(nextline, '('); 

        team_name = strtrim(team_name);
    
    
        [stuff, scores] = strtok(remainder, ')');
 
    % Consider: what if there is another parenthesis? ex:
    % Lincoln (PA) (1-0)	 68
        [a, b] = strtok(scores, ')');
        if(~isempty(b))
            [stuff, scores] = strtok(scores, ')');
        end
    
        scores = strrep(scores, ')', ''); 
        scores = str2num(scores);
        score = scores(length(scores));
    end
    
    % Create this entry if it doesn't already exist
    if (~isKey(eloMap, team_name))
        AddNewEntry(team_name);
    end
    
    
end

function AddNewEntry(key)
    global eloMap
    values = struct('rating', 1000, 'deviation', 350, 'last_time', -1, 'numGames', 0);
    tempMap =  containers.Map(key, values);
    eloMap = [eloMap ; tempMap];
end

function OutputRankings()
    global eloMap
    
    filename = 'AllSchools_glicko';
    
    x = eloMap.keys;
%     y = eloMap.values;
%     y2 = cell2mat(y);

    filename_alphabetical = [filename '_alphabetical.txt'];
    delete(filename_alphabetical);
    fid = fopen(filename_alphabetical, 'w');
    fprintf(fid, '         School_name rating deviation  num_games \n');
    
    all_ratings = zeros(length(x));
    for i=1:length(x)
        y  = eloMap(x{i});
        all_ratings(i) = y.rating;
        fprintf(fid, [num2str(i) ' %20s  % 7.2f  % 7.2f % 5d \n'], x{i}, y.rating, y.deviation, y.numGames);
    end
    fclose(fid);
    
    filename_ranked = [filename '_ranked.txt'];
    [y_sorted, index] = sort(all_ratings, 'descend');
    x_sorted = x(index);
    
    delete(filename_ranked);
    
    fid = fopen(filename_ranked, 'w');
    fprintf(fid, '         School_name rating deviation  num_games \n');
    
    for i=1:length(x_sorted)
        y  = eloMap(x_sorted{i});
%         fprintf(fid, [num2str(i) ' %20s  % 7.2f \n'], x_sorted{i}, y_sorted(i));
        fprintf(fid, [num2str(i) ' %20s  % 7.2f  % 7.2f % 5d \n'], x_sorted{i}, y.rating, y.deviation, y.numGames);
    end
    fclose(fid);
end
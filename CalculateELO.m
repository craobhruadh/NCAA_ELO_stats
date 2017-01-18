
% function CalculateELO()
% -----------------------
% Main function - call all other stuff.
% 
% Currently all of the data is stored in a hash table, a global variable
% called "eloMap".
% 
% For more info look at: http://en.wikipedia.org/wiki/Elo_rating_system
% 
% Data taken here:
% http://stats.ncaa.org/team/inst_team_list?sport_code=MBB&division=1
function CalculateELO()
tic
    global eloMap
    eloMap = containers.Map('KeyType','char','ValueType','double');
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
    while ~feof(fid)
        nextline = strtrim(fgetl(fid));
        count = count+1;
        if ~strcmpi(nextline, '') % Make sure you don't read empty strings
            % Considering dates maybe worthwhile but currently it isn't
            % considered - ignore lines with dates
            if (strcmpi(nextline(1), '<'))
                date = strrep(nextline, '<', '');
                date = strrep(date, '<', '');
                date = strtok(date, ' ');
                disp(['***Processing data from ' datestr(datenum(date))])
            else
                first_team = nextline;
                second_team = fgetl(fid); % First assumption - they come in pairs on subsequent lines
                count = count+1;
                calculateELO(first_team, second_team)
                
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

function calculateELO(first, second)
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
    
    first_oldScore = eloMap(first_name);
    second_oldScore = eloMap(second_name);
%     if (isKey(eloMap, first_name))
%         
%     else
%         first_oldScore = 1000;
%         eloMap(first_name) = 1000;
%     end
%     
%     if (isKey(eloMap, second_name))
%         
%     else
%         second_oldScore = 1000.0;
%         eloMap(second_name) = 1000.0;
%     end
    
    first_expectedScore = 1.0 / (1 + 10^((second_oldScore - first_oldScore)/N ));
    second_expectedScore = 1.0 / (1 + 10^((first_oldScore - second_oldScore)/N ));
    
    first_newscore = first_oldScore + K * (first_outcome - first_expectedScore);
    second_newscore = second_oldScore + K * (second_outcome - second_expectedScore);
    
    
    eloMap(first_name) = first_newscore;
    eloMap(second_name) = second_newscore;
    
disp(['   ' first_name ' adjusted from ' num2str(first_oldScore) ' to ' num2str(first_newscore)]);
disp(['   ' second_name ' adjusted from ' num2str(second_oldScore) ' to ' num2str(second_newscore)]);

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
        eloMap(team_name) = 1000;
    end
    
    
%         team_name = strtrim(team_name);
%     team_name = strrep(team_name, '.', '');
    
end


function OutputRankings()
    global eloMap
    
    filename = 'AllSchools';
    
    x = eloMap.keys;
    y = eloMap.values;
    y2 = cell2mat(y);

    filename_alphabetical = [filename '_alphabetical.txt'];
    delete(filename_alphabetical);
    fid = fopen(filename_alphabetical, 'w');
    for i=1:length(x)
        fprintf(fid, [num2str(i) ' %20s  % 7.2f \n'], x{i}, y2(i));
    end
    fclose(fid);
    
    filename_ranked = [filename '_ranked.txt'];
    [y_sorted, index] = sort(y2, 'descend');
    x_sorted = x(index);
    
    delete(filename_ranked);
    
    fid = fopen(filename_ranked, 'w');
    for i=1:length(x_sorted)
        fprintf(fid, [num2str(i) ' %20s  % 7.2f \n'], x_sorted{i}, y_sorted(i));
    end
    fclose(fid);
end
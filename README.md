README
------


A little while back our office did a “March Madness” fantasy football bracket.  The problem is, I know next to nothing about college 
football; however it seemed like a fun challenge.  

This was my attempt to try and rank schools to find a best estimate of their “true” skill using both the Elo system used for Chess, 
and the Glicko system that’s meant to be an improvement.  It assumes the data is already mined from the website in text format 
(my data-mining attempt left it in ASCII for simplicity). 

Written in matlab. There are two stand-alone .m files, “CalculateELO.m” and “CalculateGlicko.m” that read in the files and outputs 
their rough rankings and scores in two lists, alphabetical and ranked. 

If you compare to the actual results, know that the actual prediction wasn’t all that great, but the algorithm is theoretically sound 
and could perhaps use some refinement and optimization. 


# knapsack.cpp 

This is a program to brute-force the Calibron 12 puzzle via a backtracking
search.  Here's the puzzle on amazon: 

> https://www.amazon.com/Calibron-12-Brain-Teaser-Difficult/dp/B00A7EZX74

I immediately recognized it as having the flavor of NP-Complete problems like knapsack 
and subset-sum, so I didn't try to find a more elegant approach than backtracking
search.

I wrote it in C++ because I feared the search might take a long time, but it actually found
a solution in seconds, the first time I tried to run it (in debug mode from the IDE)!  When I ran
it in Release mode, it returned in a fraction of a second.

So, probably a python solution would have been quicker to write and would have sufficed.
Oh well!  This was still a fun exercise in premature optimization.  I was actaully thinking
about changing out the vectors in the recursive calls for stack-allocated arrays, to save
more time, but that's clearly pointless now.


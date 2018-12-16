# adventofcode-rb-2018

[![Build Status](https://travis-ci.org/petertseng/adventofcode-rb-2018.svg?branch=master)](https://travis-ci.org/petertseng/adventofcode-rb-2018)

For the fourth year in a row, it's the time of the year to do [Advent of Code](http://adventofcode.com) again.

When will it end?

The solutions are written with the following goals, with the most important goal first:

1. **Speed**.
   Where possible, use efficient algorithms for the problem.
   Solutions that take more than a second to run are treated with high suspicion.
   This need not be overdone; micro-optimisation is not necessary.
2. **Readability**.
3. **Less is More**.
   Whenever possible, write less code.
   Especially prefer not to duplicate code.
   This helps keeps solutions readable too.

All solutions are written in Ruby.
Features from 2.5.x will be used, with no regard for compatibility with past versions.

# Input

In general, all solutions can be invoked in both of the following ways:

* Without command-line arguments, takes input on standard input.
* With command-line arguments, reads input from the named files (- indicates standard input).

Some may additionally support other ways:

* Day 9 (Marble Mania): Pass the number of players and the last marble in ARGV
* Day 11 (Max Square / Chronal Charge): Pass the serial in ARGV
* Day 14 (Chocolate Charts): Pass the input in ARGV

# Highlights

Favourite problems:

* None yet

Interesting approaches:

* Day 01 (Frequency Deltas / Chronal Calibration): See https://www.reddit.com/r/adventofcode/comments/a20646/2018_day_1_solutions/eaukxu5/ . I have decided not to pursue this implementation here, but it boasts better performance for some adversarial inputs.
* Day 02 (Inventory Management): Interesting `O(k^2 * n)` solution rather than `O(k * n^2)`, where `k` is length of strings. See some others which may achieve `O(kn)` time:
    * https://www.reddit.com/r/adventofcode/comments/a2damm/2018_day2_part_2_a_linear_time_solution/
    * https://www.reddit.com/r/adventofcode/comments/a2mavh/day_2_part_2_under_n2_time_show_off_your_solution/
    * https://www.reddit.com/r/adventofcode/comments/a2rt9s/2018_day_2_part_2_here_are_some_big_inputs_to/
* Day 05 (Alchemical Reduction): Since characters can only react with their immediate neighbours, use a stack.
* Day 09 (Marble Mania):
    * The marble to be removed is the one to the right of the 18th marble in a cycle of 23. Thus, we only need a singly-linked list, not a doubly-linked list.
    * Marbles to be removed are at indices 19, 35, 51, 67.... Once we have enough marbles in the list, we can stop adding new ones.
* Day 11 (Max Square / Chronal Charge):
    * https://en.wikipedia.org/wiki/Summed-area_table
    * We can calculate a maximum upper bound on the size of a square with length 2N by using four squares of length N.
    * We can calculate a maximum upper bound on the size of a square with length 2N+1 by using two squares of length N plus two squares of length N+1 minus one square.
* Day 14 (Chocolate Charts):
    When wrapping around, you must land on one of the first ten elements of the array.
    All sequences converge on index 23.
    From that point forward, we only need to store the scores that elves will land on.
    All other scores can be immediately discarded after updating the state of "how many charactes have I seen".
* Day 15 (Beverage Bandits):
    A single BFS seems like the way to go here.
    It's easy to keep track of the layers of the BFS, so as soon as a layer finds a nonzero number of goals, we can stop.
    In addition, implement the "and so none of the units can move until a unit dies" optimisation noted in the problem text.

# Takeaways

* Day 06 (Chronal Coordinates): Assumed I needed to be clever about which coordinates I check, wrote incorrect code that attempted to scan every row for the start/end column of the safe region on that row, but was actually an infinite loop. Changed to a flood-fill solution to get a spot on the leaderboard. Later discovered that using only the points in the bounding box would have been fine, given how far away the points are.
* Day 09 (Marble Mania): Assumed there would be some pattern to be found within the sequence and wasted time trying to find it, rather than just brute-forcing it with a better data structure.
* Day 11 (Max Square / Chronal Charge): Attempted to cache (only add new edges and corners) which still ends up taking 2 minutes to run because it's O(n^4), and was bug-prone and took a long time to write. For getting on the leaderboard, consider a completely different approach: Just use the O(n^5) approach, but with size as the outermost loop. Print out the largest square found for each size and submit when they start decreasing. In other words, try asymptotically-slow approaches that can nevertheless give an answer reasonably fast, rather than waiting for an asymptotically-fast approach to finish.
* Day 14 (Chocolate Charts): As I recall, I tried just taking a subarray of the last 6 scores at any time and comparing this against the desired sequence, but even this was too slow; I switched to only incrementing a counter when I had a match, which worked fast enough but was a bit error prone. I saw others just check every 1000 scores or so, only checking the last 1000+6 scores.
* Day 16 (Chronal Classification): A small reading mistake here; I checked for `== 3` instead of `>= 3`.

# Posting schedule and policy

Before I post my day N solution, the day N leaderboard **must** be full.
No exceptions.

Waiting any longer than that seems generally not useful since at that time discussion starts on [the subreddit](https://www.reddit.com/r/adventofcode) anyway.

Solutions posted will be **cleaned-up** versions of code I use to get leaderboard times (if I even succeed in getting them), rather than the exact code used.
This is because leaderboard-seeking code is written for programmer speed (whatever I can come up with in the heat of the moment).
This often produces code that does not meet any of the goals of this repository (seen in the introductory paragraph).

# Past solutions

The [index](https://github.com/petertseng/adventofcode-common/blob/master/index.md) lists all years/languages I've ever done (or will ever do).

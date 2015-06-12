### Evolution/Genetic algorithms

#### What is this ?

Here I will collect my experiments on Evolution/Genetic algorithms.

### Example 1 : Finding a string (evo.pl, evo.rb)

First example is implemented in two programming languages : **Perl and Ruby**. (Just wanted to be able to make a comparison)

You provide a target string and the app evolves a pool of strings until some of them match the target.
Keep in mind this is just example to understand the basic algorithm. Evolution normally does not have specific goal ;).
I have planned more elaborate and interesting examples in the future.

#### TODO

1. Tutorial
2. Trend search evolution algorithm (**Python**)

#### Algorithm

0. Check if we have found a match. If yes then end the evolution cycle.
1. **SELECTION** : Pick two random parents (with tendency for ones that are closer to the target, better fitness score)
2. **CROSSOVER** : Mate and produce a child
4. **MUTATION**  : Mutate the child-string
5. If child is better than the worse parent, then parent dies, child takes its place in the pool
6. Rinse and repeat until the process produces a match.

-----

##### Important :
```
def rand_parent range; ((rand * rand) * range).to_i end
```

guarantees that parents with lower fitness will be picked (pool is sorted higher --> lower fitness).

> Multiplying (rand * rand), will on average pick number closer to 1 rather than 0 i.e. because pool is SORTED h-to-l, lower fittness wins.


### Example 2 : Traveling salesman problem (tsp.rb, tsp_test.rb)

This is the famous Traveling salesman problem. You have N cities and distance between them and you have to visit them all using the shortest possible path
without visiting the same town twice.

On first sight it does not seem as hard problem, but when you start to think how many permutations of paths there are it becomes clear that brute
force computation will work only for small number of cities.

The number of possible paths are (N-1)! and if you don't count reverse paths then (N-1)!/2

If we quickly do the math for different number of cities (using the second formula) :

- 10 cities = 181_440 non-duplicate paths
- 20 cities = ~ 6 * 10^16 paths i.e. ~60 quadrillion
- 30 cities = ~ 4.4 * 10^30, no idea what number this is
- 70 cities = ~ 1 Gogol paths

Now that sucks. But we can use Genetic/Evolution algorithm to find may be not the best but somewhat optimal solution, with much less computational resources.
The code structure is almost the same as the one we used for String-target example. We again use Character-encoding, which is convenient :).

The main differences are the following :

1. There is no TARGET we try to find, we just search thought this humongous search space guided only by the fitness function.
2. Fitness function is the primary tool by which we direct the algorithm by calculating the distance between cities. Shortest path wins.
3. Mutation just swaps two characters (instead of introducing new character : Example 1). The reason is that there can't be duplicate cities in the path.
4. Crossover picks part of the path from the first path and then selects cities from the second, again no duplicates allowed.

The rest of the code is mostly cosmetic changes and reporting methods.

In tsp_test.rb uncomment loop_over() statements to see the two examples with USA cities.

**TODO:** draw the paths, so we can visually see what is the solution.

**Observations:** When I increase the gene pool it seems that the solution becomes worse. The reason I think is that now I need to increase the number of iterations to achieve similar results. Smaller number of genes will search trough smaller and more narrow part of the whole search space.
That can be both good or bad.


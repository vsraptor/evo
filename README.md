### Evolution/Genetic algorithms

#### What is this ?

Here I will collect my experiments on Evolution/Genetic algorithms.

#### Finding a string

First example is implemented in two programming languages : **Perl and Ruby**. (Just wanted to be able to make a comparison)

You provide a target string and the app evolves a pool of strings until some of them match the target.
Keep in mind this is just example to understand the basic algorithm. Evolution normally does not have specific goal ;).
I have planned more elaborate and interesting examples in the future.

#### TODO

1. Tutorial
2. Trend search evolution algorithm (**Python**)

#### Algorithm

0. Check if we have found a match. If yes then end the evolution cycle.
1. **CROSSOVER**
  - Pick two random parents (with tendency for ones that are closer to the target, better fitness score)
  - Mate and produce a child
2. **MUTATION**
  - Mutate the child-string
3. **SELECTION** (by fitness score)
  - If child is better than the worse parent, then parent dies, child takes its place in the pool
4. Rinse and repeat until the process produces a match.

-----

##### Important :
```
def rand_parent range; ((rand * rand) * range).to_i end
```

guarantees that parents with lower fitness will be picked (pool is sorted higher --> lower fitness).

> Multiplying (rand * rand), will on average pick number closer to 1 rather than 0 i.e. because pool is SORTED h-to-l, lower fittness wins.


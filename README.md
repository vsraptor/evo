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

> Multiplying (rand * rand), will on average pick number closer to 1 rather than 0 i.e. because pool is SORTED h-to-l, lower fitness wins.

-----

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

1. There is no TARGET that we are trying to find, we just search thought this humongous search space guided only by the fitness function.
2. Fitness function is the primary tool by which we direct the algorithm by calculating the distance between cities. Shortest path wins.
3. Mutation just swaps two characters (instead of introducing new character as in Example 1). The reason is that there can't be duplicate cities in the path.
4. Crossover picks part of the path from the first path and then selects cities from the second, because again no duplicates allowed.

The rest of the code is mostly cosmetic changes and reporting methods.

#### Run the tests

There are 3 tests, available in test_tsp.rb :

1. Basic USA cities
2. Extended USA cities
3  Generate random cities (default if no arg provided).

You can run it like this :

``` ruby test_tsp.rb 2 ```

If you have green_shoes lib installed the app will also draw a graph of the path.

**Observations:** When I increase the gene pool it seems that the solution becomes worse. The reason I think is that now I need to increase the number of iterations to achieve similar results. Smaller number of genes will search trough smaller and more narrow part of the whole search space.
That can be both good or bad.

Please try to run experiments with more than 10_000 iterations.


### Example 3 : Discover the expression ! (evo_expressions.rb, expr_test.rb)

For our third example, lets go in different direction.

The idea here is that we are provided with INPUT and corresponding OUTPUT data sets of a arithmetic expression/function.
Our goal is to find/evolve the expression that satisfies the data as close as possible.

Again the core algorithm and code closely resembles the previous two.
The first obvious change we have to do is dictated by the problem.
We can no longer use String encoding, instead we represent the evolving expressions via Tree structure (TreeExpr class) and whenever we
need to do fitness-calculation, we convert the tree to string-expression which we eval()-uate.
We will also need tree-aware mutate() and mate() methods.

This complicates the encoding/decoding process, if you look at the code you will see that the routines are logically simple, it is just little 
harder to debug and interpret the results. Another complication is that we need to make sure that we are building correct expressions which can
be evaluated.

You will need :

```
gem install rubytree
```

to test this application.

This evolution process has much more knobs that can be tweaked to get different result.

- **vars** : provide an array of variable names to be used in the expressions.
- **pool_size** : how many chromosomes will be used. Smaller values means faster computation and faster mutation, but explores smaller search space.
- **max_depth** : specifies up to how many level "deep" expression trees will be, when generating the initial random pool.
- **drop_node_count** : when new tree-expr is created by mating&mutation if it exceeds this "depth" part of the expression is dropped, to lower its complexity.
- **max_children** : In comparison with previous examples, in the current one in one evolution iteration the parents may have multiple offspring.
This is closer to what happen in real biological world, where animals have much more children that the environment can bare, this way give better survival of the genes. Also in the "real"-evolution the variations comes primary by crossover/mating rather than mutation.
- **max_mate_pairs** : In conjunction with the previous option, I'm trying to make every evolution step "heavier" by allowing multiple parents to mate during single evolutionary iteration.
- **min_fitness** : At least what fitness is considered a plausible solution to our problem.
- **do_fun** : If true then math function as exp(), log2() and such will be used. This is experimental option and was not my goal to use functions when I started this experiment.

Remember evolutionary process does not guarantee the best solution.

*TODO:* Add support for Constants. Supporting constants is abit tricky because they can vary much widely than pre-specified arithmetic operations and couple of variables. There is many different ways I can implement some support for them, when I'm clear what like to do I will do it.

#### Running the tests :

Here is how to quickly run the tests :

```
ruby expr_test.rb three2
```

where the argument "three2"is the name of the test function (which is defined in the beginning of expression_test.rb. You can define your own there too, just follow the naming convention).
Here is some running examples :

```
> ruby expr_test.rb four1

......
{:best_match=>{:expr=>((((x1+x0)/x3)-x2)*x3), :fitness=>6.826013412877415e-26, :generation=>2803}, :iter=>2803, :found=>true}

Using variables : ["x0", "x1", "x2", "x3"]
Using function: four2()
def four2 a; a[0] + a[1] - a[2] * a[3] end

> ruby expr_test.rb four1

......
{:best_match=>{:expr=>(((x3-x2)+x0)+x1), :fitness=>7.947181974422779e-29, :generation=>1297}, :iter=>1297, :found=>true}

Using variables : ["x0", "x1", "x2", "x3"]
Using function: four1()
def four1 a; a[0] + a[1] - a[2] + a[3] end

```

###### *Observations*
You can see that you can get different results at different iteration, but that is OK.
Sometimes the process goes astray for example trying to approximate two-var function that contains math-function, but using only variables in the search.
One of the reasons for this is just two variables does not provide enough targets for mutation, when you can pick from only two options.
Other times the "found" function will be complicated version of the original, but we should expect that.

Once you go to 5 arguments things start to get tricky :), probably the solution which I may explore in future apps is it to simulate changing environment (f.e. dynamic pool size change, so that I can force specialization and/or run multiple pools that mix and die out..etc.).
Play with the options if you hit problem.

Also clever-er ways to do crossover may help, because the current slice&dice crossover does not help much in going toward better solution, instead it is very random.
On the other hand if we put more intelligence into the crossover we are deviating from the idea that we want to explore the solutions w/o pre-knowledge of the sub-search-space where the right solution is.

----

> github code browser substities 8 spaces for every TAB and the code look too dispersed. You can use a trick to change how many spaces a TAB will occupy. Just add ?ts=2 at the end of the URL or whatever number you feel comfortable with and everything will be dandy.

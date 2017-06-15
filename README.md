# POMDPToolbox
[![Build Status](https://travis-ci.org/JuliaPOMDP/POMDPToolbox.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/POMDPToolbox.jl)
[![Coverage Status](https://coveralls.io/repos/github/JuliaPOMDP/POMDPToolbox.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaPOMDP/POMDPToolbox.jl?branch=master)

Support tools for POMDPs.jl. This is a supported [JuliaPOMDP](https://github.com/JuliaPOMDP) package that provides tools
for belief updating, problem modeling, and running simulations. 

The most important tools in this package are the [simulators](#Simulators). They can be used to easily run simulations of POMDP problems and policies.

## Installation

This package requires [POMDPs.jl](https://github.com/JuliaPOMDP). To install this module run the following command:

```julia
using POMDPs
POMDPs.add("POMDPToolbox")
```

## Code structure

Within src, there are three directories representing classes of tools, beliefs, policies, and simulators.

Within each class directory, each file contains one tool. Each file should clearly indicate who is the maintainer of that file.

## Tools

### Beliefs
  - `discrete.jl`: dense discrete probability distribution and updater.
  - `particle.jl`: basic particle filter (deprecated; use [ParticleFilters.jl](https://github.com/JuliaPOMDP/ParticleFilters.jl))
  - `previous_observation.jl`: beliefs (and updaters) that only deal with the most recent observation
    - `PreviousObservationUpdater` maintains a "belief" that is a `Nullable{O}` where `O` is the observation type. The "belief" is null if there is no observation available, and contains the previous observation if there is one.
    - `FastPreviousObservationUpdater` just returns the previous observation when `update` is called. There is no mechanism for representing the case when an observation is not available.
    - `PrimedPreviousObservationUpdater` also returns the previous observation, but if an observation is not available, it returns a default.
  - `void.jl`: an updater useful for when a belief is not necessary (i.e. for a random policy). `update` always returns `nothing`.

### Convenience
  - `implementations.jl`: default implementations for simple cases (e.g. `states(::MDP{Bool, Bool})`).

### Distributions
  - `distributions_jl.jl`: provides some compatibility with [Distributions.jl](https://github.com/JuliaStats/Distributions.jl).

### Model
  - `initial.jl`: a uniform distribution for discrete problems.
  - `ordered_spaces.jl`: functions that return vectors of all the items in a space correctly ordered. For example `ordered_actions(mdp)` will return a vector `v`, containing all of the actions in `actions(mdp)` in the order such that  `action_index(v[i]) == i`.

### Policies
  - `function.jl`: turns a function into a `Policy` object, i.e. when `action` is called on `FunctionPolicy(s->1)`, it will always return `1` as the action.
  - `random.jl`: a policy that returns a randomly selected action using `rand(rng, actions(pomdp))`.
  - `stochastic.jl`: a more flexible set of randomized policies including the following:
    - `StochasticPolicy` samples actions from an arbitrary distribution.
    - `EpsGreedy` uses epsilon-greedy action selection.
  - `vector.jl`: tabular policies including the following:
    - `VectorPolicy` holds a vector of actions, one for each state, ordered according to `state_index`.
    - `ValuePolicy` holds a matrix of values for state-action pairs and chooses the action with the highest value at the given state

### Simulators
  - `rollout.jl`: `RolloutSimulator` is the simplest MDP or POMDP simulator. When `simulate` is called, it simply simulates a single trajectory of the process and returns the discounted reward.
    ```julia
    rs = RolloutSimulator()
    mdp = GridWorld()
    policy = RandomPolicy(mdp)

    r = simulate(rs, mdp, policy)
    ```
    See output of `?RolloutSimulator` for a list of keyword arguments.

  - `history_recorder.jl`: `HistoryRecorder` runs a simulation and records the trajectory. It returns an `MDPHistory` or `POMDPHistory` (see `history.jl` below).
    ```julia
    hr = HistoryRecorder(max_steps=100)
    pomdp = TigerPOMDP()
    policy = RandomPolicy(pomdp)

    h = simulate(hr, pomdp, policy)
    ```
    See the output of `?HistoryRecorder` for a list of keyword arguments.

  - `history.jl`: contains types for representing simulation histories (i.e. trajectories or episodes).

    An `MDPHistory` represents a state-action-reward history from simulating an MDP. A `POMDPHistory` contains a record of the states, actions, observations, rewards, and beliefs encountered during a simulation of a POMDP. Both of these are subtypes of `SimHistory`.
    
    The steps of any `SimHistory` object `h` can be iterated through as follows:

    ```julia
    for (s, a, r, sp) in eachstep(h, "(s, a, r, sp)")    
        println("reward $r received when state $sp was reached after action $a was taken in state $s")
    end
    ```
    
    The iterator specification string may or may-not include commas and parentheses the possible valid elements in a step tuple are
    - `s` - the initial state in a step
    - `b` - the initial belief in the step (for POMDPs only)
    - `a` - the action taken in the step
    - `r` - the reward received for the step
    - `sp` - the final state at the end of the step (s')
    - `o` - the observation received during the step (note that this is usually based on `sp` instead of `s`)

    Examples:
    ```julia
    collect(eachstep(h, "ao"))
    ```
    will produce a vector of action-observation tuples.

    ```julia
    collect(norm(sp-s) for (s,sp) in eachstep(h, "s,sp"))
    ```
    will produce a vector of the distances traveled on each step (assuming the state is a Euclidean vector).

    Notes:
    - The iteration specification can be specified as a tuple of symbols (e.g. `(:s, :a)`) instead of a string.
    - For type stability in performance-critical code, one should construct an iterator directly using `HistoryIterator{typeof(h), (:a,:r)}(h)` rather than `eachstep(h, "ar")`.
    
    `state_hist(h)`, `action_hist(h)`, `observation_hist(h)` `belief_hist(h)`, and `reward_hist(h)` will return vectors of the states, actions, and rewards, and `undiscounted_reward(h)` and `discounted_reward(h)` will return the total rewards collected over the trajectory. `n_steps(h)` returns the number of steps in the history. `exception(h)` and `backtrace(h)` can be used to hold an exception if the simulation failed to finish.

    `view(h, range)` (e.g. `view(h, 1:n_steps(h)-4)`) can be used to create a view of the history object `h` that only contains a certain range of steps. The object returned by `view` is a `SimHistory` that can be iterated through and manipulated just like a complete `SimHistory`.


  - `sim.jl`: The `sim` function provides a convenient way to interact with a POMDP or MDP environment. The first argument is a function that is called at every time step and takes a state (in the case of an MDP) or an observation (in the case of a POMDP) as the argument and then returns an action. The second argument is a pomdp or mdp. It is intended to be used with Julia's `do` syntax as follows:
    ```julia
    pomdp = TigerPOMDP()
    history = sim(pomdp, max_steps=10) do obs
        println("Observation was $obs.")
        return TIGER_OPEN_LEFT
    end
    ```
    This allows a flexible and general way to interact with a POMDP environment without creating new `Policy` types.

    Note: by default, since there is no observation before the first action, on the first call to the `do` block, `obs` is `nothing`.

  - `stepthrough.jl`: The `stepthrough` function exposes a simulation as an iterator so that the steps can be iterated through with a for loop syntax as follows:
    ```julia
    pomdp = BabyPOMDP()
    policy = RandomPolicy(pomdp)

    for (s, a, o, r) in stepthrough(pomdp, policy, "s,a,o,r", max_steps=10)
        println("in state $s")
        println("took action $o")
        println("received observation $o and reward $r")
    end
    ```
    For more information, see the documentation for the `stepthrough` function.

    The `StepSimulator` contained in this file can provide the same functionality with the following syntax:
    ```julia
    sim = StepSimulator("s,a,r,sp")
    for (s,a,r,sp) in simulate(sim, problem, policy)
        # do something
    end
    ```

### Testing
  - `model.jl`: generic functions for testing POMDP models.
  - `solver.jl`: standard functions for testing solvers. New solvers should be able to be used with the functions in this file.


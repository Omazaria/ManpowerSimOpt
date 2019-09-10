#include(joinpath( dirname( Base.source_path() ), "..", "Functions", "mpInit.jl" ))

@everywhere module MPStochasticSearch
    import StochasticSearch

    # Types
    import StochasticSearch:   Parameter,
                               NumberParameter,
                               IntegerParameter,
                               FloatParameter,
                               PermutationParameter,
                               EnumParameter,
                               StringParameter,
                               BoolParameter,
                               Configuration,
                               Result,
                               AbstractResult,
                               ResultChannel,
                               Run

    # Methods
    import StochasticSearch:   perturb!,
                               perturb_elements!,
                               neighbor!,
                               optimize,
                               update!,
                               unit_value,
                               unit_value!

    # Measurement Tools
    import StochasticSearch: measure_mean!,
                             sequential_measure_mean!

    # Search Building Blocks
    import StochasticSearch:   first_improvement,
                               probabilistic_improvement,
                               greedy_construction,
                               random_walk

    # Search Techniques
    import StochasticSearch:   simulated_annealing,
                               #iterative_gredy_construction,
                               iterative_first_improvement,
                               randomized_first_improvement,
                               iterative_probabilistic_improvement,
                               iterated_local_search

    # Search Tools
    import StochasticSearch:   initialize_search_tasks!,
                               get_new_best,
                               elapsed_time_criterion,
                               iterations_criterion,
                               iterations_reporting_criterion,
                               elapsed_time_reporting_criterion,
                               log_temperature
   #Extra
   import StochasticSearch:   chooseproc,
                              metropolis,
                              rand_in

   # New Methods for Base Functions
   import Base: convert,
          show,
          getindex,
          setindex!,
          put!,
          take!,
          fetch,
          isready

   # Types
   export Parameter,
          NumberParameter,
          IntegerParameter,
          FloatParameter,
          PermutationParameter,
          EnumParameter,
          StringParameter,
          BoolParameter,
          Configuration,
          Result,
          ResultChannel,
          Run

   # Methods
   export perturb!,
          perturb_elements!,
          neighbor!,
          optimize,
          update!,
          unit_value,
          unit_value!

   # Measurement Tools
   export measure_mean!,
          sequential_measure_mean!

   # Search Building Blocks
   export first_improvement,
          probabilistic_improvement,
          greedy_construction,
          random_walk

   # Search Techniques
   export simulated_annealing,
          iterative_gredy_construction,
          iterative_first_improvement,
          randomized_first_improvement,
          iterative_probabilistic_improvement,
          iterated_local_search


   # Search Tools
   export initialize_search_tasks!,
          get_new_best,
          elapsed_time_criterion,
          iterations_criterion,
          iterations_reporting_criterion,
          elapsed_time_reporting_criterion,
          log_temperature

    # My adds
    export  get_best,
            MPResult,
            MPprobabilistic_improvement,
            MPsimulated_annealing,
            MPRun,
            MPResultChannel


    include(joinpath( dirname( Base.source_path() ), myid()==1? "..": "src", "types", "MPresults.jl" ))
    include(joinpath( dirname( Base.source_path() ), myid()==1? "..": "src", "types", "MPRun.jl" ))
    include(joinpath( dirname( Base.source_path() ), myid()==1? "..": "src", "Functions", "MPStochasticSearch.jl" ))
    include(joinpath( dirname( Base.source_path() ), myid()==1? "..": "src", "Functions", "Tests41-48.jl" ))
    include(joinpath( dirname( Base.source_path() ), myid()==1? "..": "src", "types", "MPResultChannel.jl" ))

end

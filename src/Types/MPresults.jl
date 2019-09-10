type MPResult{T <: Configuration, R <: Number} <: AbstractResult
    technique::String
    start::T
    minimum::T
    cost_minimum::R
    iterations::Int
    current_iteration::Int
    cost_calls::Int
    is_final::Bool
    current_time::Float64
    Fitness::Dict{String, Any}
    function MPResult(technique::String,
                      start::T,
                      minimum::T,
                      cost_minimum::R,
                      iterations::Int,
                      current_iteration::Int,
                      cost_calls::Int,
                      is_final::Bool,
                      Fitness::Dict{String, Any})
        new(technique, start, minimum, cost_minimum,
            iterations, current_iteration, cost_calls, is_final, 0, Fitness)
    end
end

function MPResult{T <: Configuration, R <: Number}(technique::String,
                                                 start::T,
                                                 minimum::T,
                                                 cost_minimum::R,
                                                 iterations::Int,
                                                 current_iteration::Int,
                                                 cost_calls::Int,
                                                 is_final::Bool,
                                                 Fitness::Dict{String, Any})
    MPResult{T, R}(technique, start, minimum, cost_minimum,
                 iterations, current_iteration, cost_calls, is_final, Fitness)
end

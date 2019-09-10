type MPResultChannel <: AbstractChannel
    current_result::MPResult
    MPResultChannel(result::MPResult) = new(result)
end

function put!(channel::MPResultChannel, result::MPResult)
    if result.cost_minimum < channel.current_result.cost_minimum
        channel.current_result = result
    end
    channel
end

function take!(channel::MPResultChannel)
    fetch(channel)
end

function fetch(channel::MPResultChannel)
    channel.current_result
end

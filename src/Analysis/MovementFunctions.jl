function distance(x::AbstractVector, y::AbstractVector)
    xdist = pushfirst!(diff(x),0.0)
    ydist = pushfirst!(diff(y),0.0)
    @. ((sqrt(xdist^2 + ydist^2))/80)*12
end

function baseline_speed(period_vec, speed_vec)
    length(period_vec) == 10 || return missings(length(period_vec))
    if all(period_vec .== 0)
        return missings(length(speed_vec))
    elseif all(period_vec .!= 0)
        baseline = mean(skipmissing(speed_vec[1:3]))
        return speed_vec .- baseline
    else
        error("unclear situation")
    end
end
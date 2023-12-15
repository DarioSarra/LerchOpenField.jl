function distance(x::AbstractVector, y::AbstractVector)
    xdist = pushfirst!(diff(x),0.0)
    ydist = pushfirst!(diff(y),0.0)
    @. ((sqrt(xdist^2 + ydist^2))/80)*12
end
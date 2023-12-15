function shift_run_period(period_vec::AbstractVector)
    v = copy(period_vec)
    if v[1] == 2
        v[1:7] .= 1
    elseif v[1] == 3
        v[1:7] .= 2
    end
    return v
end

function adjustperiods!(df::AbstractDataFrame)
    rename!(df, " StimState" => "StimState")
    transform!(groupby(df,[:MouseID]), :RunState => (x -> cumsum(pushfirst!(diff(x),0) .!= 0).+1) => :Block)
    transform!(groupby(df,[:MouseID, :Block]), :RunState => shift_run_period => :RunState)
    transform!(groupby(df,[:MouseID]), :RunState => (x -> cumsum(pushfirst!(diff(x),0) .!= 0).+1) => :Block)
    idxs = findall((df.RunState .== 2) .&& (df.StimState .== 0))
    df[idxs,:StimState] .= 1
    transform!(groupby(df,[:MouseID, :Block]), :RunState => (x -> collect(1:length(x))) => :BlockVolume)
    transform!(groupby(df,[:MouseID, :Block]), :X => (x -> repeat(1:10, Int64(ceil(length(x)/10)))[1:length(x)]) => :Period)
end

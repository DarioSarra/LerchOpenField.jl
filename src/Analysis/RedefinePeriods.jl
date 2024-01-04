function shift_run_period(period_vec::AbstractVector)
    v = copy(period_vec)
    if v[1] == 2
        v[1:7] .= 1
    elseif v[1] == 3
        v[1:7] .= 2
    end
    return v
end

## old version
# function adjustperiods!(df::AbstractDataFrame)
#     rename!(df, " StimState" => "StimState", " StimCount" => "StimCount")
#     transform!(groupby(df,[:MouseID]), :RunState => (x -> cumsum(pushfirst!(diff(x),0) .!= 0).+1) => :Block)
#     transform!(groupby(df,[:MouseID, :Block]), :RunState => shift_run_period => :RunState)
#     transform!(groupby(df,[:MouseID]), :RunState => (x -> cumsum(pushfirst!(diff(x),0) .!= 0).+1) => :Block)
#     idxs = findall((df.RunState .== 2) .&& (df.StimState .== 0))
#     df[idxs,:StimState] .= 1
#     transform!(groupby(df,[:MouseID, :Block]), :RunState => (x -> collect(1:length(x))) => :BlockVolume)
#     transform!(groupby(df,[:MouseID, :Block]), :X => (x -> repeat(1:10, Int64(ceil(length(x)/10)))[1:length(x)]) => :Period)
#     transform!(groupby(df,:MouseID), :Block => add_ripetitions_count => :Repetitions)
# end

function adjustperiods!(df::AbstractDataFrame)
    rename!(df, " StimState" => "StimState", " StimCount" => "StimCount", " MaskLED" => "MaskLED", " Pulse" => "Pulse")
    transform!(groupby(df,[:MouseID]), :RunState => (x -> vcat(fill(1,4), x[1:end-4])) => :RunState,
        [:MaskLED, :Pulse, :StimCount] .=> (x -> vcat(fill(0,4), x[1:end-4])) .=> [:MaskLED, :Pulse, :StimCount])
    transform!(groupby(df,[:MouseID]), :RunState => (x -> cumsum(pushfirst!(diff(x),0) .!= 0).+1) => :Block)
    idxs = findall((df.RunState .== 2) .&& (df.StimState .== 0))
    df[idxs,:StimState] .= 1
    transform!(groupby(df,[:MouseID, :Block]), :RunState => (x -> collect(1:length(x))) => :BlockVolume)
    transform!(groupby(df,[:MouseID, :Block]), :X => (x -> repeat(1:10, Int64(ceil(length(x)/10)))[1:length(x)]) => :Period)
    transform!(groupby(df,:MouseID), :Block => add_ripetitions_count => :Repetitions)
    transform!(df, [:StimCount,:Repetitions] => ByRow((c,r) -> c!=0 ? c+(30*(r-1)) : 0) => :StimCount)
end

function add_ripetitions_count(df_vec)
    block_ends = 599:600:length(df_vec)
    block_starts = 0:600:length(df_vec)
    n_blocks = length(block_ends) + 1
    block_intervals = [starts == 0 ? (1:ends) : (starts:ends) for (starts,ends) in zip(block_starts, block_ends)]
    repetitions = fill(n_blocks, length(df_vec))
    for (idx,int) in enumerate(block_intervals)
        repetitions[int] .= idx
    end
    return repetitions
end
function read_of(filepath::String) #joinpath(main_path,file_df[i,:OF])
    f_of = CSV.read(filepath, DataFrame; missingstring=["NA", "NAN", "NULL", "NaN"])
    rename!(f_of, :Item1 => :X, :Item2 => :Y, :Item4 => :LED, :Item5 => :Distance)
    f_of[!,:Blink] = pushfirst!(diff(f_of.LED),0) .== -1
    f_of[!,:Frame] = 1:nrow(f_of)
    return f_of
end

function read_of(filepath::DataFrameRow)
    read_of(filepath.OF)
end

function detect_blink(f_of::AbstractDataFrame)
    pre_of = subset(f_of, :Blink)
    pre_of[!,:FrameCounter] = pushfirst!(diff(pre_of.Frame),0)
    select!(pre_of, [:Frame,:FrameCounter])
    start_idx = pre_of[findfirst(pre_of.FrameCounter .> 20), :Frame]
    f_of = leftjoin(f_of, pre_of, on = :Frame; matchmissing = :equal, makeunique = true)
    sort!(f_of, :Frame)

    return f_of, start_idx
end

function adjust_of(f_of::AbstractDataFrame)
    f_of, start_idx = detect_blink(f_of)
    f_of = f_of[start_idx:end,:];
    transform!(f_of, :Blink => cumsum => :Timer)
    combine(groupby(f_of, :Timer), :X => mean => :X, :Y => mean => :Y)
end

function adjust_of(filepath::String)
    f_of = read_of(filepath)
    adjust_of(f_of)
end

function adjust_of(filepath::DataFrameRow)
    adjust_of(filepath.OF)
end
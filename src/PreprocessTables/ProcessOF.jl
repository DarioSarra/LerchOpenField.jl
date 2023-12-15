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

#=
    This function is used when LZR has a lot more data than OF. 
    Assuming the camera has not detected some blinks, this loop jumps from the last detected blinks to the previous correcting the interval.
    To keep track of the correct number of blinks the loop is controlled by the number of volumes detected by arduino.
    This means that at each step of the LZR file we correct the previous assignment of frame.
    There fore when we reach the last row of the LZR file all previous blinks are set to false
=#
function checkframecounter!(vector, lastblink, step; verbose = false)
    thisblink = findprev(vector,lastblink-1)
    dist = lastblink - thisblink
    if dist > 2*step
        verbose && println("larger than step lastblink = $lastblink. thisblink = $thisblink")
        # vector[thisblink] = false
        thisblink = lastblink - step
        vector[thisblink] = true
    elseif dist < step/2
        verbose && println("smaller than step lastblink = $lastblink. thisblink = $thisblink")
        vector[thisblink] = false
        nextblink = findprev(vector,thisblink-1)
        if lastblink - nextblink > 2*step
            thisblink = lastblink - step
            vector[thisblink] = true
        else
            thisblink = nextblink
        end
    end
    return thisblink
end

function fix_short_of(lzr_df, f_of; verbose = false)
    cp_of, start_idx = detect_blink(f_of)
    step = mode(skipmissing(cp_of.FrameCounter))
    lastblink = 0
    for idx in nrow(lzr_df):-1:1
        verbose && println(idx)
        if idx == nrow(lzr_df)
            lastblink = findprev(cp_of.Blink,findlast(cp_of.Blink)-1)
            continue
        elseif idx == 1
            cp_of[1:lastblink - 1,:Blink] .= false
            break
        else
            lastblink = checkframecounter!(cp_of.Blink, lastblink, step)
        end
    end
    return cp_of
end
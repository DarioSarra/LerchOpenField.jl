function adjust_lzr(filepath::String)
    f_lzr = CSV.read(filepath, DataFrame; header=2, missingstring=["NA", "NAN", "NULL", "NaN"])
    f_lzr[!,:Timer] = push!(diff(f_lzr.Time),1000)
    if f_lzr[1,:Time] > 2000 
        lzr_df = f_lzr[2:end,:]
        lzr_df[!, :Volume] = 1:nrow(lzr_df) 
    else
        lzr_df = f_lzr
    end
    return lzr_df
end

function adjust_lzr(filepath::DataFrameRow)
    adjust_lzr(filepath.LZR)
end
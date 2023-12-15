
function process_session(df_row::DataFrameRow)
    println("session $(df_row.MouseID):")

    of_df = adjust_of(df_row)
    lzr_df = adjust_lzr(df_row)
   
    if nrow(of_df) == nrow(lzr_df)
        println("OF and LZR's counters match, proceeding with join")
    elseif nrow(of_df) > nrow(lzr_df)
        println("OF counter longer than LZR, proceeding with shortening OF")
        of_df = of_df[1:nrow(lzr_df),:]
    elseif nrow(of_df) < nrow(lzr_df)
        println("LZR counter longer than OF")
        if nrow(lzr_df) - 1 == nrow(of_df)
            println("1 extra counter in LZR, proceeding removing last values")
            lzr_df = lzr_df[1:end-1,:]
        else
            # error("unknown condition: LZR rows = $(nrow(lzr_df)), OF rows = $(nrow(of_df))")
            println("attempting inferring blinks: LZR rows = $(nrow(lzr_df)), OF rows = $(nrow(of_df))")
            cp_of = fix_short_of(lzr_df, read_of(df_row))
            start_idx = findfirst(cp_of.Blink)
            cp_of = cp_of[start_idx:end,:];
            transform!(cp_of, :Blink => cumsum => :Timer)
            of_df = combine(groupby(cp_of, :Timer), :X => mean => :X, :Y => mean => :Y)
        end
    end
    df = leftjoin(lzr_df, of_df, on = :Volume => :Timer)
    df[!,:MouseID] .= string(df_row.MouseID)
    df[!, :Gene] .= get(genotypes, string(df_row.MouseID), missing)
    return df
end

function process_session(dataset::AbstractDataFrame)
    df = DataFrame()
    for (i,r) in zip(1:nrow(dataset), eachrow(dataset))
        println(i)
        prov = process_session(r)
        if isempty(df)
            df = prov
        else
            append!(df,prov)
        end
    end
    return df
end
function read_database(;dir_path = main_path)
    pre_file_df = DataFrame(filename = readdir(dir_path))
    transform!(pre_file_df, :filename => ByRow(x -> split(x, "_")[1]) => :MouseID)
    sort!(pre_file_df, :MouseID)

    file_df = combine(groupby(pre_file_df, :MouseID), :filename => (x-> (LZR = x[1], OF = x[2])) => AsTable)
    transform!(file_df, [:LZR,:OF] .=> ByRow(x -> joinpath(dir_path,x)) .=> [:LZR,:OF])
    return file_df
end
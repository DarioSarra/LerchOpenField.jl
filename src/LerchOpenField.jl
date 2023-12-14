module LerchOpenField
#= 
Some lazer files might have been restarted multiple times and need to be corrected by hand
    LZR files that need to have the last rows deleted: 72b, 72e
=#
using Reexport
@reexport using DataFrames, CSV, BrowseTables, Dates, CategoricalArrays, StatsBase
@reexport using MixedModels, StandardizedPredictors
import MixedModels: term, lrtest
include(joinpath("PreprocessTables","LoadFiles.jl"))
include(joinpath("PreprocessTables","ProcessOF.jl"))
include(joinpath("PreprocessTables","ProcessLZR.jl"))
include(joinpath("PreprocessTables","ProcessSession.jl"))



# Write your package code here.

if isdir("/home/beatriz/Documents/LerchOpenField")
    main_path = "/home/beatriz/Documents/LerchOpenField"
else
    error("main path for data not found")
end

export main_path, read_database, read_of, detect_blink, adjust_of, adjust_lzr, process_session

end
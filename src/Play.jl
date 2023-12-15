using Revise
using LerchOpenField
##
file_df = read_database()
df = process_session(file_df)
adjustperiods!(df)
transform!(groupby(df,[:MouseID]), [:X, :Y] => distance => :Distance)
df[!,:Speed] = (df.Distance ./ df.Timer).*1000
# open_html_table(df[1:2000,:])
dropmissing!(df)

het = subset(df, :Gene => x -> x .== "HET")
wt = subset(df, :Gene => x -> x .!= "HET")

##
plt_het = data(het) * mapping(:Period, :Speed; color = :RunState => nonnumeric) * smooth()
draw(plt_het, axis = (; title = "HET"))

plt_wt = data(wt) * mapping(:Period, :Speed; color = :RunState => nonnumeric) * smooth()
draw(plt_wt, axis = (; title = "WT"))

##
df1 = combine(groupby(df, [:MouseID, :Gene, :RunState, :Period]), :Speed => mean => :Speed)
df2 = combine(groupby(df1, [:Gene, :RunState, :Period]), :Speed => mean => :Speed_cm, :Speed => sem)
transform!(df2, [:Speed_cm, :Speed_sem] => ByRow((m,s) -> m-s) => :Lower)
transform!(df2, [:Speed_cm, :Speed_sem] => ByRow((m,s) -> m+s) => :Upper)


plt = data(df2) * mapping(:Period, :Speed_cm; linestyle = :Gene, marker = :Gene,
    color = :RunState => renamer([1 => "PreStim", 2 => "Stim", 3 => "PostStim"]) => "StimState") 
layers = smooth() + visual(Scatter)
fg = draw(layers * plt)

save("firstResuts.png", fg, px_per_unit = 3)
## debug
i = 9
file_df[i,:]
of_df = adjust_of(file_df[i,:])
lzr_df = adjust_lzr(file_df[i,:])
df = process_session(file_df[i,:])


using Revise
using LerchOpenField
##
file_df = read_database()
df = process_session(file_df)
adjustperiods!(df)
transform!(groupby(df,[:MouseID]), [:X, :Y] => distance => :Distance)
df[!,:Speed] = (df.Distance ./ df.Timer).*1000
dropmissing!(df)
# open_html_table(df[1:1800,:])
het = subset(df, :Gene => x -> x .== "HET")
wt = subset(df, :Gene => x -> x .!= "HET")

##
plt_het = data(het) * mapping(:Period, :Speed; color = :RunState => nonnumeric) * smooth()
draw(plt_het, axis = (; title = "HET"))

plt_wt = data(wt) * mapping(:Period, :Speed; color = :RunState => nonnumeric) * smooth()
draw(plt_wt, axis = (; title = "WT"))

##
df0 = dropmissing(df)
df1 = combine(groupby(df0, [:MouseID, :Gene, :RunState, :Period]), :Speed => mean => :Speed)
df2 = combine(groupby(df1, [:Gene, :RunState, :Period]), :Speed => mean => :Speed_cm, :Speed => sem)
transform!(df2, [:Speed_cm, :Speed_sem] => ByRow((m,s) -> m-s) => :Lower)
transform!(df2, [:Speed_cm, :Speed_sem] => ByRow((m,s) -> m+s) => :Upper)


plt = data(df2) * mapping(:Period, :Speed_cm; linestyle = :Gene, marker = :Gene,
    color = :RunState => renamer([1 => "PreStim", 2 => "Stim", 3 => "PostStim"]) => "StimState") 
layers = smooth() + (visual(Scatter)) #+ mapping(:Period,:Speed_sem) * visual(Errorbars))
fg = draw(layers * plt, axis = (; limits = (nothing,nothing,0,4)))
save("firstResuts_witherror.png", fg, px_per_unit = 3)
##
df_short = filter(r -> r.Repetitions < 4, df)
plt3 = data(df_short) * mapping(:Period, :Speed; layout = :Repetitions => nonnumeric, linestyle = :Gene, 
    color = :RunState => renamer([1 => "PreStim", 2 => "Stim", 3 => "PostStim"]) => "StimState") * smooth()
fg3 = draw(plt3)
save("SplitbyRepetitions.png", fg3, px_per_unit = 3)
##
transform!(df, [:StimCount,:Repetitions] => ByRow((c,r) -> c!=0 ? c+(30*(r-1)) : 0) => :StimulationNumber)
transform!(groupby(df, :MouseID), :StimulationNumber => (x -> vcat(fill(0,4),x[1:end-4])) => :ShiftStimNumber)
transform!(groupby(df, [:MouseID,:ShiftStimNumber]), 
    :StimCount => (c -> c[1] == 0 ? fill(0,length(c)) : (collect(1:length(c)) .+ 6).%10) => :ShiftedPeriod)

transform!(groupby(df, [:MouseID, :ShiftStimNumber]),
    :ShiftStimNumber => (x-> x[1] == 0 ? fill(0,length(x)) : collect(1:length(x))) => :BaselinePeriod)
    # [:ShiftStimNumber, :ShiftedPeriod] => ByRow((n,p) -> n == 0 ? 0 : p==0 ? 10 : p) => :BaselinePeriod)
transform!(groupby(df, [:MouseID, :ShiftStimNumber]),
    [:BaselinePeriod, :Speed] => ((p,s) -> baseline_speed(p,s)) => :NormSpeed)
open_html_table(df[1:5000,:])

    ##
subdf = dropmissing(df, :NormSpeed)
open_html_table(subdf[1:5000,:])
filter!(r -> r.Repetitions <4, subdf)
m_subdf = combine(groupby(subdf,[:MouseID,:Gene,:Repetitions,:BaselinePeriod]), :NormSpeed => median => :NormSpeed)
g_subdf = combine(groupby(m_subdf,[:Gene,:Repetitions,:BaselinePeriod]), :NormSpeed => mean => :NormSpeed, :NormSpeed => sem => :Err)
g_subdf[!, :lower] = @. g_subdf.NormSpeed - g_subdf.Err
g_subdf[!, :upper] = @. g_subdf.NormSpeed + g_subdf.Err
##
plt = data(g_subdf) * mapping(:BaselinePeriod, :NormSpeed; layout = :Repetitions => nonnumeric,
    color = :Gene, lower=:lower, upper=:upper) * (visual(Lines) + visual(LinesFill))
fig = Figure(; size=(600, 600))
ag = draw!(fig[1,1],plt)
for ae in ag
    vspan!(ae.axis,[4],[6]; color = [(:green, 0.2)])
end
legend!(fig[end+1, 1], ag, orientation=:horizontal, tellheight=true)
fig
##
save("SplitbyRepetitions.png", fg3, px_per_unit = 3)



## debug
i = 9
file_df[i,:]
of_df = adjust_of(file_df[i,:])
lzr_df = adjust_lzr(file_df[i,:])
df = process_session(file_df[i,:])
#
linesfill()


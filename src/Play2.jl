using Revise
using LerchOpenField
##
file_df = read_database();
df = process_session(file_df);
adjustperiods!(df)
transform!(groupby(df,[:MouseID]), [:X, :Y] => distance => :Distance)
df[!,:Speed] = (df.Distance ./ df.Timer).*1000
transform!(groupby(df, [:MouseID, :StimCount]),
    [:Period, :Speed] => ((p,s) -> baseline_speed(p,s)) => :NormSpeed)
transform!(df, :NormSpeed => ByRow(x -> ismissing(x) ? missing : isnan(x) ? missing : x) => :NormSpeed)
open_html_table(df[1:5000,:])

##
df0 = dropmissing(df)
df1 = combine(groupby(df0, [:MouseID, :Gene, :RunState, :Period]), :Speed => mean => :Speed)
df2 = combine(groupby(df1, [:Gene, :RunState, :Period]), :Speed => mean => :Speed_cm, :Speed => sem)
transform!(df2, [:Speed_cm, :Speed_sem] => ByRow((m,s) -> m-s) => :Lower)
transform!(df2, [:Speed_cm, :Speed_sem] => ByRow((m,s) -> m+s) => :Upper)

##
fig = Figure(; size=(600, 600))
plt = data(df2) * mapping(:Period, :Speed_cm; linestyle = :Gene, marker = :Gene,
    color = :RunState => renamer([1 => "PreStim", 2 => "Stim", 3 => "PostStim"]) => "StimState") * (smooth() + (visual(Scatter)))
ag = draw!(fig[1,1],plt)
vspan!(ag[1].axis,[4],[6]; color = [(:green, 0.1)])
ag[1].axis
legend!(fig[end+1, 1], ag, orientation=:horizontal, tellheight=true)
fig
save("ResultsByStimState.png", fg, px_per_unit = 3)
##
subdf = filter(r -> r.RunState == 2,df)
filter!(r -> r.Repetitions < 4, subdf)
measure = :NormSpeed
m_subdf = combine(groupby(subdf,[:MouseID,:Gene,:Repetitions,:Period]), 
    measure => (x -> median(skipmissing(x))) => measure,
    measure => (x -> sem(skipmissing(x))) => :Err)
m_subdf[!, :lower] = @. m_subdf[:,measure] - m_subdf.Err
m_subdf[!, :upper] = @. m_subdf[:,measure] + m_subdf.Err
    
g_subdf = combine(groupby(m_subdf,[:Gene,:Repetitions,:Period]), 
    measure => (x -> mean(skipmissing(x))) => measure, 
    measure => (x -> sem(skipmissing(x))) => :Err)
g_subdf[!, :lower] = @. g_subdf[:,measure] - g_subdf.Err
g_subdf[!, :upper] = @. g_subdf[:,measure] + g_subdf.Err
##
plt = data(g_subdf) * mapping(:Period, measure; layout = :Repetitions => nonnumeric,
    color = :Gene, lower=:lower, upper=:upper) * (visual(Lines) + visual(LinesFill))
fig = Figure(; size=(600, 600))
ag = draw!(fig[1,1],plt)
for ae in ag
    vspan!(ae.axis,[4],[6]; color = [(:green, 0.2)])
end
legend!(fig[end+1, 1], ag, orientation=:horizontal, tellheight=true)
fig
save("ResultsByBaseline.png", fig, px_per_unit = 3)
##
m_subdf[!,:Name] = @. m_subdf.MouseID * "_" * m_subdf.Gene
plt = data(m_subdf) * mapping(:Period, measure; layout = :Name,
    color = :Repetitions => nonnumeric, lower=:lower, upper=:upper) * (visual(Lines) + visual(LinesFill))
fig = Figure(; size=(600, 600))
ag = draw!(fig[1,1],plt)
for ae in ag
    vspan!(ae.axis,[4],[6]; color = [(:green, 0.2)])
end
legend!(fig[1, 2], ag, orientation=:vertical, tellheight= false)
fig
save("ResultsByMouse_all.png", fig, px_per_unit = 3)
##
pag = paginate(plt, layout = 4)
fig_grid = draw(pag)
n = 4
fig_grid[n]
save("ResultsByMouse_$n.png", fig_grid[n], px_per_unit = 3)
using Revise
using LerchOpenField

file_df = read_database()
i = 9
file_df[i,:]
of_df = adjust_of(file_df[i,:])
lzr_df = adjust_lzr(file_df[i,:])
df = process_session(file_df[i,:])

df = process_session(file_df)

open_html_table(of_df)
open_html_table(lzr_df)
open_html_table(df)
countmap(lzr_df.timer)

for (i,r) in zip(1:nrow(file_df),eachrow(file_df))
    println(i,r.MouseID)
end

##
f_of = LerchOpenField.read_of(file_df[i,:OF])
pre_of = subset(f_of, :Blink)
pre_of[!,:FrameCounter] = pushfirst!(diff(pre_of.Frame),0)
countmap(pre_of.FrameCounter)
select!(pre_of, [:Frame,:FrameCounter])
start_idx = pre_of[findfirst(pre_of.FrameCounter .> 20), :Frame]
open_html_table(pre_of)
step = mode(pre_of.FrameCounter)
step*1.25
lzr_df = adjust_lzr(file_df[i,:])
f_of = read_of(file_df[i,:])

##
open_html_table(cp_of)
idx = nrow(lzr_df)

step = mode(skipmissing(cp_of.FrameCounter))
#=
    This function is used when LZR has a lot more data than OF. 
    Assuming the camera has not detected some blinks, this loop jumps from the last detected blinks to the previous correcting the interval.
    To keep track of the correct number of blinks the loop is controlled by the number of volumes detected by arduino.
    This means that at each step of the LZR file we correct the previous assignment of frame.
    There fore when we reach the last row of the LZR file all previous blinks are set to false
=#

##### this is wrong we need to loop into the blink to make sure we continue correcting the values
function fix_short_of(lzr_df, f_of)
    cp_of, start_idx = detect_blink(f_of)
    lastblink = 0
    thisblink = 0
    for idx in nrow(lzr_df):-1:1
        println(idx)
        if idx == nrow(lzr_df)
            thisblink = findlast(cp_of.Blink)
            lastblink = nrow(cp_of)
        elseif idx == 1
            cp_of[1:lastblink - 1,:Blink] .= false
            break
        else
            thisblink = findprev(cp_of.Blink, lastblink)
        end

        if cp_of[thisblink, :FrameCounter] > step * 2
            cp_of[lastblink - step,:Blink] = true
        elseif cp_of[thisblink, :FrameCounter] < step / 2
            cp_of[thisblink,:Blink] = false
        end
        lastblink = thisblink
    end
    return cp_of
end

cp_of = fix_short_of(lzr_df, f_of)
open_html_table(cp_of)
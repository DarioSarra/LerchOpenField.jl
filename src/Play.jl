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
nrow(f_of)/15

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
function checkframecounter!(vector, lastblink, step)
    thisblink = findprev(vector,lastblink-1)
    dist = lastblink - thisblink
    if dist > 2*step
        vector[thisblink] = false
        thisblink = lastblink - step
        vector[thisblink] = true
    elseif dist < step/2
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
function fix_short_of(lzr_df, f_of)
    cp_of, start_idx = detect_blink(f_of)
    step = mode(skipmissing(cp_of.FrameCounter))
    lastblink = 0
    thisblink = 0
    for idx in nrow(lzr_df):-1:1
        println(idx)
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

cp_of = fix_short_of(lzr_df, f_of)
cp_of, start_idx = detect_blink(f_of)
open_html_table(cp_of)


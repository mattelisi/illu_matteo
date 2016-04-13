function drawFixation(col,loc,scr,visual)

if length(loc)==2
    loc=[loc loc];
end
pu = round(visual.ppd*0.1);
Screen(scr.main,'FillOval',col,loc+[-pu -pu pu pu]);

egg = xdf{2}.time_series(2,:);
aud = xdf{2}.time_series(1,:);
t = xdf{2}.time_stamps;
mark_t = xdf{3}.time_stamps;
m = 1:length(mark_t);
for i = 1:length(mark_t)
    m(i) = find(t > mark_t(i), 1);
end

%%
for i = 1:length(m)
    seg = egg(m(i) - 48000/3:m(i) + 48000/3);
    
    
end



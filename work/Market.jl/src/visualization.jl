# using .Market: plt, DataFrame


# ### Accepts a DataFrame of 5min trade data with features already computed 
# function make_tickgif(df5::DataFrame, gif_range::UnitRange{Int64}, framesize::Int64)
#     anim = @animate for last=gif_range
#         interval = (last-framesize):last
#         data = it5.lastPrice[interval]
#         volume = it5.volume[interval]
#         p1 = plt.plot(interval, data, legend=nothing)
#         plt.hline!(rowToarray(it5[last, 12:14]), color="red")
#         plt.hline!(rowToarray(it5[last, 15:17]), color="green")
#         plt.plot!(interval, dfToarray(it5[interval,20:22]))
#         p2 = plt.plot(volume)
#         plt.plot(p1, p2, layout=@layout[a{0.6h}; b{0.2h}], title = "$last")
#     end
#     gif(anim, "anim_fps15.gif", fps = 3)
# end
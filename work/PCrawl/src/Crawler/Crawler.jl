module Crawler
using ..PCrawl
include("benchmark.jl")

#crawlers
export pcrawlerpso, pcrawlerevol

# loading.jl
export loadsignalpaperdata, loadpaper, loadpaperdata, loadsignal, crawlpaper, crawlpapers, papers, savesig, loadfullpaperdata

# models.jl
export rfcrawler, boostcrawler, boostgrid, rfgrid, halfsample, classifynew, crossmase

# benchmarking
export wholebench, signalquality, crawlertests, getcoverage, selectsig

end
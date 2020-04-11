using Pkg

Pkg.add(PackageSpec(name="Revise", version="2.6.0"))
Pkg.add(PackageSpec(name="CSV", version="0.6.1"))
Pkg.add(PackageSpec(name="DataFrames", version="0.20.2"))
Pkg.add(PackageSpec(name="StatsBase", version="0.33.0"))
Pkg.add(PackageSpec(name="PyCall", version="1.91.4"))
Pkg.add(PackageSpec(name="Indicators", version="0.7.0"))

Pkg.develop(PackageSpec(path="PCrawl"))

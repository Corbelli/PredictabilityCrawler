# Fuzzy Sets 

## Fuzzy sets must implement:

    A struct with their names

    A params() function to return their parameters

    A \mu function to compute their score of a real-valued number

    At least one Range Function (even_range, percentile_range...) to generate a fuzzy representation
    of the range
    
    Recipes for printing the individual set as well as the range coverage
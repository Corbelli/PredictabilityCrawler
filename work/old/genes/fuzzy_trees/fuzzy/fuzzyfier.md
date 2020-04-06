The fuzzyfier holds a struct representing the Settings used in the fuzzy logic.
The struct holds the topology of the fuzzy representation for the inputs and the
set of allowed fuzzy operations: 
# FuzzyTopologyAndOperations 
    This structure holds 
        A "topology" array of tuples with the index of input and number of fuzzy sets used for that input
        A "operations" struct, containing arrays of functions separeted by arity
        A "fuzzy_sets" array of arrays representing the fuzzy-sets representation for each input

Furthermore, it also have :
A function to extract the topology from an fuzzy vector:
# fuzzysets_to_topology(inputs_fuzzysets)

A function to convert the topology representation to the value of the corresponding set:
# fuzzy_indexes_to_values(fuzzy_input_array, indexes)

A function to transform the input vector to the fuzzy form:
# fuzzy(input_array, fuzzy_settings)
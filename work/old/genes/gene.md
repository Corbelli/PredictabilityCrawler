A gene is a structure representing a function of the fuzzy entries.
The type of structure used to represent the gene is the dna

A dna to be valid should implement the following functions :

# create_dna(nr_variables, fuzzy_settings)

    A function that randomly creates the structure

# compute_score(fuzzy_x, dna)

    A function that compute the gene function given the inputs

# print(dna)

    A graphical representation of the gene


# TODO
## A GENE TO BE VALID MUST ONLY IMPLEMENT ACTIVATION(X, gene.dna, gene.settings::TYPEOFSETTINGS)
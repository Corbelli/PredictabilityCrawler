struct Gene
    dna
    settings
    param
end

# Para criar um Gene, definir:
#    Um construtor que recebe um settings específico e qualquer outro parâmetro Gene(gene_param, settings)
#    uma função activation, que recebe os valores, o modelo e o settings e calcula a ativação
#    uma função print, que recebe o modelo e os settings e printa o gene

activate(values::Union{Array{Float64,2}, Nothing}, gene::Gene) = activation(values, gene.dna, gene.settings)

print(gene::Gene) = print(gene.dna, gene.settings)



process UNICYCLER {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/unicycler:0.4.8--py38h8162308_3' :
        'biocontainers/unicycler:0.4.8--py38h8162308_3' }"

    input:
    tuple val(meta), path(shortreads), path(longreads)

    output:
    tuple val(meta), path('*.scaffolds.fa.gz'), emit: scaffolds
    tuple val(meta), path('*.assembly.gfa.gz'), emit: gfa
    tuple val(meta), path('*.log')            , emit: log
    path "bins"                               , emit: bins
    path  "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if(params.assembly_type == 'long'){
        input_reads = "-l $longreads"
    } else if (params.assembly_type == 'short'){
        input_reads = "-1 ${shortreads[0]} -2 ${shortreads[1]}"
    } else if (params.assembly_type == 'hybrid'){
        input_reads = "-1 ${shortreads[0]} -2 ${shortreads[1]} -l $longreads"
    }
    """
    unicycler \\
        --threads $task.cpus \\
        $args \\
        $input_reads \\
        --out ./
    mkdir bins
    cp assembly.fasta bins/${prefix}_assembly.fasta
    mv assembly.fasta ${prefix}.scaffolds.fa
    gzip -n ${prefix}.scaffolds.fa
    mv assembly.gfa ${prefix}.assembly.gfa
    gzip -n ${prefix}.assembly.gfa
    mv unicycler.log ${prefix}.unicycler.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        unicycler: \$(echo \$(unicycler --version 2>&1) | sed 's/^.*Unicycler v//; s/ .*\$//')
    END_VERSIONS
    """
}

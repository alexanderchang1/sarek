include { GATK4_CNNSCOREVARIANTS      as CNNSCOREVARIANTS               } from '../../../../modules/nf-core/modules/gatk4/cnnscorevariants/main'
include { GATK4_FILTERVARIANTTRANCHES as FILTERVARIANTTRANCHES          } from '../../../../modules/nf-core/modules/gatk4/filtervarianttranches/main'

workflow GATK_SINGLE_SAMPLE_GERMLINE_VARIANT_CALLING{

    take:
    vcf             // meta, vcf, tbi
    fasta
    fasta_fai
    dict
    known_sites
    known_sites_tbi

    main:

    ch_versions = Channel.empty()

    //not Using intervals, because especially for targeted analysis, it easily fails with 0 SNPS in region, WGS?
    cnn_in = vcf.map{ meta, vcf, tbi, intervals -> [meta,vcf,tbi,[], intervals]}

    CNNSCOREVARIANTS(cnn_in,
                    fasta,
                    fasta_fai,
                    dict,
                    [],
                    [])

    cnn_out = CNNSCOREVARIANTS.out.vcf.join(CNNSCOREVARIANTS.out.tbi).join(vcf)
        .map{   meta, cnn_vcf,cnn_tbi, haplotyc_vcf, haplotyc_tbi, intervals
            -> [meta, cnn_vcf, cnn_tbi, intervals]
        }

    FILTERVARIANTTRANCHES(cnn_out,
                            known_sites,
                            known_sites_tbi,
                            fasta,
                            fasta_fai,
                            dict)

    // Figure out if using intervals or no_intervals
    FILTERVARIANTTRANCHES.out.vcf.map{ meta, vcf ->
                                            [[patient:meta.patient, sample:meta.sample, status:meta.status, gender:meta.gender, id:meta.sample, num_intervals:meta.num_intervals, variantcaller:"haplotypecaller"], vcf]
                                        }

    ch_versions = ch_versions.mix(CNNSCOREVARIANTS.out.versions)
    ch_versions = ch_versions.mix(FILTERVARIANTTRANCHES.out.versions)

    emit:
    versions = ch_versions
    filtered_vcf = FILTERVARIANTTRANCHES.out.vcf
}

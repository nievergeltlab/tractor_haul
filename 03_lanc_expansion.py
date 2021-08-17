#!/usr/bin/env python3
"""
----- Description -----
Calculates local ancestry totals given ancestry indicators and snp indicators (split by haplotype)

----- Usage -----
Usage: ./03_lanc_expansion.py {ancestry_directory} {study_name} {chromosome_number}

----- Arguments -----
ancestry_directory: Absolute path to ancestry directory
study_name: Name of the study
chromosome_number: Chromosome the input file represents
"""
import numpy as np
import pandas as pd
import os
import sys

def main(anc_dir, study, chr_num):
    # SNP data files
    hap0file = f'{anc_dir}/lanc_expansion/haplotypes/{study}/{chr_num}/{study}_{chr_num}.hap0.tsv'
    hap1file = f'{anc_dir}/lanc_expansion/haplotypes/{study}/{chr_num}/{study}_{chr_num}.hap1.tsv'
    # EUR files
    anc2_hap0file = f'{anc_dir}/lanc_expansion/indicators/{study}/{chr_num}/{study}_{chr_num}.anc2.hap0.msp.tsv'
    anc2_hap1file = f'{anc_dir}/lanc_expansion/indicators/{study}/{chr_num}/{study}_{chr_num}.anc2.hap1.msp.tsv'
    # AFR & AMR covar files
    anc0anc1_hap0file = f'{anc_dir}/lanc_expansion/indicators/{study}/{chr_num}/{study}_{chr_num}.anc0.anc1.hap0.msp.tsv'
    anc0anc1_hap1file = f'{anc_dir}/lanc_expansion/indicators/{study}/{chr_num}/{study}_{chr_num}.anc0.anc1.hap1.msp.tsv'
    # Check all files exist
    missing = []
    for file in [hap0file, hap1file, anc2_hap0file, anc2_hap1file, anc0anc1_hap0file, anc0anc1_hap1file]:
        if not os.path.isfile(file):
            missing.append(file)
    assert len(missing) == 0, 'Missing file(s): "' + '", "'.join(missing) + '"'
    # Output files
    anc2_outfile = f'{anc_dir}/lanc_expansion/lanctotals/{study}/{chr_num}/{study}_{chr_num}.total.anc2.msp.tsv'
    anc0anc1_outfile = f'{anc_dir}/lanc_expansion/lanctotals/{study}/{chr_num}/{study}_{chr_num}.total.anc0.anc1.msp.tsv'
    # Compute EUR totals
    compute_lanc_total(hap0file, hap1file, anc2_hap0file, anc2_hap1file, anc2_outfile)
    # Compute AFR & AMR covar totals
    compute_lanc_total(hap0file, hap1file, anc0anc1_hap0file, anc0anc1_hap1file, anc0anc1_outfile)

def compute_lanc_total(hap0file, hap1file, anc_hap0file, anc_hap1file, outfile):
    # open files
    hap0 = open(hap0file)
    hap1 = open(hap1file)
    anc_hap0 = open(anc_hap0file)
    anc_hap1 = open(anc_hap1file)
    # helper function to read next line from each file
    def readlines(hap0_fp, hap1_fp, anc_hap0_fp, anc_hap1_fp):
        anc_hap0_line = anc_hap0_fp.readline()
        if not anc_hap0_line:
            return (None, None, None, None)
        anc_hap0_line = np.array(anc_hap0_line.split('\t'))
        anc_hap1_line = np.array(anc_hap1_fp.readline().split('\t'))
        # nsnps is the fifth column of the .msp.tsv file output by xgmix
        nsnps = int(anc_hap0_line[5])
        # subset lines to only subject data columns
        anc_hap0_line = anc_hap0_line[6:]
        anc_hap1_line = anc_hap1_line[6:]
        # read {nsnps} lines from the haplotype vcf files
        hap0_lines = []
        hap1_lines = []
        snps = []
        for i in range(nsnps):
            # uses [9:] to subset to only subject data columns
            hap0_line = hap0_fp.readline().split('\t')
            snps.append(hap0_line[2])
            hap0_lines.append(hap0_line[9:])
            hap1_lines.append(hap1_fp.readline().split('\t')[9:])
        return (np.array(hap0_lines), np.array(hap1_lines), anc_hap0_line, anc_hap1_line, snps)
    # write header
    hap0_line, hap1_line, anc_hap0_line, anc_hap1_line = (hap0.readline(), hap1.readline(),
        anc_hap0.readline(), anc_hap1.readline())
    with open(outfile, 'w') as f:
        f.write(hap0_line)
    # calculate lanc totals and write to file
    hap0_lines, hap1_lines, anc_hap0_line, anc_hap1_line, snps = readlines(hap0, hap1, anc_hap0, anc_hap1)
    while len(anc_hap0_line) != 0:
        result = np.sum(
            np.multiply(hap0_lines, anc_hap0_line),
            np.multiply(hap1_lines, anc_hap1_line)
        )
        output = np.insert(result, 0, snps, axis=1)
        with open(outfile, 'a') as f:
            f.write('\n' + '\n'.join('\t'.join(f'{x}' for x in row) for row in output))
        hap0_lines, hap1_lines, anc_hap0_line, anc_hap1_line, snps = readlines(hap0, hap1, anc_hap0, anc_hap1)


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print('Usage: ' + sys.argv[0] + ' {ancestry_directory} {study_name} {chr_num}')
    else:
        main(sys.argv[1], sys.argv[2], sys.argv[3])

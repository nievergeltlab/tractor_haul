#!/usr/bin/env python3
"""
----- Description -----
Calculates local ancestry totals given ancestry indicators and snp indicators (split by haplotype)

----- Usage -----
Usage: ./03_lanc_expansionn.py {ancestry_directory} {study_name} {chromosome_number}

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
    """
    Gets the total number of SNPs each individual has from each ancestry
    (currently only implemented for three ancestries), and creates a
    covariate file for the first two ancestries to use with plink

    ----- Parameters -----
    anc_dir - str : absolute path to the ancestry directory
    study - str: name of the study
    chr_num - int: chromosome number
    """
    # SNP data files
    hap0file = f'{anc_dir}/lanc_expansion/haplotypes/{study}/{chr_num}/{study}_{chr_num}.hap0.tsv.gz'
    hap1file = f'{anc_dir}/lanc_expansion/haplotypes/{study}/{chr_num}/{study}_{chr_num}.hap1.tsv.gz'
    # AFR files
    anc0_hap0file = f'{anc_dir}/lanc_expansion/indicators/{study}/{chr_num}/{study}_{chr_num}.anc0.hap0.msp.tsv.gz'
    anc0_hap1file = f'{anc_dir}/lanc_expansion/indicators/{study}/{chr_num}/{study}_{chr_num}.anc0.hap1.msp.tsv.gz'
    # AMR files
    anc1_hap0file = f'{anc_dir}/lanc_expansion/indicators/{study}/{chr_num}/{study}_{chr_num}.anc1.hap0.msp.tsv.gz'
    anc1_hap1file = f'{anc_dir}/lanc_expansion/indicators/{study}/{chr_num}/{study}_{chr_num}.anc1.hap1.msp.tsv.gz'
    # EUR files
    anc2_hap0file = f'{anc_dir}/lanc_expansion/indicators/{study}/{chr_num}/{study}_{chr_num}.anc2.hap0.msp.tsv.gz'
    anc2_hap1file = f'{anc_dir}/lanc_expansion/indicators/{study}/{chr_num}/{study}_{chr_num}.anc2.hap1.msp.tsv.gz'
    # Check all files exist
    missing = []
    for file in [hap0file, hap1file, anc0_hap0file, anc0_hap1file, anc1_hap0file, anc1_hap1file, anc2_hap0file, anc2_hap1file]:
        if not os.path.isfile(file):
            missing.append(file)
    assert len(missing) == 0, 'Missing file(s): "' + '", "'.join(missing) + '"'
    # Output files
    anc0_outfile = f'{anc_dir}/lanc_expansion/lanctotals/{study}/{chr_num}/{study}_{chr_num}.total.anc0.msp.tsv.gz'
    anc1_outfile = f'{anc_dir}/lanc_expansion/lanctotals/{study}/{chr_num}/{study}_{chr_num}.total.anc1.msp.tsv.gz'
    anc2_outfile = f'{anc_dir}/lanc_expansion/lanctotals/{study}/{chr_num}/{study}_{chr_num}.total.anc2.msp.tsv.gz'
    # Compute AFR totals
    compute_lanc_total(hap0file, hap1file, anc0_hap0file, anc0_hap1file, 'AFR', anc0_outfile)
    # Compute AMR totals
    compute_lanc_total(hap0file, hap1file, anc1_hap0file, anc1_hap1file, 'AMR', anc1_outfile)
    # Compute EUR totals
    compute_lanc_total(hap0file, hap1file, anc2_hap0file, anc2_hap1file, 'EUR', anc2_outfile)
    # Merge AFR and AMR into a covar file
    covar_outfile = f'{anc_dir}/lanc_expansion/lanctotals/{study}/{chr_num}/{study}_{chr_num}.total.covar.msp.tsv.gz'
    merge_covars([anc0_outfile, anc1_outfile], covar_outfile)


def compute_lanc_total(hap0file, hap1file, anc_hap0file, anc_hap1file, suffix, outfile):
    """
    Computes the local ancestry total, given the SNP indicators for each
    haplotype and the ancestry indicators for each haplotype

    ----- Parameters -----
    hap0file - str: SNP indicator file for first haplotype
    hap1file - str: SNP indicator file for second haplotype
    anc_hap0file - str: ancestry indicator file for first haplotype
    anc_hap1file - str: ancestry indicator file for second haplotype
    suffix - str: suffix to add to the subject names (to distinguish ancestry)
    outfile - str: file to write output total to; result contains the total
                   number of SNPs coming from this ancestry for each subject
    """
    # open files
    hap0 = pd.read_csv(hap0file, sep='\t')
    hap1 = pd.read_csv(hap1file, sep='\t')
    anc_hap0 = pd.read_csv(anc_hap0file, sep='\t')
    anc_hap1 = pd.read_csv(anc_hap1file, sep='\t')
    assert len(hap0) == len(hap1)
    assert len(anc_hap0) == len(anc_hap1)
    # get intervals - index row in hap0/hap1 dataframe that corresponds to the snp in the ancestry indicator dataframe
    # note that this is the same for both haplotypes
    intervals = np.searchsorted(anc_hap0['spos'], hap0['POS']) - 1
    # get as matrix
    hap0_matr = hap0.iloc[:,9:].to_numpy()
    hap1_matr = hap1.iloc[:,9:].to_numpy()
    anc_hap0_matr = anc_hap0.iloc[:,6:].to_numpy()
    anc_hap1_matr = anc_hap1.iloc[:,6:].to_numpy()
    # for each row in haplotypes, multiply it by it's corresponding ancestry indicator
    out_hap0 = []
    out_hap1 = []
    for i in range(len(hap0_matr)):
        out_hap0.append(np.multiply(hap0_matr[i], anc_hap0_matr[intervals[i]]))
        out_hap1.append(np.multiply(hap1_matr[i], anc_hap1_matr[intervals[i]]))
    # delete matrices to preserve memory
    del(hap0_matr)
    del(hap1_matr)
    del(anc_hap0_matr)
    del(anc_hap1_matr)
    # sum outputs, delete hap0 and hap1 matrices to preserve memory
    out = np.add(out_hap0, out_hap1)
    del(out_hap0)
    del(out_hap1)
    # create dataframe
    out = pd.DataFrame(out, columns=hap0.columns[9:])
    out.columns = pd.Series(out.columns).apply(lambda x: x + '_' + suffix)
    # Add CHROM, POS, ID columns
    out['CHROM'] = hap0['CHROM']
    out['POS'] = hap0['POS']
    out['ID'] = hap0['ID']
    # reorder columns so CHROM, POS, ID come first
    columns = list(out.columns)
    columns = columns[-3:] + columns[:-3]
    out = out[columns]
    # save to file
    out.to_csv(outfile, sep='\t', index=False)

def merge_covars(covar_files, outfile):
    """
    Reads each covariate ancestry file and creates a single covariate file

    ----- Parameters -----
    covar_files - list: list of files to read in
    outfile - str: file to write output to
    """
    num_covars = len(covar_files)
    covar_data = pd.concat([pd.read_csv(file, sep='\t').set_index(['CHROM', 'POS', 'ID']) for file in covar_files], axis=1)
    columns = list(covar_data.columns)
    newcols = []
    num_subjs = int(len(columns) / num_covars)
    for i in range(num_subjs):
        for j in range(num_covars):
            newcols.append(columns[i+j*num_subjs])
    covar_data = covar_data[newcols]
    covar_data.to_csv(outfile, sep='\t')


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print('Usage: ' + sys.argv[0] + ' {ancestry_directory} {study_name} {chr_num}')
    else:
        main(sys.argv[1], sys.argv[2], sys.argv[3])

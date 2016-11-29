CRB-BLAST
=========

Conditional Reciprocal Best BLAST - high confidence ortholog assignment.

### What is Conditional Reciprocal Best BLAST?

CRB-BLAST is a novel method for finding orthologs between one set of sequences and another. This is particularly useful in genome and transcriptome annotation.

CRB-BLAST initially performs a standard reciprocal best BLAST. It does this by performing BLAST alignments of query->target and target->query. Reciprocal best BLAST hits are those where the best match for any given query sequence in the query->target alignment is also the best hit of the match in the reverse (target->query) alignment.

Reciprocal best BLAST is a very conservative way to assign orthologs. The main innovation in CRB-BLAST is to learn an appropriate e-value cutoff to apply to each pairwise alignment by taking into account the overall relatedness of the two datasets being compared. This is done by fitting a function to the distribution of alignment e-values over sequence lengths. The function provides the e-value cutoff for a sequence of given length.

CRB-BLAST greatly improves the accuracy of ortholog assignment for de-novo transcriptome assembly ([Aubry et al. 2014](http://www.plosgenetics.org/article/info%3Adoi%2F10.1371%2Fjournal.pgen.1004365)).

The CRB-BLAST algorithm was designed by [Steve Kelly](http://www.stevekellylab.com), and this implementation is by Chris Boursnell and Richard Smith-Unna. The original reference implementation from the paper is available for online use at http://www.stevekellylab.com/software/conditional-orthology-assignment.

### Installation

To install CRB-BLAST, simply use rubygems:

`gem install crb-blast`

### Prerequisites

 - NCBI BLAST+ (preferably the latest version) should be installed and in your PATH.
 - Ruby v2.0 or later. If you don't have Ruby, we suggest installing it with [RVM](http://rvm.io).

`\curl -sSL https://get.rvm.io | bash -s stable --ruby`


### Usage

CRB-BLAST can be run from the command-line as a standalone program, or used as a library in your own code.

#### Command-line usage

CRB-BLAST can be run from the command line with:

```
crb-blast
```

The options are

```
    --query, -q <s>:   query fasta file in nucleotide format
   --target, -t <s>:   target fasta file as nucleotide or protein
   --evalue, -e <f>:   e-value cut off for BLAST. Format 1e-5 (default: 1.0e-05)
  --threads, -h <i>:   number of threads to run BLAST with (default: 1)
   --output, -o <s>:   output file as tsv
        --split, -s:   split the fasta files into chunks and run multiple blast
                       jobs and then combine them.
         --help, -l:   Show this message
```

An example command is:

```bash
crb-blast --query assembly.fa --target reference_proteins.fa --threads 8 --output annotation.tsv
```

#### Library usage

To include the gem in your code just `require 'crb-blast'`

A quick example:

```ruby
blaster = CRB_Blast.new('test/query.fasta', 'test/target.fasta')
blaster.run(1e-5, 4, true) # to run with an evalue cutoff of 1e-5 and 4 threads
```

A longer example with each step at a time:

```ruby
blaster = CRB_Blast.new('test/query.fasta', 'test/target.fasta')
blaster.makedb
blaster.run_blast(1e-5, 6, true)
blaster.load_outputs
blaster.find_reciprocals
blaster.find_secondaries
```

### Output

The output file for CRB-Blast pulls columns from the blast output.

```
query - the name of the transcript from the 'query' fasta file
target - the name of the transcript from the 'target' fasta file
id - the percent sequence identity
alnlen - the alignment length
evalue - the blast evalue
bitscore - the blast bitscore
qstart..qend - the coordinates of the alignment in the query from start to end
tstart..tend - the coordinates of the alignment in the target from start to end 
qlen - the length of the query transcript
tlen - the length of the target transcript
```

### Getting help

Please use the issue tracker if you find bugs or have trouble running CRB-BLAST.

Chris Boursnell <cmb211@cam.ac.uk> maintains this software.

### License

This is adademic software - please cite us if you use it in your work.

CRB-BLAST is released under the MIT license.

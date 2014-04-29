CRB-BLAST
=========

A Ruby Gem for Conditional Reciprocal Best BLAST (Aubry et al. 2014, accepted at PLoS Genetics).

### Installation

You'll need Ruby v2.0 or later. If you don't have Ruby, we suggest installing it with [RVM](http://rvm.io).

To install CRB-BLAST, simply use rubygems:

`gem install crb-blast`

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
blaster.run(1e-5, 4) # to run with an evalue cutoff of 1e-5 and 4 threads
```

A longer example with each step at a time:

```ruby
blaster = CRB_Blast.new('test/query.fasta', 'test/target.fasta')
blaster.makedb
blaster.run_blast(1e-5, 6)
blaster.load_outputs
blaster.find_reciprocals
blaster.find_secondaries
```

### Getting help

Please use the issue tracker if you find bugs or have trouble running CRB-BLAST.

Chris Boursnell <cmb211@cam.ac.uk> maintains this software.

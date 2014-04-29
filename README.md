CRB-BLAST
=========

A Ruby Gem for Condition Reciprocal Best BLAST

When this gem is install it can be run from the command line with

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

To include the gem in your code just `require 'crb-blast'`

A quick example:

```
blaster = CRB_Blast.new('test/query.fasta', 'test/target.fasta')
blaster.run(1e-5, 4) # to run with an evalue cutoff of 1e-5 and 4 threads
```

A longer example with each step at a time:

```
blaster = CRB_Blast.new('test/query.fasta', 'test/target.fasta')
@blaster.makedb
@blaster.run_blast(1e-5, 6)
@blaster.load_outputs
@blaster.find_reciprocals
@blaster.find_secondaries
```
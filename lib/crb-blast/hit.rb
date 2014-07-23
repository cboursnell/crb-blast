module CRB_Blast

  class Hit
    # Fields: query id, subject id, % identity, alignment length, mismatches,
    # gap opens, q. start, q. end, s. start, s. end, evalue, bit score
    attr_accessor :query, :target, :id, :alnlen, :mismatches, :gaps, :qstart,
    :qend, :tstart, :tend, :evalue, :bitscore, :qlen, :tlen

    def initialize(list)
      raise(RuntimeError, "unexpected number of columns") unless list.length==14
      @query      = list[0].split(/[\|\ ]/).first
      @target     = list[1].split(/[\|\ ]/).first
      @id         = list[2]
      @alnlen     = list[3].to_i
      @mismatches = list[4].to_i
      @gaps       = list[5].to_i
      @qstart     = list[6].to_i
      @qend       = list[7].to_i
      @tstart     = list[8].to_i
      @tend       = list[9].to_i
      @evalue     = list[10].to_f
      @bitscore   = list[11].to_f
      @qlen       = list[12].to_f
      @tlen       = list[13].to_f
    end

    def to_s
      s = "#{@query}\t#{@target}\t#{@id}\t#{@alnlen}\t#{@evalue}\t#{@bitscore}\t"
      s << "#{@qstart}..#{@qend}\t#{@tstart}..#{@tend}"
      return s
    end
  end

end
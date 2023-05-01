require "minimap2"

# Usage

if ARGV.size < 3
  puts "Usage: ruby sr.rb <ref.fa> <a1.fa> <a2.fa>"
  exit 1
end

# Prepare aligner

REFERENCE = ARGV[0] # reference.fa
FASTQ1    = ARGV[1] # a_1.fa
FASTQ2    = ARGV[2] # a_2.fa

aligner = Minimap2::Aligner.new(
  REFERENCE,
  preset: "sr" # Paired short reads
)

# Read Fastq file

a1 = Minimap2.fastx_read(FASTQ1) # Enumerator
a2 = Minimap2.fastx_read(FASTQ2) # Enumerator

# Output

loop do
  r1 = a1.first
  r2 = a2.first
  break if r1.nil? or r2.nil?

  s1 = r1[1]
  s2 = r2[1]

  aligner.align(s1, s2).each do |aln|
    puts aln
  end
end

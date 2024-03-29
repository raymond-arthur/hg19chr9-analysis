#tidyverse for plotting and vis
library(tidyverse)
#janitor for cont tables
library(janitor)
library(reshape2)
#base BSgenome
library(BSgenome)
#genome for Homo sapiens
library(BSgenome.Hsapiens.UCSC.hg19)


#set var for human genome v19
genome <- getBSgenome(BSgenome.Hsapiens.UCSC.hg19)
#to view list of sequences:
genome

## UCSC genome browser: https://genome.ucsc.edu/cgi-bin/hgTracks?db=hg19&lastVirtModeType=default&lastVirtModeExtraState=&virtModeType=default&virtMode=0&nonVirtPosition=&position=chr9%3A135900001%2D137400000&hgsid=1934901872_BEYKSWSyGA7yhW5PLZ8M51UvFa9c
#isolate chromosome 9
seqchr9 <- getSeq(genome, "chr9")
#isolate long arm q region 34 subband 2
seqchr9q34.2 <- getSeq(genome, "chr9", start=135900001, end=137400000)
#isolate ABO gene
seqchr9q34.2ABO <- getSeq(genome, "chr9", start=136130563, end=136150630)
#look at ABO gene as S4 file
seqchr9q34.2ABO
#ABO gene as characters
ABO_char <- getSeq(genome, "chr9", start=136130563, end=136150630, as.character=TRUE)


## Save Sequence as html file for easy viewing ##
#save a char string as html
writeLines(ABO_char, "ABO_gene.html")

#Create function to easier viewing that isn't all a single line
# Function to insert line breaks every n characters
insert_line_breaks <- function(sequence, n) {
  # Split the sequence into chunks of n characters
  chunks <- strsplit(sequence, "")
  chunks <- lapply(chunks, function(x) paste(x, collapse = ""))
  chunks <- lapply(chunks, function(x) gsub(paste0("(.{", n, "})"), "\\1\n", x))
  # Concatenate the chunks with line breaks
  formatted_sequence <- unlist(chunks)
  formatted_sequence <- paste(formatted_sequence, collapse = "")
  return(formatted_sequence)
}
# Format the sequence with line breaks every 50 characters
formatted_sequence <- insert_line_breaks(ABO_char, 50)
# Write the formatted sequence to an HTML file
write_html_sequence <- function(sequence, filename) {
  cat('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sequence Display</title>
</head>
<body>
    <div>
        <h1>Sequence</h1>
        <pre id="sequence">', file = filename)
  cat(sequence, file = filename, sep = "", append = TRUE)
  cat('</pre>
    </div>
</body>
</html>', file = filename, sep = "\n", append = TRUE)
}
# Write the formatted sequence to the HTML file
write_html_sequence(formatted_sequence, "ABO_gene_formatted.html")




## DATA ANALYSIS ##

### G+C content ###

#Get G+C content for the gene
atcg <- alphabetFrequency(seqchr9q34.2ABO)
atcg

#Create the data frame
df <- as.data.frame(atcg)
#insert row names in its own column
df$Letter <- rownames(df)
#remove old row names
rownames(df) <- NULL
#swap cols
df <- df[, c("Letter", "atcg")]
#remove all rows where frequency is 0
df <- df[df$atcg != 0,]

#plot the data with ggplot with g being blue, t being pink, c being green and a being red
ggplot(df, aes(x = Letter, y = atcg, fill = Letter)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("red", "green", "blue", "pink")) +
  labs(
    title = "Nucleotide frequency in the ABO gene",
    x = "Nucleotide",
    y = "Frequency"
  ) +
  theme_minimal()

##Perform statistical analysis to see if there is a significant difference in the frequency of nucleotides
#perform a chi-squared test
  #H0: there is no significant difference in the frequency of nucleotides in the ABO gene
  #H1: there is a significant difference in the frequency of nucleotides in the ABO gene
chisq.test(df$atcg)
  #X-squared = 41.998 (crit 7.81), df = 3, p-value = 4.015e-09
#We reject the null hypothesis and conclude that there is a significant difference in the frequency of nucleotides in the ABO gene


### Nucleotide Frequency ###

#### Longest Consecutive Sequence ####

# Find the longest consecutive sequence of the same nucleotide
longest_consecutive <- function(sequence) {
  
  # Split the sequence into individual characters
  chars <- unlist(strsplit(sequence, ""))
    
  # Initialize variables to store information about the current consecutive sequence
  current_char <- chars[1]
  current_count <- 1
  max_char <- chars[1]
  max_count <- 1
  
  # Loop through each character in the sequence
  for (i in 2:length(chars)) {
    if (chars[i] == current_char) {
      # Increment count if the current character matches the previous one
      current_count <- current_count + 1
    } else {
      # Update max_count and max_char if the current consecutive sequence is longer
      if (current_count > max_count) {
        max_count <- current_count
        max_char <- current_char
      }
      # Reset current_count and current_char for the new consecutive sequence
      current_count <- 1
      current_char <- chars[i]
    }
  }
  
  # Check if the last consecutive sequence is the longest
  if (current_count > max_count) {
    max_count <- current_count
    max_char <- current_char
  }
  
  # Return the longest consecutive sequence and its length
  return(list(character = max_char, length = max_count))
}

result <- longest_consecutive(ABO_char)

cat("Longest consecutive sequence:", result$length, "characters of", result$character, "\n")



#### Runs of Nucleotides ####

# Find runs of nucleotides in the ABO gene

# Find all consecutive sequences of A, C, T, or G
consecutive_sequences <- gregexpr("(A+|C+|T+|G+)", ABO_char, perl = TRUE)

# Extract the consecutive sequences

sequences <- regmatches(ABO_char, consecutive_sequences)[[1]]
# Function to count runs of 5+ and 10+

count_runs <- function(seq, length_threshold) {
  runs <- nchar(seq)
  runs_5_plus <- sum(runs >= length_threshold)
  runs_10_plus <- sum(runs >= length_threshold * 2)
  return(c(runs_5_plus, runs_10_plus))
}

# Initialize a data frame to store the counts
counts_df <- data.frame(Character = c("A", "C", "G", "T"),
                        Runs_5_plus = numeric(4),
                        Runs_10_plus = numeric(4))

# Iterate over each character and count runs of 5+ and 10+
for (i in 1:4) {
  char <- counts_df$Character[i]
  char_sequences <- sequences[grep(char, sequences)]
  counts <- count_runs(char_sequences, 5)
  counts_df$Runs_5_plus[i] <- counts[1]
  counts_df$Runs_10_plus[i] <- counts[2]
}

# Print the data frame
print(counts_df)

# Plot the counts
counts_df_long <- melt(counts_df, id.vars = "Character")

ggplot(counts_df_long, aes(x = Character, y = value, fill = variable)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(
    title = "Runs of Nucleotides in the ABO Gene",
    x = "Nucleotide",
    y = "Count",
    fill = "Run Length"
  ) +
  theme_minimal()

# Perform statistical analysis to see if there is a significant difference in the number of runs of nucleotides
# Perform a chi-squared test
# H0: there is no significant difference in the number of runs of nucleotides in the ABO gene
# H1: there is a significant difference in the number of runs of nucleotides in the ABO gene
chisq.test(counts_df$Runs_5_plus)
# X-squared = 26.767, df = 3, p-value = 6.588e-16
# We reject the null hypothesis and conclude that there is a significant difference in the number of runs of nucleotides in the ABO gene


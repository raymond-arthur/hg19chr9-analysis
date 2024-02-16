from itertools import groupby
import timeit

def longest_consecutive_chars(sequence):
    if not sequence:
        return None

    groups = [list(group) for key, group in groupby(sequence)]
    longest_group = max(groups, key=len)
    
    return ''.join(longest_group)

def find_repeating_sequences(gene):
    repeating_sequences = []
    current_sequence = gene[0]
    count = 1

    for i in range(1, len(gene)):
        if gene[i] == gene[i - 1]:
            count += 1
            current_sequence += gene[i]
        else:
            if count >= 5:
                #print(current_sequence)
                repeating_sequences.append(current_sequence)
            current_sequence = gene[i]
            count = 1

    # Check if the last sequence qualifies
    if count >= 5:
        repeating_sequences.append(current_sequence)

    total_count = len(repeating_sequences)
    return total_count


# main

start = timeit.default_timer()

file_name = "ABO.gene"

print(f'starting search on {file_name}')

with open(file_name, 'r') as file:
    gene_sequence = file.read().strip()

    longest_consecutive = longest_consecutive_chars(gene_sequence)
    five_or_more = find_repeating_sequences(gene_sequence)


print("Longest consecutive characters:", longest_consecutive)
print("Total number of 5-character or higher sequences:", five_or_more)

end = timeit.default_timer() - start

print(f'total time {end}')

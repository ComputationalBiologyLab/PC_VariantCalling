# Install matplotlib-venn if necessary (uncomment the following line if needed)
# pip install matplotlib-venn
# Use matplotlib-venn to draw the Venn diagram
from matplotlib import pyplot as plt
from matplotlib_venn import venn2
import sys
file1 = sys.argv[1]
file2 = sys.argv[3]
inter = sys.argv[2]
venn2(subsets=(int(file1), int(file2), int(inter)), set_labels=('Deep Variant', 'Haplotype'),set_colors=('Green', 'Red'))
#plt.show()
plt.savefig('intersection_plot.png',dpi=300)


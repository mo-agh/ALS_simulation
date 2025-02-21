# Define paths
input_laz_path="NEON_D01_BART_DP1_315000_4879000_classified_point_cloud_colorized.laz"
output_las_path="las/NEON_D01_BART_DP1_315000_4879000_classified_point_cloud_colorized.las"
input_coords="txts/gedi_footprint_site1.txt" # EPSG:4326
output_h5="h5/site1/GEDI_orbit/gedi_footprint_site1.h5"
output_metrics="metrics/site1/GEDI_orbit/gedi_footprint_site1"


# # convert laz to las
# echo "## Converting laz to las"
# /gpfs/data1/vclgp/decontot/repos/LAStools/bin/las2las -i "$input_laz_path" -o "$output_las_path"


# convert coords to las CRS
echo "## Converting coordinates to las CRS"
source /gpfs/data1/vclgp/software/anaconda3/etc/profile.d/conda.sh
conda activate /gpfs/data1/vclgp/aghdamim/envs/edge

python3 <<EOF
import laspy
from pyproj import Transformer
import numpy as np

coords_file = "${input_coords}"
las_file = "${output_las_path}"

las = laspy.read(las_file)
las_crs = las.header.parse_crs()
transformer = Transformer.from_crs("EPSG:4326", las_crs, always_xy=True)

coords = np.loadtxt(coords_file, delimiter="\t", dtype=str)
x_list, y_list = transformer.transform(coords[:, 0], coords[:, 1])

with open(coords_file.split('.txt')[0]+'_converted.txt', "w") as file:
    for x, y in zip(x_list, y_list):
        file.write(f'{x}\t{y}\n')
EOF


# run gediRat
echo "## Running gediRat"
conda deactivate
module load gedisimulator
module load gdal
module load libgeotiff
module add proj4
module add wine
module add hdf5/1.8.15/patch1

output_coords="${input_coords%.txt}_converted.txt"
/gpfs/data1/vclgp/wertisl/git/gedisimulator/gedisimulator/gediRat -input "$output_las_path" -output "$output_h5" -listCoord "$output_coords" -hdf -aEPSG 4326 -readPulse /gpfs/data1/vclgp/data/gedi/simulations/gedi_onorbit/pulses/meanPulse.BEAM1000.filt


# run gediMetric
echo "## Running gediMetric"
/gpfs/data1/vclgp/wertisl/git/gedisimulator/gedisimulator/gediMetric -input "$output_h5" -readHDFgedi -outRoot "$output_metrics"
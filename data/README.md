# Example Data

Data files are provided here for the ease of testing and illustrations.
The data may have been processed for the ease of usage
and are stored in compressed CSV (`.csv.gz`) files.
See [`data/src/make.jl`](src/make.jl) for the source code
that generates these files from original data.

## Sources

| Name | Source | File |
| :---: | :----: | :-------: |
| `bayes.csv.gz` | [Auclert et al. (2021)](https://doi.org/10.3982/ECTA17434) | `import_export/data/data_bayes.csv` |
| `vlw.json.gz` | [vom Lehn and Winberry (2021)](https://doi.org/10.7910/DVN/CALDHX) | `Model Analysis/modelparm_37sec.mat`; `Model Analysis/inddat_TFP_37sec.mat` |

## References

**Auclert, Adrien, Bence Bardóczy, Matthew Rognlie, and Ludwig Straub.** 2021.
"Supplement to 'Using the Sequence-Space Jacobian to Solve and Estimate Heterogeneous-Agent Models'."
*Econometrica Supplemental Material*, 89, https://doi.org/10.3982/ECTA17434.

**vom Lehn, Christian, Thomas Winberry.** 2021.
"Replication Data for: 'The Investment Network, Sectoral Comovement, and the Changing U.S. Business Cycle'."
*The Quarterly Journal of Economics Dataverse*, V1, https://doi.org/10.7910/DVN/CALDHX.

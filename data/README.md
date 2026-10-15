# Data inputs

Obtain the clinical and MRI-feature tables from the
[official TCIA I-SPY2 collection](https://www.cancerimagingarchive.net/collection/ispy2/).
Download the tabular files, not the full MRI images; this analysis uses existing
measurements rather than processing DICOM scans.

Use one of these input routes. Keep patient-level data locally; `.gitignore`
excludes CSV/XLSX files in this directory from normal Git commits.

## Route A: two original tables

Place one CSV or XLSX version of each file here:

- `ISPY2-Imaging-Cohort-1-Clinical-Data.xlsx` (or `.csv`)
- `Multi-feature-MRI-NACT-Data.xlsx` (or `.csv`)

| Table | Required columns |
|---|---|
| Clinical | `Patient_ID`, `pCR`, `HR`, `HER2` |
| MRI features | `CLINICAL.TRIAL.SUBJECT.ID`, `LD_T0`, `SPHERICITY_T0` |

Headers are normalized with R's `make.names()` so a space-separated ID header
may become dot-separated. Files must contain one row per patient and data on
the first worksheet. If a current source export differs, inspect its data
dictionary and adapt the import explicitly; do not guess mappings.

The importer checks for missing or duplicate IDs. It retains the full union of
IDs before complete-case filtering, matching the original full-join design.
No patient IDs are written to the aggregate audit output.

## Route B: already merged input

Provide `analysis_input.csv` with these columns:

| Column | Meaning | Accepted coding |
|---|---|---|
| `pCR` | Pathologic complete response | 0 = no, 1 = yes |
| `LD_T0` | Pretreatment longest tumor diameter | Numeric, source measurement units |
| `SPHERICITY_T0` | Pretreatment tumor sphericity | Numeric |
| `HR` | Hormone receptor status | 0 = negative, 1 = positive |
| `HER2` | HER2 status | 0 = negative, 1 = positive |

One row must represent one patient. This route cannot validate patient uniqueness
unless you check it before exporting. `analysis_input.csv` takes precedence over
the two-table route. Missing values may be blank or `NA`; incomplete rows are
excluded. Invalid nonnumeric or nonbinary values cause an error.

The archived report recorded 384 complete cases. The script warns if a new
input produces a different count; it never forces the data to match that number.
Do not use the aggregate CSVs in `results/reference/` as model inputs.

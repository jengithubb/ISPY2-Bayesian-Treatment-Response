"""Draw archived aggregate results and a clean portfolio PDF; does not fit models.

From repository root: python scripts/render_reference_assets.py
Optional dependencies: pip install -r requirements-report.txt
"""
from pathlib import Path
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak,
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.colors import HexColor, white
from reportlab.lib.enums import TA_LEFT

ROOT = Path(__file__).resolve().parents[1]
FIG = ROOT / "figures"
FIG.mkdir(exist_ok=True)
GREEN, INK, MUTED, PALE = "#286A59", "#203E35", "#66756E", "#EEF4F0"

def read_csv(name):
    with (ROOT / "results/reference" / name).open() as f:
        return list(csv.DictReader(f))

rows = read_csv("posterior_odds_ratios.csv")
loo = read_csv("loo_comparison.csv")
sensitivity = read_csv("default_prior_odds_ratios.csv")
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 11,
                     "axes.spines.top": False, "axes.spines.right": False})

fig, ax = plt.subplots(figsize=(9, 4.2), layout="constrained")
for y, r in enumerate(rows):
    point, lo, hi = (float(r[k]) for k in ("odds_ratio", "lower_95", "upper_95"))
    ax.errorbar(point, y, xerr=[[point-lo], [hi-point]], fmt="o", color=GREEN,
                markersize=7, linewidth=2, capsize=4)
ax.axvline(1, color="#9CA9A2", linestyle="--", linewidth=1)
ax.set_yticks(range(4), [r["label"] for r in rows])
ax.invert_yaxis()
ax.set_xscale("log")
ax.set_xlim(.13, 5.6)
ax.set_xticks([.2, .5, 1, 2, 5], ["0.2", "0.5", "1", "2", "5"])
ax.minorticks_off()
ax.set_xlabel("Odds ratio and 95% credible interval (log scale)")
ax.set_title("MRI features and receptor status", loc="left", fontsize=16, fontweight="bold", pad=20)
ax.spines["left"].set_visible(False)
ax.tick_params(axis="y", length=0, pad=12)
fig.savefig(FIG / "posterior-odds-ratios.png", dpi=190, facecolor="white")
plt.close(fig)

fig, ax = plt.subplots(figsize=(9, 3.4), layout="constrained")
for y, r in enumerate(loo):
    ax.errorbar(float(r["elpd_diff"]), y, xerr=float(r["se_diff"]), fmt="o",
                color=GREEN, markersize=7, capsize=4, linewidth=2)
ax.axvline(0, color="#9CA9A2", linestyle="--", linewidth=1)
ax.set_yticks(range(3), [r["label"] for r in loo])
ax.invert_yaxis()
ax.set_xlim(-26, 2)
ax.set_xlabel("ELPD difference vs additive model; bars show +/- 1 SE")
ax.set_title("Internal LOO model comparison", loc="left", fontsize=16, fontweight="bold", pad=20)
ax.spines["left"].set_visible(False)
ax.tick_params(axis="y", length=0, pad=12)
fig.savefig(FIG / "loo-model-comparison.png", dpi=190, facecolor="white")
plt.close(fig)

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="KickerX", fontName="Helvetica-Bold", fontSize=9,
    textColor=HexColor(GREEN), spaceAfter=14, leading=13))
styles.add(ParagraphStyle(name="TitleX", fontName="Helvetica-Bold", fontSize=29,
    leading=33, textColor=HexColor(INK), spaceAfter=17))
styles.add(ParagraphStyle(name="SubX", fontName="Helvetica", fontSize=12,
    leading=18, textColor=HexColor(MUTED), spaceAfter=16))
styles.add(ParagraphStyle(name="HeadX", fontName="Helvetica-Bold", fontSize=14,
    leading=19, textColor=HexColor(INK), spaceBefore=17, spaceAfter=8))
styles.add(ParagraphStyle(name="BodyX", fontName="Helvetica", fontSize=10.1,
    leading=15, textColor=HexColor(INK), spaceAfter=10))
styles.add(ParagraphStyle(name="SmallX", fontName="Helvetica", fontSize=8.5,
    leading=12, textColor=HexColor(MUTED), spaceAfter=9))
styles.add(ParagraphStyle(name="CellX", fontName="Helvetica", fontSize=9.2,
    leading=13, textColor=HexColor(INK)))

def p(text, style="BodyX"):
    return Paragraph(text, styles[style])

def table(data, widths):
    cells = [[p(str(cell), "CellX") for cell in row] for row in data]
    t = Table(cells, colWidths=widths, hAlign="LEFT")
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), HexColor(PALE)),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 9),
        ("RIGHTPADDING", (0, 0), (-1, -1), 9),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("LINEBELOW", (0, 0), (-1, 0), .6, HexColor("#CFDCD4")),
        ("LINEBELOW", (0, 1), (-1, -1), .3, HexColor("#E5EBE7")),
    ]))
    return t

def footer(canvas, doc):
    canvas.setStrokeColor(HexColor("#D6E2DA"))
    canvas.line(48, 43, 564, 43)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(HexColor(MUTED))
    canvas.drawString(48, 29, "JENNIFER ZHU  /  BIOSTAT 226  /  RECONSTRUCTED PORTFOLIO EDITION")
    canvas.drawRightString(564, 29, str(doc.page))

story = [
    p("BAYESIAN BIOSTATISTICS  /  I-SPY2", "KickerX"),
    p("Modeling breast cancer<br/>treatment response", "TitleX"),
    p("Baseline MRI features, receptor status and uncertainty-aware statistical modeling.", "SubX"),
    p("Jennifer Zhu  |  Original course analysis: March 2026", "SmallX"),
    table([["384", "3", "8,000"],
           ["Complete-case observations", "Primary model specifications", "Post-warmup draws per fitted model"]], [172,172,172]),
    p("The research question", "HeadX"),
    p("Do pretreatment tumor longest diameter and sphericity help characterize pathologic complete response (pCR)? Does receptor status provide additional information? This course project examines those questions with interpretable Bayesian logistic regression."),
    p("Data and study design", "HeadX"),
    p("Clinical and MRI-feature tables from the I-SPY2 imaging cohort were joined by participant identifiers. An independent Python audit of the supplied 985-row clinical and 384-row MRI tables confirmed 384 complete cases for pCR, diameter, sphericity, HR and HER2, matching the course report. Both continuous predictors were standardized before modeling."),
    p("Modeling strategy", "HeadX"),
    table([["Specification", "Predictors"],
           ["Imaging only", "Standardized diameter and sphericity"],
           ["Additive", "Imaging features plus HR and HER2"],
           ["Interaction", "Imaging features plus HR, HER2 and HR x HER2"]], [135,381]),
    Spacer(1, 12),
    p("All models used a Bernoulli likelihood with logit link. Normal priors were specified with SD 1.5 for the intercept, 0.7 for imaging coefficients and 1 for receptor/interaction coefficients. Each fit used four chains, 4,000 iterations per chain, 2,000 warmup and seed 123."),
    p("Provenance: model findings come from the archived course PDF. Input counts were verified separately in Python; the reconstructed R/Stan models have not been rerun.", "SmallX"),
    PageBreak(),
    p("01  /  POSTERIOR ASSOCIATIONS", "KickerX"),
    p("Receptor status carried<br/>clearer associations", "TitleX"),
    p("Conditional on the included predictors, HR-positive status was associated with lower odds of pCR and HER2-positive status with higher odds. The two MRI-feature intervals overlapped an odds ratio of 1."),
    Image(str(FIG / "posterior-odds-ratios.png"), width=480, height=224),
    p("Figure 1. Redrawn from archived additive-model estimates. Points show exponentiated posterior mean log-odds coefficients; bars show 95% credible intervals. No new model was fitted.", "SmallX"),
    table([["Predictor", "Odds ratio", "95% credible interval"]] +
          [[r["label"], f'{float(r["odds_ratio"]):.2f}', f'{float(r["lower_95"]):.2f} to {float(r["upper_95"]):.2f}'] for r in rows], [245,100,171]),
    p("What the estimates mean", "HeadX"),
    p("The receptor variables provided stronger evidence of association in the additive model than these two baseline size and shape features. This does not establish that MRI is uninformative generally; the analysis included only a small subset of possible imaging measurements."),
    p("These conditional associations are not causal treatment effects. OR point estimates follow the source's exp(mean log-odds) convention, rather than the mean of exponentiated posterior draws.", "SmallX"),
    PageBreak(),
    p("02  /  MODEL COMPARISON AND LIMITATIONS", "KickerX"),
    p("A parsimonious<br/>additive specification", "TitleX"),
    Image(str(FIG / "loo-model-comparison.png"), width=516, height=195),
    p("Figure 2. Archived LOO differences relative to the additive model. Error bars are +/- one standard error of the difference, not 95% intervals. The reference model's zero is defined by the comparison.", "SmallX"),
    p("The additive model ranked highest. The interaction specification had a similar score (difference -0.5, SE 0.4), while imaging alone scored lower (-17.9, SE 5.8). The original analysis selected the additive model for its balance of fit and simplicity."),
    p("Diagnostics and sensitivity", "HeadX"),
    p("The archived additive-model summary reported R-hat values of 1.00 and large effective sample sizes. A default-prior refit retained similar coefficient directions: HR OR 0.26 and HER2 OR 2.86, compared with 0.29 and 2.60 under the specified priors. This is a limited sensitivity check."),
    p("Limits of the evidence", "HeadX"),
    p("Complete-case selection, a small predictor set, and lack of treatment-arm adjustment limit interpretation. The comparison used internal LOO, not external validation, and preserved global standardization. Original draws and full Pareto-k output were unavailable. The source PDF also retains compiler messages alongside later sampling outputs; an error-free original execution is not assumed."),
    p("Reconstruction and sources", "HeadX"),
    p("The editable original was unavailable. R scripts were reconstructed from the author's archived report; displayed results were transcribed, not refitted. Source: reports/source-course-report.pdf, pp. 3-4, 7-9 and 14-15. Data collection: cancerimagingarchive.net/collection/ispy2/. Software: paulbuerkner.com/brms/.", "SmallX"),
]
pdf = ROOT / "reports/bayesian-treatment-response-report.pdf"
SimpleDocTemplate(str(pdf), pagesize=(612,792), rightMargin=48, leftMargin=48,
                  topMargin=45, bottomMargin=62, title="Bayesian Modeling of Breast Cancer Treatment Response",
                  author="Jennifer Zhu").build(story, onFirstPage=footer, onLaterPages=footer)
print(pdf)

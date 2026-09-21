# Quick codebook: variables for descriptive subgroup comparisons

Source: labels and observed values in `world_values_survey_data/raw_data/WVS_Wave_7_South_Korea_Stata_v5.1.dta` (South Korea, 2018; 1,245 respondents). Checked against `R/outputs/CODE.R` on 2026-09-17. Descriptions below are concise summaries, not the full questionnaire wording.

## Already selected in clean_data

| Variable | Meaning | Codes / interpretation |
| --- | --- | --- |
| `Q260` | Sex | `1` = Male; `2` = Female. You currently display these as Men and Women. |
| `Q262` | Age | Age in years; observed range: 18–88. Any age bands must be defined by you. |
| `Q275R` | Education, three groups | `1` = Lower; `2` = Middle; `3` = Higher. See the definitions below. |
| `Q240` | Position on the left–right political scale | `1` = Left; `10` = Right. Intermediate values run from 2 to 9. Any division into left, centre, and right is your recoding, not an existing three-category variable. |
| `Q223` | Which party the respondent would vote for if a national election were held tomorrow | Uses the party codes below. This is voting intention, not a record of the respondent's vote in a previous election. |

### Education: Q275R

These group definitions were verified by cross-tabulating `Q275R` with the detailed education variable `Q275` in this file.

| Code | Group | Education included | Respondents |
| --- | --- | --- | ---: |
| `1` | Lower | ISCED 0–2: no education / early childhood, primary, or lower secondary | 140 |
| `2` | Middle | ISCED 3–4: upper secondary or post-secondary non-tertiary | 522 |
| `3` | Higher | ISCED 5–8: short-cycle tertiary, bachelor's, master's, or doctoral level | 583 |

### Party codes: Q223

These are the historical party labels in this dataset, not a list of current parties.

| Code | Party / response | Respondents |
| --- | --- | ---: |
| `410001` | Liberty Korea Party - Grand National Party | 183 |
| `410002` | Democratic Party | 533 |
| `410008` | People's Party | 71 |
| `410009` | Bareun Party | 34 |
| `410010` | Justice Party | 23 |
| `5` | Other | 3 |
| `8` | Independent candidate | 32 |
| `NA` | No answer | 366 |

There are 879 valid answers to `Q223`. Do not treat missing answers as a party or infer support for a previous election's winner directly from this question.

## Optional variables: available in raw_data, not yet selected in clean_data

| Variable | Meaning | Codes / interpretation |
| --- | --- | --- |
| `Q199` | Interest in politics | `1` = Very interested; `2` = Somewhat interested; `3` = Not very interested; `4` = Not at all interested. |
| `Q288R` | Income, three groups | `1` = Low; `2` = Medium; `3` = High. Group counts: 196, 1,028, and 21. |
| `Q288` | More detailed income scale | Observed codes are 1–8 in this file, ordered from lower to higher income. These are scale categories, not currency amounts. |
| `Q279` | Employment status | `1` = Full time (30+ hours/week); `2` = Part time (<30 hours/week); `3` = Self employed; `4` = Retired/pensioned; `5` = Homemaker not otherwise employed; `6` = Student; `7` = Unemployed. |
| `Q222` | Frequency of voting in national elections | `1` = Always; `2` = Usually; `3` = Never; `4` = Not allowed to vote. |
| `Q275` | Detailed education, ISCED 2011 | `0` = Early childhood / no education; `1` = Primary; `2` = Lower secondary; `3` = Upper secondary; `4` = Post-secondary non-tertiary; `5` = Short-cycle tertiary; `6` = Bachelor's or equivalent; `7` = Master's or equivalent; `8` = Doctoral or equivalent. |

To use an optional variable in your plotting calls, first include it in the `dplyr::select()` that creates `clean_data`.

## Quick cautions

- Sex: 607 men and 638 women in the full file. A particular graph's valid counts still depend on missing answers to the plotted question.
- Small groups: very interested in politics (`Q199 = 1`, n = 30); high income (`Q288R = 3`, n = 21); retired (`Q279 = 4`, n = 29); unemployed (`Q279 = 7`, n = 21); several party categories are also small. Small groups provide less precise estimates.
- Voting: not allowed to vote is distinct from never voting; do not combine them automatically.
- Missing values: among the variables listed here, `Q223` has 366 missing values; the others have none in this file. Missingness can differ for your election and democracy questions.
- Weight: `W_WEIGHT` is already selected and equals 1 for all 1,245 respondents in this file, so applying this particular weight does not change the percentages.
- Percentage interpretation: calculate each answer's percentage within the subgroup. Each subgroup's four valid-response percentages total 100%, apart from rounding.
